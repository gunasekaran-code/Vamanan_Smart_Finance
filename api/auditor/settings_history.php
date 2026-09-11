<?php
// api/auditor/settings_history.php — immutable log of platform_settings changes.
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
    if (!empty($_GET['key']))    { $where[] = "config_key = ?"; $params[] = $_GET['key']; }
    if (!empty($_GET['search'])) { $where[] = "(config_key LIKE ? OR changed_by LIKE ?)"; $like = "%{$_GET['search']}%"; array_push($params, $like, $like); }
    $whereSql = $where ? ('WHERE ' . implode(' AND ', $where)) : '';

    $stmt = $db->prepare("SELECT id, config_key, old_value, new_value, changed_by, created_at
                          FROM settings_audit $whereSql ORDER BY created_at DESC, id DESC LIMIT 500");
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Distinct keys for the filter dropdown.
    $keys = $db->query("SELECT DISTINCT config_key FROM settings_audit ORDER BY config_key")->fetchAll(PDO::FETCH_COLUMN);

    echo json_encode(["status" => "success", "data" => $rows, "keys" => $keys, "count" => count($rows)]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
