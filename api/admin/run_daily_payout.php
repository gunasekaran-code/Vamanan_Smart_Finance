<?php
// api/admin/run_daily_payout.php
// Manual trigger for the daily cashback payout — callable from Admin Dashboard.
//
// Delegates to the canonical daily yield engine (run_daily_yield) so this path
// ALWAYS matches the cron: configured daily cashback rate, TDS + service charges
// withheld (net credited), and the FLAT single-level referral bonus (no tree).
// Kept as a thin wrapper for backward compatibility with any old callers.
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

date_default_timezone_set('Asia/Kolkata');

require_once '../config.php';                 // provides global $pdo (+ self-healing migrations)
require_once '../cron/daily_yield_engine.php';

try {
    $result = run_daily_yield($pdo);

    if (($result['status'] ?? '') === 'success') {
        echo json_encode([
            "status"          => "success",
            "message"         => ($result['processed'] ?? 0) . " cycles processed via yield engine.",
            "processed_count" => $result['processed'] ?? 0,
            "logs"            => $result['logs'] ?? [],
        ]);
    } else {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => $result['message'] ?? 'Yield engine failed.']);
    }
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
