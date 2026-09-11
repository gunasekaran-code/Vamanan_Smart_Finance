<?php
// api/admin/get_user_daily_payout.php

// Suppress errors from breaking JSON, but log them if possible
error_reporting(0);
ini_set('display_errors', 0);

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

try {
    require_once '../config/db.php';

    $database = new Database();
    $db = $database->getConnection();

    if (!$db) {
        throw new Exception("Database connection failed");
    }

    $user_id = $_GET['user_id'] ?? null;

    if (!$user_id) {
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "user_id is required"]);
        exit;
    }

    // 1. Fetch Cycles
    $cStmt = $db->prepare("SELECT * FROM cashback_cycles WHERE user_id = ? AND status = 'active' ORDER BY created_at DESC");
    $cStmt->execute([$user_id]);
    $cycles = $cStmt->fetchAll(PDO::FETCH_ASSOC);

    // 2. Fetch Wallet
    $wStmt = $db->prepare("SELECT balance, total_earned, total_withdrawn FROM wallets WHERE user_id = ? LIMIT 1");
    $wStmt->execute([$user_id]);
    $wallet = $wStmt->fetch(PDO::FETCH_ASSOC);

    // 2b. Live rates (same source the yield engine uses) — never trust a stale stored payout.
    $rates = $db->query("SELECT config_key, config_value FROM platform_settings
                         WHERE config_key IN ('plan_duration_months','tds_rate','service_charge_rate','tds_charges_rate')")
                ->fetchAll(PDO::FETCH_KEY_PAIR);
    // Monthly plan: one installment = principal / plan months (e.g. 10 → 10%/month).
    $planMonths = max(1, (int)($rates['plan_duration_months'] ?? 10));
    if (isset($rates['tds_rate']) || isset($rates['service_charge_rate'])) {
        $tdsRate    = (float)($rates['tds_rate'] ?? 0) / 100;
        $chargeRate = (float)($rates['service_charge_rate'] ?? 0) / 100;
    } else {
        $tdsRate    = (float)($rates['tds_charges_rate'] ?? 10) / 100;
        $chargeRate = 0.0;
    }

    // 3. Totals — daily payout is COMPUTED from the ex-GST cashback base (matches the engine),
    //    falling back to the stored column only when a base isn't available.
    $total_daily_payout   = 0;   // gross monthly installment
    $total_daily_tds      = 0;
    $total_daily_charges  = 0;
    $total_invested       = 0;   // sum of total_value (incl. GST) — what the customer paid
    $total_eligible       = 0;   // sum of ex-GST base — the actual 100% cap the engine uses
    $total_earned_cycles  = 0;

    if ($cycles) {
        foreach($cycles as &$c) {
            $eligible = (float)($c['cashback_eligible_amount'] ?? 0);
            if ($eligible <= 0) $eligible = (float)($c['total_value'] ?? 0);
            $grossDaily = round($eligible / $planMonths, 2); // one MONTHLY installment (gross)
            if ($grossDaily <= 0) $grossDaily = (float)($c['daily_payout'] ?? 0); // last-resort fallback
            $c['daily_payout']      = $grossDaily;                         // normalise for the UI
            $c['daily_tds']         = round($grossDaily * $tdsRate, 2);
            $c['daily_charges']     = round($grossDaily * $chargeRate, 2);
            $c['daily_net']         = round($grossDaily - $c['daily_tds'] - $c['daily_charges'], 2);

            $total_daily_payout  += $grossDaily;
            $total_daily_tds     += $c['daily_tds'];
            $total_daily_charges += $c['daily_charges'];
            $total_invested      += (float)($c['total_value'] ?? 0);
            $total_eligible      += $eligible;
            $total_earned_cycles += (float)($c['paid_amount'] ?? 0);
        }
        unset($c);
    }

    // 2c. Combined earnings breakdown (cashback + referral incentives together)
    $ref_earned_tx = (float)$db->query("SELECT COALESCE(SUM(t.amount), 0) FROM transactions t JOIN wallets w ON t.wallet_id = w.id WHERE w.user_id = " . intval($user_id) . " AND t.category = 'referral' AND t.type = 'credit'")->fetchColumn();
    $cashback_earned_tx = (float)$db->query("SELECT COALESCE(SUM(t.amount), 0) FROM transactions t JOIN wallets w ON t.wallet_id = w.id WHERE w.user_id = " . intval($user_id) . " AND t.category = 'cashback' AND t.type = 'credit'")->fetchColumn();
    $combined_earned = max((float)($wallet['total_earned'] ?? 0), (float)$total_earned_cycles, (float)($cashback_earned_tx + $ref_earned_tx));

    $total_daily_deduction = round($total_daily_tds + $total_daily_charges, 2);
    $total_daily_net = round($total_daily_payout - $total_daily_deduction, 2);
    // Remaining / progress measured against the EX-GST eligible base (the real 100% cap the
    // combined cashback + referral stops at) — so a completed plan reads 100%, not ~78%.
    $remaining_value = max(0, $total_eligible - $combined_earned);
    $cashback_pct = $total_eligible > 0 ? round(($combined_earned / $total_eligible) * 100, 2) : 0;
    $days_completed = !empty($cycles) ? (int)($cycles[0]['days_paid'] ?? 0) : 0;

    echo json_encode([
        "status" => "success",
        "data"   => [
            "cycles"                 => $cycles,
            "total_daily_payout"     => (float)$total_daily_payout,      // gross 1% yield
            "total_daily_tds"        => (float)$total_daily_tds,
            "total_daily_charges"    => (float)$total_daily_charges,
            "total_daily_deduction"  => (float)$total_daily_deduction,
            "total_daily_net"        => (float)$total_daily_net,         // net credited after deductions
            "total_invested"         => (float)$total_invested,
            "total_eligible"         => (float)$total_eligible,          // ex-GST 100% cap base
            "total_earned"           => (float)$combined_earned,
            "cashback_earned"        => (float)$cashback_earned_tx,
            "referral_earned"        => (float)$ref_earned_tx,
            "remaining_value"        => (float)$remaining_value,         // vs ex-GST cap
            "cashback_percentage"    => (float)$cashback_pct,
            "days_completed"         => $days_completed,     // repurposed: months paid
            "months_completed"       => $days_completed,
            "plan_months"            => $planMonths,
            "total_monthly_payout"   => (float)$total_daily_payout,   // gross monthly installment (alias)
            "total_monthly_net"      => (float)$total_daily_net,
            "active_cycles"          => count($cycles),
            "wallet_balance"         => (float)($wallet['balance'] ?? 0),
            "total_withdrawn"        => (float)($wallet['total_withdrawn'] ?? 0),
        ]
    ]);

} catch (Throwable $e) {
    // Return 200 with error status so Axios can read the message
    // http_response_code(200); 
    echo json_encode([
        "status" => "error", 
        "message" => "API Error: " . $e->getMessage(),
        "file" => basename($e->getFile()),
        "line" => $e->getLine()
    ]);
}
?>
