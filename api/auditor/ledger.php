<?php
// api/auditor/ledger.php — read-only financial ledger. Every transaction with the
// gross → TDS → charges → net breakdown, filterable by date / user / category / status.
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

require_once __DIR__ . '/../config.php';
$db = $pdo;

try {
    $where = [];
    $params = [];
    if (!empty($_GET['from']))     { $where[] = "t.created_at >= ?"; $params[] = $_GET['from'] . " 00:00:00"; }
    if (!empty($_GET['to']))       { $where[] = "t.created_at <= ?"; $params[] = $_GET['to'] . " 23:59:59"; }
    if (!empty($_GET['category']) && $_GET['category'] !== 'all') { $where[] = "t.category = ?"; $params[] = $_GET['category']; }
    if (!empty($_GET['status'])   && $_GET['status']   !== 'all') { $where[] = "t.status = ?";   $params[] = $_GET['status']; }
    if (!empty($_GET['type'])     && $_GET['type']     !== 'all') { $where[] = "t.type = ?";     $params[] = $_GET['type']; }
    if (!empty($_GET['user_id']))  { $where[] = "u.id = ?"; $params[] = (int)$_GET['user_id']; }
    if (!empty($_GET['search']))   {
        $where[] = "(u.name LIKE ? OR u.customer_id LIKE ? OR t.description LIKE ?)";
        $like = "%{$_GET['search']}%"; array_push($params, $like, $like, $like);
    }
    $whereSql = $where ? ('WHERE ' . implode(' AND ', $where)) : '';
    $limit = isset($_GET['limit']) ? max(1, min(1000, (int)$_GET['limit'])) : 300;

    // Totals across the whole filtered set (not just the page).
    $totStmt = $db->prepare("SELECT
        COUNT(*) cnt,
        COALESCE(SUM(CASE WHEN t.type='credit' THEN t.amount ELSE 0 END),0) credits,
        COALESCE(SUM(CASE WHEN t.type='debit'  THEN t.amount ELSE 0 END),0) debits,
        COALESCE(SUM(COALESCE(t.gross_amount,t.amount)),0) gross,
        COALESCE(SUM(COALESCE(t.tds_amount,0)),0) tds,
        COALESCE(SUM(COALESCE(t.charges_amount,0)),0) charges
        FROM transactions t JOIN wallets w ON t.wallet_id=w.id JOIN users u ON w.user_id=u.id $whereSql");
    $totStmt->execute($params);
    $tot = $totStmt->fetch(PDO::FETCH_ASSOC);

    $stmt = $db->prepare("SELECT t.id, t.type, t.category, t.amount, t.gross_amount, t.tds_amount, t.charges_amount, t.deduction,
                                 t.description, t.status, t.created_at, u.id AS user_id, u.name AS user_name, u.customer_id
                          FROM transactions t JOIN wallets w ON t.wallet_id=w.id JOIN users u ON w.user_id=u.id
                          $whereSql ORDER BY t.created_at DESC, t.id DESC LIMIT $limit");
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode(["status" => "success", "data" => $rows, "summary" => [
        "count"        => (int)$tot['cnt'],
        "total_credits"=> round((float)$tot['credits'], 2),
        "total_debits" => round((float)$tot['debits'], 2),
        "total_gross"  => round((float)$tot['gross'], 2),
        "total_tds"    => round((float)$tot['tds'], 2),
        "total_charges"=> round((float)$tot['charges'], 2),
        "net_flow"     => round((float)$tot['credits'] - (float)$tot['debits'], 2),
        "shown"        => count($rows),
    ]]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
