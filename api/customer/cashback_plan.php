<?php
// api/customer/cashback_plan.php
// Returns full cashback plan details for the logged-in customer
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

date_default_timezone_set('Asia/Kolkata');

try {
    require_once '../config/db.php';
    
    $database = new Database();
    $db       = $database->getConnection();

    $userId = $_GET['user_id'] ?? null;
    if (!$userId) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "user_id required"]);
        exit;
    }

    // 1. Fetch Cycles with new real-time columns
    $cStmt = $db->prepare("
        SELECT c.*
        FROM cashback_cycles c
        WHERE c.user_id = ?
        ORDER BY c.created_at DESC
    ");
    $cStmt->execute([$userId]);
    $cycles = $cStmt->fetchAll(PDO::FETCH_ASSOC);

    // ── AUTOMATIC PAYOUT TRIGGER (Lazy Processing) ───────────────────────────
    // Delegate to the canonical daily yield engine so this page can never diverge
    // from the cron: it applies the configured daily cashback rate, withholds TDS +
    // service charges (net credited), and pays the flat single-level referral bonus.
    // Idempotent per day (claimed atomically via platform_settings.last_yield_run).
    $payoutRun = false;
    require_once '../cron/daily_yield_engine.php';
    $engineResult = maybe_run_daily_yield($db);
    if ($engineResult && ($engineResult['status'] ?? '') === 'success' && ($engineResult['processed'] ?? 0) > 0) {
        $payoutRun = true;
        // Re-fetch cycles so the response reflects the just-credited progress.
        $cStmt->execute([$userId]);
        $cycles = $cStmt->fetchAll(PDO::FETCH_ASSOC);
    }
    // ─────────────────────────────────────────────────────────────────────────


    // 2. Aggregate stats
    $totalInvested    = 0;   // total actually paid (incl. GST)
    $totalEligible    = 0;   // GST-excluded base that cashback is earned on
    $totalGst         = 0;
    $totalEarned      = 0;
    $totalDailyPayout = 0;
    $activeCyclesCount = 0;
    $activeCycle      = null;
    // Monthly plan duration (installments). days_paid is repurposed as months paid.
    $planMonths = (int)($db->query("SELECT config_value FROM platform_settings WHERE config_key = 'plan_duration_months'")->fetchColumn() ?: 10);
    if ($planMonths < 1) $planMonths = 10;

    foreach ($cycles as $cycle) {
        $cycleEligible = (float)($cycle['cashback_eligible_amount'] ?? 0);
        if ($cycleEligible <= 0) $cycleEligible = (float)$cycle['total_value'];
        $totalInvested += (float)$cycle['total_value'];
        $totalEligible += $cycleEligible;
        $totalGst      += (float)($cycle['gst_amount'] ?? 0);
        $totalEarned   += (float)($cycle['paid_amount'] ?? 0);

        if ($cycle['status'] === 'active' || $cycle['status'] === 'pending') {
            if ($cycle['status'] === 'active') {
                $totalDailyPayout += (float)($cycle['daily_payout'] ?? 0);
                $activeCyclesCount++;
            }
            if (!$activeCycle) {
                $activeCycle = $cycle;
            }
        }
    }

    // Current metrics (days_paid repurposed as monthly installments paid).
    $daysCompleted = $activeCycle ? (int)$activeCycle['days_paid'] : 0;
    $daysRemaining = max(0, $planMonths - $daysCompleted);
    // Progress is measured against the GST-excluded base (the 100% cashback cap).
    $activeEligible = $activeCycle ? ((float)($activeCycle['cashback_eligible_amount'] ?? 0) ?: (float)$activeCycle['total_value']) : 0;
    $remainingValue = $activeCycle ? $activeEligible - (float)$activeCycle['paid_amount'] : 0;
    $cashbackPct = $totalEligible > 0 ? round(($totalEarned / $totalEligible) * 100, 2) : 0;

    // 3. Transactions
    $tStmt = $db->prepare("
        SELECT t.*
        FROM transactions t
        JOIN wallets w ON t.wallet_id = w.id
        WHERE w.user_id = ? AND t.category IN ('cashback', 'referral', 'payout')
        ORDER BY t.created_at DESC
        LIMIT 50
    ");
    $tStmt->execute([$userId]);
    $transactions = $tStmt->fetchAll(PDO::FETCH_ASSOC);

    // 4. Today's Earning
    $today = date('Y-m-d');
    $todayEarned = 0;
    foreach($transactions as $tx) {
        // Match today's date and either 'cashback' or legacy 'payout' category
        if (strpos($tx['created_at'], $today) === 0 && ($tx['category'] === 'cashback' || $tx['category'] === 'payout')) {
            $todayEarned += (float)$tx['amount'];
        }
    }

    // 5. Referral Earned
    $referralEarned = 0;
    foreach($transactions as $tx) {
        if ($tx['category'] === 'referral') {
            $referralEarned += (float)$tx['amount'];
        }
    }

    // 5. Next Payout In — the next MONTHLY installment anniversary from the cycle start.
    //    Installment N is due at created_at + N months; next due = created_at + (months_paid + 1) months.
    $now = new DateTime();
    if ($activeCycle && $daysRemaining > 0) {
        $start = new DateTime($activeCycle['created_at'] ?? 'now');
        $payoutTime = (clone $start)->modify('+' . ($daysCompleted + 1) . ' months');
        if ($payoutTime < $now) $payoutTime = $now; // overdue → due now
    } else {
        $payoutTime = (clone $now)->modify('+1 month');
    }

    $diff = $now->diff($payoutTime);
    $nextPayoutStr = $diff->days > 0 ? ($diff->days . "d " . $diff->h . "h") : ($diff->h . "h " . $diff->i . "m");
    $nextPayoutTs  = $payoutTime->getTimestamp() * 1000; // JavaScript timestamp (ms)

    $combinedEarned = max((float)$totalEarned, (float)($activeCycle['paid_amount'] ?? 0));

    echo json_encode([
        "status" => "success",
        "data"   => [
            "cycles"             => $cycles,
            "active_cycle"       => $activeCycle ? [
                "id"             => $activeCycle['id'],
                "total_value"    => (float)$activeCycle['total_value'],
                "product_amount" => (float)($activeCycle['product_amount'] ?? $activeEligible),
                "gst_amount"     => (float)($activeCycle['gst_amount'] ?? 0),
                "total_amount"   => (float)($activeCycle['total_amount'] ?? $activeCycle['total_value']),
                "cashback_eligible_amount" => (float)$activeEligible,
                "daily_payout"   => (float)$activeCycle['daily_payout'],
                "monthly_payout" => (float)$activeCycle['daily_payout'],   // repurposed: monthly installment
                "total_earned"   => (float)$activeCycle['paid_amount'],
                "remaining_value"=> (float)$remainingValue,
                "days_completed" => $daysCompleted,
                "days_remaining" => $daysRemaining,
                "plan_months"      => $planMonths,
                "months_completed" => $daysCompleted,
                "months_remaining" => $daysRemaining,
                "status"         => $activeCycle['status'],
                "asset_type"     => $activeCycle['asset_type'] ?? 'gold',
                "weight"         => (float)($activeCycle['weight'] ?? 0),
                "product_name"   => ($activeCycle['asset_type'] === 'silver' ? 'Pure Silver' : '22K Gold') . ' Asset',
                "cashback_pct"   => $cashbackPct,
            ] : null,
            "stats" => [
                "total_invested"     => (float)$totalInvested,
                "total_eligible"     => (float)$totalEligible,
                "total_gst"          => (float)$totalGst,
                "total_earned"       => (float)$combinedEarned,
                "total_daily_payout" => (float)$totalDailyPayout,   // repurposed: total monthly installment
                "total_monthly_payout" => (float)$totalDailyPayout,
                "plan_months"        => $planMonths,
                "active_cycles"      => $activeCyclesCount,
                "today_earned"       => (float)$todayEarned,
                "referral_earned"    => (float)$referralEarned,
                "next_payout_in"     => $nextPayoutStr,
                "next_payout_ts"     => $nextPayoutTs,
                "cashback_percentage"=> $cashbackPct
            ],
            "transactions" => $transactions
        ]
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "CASHBACK_ERR: " . $e->getMessage()]);
}
?>
