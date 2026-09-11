<?php
// api/admin/holidays.php
// Admin-managed holiday calendar. Dates listed here are non-working days on which
// the daily yield engine does NOT accrue cashback or referral. Real-time, DB-backed.
//   GET                       → list all holidays (+ this-year count)
//   POST {date,name,type}     → add / upsert a holiday
//   POST {action:'delete',id} → remove a holiday
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

require_once '../config.php';
$db = $pdo;

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $data = json_decode(file_get_contents("php://input"), true) ?: [];
        $action = $data['action'] ?? 'add';

        if ($action === 'delete') {
            $id = (int)($data['id'] ?? 0);
            if ($id <= 0) throw new Exception("Valid holiday id required.");
            $db->prepare("DELETE FROM holidays WHERE id = ?")->execute([$id]);
            echo json_encode(["status" => "success", "message" => "Holiday removed."]);
            exit;
        }

        // Add / upsert
        $date = trim($data['date'] ?? '');
        $name = trim($data['name'] ?? '');
        $type = trim($data['type'] ?? 'government');
        if ($date === '' || !preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) throw new Exception("Valid date (YYYY-MM-DD) required.");
        if ($name === '') $name = 'Holiday';
        if (!in_array($type, ['government', 'bank', 'weekend', 'other'], true)) $type = 'government';

        $db->prepare("INSERT INTO holidays (holiday_date, name, type) VALUES (?,?,?)
                      ON DUPLICATE KEY UPDATE name = VALUES(name), type = VALUES(type)")
           ->execute([$date, $name, $type]);
        echo json_encode(["status" => "success", "message" => "Holiday saved."]);
        exit;
    }

    // GET — list
    $rows = $db->query("SELECT id, holiday_date, name, type FROM holidays ORDER BY holiday_date ASC")->fetchAll(PDO::FETCH_ASSOC);
    $year = date('Y');
    $thisYear = 0;
    foreach ($rows as $r) { if (substr($r['holiday_date'], 0, 4) === $year) $thisYear++; }

    echo json_encode([
        "status" => "success",
        "data" => $rows,
        "summary" => [
            "total" => count($rows),
            "this_year" => $thisYear,
            "year" => (int)$year,
        ],
    ]);
} catch (Throwable $e) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
