<?php
// api/cron/daily_yield_engine.php
//
// Reusable "Monthly Yield" engine — credits each customer's MONTHLY cashback
// installment (principal returned over `plan_duration_months` equal months,
// default 10 → 10%/month = 100% total) plus a FLAT single-level referral
// commission (direct referrer only — no multi-level tree). Referral shares the
// same 100% principal cap. Installments are anniversary-based: one per month from
// the purchase date. Rates & duration are admin-configurable.
//
// Two entry points:
//   run_daily_yield($db)        → process today's payout for every active cycle.
//                                 Idempotent per day: each cycle carries
//                                 last_paid_at, and only cycles with
//                                 last_paid_at < CURDATE() are picked up, so a
//                                 second run on the same day is a no-op.
//   maybe_run_daily_yield($db)  → "lazy cron": runs run_daily_yield() at most
//                                 once per calendar day, claimed atomically via
//                                 platform_settings.last_yield_run so concurrent
//                                 web requests can't double-trigger it. Safe to
//                                 call from any high-traffic endpoint; never
//                                 throws (failures are swallowed so the host
//                                 request is unaffected).

require_once __DIR__ . '/../models/Wallet.php';

if (!function_exists('yield_is_working_day')) {
    // Cashback (and the daily referral run) accrue ONLY on working days.
    // Non-working = weekend (Sat/Sun, unless disabled via `cashback_skip_weekends`)
    // OR a date listed in the admin-managed `holidays` table (government/bank/other).
    // So over a month, only business days earn cashback.
    function yield_is_working_day(PDO $db, string $date, array $settings = []): bool {
        // Weekend gate (default ON: Saturday + Sunday are off).
        $skipWeekends = !isset($settings['cashback_skip_weekends']) || (string)$settings['cashback_skip_weekends'] !== '0';
        if ($skipWeekends) {
            $dow = (int)date('N', strtotime($date)); // 1=Mon … 6=Sat, 7=Sun
            if ($dow === 6 || $dow === 7) return false;
        }
        // Explicit holiday gate.
        try {
            $st = $db->prepare("SELECT COUNT(*) FROM holidays WHERE holiday_date = ?");
            $st->execute([$date]);
            if ((int)$st->fetchColumn() > 0) return false;
        } catch (Throwable $e) { /* holidays table may not exist yet — treat as working day */ }
        return true;
    }
}

