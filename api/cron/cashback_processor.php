<?php
// api/cron/cashback_processor.php
// Legacy cashback cron — now a thin wrapper around the canonical monthly yield
// engine so it can never diverge (monthly installment, TDS + charges withheld,
// flat referral, 100% principal cap). Kept for backward compatibility with any
// old scheduler still hitting this URL.
header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . '/../config.php';                 // global $pdo
require_once __DIR__ . '/daily_yield_engine.php';

try {
    $result = run_daily_yield($pdo);
    echo json_encode([
        "status"  => ($result['status'] ?? 'error') === 'success' ? 'success' : 'error',
        "message" => ($result['processed'] ?? 0) . " cycle(s) processed via monthly yield engine.",
        "processed" => $result['processed'] ?? 0,
    ]);
} catch (Throwable $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
