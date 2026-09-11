<?php
// api/customer/referrals.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../config.php';
$db = $pdo;

$userId = $_GET['user_id'] ?? null;
if (!$userId) {
    echo json_encode(["status" => "error", "message" => "User ID required"]);
    exit;
}

try {
    // ── 1. User info + referral code ─────────────────────────────
    $uStmt = $db->prepare("SELECT name, referral_code, COALESCE(referral_active, 1) AS referral_active FROM users WHERE id = ?");
    $uStmt->execute([$userId]);
    $userRow = $uStmt->fetch(PDO::FETCH_ASSOC);
    $referralCode = $userRow['referral_code'] ?? 'N/A';
    $referralActive = (int)($userRow['referral_active'] ?? 1);

    // ── 2. Flat referral commission rate (single level — no tree) ─
    $stmtSet = $db->query("SELECT config_key, config_value FROM platform_settings WHERE config_key IN ('referral_commission_rate','referral_commission_l1')");
    $rates = $stmtSet->fetchAll(PDO::FETCH_KEY_PAIR);
    $commissionRateNum = (float)($rates['referral_commission_rate'] ?? $rates['referral_commission_l1'] ?? 2);
    $commissionRate = $commissionRateNum . '%';

    // ── 2b. Own daily cashback rate (for "YOU" node in the structure) ──
    $dcStmt = $db->prepare("SELECT config_value FROM platform_settings WHERE config_key = 'daily_cashback_rate'");
    $dcStmt->execute();
    $dailyCashbackRate = ($dcStmt->fetchColumn() ?: '2') . '%';

    // ── 2c. TDS + service/processing charge rates withheld from incentives ──
    $rateStmt = $db->query("SELECT config_key, config_value FROM platform_settings WHERE config_key IN ('tds_rate','service_charge_rate','tds_charges_rate')");
    $rateMap = $rateStmt->fetchAll(PDO::FETCH_KEY_PAIR);
    if (isset($rateMap['tds_rate']) || isset($rateMap['service_charge_rate'])) {
        $tdsRatePct    = (float)($rateMap['tds_rate'] ?? 0);
        $chargeRatePct = (float)($rateMap['service_charge_rate'] ?? 0);
    } else {
        $tdsRatePct    = (float)($rateMap['tds_charges_rate'] ?? 10);
        $chargeRatePct = 0.0;
    }
    $totalDedRatePct = $tdsRatePct + $chargeRatePct;

    // ── 3. Flat referral earnings from ALL referral commissions ──
    // Single level (direct referrals only) — every referral transaction for this
    // user is a flat direct-referral commission. amount = net credited;
    // gross_amount / deduction carry the TDS/charges breakdown (COALESCE to amount
    // for any legacy rows written before the TDS columns existed).
    $earnStmt = $db->prepare("
        SELECT COALESCE(SUM(t.amount), 0) as earnings,
               COALESCE(SUM(COALESCE(t.gross_amount, t.amount)), 0) as gross,
               COALESCE(SUM(COALESCE(t.tds_amount, 0)), 0) as tds,
               COALESCE(SUM(COALESCE(t.charges_amount, 0)), 0) as charges,
               COALESCE(SUM(COALESCE(t.deduction, 0)), 0) as deduction
        FROM transactions t
        JOIN wallets w ON t.wallet_id = w.id
        WHERE w.user_id = ? AND t.category = 'referral'
    ");
    $earnStmt->execute([$userId]);
    $earnRow  = $earnStmt->fetch(PDO::FETCH_ASSOC);
    $totalEarnings  = (float) ($earnRow['earnings'] ?? 0);   // net (credited)
    $totalGross     = (float) ($earnRow['gross'] ?? 0);      // pre-deduction
    $totalTds       = (float) ($earnRow['tds'] ?? 0);        // TDS component
    $totalCharges   = (float) ($earnRow['charges'] ?? 0);    // service/processing charge component
    $totalDeduction = (float) ($earnRow['deduction'] ?? 0);  // total withheld (tds + charges)

    // ── 4. Direct referrals (Level 1 full list) ──────────────────
    $directStmt = $db->prepare("
        SELECT u.id, u.customer_id, u.name, u.created_at, u.kyc_status,
               COALESCE(SUM(c.total_value), 0) as invested
        FROM users u
        LEFT JOIN cashback_cycles c ON c.user_id = u.id AND c.status = 'active'
        WHERE u.referrer_id = ?
        GROUP BY u.id, u.customer_id, u.name, u.created_at, u.kyc_status
        ORDER BY u.created_at DESC
    ");
    $directStmt->execute([$userId]);
    $directReferrals = $directStmt->fetchAll(PDO::FETCH_ASSOC);

    // ── 5. Eligibility check (REMOVED as per request - now automatic) ──
    $progress = count($directReferrals);
    $eligible = true; 

    // ── 6. Today's referral earnings ─────────────────────────────
    $todayStmt = $db->prepare("
        SELECT COALESCE(SUM(t.amount), 0) as today
        FROM transactions t
        JOIN wallets w ON t.wallet_id = w.id
        WHERE w.user_id = ? AND t.category = 'referral'
          AND DATE(t.created_at) = CURDATE()
    ");
    $todayStmt->execute([$userId]);
    $todayEarnings = (float) $todayStmt->fetch(PDO::FETCH_ASSOC)['today'];

    // ── 7. Referral transaction history ──────────────────────────
    $histStmt = $db->prepare("
        SELECT t.id, t.amount, t.gross_amount, t.tds_amount, t.charges_amount, t.deduction, t.description, t.created_at, t.status
        FROM transactions t
        JOIN wallets w ON t.wallet_id = w.id
        WHERE w.user_id = ? AND t.category = 'referral'
        ORDER BY t.created_at DESC
        LIMIT 30
    ");
    $histStmt->execute([$userId]);
    $history = $histStmt->fetchAll(PDO::FETCH_ASSOC);

    // ── 8. User's active investment ─────────────────────────────
    $invStmt = $db->prepare("SELECT COALESCE(SUM(total_value),0) as inv FROM cashback_cycles WHERE user_id = ? AND status = 'active'");
    $invStmt->execute([$userId]);
    $userInvestment = (float) $invStmt->fetch(PDO::FETCH_ASSOC)['inv'];

    echo json_encode([
        "status" => "success",
        "data" => [
            "referral_code" => $referralCode,
            "referral_active" => $referralActive,
            "daily_cashback_rate" => $dailyCashbackRate,
            "commission_rate" => $commissionRate,                // flat referral rate, e.g. "2%"
            "commission_rate_num" => $commissionRateNum,         // numeric, e.g. 2
            "direct_count" => count($directReferrals),
            "tds_rate" => $tdsRatePct,
            "service_charge_rate" => $chargeRatePct,
            "total_deduction_rate" => $totalDedRatePct,
            "total_network_earnings" => $totalEarnings,          // net credited
            "total_network_gross" => $totalGross,                // before deductions
            "total_network_tds" => $totalTds,                    // TDS component
            "total_network_charges" => $totalCharges,            // charges component
            "total_network_deduction" => $totalDeduction,        // total withheld
            "today_earnings" => $todayEarnings,
            "progress" => $progress,
            "eligible" => $eligible,
            "direct_referrals" => $directReferrals,
            "user_investment" => $userInvestment,
            "history" => $history,
        ]
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>