if (!function_exists('process_referral_commission')) {
    function process_referral_commission(PDO $db, int $cycleId): ?array {
        // Ensure referral_paid column exists.
        // IMPORTANT: DDL (ALTER TABLE) causes an IMPLICIT COMMIT in MySQL. Running it
        // blindly here used to silently end the CALLER's open transaction (admin approval,
        // daily yield run), so their later commit() blew up with
        // "There is no active transaction" — the approval had already been written, but the
        // endpoint still answered HTTP 500. So: probe with a plain read, and only ever run
        // the ALTER when no transaction is open.
        static $referralPaidReady = false;
        if (!$referralPaidReady) {
            try {
                $probe = $db->query("SHOW COLUMNS FROM cashback_cycles LIKE 'referral_paid'");
                if ($probe && $probe->fetch(PDO::FETCH_ASSOC)) {
                    $referralPaidReady = true;
                } elseif (!$db->inTransaction()) {
                    $db->exec("ALTER TABLE cashback_cycles ADD COLUMN referral_paid TINYINT(1) NOT NULL DEFAULT 0 AFTER status");
                    $referralPaidReady = true;
                }
            } catch (Throwable $e) { /* column probe/creation is best-effort */ }
        }

        // Fetch cycle info
        $stmt = $db->prepare("SELECT id, user_id, cashback_eligible_amount, total_value, COALESCE(referral_paid, 0) AS referral_paid FROM cashback_cycles WHERE id = ?");
        $stmt->execute([$cycleId]);
        $cycle = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$cycle || (int)$cycle['referral_paid'] === 1) {
            return null; // Already paid or cycle not found
        }

        $buyerUserId = (int)$cycle['user_id'];
        $eligible = (float)($cycle['cashback_eligible_amount'] ?? 0);
        if ($eligible <= 0) $eligible = (float)$cycle['total_value'];

        // Find referrer
        $refStmt = $db->prepare("SELECT referrer_id FROM users WHERE id = ?");
        $refStmt->execute([$buyerUserId]);
        $referrerId = $refStmt->fetchColumn();

        if (!$referrerId) {
            $db->prepare("UPDATE cashback_cycles SET referral_paid = 1 WHERE id = ?")->execute([$cycleId]);
            return null;
        }

        // Rank (first 10 direct lines) and active flag
        $eligibilityStmt = $db->prepare("SELECT COUNT(*) FROM users WHERE referrer_id = ? AND created_at <= (SELECT created_at FROM users WHERE id = ?)");
        $eligibilityStmt->execute([$referrerId, $buyerUserId]);
        $rank = (int)$eligibilityStmt->fetchColumn();

        $refActiveStmt = $db->prepare("SELECT COALESCE(referral_active, 1) FROM users WHERE id = ?");
        $refActiveStmt->execute([$referrerId]);
        $referralActive = (int)$refActiveStmt->fetchColumn();

        if ($rank > 10 || $referralActive !== 1) {
            $db->prepare("UPDATE cashback_cycles SET referral_paid = 1 WHERE id = ?")->execute([$cycleId]);
            return null;
        }

        // Load platform settings
        $settings = [];
        try {
            $settings = $db->query("SELECT config_key, config_value FROM platform_settings")->fetchAll(PDO::FETCH_KEY_PAIR);
        } catch (Throwable $e) {}

        if (isset($settings['referral_commission_rate'])) {
            $referralRate = (float)$settings['referral_commission_rate'] / 100;
        } elseif (isset($settings['referral_commission_l1'])) {
            $referralRate = (float)$settings['referral_commission_l1'] / 100;
        } else {
            $referralRate = 0.02;
        }

        if (isset($settings['tds_rate']) || isset($settings['service_charge_rate'])) {
            $tdsRatePct    = isset($settings['tds_rate']) ? (float)$settings['tds_rate'] : 0.0;
            $chargeRatePct = isset($settings['service_charge_rate']) ? (float)$settings['service_charge_rate'] : 0.0;
        } else {
            $tdsRatePct    = isset($settings['tds_charges_rate']) ? (float)$settings['tds_charges_rate'] : 10.0;
            $chargeRatePct = 0.0;
        }
        $tdsRate    = $tdsRatePct / 100;
        $chargeRate = $chargeRatePct / 100;

        $commAmount = $eligible * $referralRate;
        if ($commAmount <= 0) {
            $db->prepare("UPDATE cashback_cycles SET referral_paid = 1 WHERE id = ?")->execute([$cycleId]);
            return null;
        }

        // Check referrer's active investment cycle & cap
        $refCycleStmt = $db->prepare("SELECT * FROM cashback_cycles WHERE user_id = ? AND status = 'active' ORDER BY created_at ASC LIMIT 1");
        $refCycleStmt->execute([$referrerId]);
        $refCycle = $refCycleStmt->fetch(PDO::FETCH_ASSOC);

        $actualComm = $commAmount;
        if ($refCycle) {
            $refTotalValue = (float)($refCycle['cashback_eligible_amount'] ?? 0);
            if ($refTotalValue <= 0) $refTotalValue = (float)$refCycle['total_value'];
            $refTotalEarned = (float)$refCycle['paid_amount'];
            if ($refTotalEarned >= $refTotalValue) {
                // Referrer reached 100% principal cap
                $db->prepare("UPDATE cashback_cycles SET referral_paid = 1 WHERE id = ?")->execute([$cycleId]);
                return null;
            }
            if (($refTotalEarned + $commAmount) > $refTotalValue) {
                $actualComm = $refTotalValue - $refTotalEarned;
            }
            $newRefEarned = $refTotalEarned + $actualComm;
            $newRefStatus = ($newRefEarned >= $refTotalValue) ? 'completed' : 'active';
            $db->prepare("UPDATE cashback_cycles SET paid_amount = ?, status = ? WHERE id = ?")
               ->execute([$newRefEarned, $newRefStatus, $refCycle['id']]);
        }

        $grossComm     = round($actualComm, 2);
        $commTds       = round($grossComm * $tdsRate, 2);
        $commCharges   = round($grossComm * $chargeRate, 2);
        $commDeduction = round($commTds + $commCharges, 2);
        $netComm       = round($grossComm - $commDeduction, 2);

        if ($netComm <= 0 && $grossComm <= 0) {
            $db->prepare("UPDATE cashback_cycles SET referral_paid = 1 WHERE id = ?")->execute([$cycleId]);
            return null;
        }

        // Get buyer name
        $buyerNameStmt = $db->prepare("SELECT name FROM users WHERE id = ?");
        $buyerNameStmt->execute([$buyerUserId]);
        $buyerName = $buyerNameStmt->fetchColumn() ?: "User #{$buyerUserId}";

        require_once __DIR__ . '/../models/Wallet.php';
        $walletModel = new Wallet($db);
        $walletModel->credit(
            $referrerId,
            $netComm,
            'referral',
            "Referral Commission (" . round($referralRate * 100, 2) . "%) from {$buyerName} (User #{$buyerUserId}) — gross ₹" . number_format($grossComm, 2) . " less TDS {$tdsRatePct}% ₹" . number_format($commTds, 2) . " + charges {$chargeRatePct}% ₹" . number_format($commCharges, 2) . " = net ₹" . number_format($netComm, 2) . " — Cycle #{$cycleId}",
            $grossComm,
            $commDeduction,
            $commTds,
            $commCharges
        );

        $db->prepare("UPDATE cashback_cycles SET referral_paid = 1 WHERE id = ?")->execute([$cycleId]);

        return [
            "referrer_id" => $referrerId,
            "gross"       => $grossComm,
            "tds"         => $commTds,
            "charges"     => $commCharges,
            "net"         => $netComm
        ];
    }
}

