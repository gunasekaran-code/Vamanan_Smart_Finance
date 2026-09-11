<?php
// api/auditor/tds_report.php — TDS + service-charge withholding report (Form-26Q style).
// Per-customer + platform totals, optional month filter.
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

require_once __DIR__ . '/../config.php';
$db = $pdo;

try {
    $where = ["t.type='credit'", "t.category IN ('cashback','referral')", "t.status='completed'"];
    $params = [];
    if (!empty($_GET['month'])) { $where[] = "DATE_FORMAT(t.created_at,'%Y-%m') = ?"; $params[] = $_GET['month']; }
    $whereSql = 'WHERE ' . implode(' AND ', $where);

    // Per-customer breakdown.
    $stmt = $db->prepare("SELECT u.id AS user_id, u.name, u.customer_id, u.pan_no,
        COALESCE(SUM(COALESCE(t.gross_amount,t.amount)),0) gross,
        COALESCE(SUM(COALESCE(t.tds_amount,0)),0) tds,
        COALESCE(SUM(COALESCE(t.charges_amount,0)),0) charges,
        COALESCE(SUM(t.amount),0) net,
        COUNT(*) txns
        FROM transactions t JOIN wallets w ON t.wallet_id=w.id JOIN users u ON w.user_id=u.id
        $whereSql GROUP BY u.id, u.name, u.customer_id, u.pan_no
        HAVING gross > 0 ORDER BY tds DESC");
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $totGross = 0; $totTds = 0; $totCharges = 0; $totNet = 0;
    foreach ($rows as &$r) {
        $r['gross'] = round((float)$r['gross'], 2);
        $r['tds'] = round((float)$r['tds'], 2);
        $r['charges'] = round((float)$r['charges'], 2);
        $r['net'] = round((float)$r['net'], 2);
        $r['txns'] = (int)$r['txns'];
        $totGross += $r['gross']; $totTds += $r['tds']; $totCharges += $r['charges']; $totNet += $r['net'];
    }
    unset($r);

    // Monthly trend (last 12 months) for the TDS chart.
    $trend = $db->query("SELECT DATE_FORMAT(created_at,'%Y-%m') m,
        SUM(COALESCE(tds_amount,0)) tds, SUM(COALESCE(charges_amount,0)) charges
        FROM transactions WHERE type='credit' AND category IN ('cashback','referral') AND status='completed'
        AND created_at >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH) GROUP BY m ORDER BY m")->fetchAll(PDO::FETCH_ASSOC);

    // Current withholding rates for reference.
    $rates = $db->query("SELECT config_key, config_value FROM platform_settings WHERE config_key IN ('tds_rate','service_charge_rate')")->fetchAll(PDO::FETCH_KEY_PAIR);

    // Available months for the filter.
    $availMonths = $db->query("SELECT DISTINCT DATE_FORMAT(created_at,'%Y-%m') m FROM transactions
        WHERE category IN ('cashback','referral') ORDER BY m DESC")->fetchAll(PDO::FETCH_COLUMN);

    echo json_encode(["status" => "success", "data" => $rows, "summary" => [
        "total_gross"   => round($totGross, 2),
        "total_tds"     => round($totTds, 2),
        "total_charges" => round($totCharges, 2),
        "total_deduction" => round($totTds + $totCharges, 2),
        "total_net"     => round($totNet, 2),
        "tds_rate"      => (float)($rates['tds_rate'] ?? 0),
        "charge_rate"   => (float)($rates['service_charge_rate'] ?? 0),
        "payees"        => count($rows),
    ], "trend" => $trend, "months" => $availMonths]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
