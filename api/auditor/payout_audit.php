<?php
// api/auditor/payout_audit.php — per-cycle cashback + referral audit with anomaly flags.
// Verifies the combined (cashback + referral) accrual never exceeds the 100% principal cap.
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

require_once __DIR__ . '/../config.php';
$db = $pdo;

try {
    $planMonths = max(1, (int)($db->query("SELECT config_value FROM platform_settings WHERE config_key='plan_duration_months'")->fetchColumn() ?: 10));

    $stmt = $db->query("SELECT c.id, c.user_id, c.product_name, c.status, c.days_paid,
        c.cashback_eligible_amount, c.total_value, c.paid_amount, c.created_at,
        u.name, u.customer_id, w.balance AS wallet_balance
        FROM cashback_cycles c
        JOIN users u ON u.id = c.user_id
        LEFT JOIN wallets w ON w.user_id = c.user_id
        ORDER BY c.created_at DESC");
    $cycles = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $rows = []; $anomalies = [];
    $totPrincipal = 0; $totEarned = 0;

    foreach ($cycles as $c) {
        $principal = (float)$c['cashback_eligible_amount']; if ($principal <= 0) $principal = (float)$c['total_value'];
        $earned = (float)$c['paid_amount'];               // combined cashback + referral (gross)
        $pct = $principal > 0 ? round(($earned / $principal) * 100, 2) : 0;
        $months = (int)$c['days_paid'];

        $flags = [];
        if ($earned > $principal + 0.01) $flags[] = 'OVER_CAP';                       // must never exceed principal
        if ($months > $planMonths)       $flags[] = 'OVER_MONTHS';
        if ((float)$c['wallet_balance'] < -0.01) $flags[] = 'NEGATIVE_WALLET';
        if ($c['status'] === 'active' && $earned >= $principal - 0.01 && $principal > 0) $flags[] = 'SHOULD_BE_COMPLETE';

        $row = [
            'cycle_id'    => (int)$c['id'],
            'user_id'     => (int)$c['user_id'],
            'name'        => $c['name'],
            'customer_id' => $c['customer_id'],
            'product'     => $c['product_name'],
            'principal'   => round($principal, 2),
            'earned'      => round($earned, 2),
            'remaining'   => round(max(0, $principal - $earned), 2),
            'pct'         => $pct,
            'months_paid' => $months,
            'plan_months' => $planMonths,
            'status'      => $c['status'],
            'wallet_balance' => round((float)$c['wallet_balance'], 2),
            'flags'       => $flags,
            'created_at'  => $c['created_at'],
        ];
        $rows[] = $row;
        if ($flags) $anomalies[] = $row;
        $totPrincipal += $principal; $totEarned += $earned;
    }

    // Cross-check: any customer with more than one ACTIVE cycle (informational flag).
    $dupes = $db->query("SELECT u.id user_id, u.name, u.customer_id, COUNT(*) c
        FROM cashback_cycles cc JOIN users u ON u.id=cc.user_id
        WHERE cc.status='active' GROUP BY u.id, u.name, u.customer_id HAVING c > 1")->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode(["status" => "success", "data" => $rows, "anomalies" => $anomalies,
        "duplicate_active" => $dupes,
        "summary" => [
            "cycles"          => count($rows),
            "anomaly_count"   => count($anomalies),
            "total_principal" => round($totPrincipal, 2),
            "total_earned"    => round($totEarned, 2),
            "total_remaining" => round(max(0, $totPrincipal - $totEarned), 2),
        ]]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