if (!function_exists('run_daily_yield')) {
    function run_daily_yield(PDO $db): array {
        date_default_timezone_set('Asia/Kolkata');
        $db->exec("SET time_zone = '+05:30'");
        $walletModel = new Wallet($db);

        $logs = [];
        $logs[] = "Initializing Yield Protocol at " . date('Y-m-d H:i:s');

        // Dynamic platform settings (rates are admin-configurable).
        $settings = [];
        try {
            $settings = $db->query("SELECT config_key, config_value FROM platform_settings")->fetchAll(PDO::FETCH_KEY_PAIR);
        } catch (Throwable $e) { /* table may not exist yet — fall back to defaults */ }

        // MONTHLY cashback plan: the principal (100% of the GST-excluded product value)
        // is returned over `plan_duration_months` EQUAL monthly installments
        // (default 10 → 10% of principal per month). Referral commissions accrue
        // alongside and share the SAME 100% principal cap, so a referrer's plan can
        // complete before all 10 months if referral fills the cap first.
        $planMonths  = isset($settings['plan_duration_months']) ? max(1, (int)$settings['plan_duration_months']) : 10;
        $monthlyRate = 1.0 / $planMonths; // e.g. 10 months → 0.10 (10% of principal / month)

        // TDS + processing/service charges withheld from every incentive credit
        // (cashback & referral). Both rates are independently admin-configurable.
        // Customer's cycle still accrues the GROSS amount (so the 1%/day, 100% cap
        // semantics are untouched); only the wallet is credited the NET after these cuts.
        // Falls back to the legacy combined `tds_charges_rate` if the split keys are absent.
        if (isset($settings['tds_rate']) || isset($settings['service_charge_rate'])) {
            $tdsRatePct     = isset($settings['tds_rate']) ? (float)$settings['tds_rate'] : 0.0;
            $chargeRatePct  = isset($settings['service_charge_rate']) ? (float)$settings['service_charge_rate'] : 0.0;
        } else {
            // Legacy: single combined rate, treated entirely as TDS.
            $tdsRatePct     = isset($settings['tds_charges_rate']) ? (float)$settings['tds_charges_rate'] : 10.0;
            $chargeRatePct  = 0.0;
        }
        $tdsRate       = $tdsRatePct / 100;
        $chargeRate    = $chargeRatePct / 100;
        $totalDedPct   = $tdsRatePct + $chargeRatePct;

        // Flat single-level referral rate — the direct referrer earns this on the
        // buyer's GST-excluded base. No multi-level tree. Reads the canonical
        // `referral_commission_rate` key, falling back to the legacy `referral_commission_l1`.
        if (isset($settings['referral_commission_rate'])) {
            $referralRate = (float)$settings['referral_commission_rate'] / 100;
        } elseif (isset($settings['referral_commission_l1'])) {
            $referralRate = (float)$settings['referral_commission_l1'] / 100;
        } else {
            $referralRate = 0.02;
        }

        $getUserInvestment = function ($uid) use ($db) {
            $st = $db->prepare("SELECT SUM(total_value) AS sum_inv FROM cashback_cycles WHERE user_id = ? AND status = 'active'");
            $st->execute([$uid]);
            return (float)($st->fetch(PDO::FETCH_ASSOC)['sum_inv'] ?? 0);
        };

        $db->beginTransaction();
        try {
            // Active cycles whose next MONTHLY installment is due. days_paid is
            // repurposed as the count of monthly installments already credited
            // (0..planMonths). Monthly payout: exactly one installment per calendar month
            // for active cycles created on or before today.
            $stmt = $db->prepare("SELECT * FROM cashback_cycles
                                  WHERE days_paid < :planMonths AND status = 'active'
                                  AND DATE(created_at) <= CURDATE()
                                  AND (last_paid_at IS NULL OR DATE_FORMAT(last_paid_at, '%Y-%m') < DATE_FORMAT(CURDATE(), '%Y-%m'))");
            $stmt->execute([':planMonths' => $planMonths]);
            $cycles = $stmt->fetchAll(PDO::FETCH_ASSOC);
            $logs[] = "Processing " . count($cycles) . " cycles with a monthly installment due...";

            foreach ($cycles as $cycle) {
                $userId = $cycle['user_id'];
                // GST-exclusive: cashback is computed on the product subtotal only.
                $eligible = (float)($cycle['cashback_eligible_amount'] ?? 0);
                if ($eligible <= 0) $eligible = (float)$cycle['total_value']; // legacy rows (GST was 0)

                // Re-read LIVE progress: referral commissions credited earlier in THIS pass
                // (when this user is an upline of an already-processed buyer) may have advanced
                // paid_amount. Using the stale bulk-fetched row would let cashback + referral
                // together exceed the principal. The cap is on the COMBINED total.
                $freshStmt = $db->prepare("SELECT paid_amount, days_paid, status FROM cashback_cycles WHERE id = ?");
                $freshStmt->execute([$cycle['id']]);
                $fresh = $freshStmt->fetch(PDO::FETCH_ASSOC);
                if (!$fresh || $fresh['status'] !== 'active') {
                    continue; // principal already reached (via referral) — stop, even before all months
                }
                $currentPaid   = (float)$fresh['paid_amount'];
                $currentMonths = (int)$fresh['days_paid']; // repurposed: installments paid so far

                // One monthly installment = principal / plan months (e.g. 10% for a 10-month plan).
                $monthlyCashback = $eligible * $monthlyRate;

                $newMonthsCompleted = $currentMonths + 1;
                $newTotalEarned     = $currentPaid + $monthlyCashback;
                $newStatus = ($newTotalEarned >= $eligible || $newMonthsCompleted >= $planMonths) ? 'completed' : 'active';

                // Cap the COMBINED (cashback + referral) earnings at 100% of the GST-excluded base.
                if ($newTotalEarned > $eligible) {
                    $monthlyCashback -= ($newTotalEarned - $eligible);
                    $newTotalEarned = $eligible;
                    $newStatus = 'completed';
                }

                if ($monthlyCashback > 0) {
                    // GROSS accrues to the cycle; NET (post TDS + charges) hits the wallet.
                    $grossCashback = round($monthlyCashback, 2);
                    $tds           = round($grossCashback * $tdsRate, 2);
                    $charges       = round($grossCashback * $chargeRate, 2);
                    $deduction     = round($tds + $charges, 2);
                    $netCashback   = round($grossCashback - $deduction, 2);
                    $db->prepare("UPDATE cashback_cycles SET days_paid = ?, paid_amount = ?, status = ?, last_paid_at = CURDATE() WHERE id = ?")
                       ->execute([$newMonthsCompleted, $newTotalEarned, $newStatus, $cycle['id']]);
                    $walletModel->credit(
                        $userId,
                        $netCashback,
                        'cashback',
                        "Monthly " . round($monthlyRate * 100, 2) . "% cashback on ₹" . number_format($eligible, 2) . " (excl. GST) — Month {$newMonthsCompleted} of {$planMonths} — gross ₹" . number_format($grossCashback, 2) . " less TDS {$tdsRatePct}% ₹" . number_format($tds, 2) . " + charges {$chargeRatePct}% ₹" . number_format($charges, 2) . " = net ₹" . number_format($netCashback, 2) . " — Cycle #{$cycle['id']}",
                        $grossCashback,
                        $deduction,
                        $tds,
                        $charges
                    );
                    $logs[] = "Node #{$userId}: Cycle #{$cycle['id']} Month {$newMonthsCompleted}/{$planMonths} gross ₹{$grossCashback}, net ₹{$netCashback}";
                }

                // Process referral commission idempotently (credited exactly once per purchase cycle)
                $refRes = process_referral_commission($db, (int)$cycle['id']);
                if ($refRes) {
                    $logs[] = "   -> Referrer #{$refRes['referrer_id']} flat referral: gross ₹{$refRes['gross']}, TDS ₹{$refRes['tds']}, charges ₹{$refRes['charges']}, net ₹{$refRes['net']}";
                }
            }

            if ($db->inTransaction()) $db->commit();
            $logs[] = "Protocol finalized successfully at " . date('Y-m-d H:i:s');
            return ["status" => "success", "message" => "Yield Protocol Completed Successfully.", "processed" => count($cycles), "logs" => $logs];
        } catch (Throwable $e) {
            if ($db->inTransaction()) $db->rollBack();
            $logs[] = "PROTOCOL_FAILURE: " . $e->getMessage();
            return ["status" => "error", "message" => "PROTOCOL_FAILURE: " . $e->getMessage(), "logs" => $logs];
        }
    }
}

if (!function_exists('maybe_run_daily_yield')) {
    function maybe_run_daily_yield(PDO $db): ?array {
        try {
            // Guard store (shares the platform_settings table).
            $db->exec("CREATE TABLE IF NOT EXISTS platform_settings (
                id INT AUTO_INCREMENT PRIMARY KEY,
                config_key VARCHAR(100) UNIQUE NOT NULL,
                config_value TEXT,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )");
            $db->exec("INSERT IGNORE INTO platform_settings (config_key, config_value) VALUES ('last_yield_run', NULL)");

            // Atomically claim today's run — only one concurrent request wins.
            $claim = $db->prepare("UPDATE platform_settings SET config_value = CURDATE()
                                   WHERE config_key = 'last_yield_run'
                                   AND (config_value IS NULL OR config_value = '' OR config_value < CURDATE())");
            $claim->execute();
            if ($claim->rowCount() !== 1) {
                return null; // already ran (or claimed) today
            }

            $result = run_daily_yield($db);

            // If the engine failed, release the claim so a later request can retry today.
            if (($result['status'] ?? '') !== 'success') {
                $db->prepare("UPDATE platform_settings SET config_value = NULL WHERE config_key = 'last_yield_run'")->execute();
            }
            return $result;
        } catch (Throwable $e) {
            // Never let the lazy trigger break the host request.
            try {
                if ($db->inTransaction()) $db->rollBack();
                $db->prepare("UPDATE platform_settings SET config_value = NULL WHERE config_key = 'last_yield_run'")->execute();
            } catch (Throwable $ignored) {}
            return null;
        }
    }
}
?>
