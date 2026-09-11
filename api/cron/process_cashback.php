<?php
// api/cron/process_cashback.php
// Manual "Process Yield" trigger (admin button). LIMITED TO ONCE PER CALENDAR MONTH:
// once a successful run has happened in a month, further clicks are rejected (nothing
// is credited) until the 1st of the next month. The per-cycle anniversary + last_paid_at
// guards inside the engine are the ultimate safety net against any double-credit.
//   GET ?check=1  → report whether this month has already been processed (no run)
//   GET           → run the monthly yield (once per month), else report already_run
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");

date_default_timezone_set('Asia/Kolkata');

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/daily_yield_engine.php';

$month = date('Y-m');                                  // current calendar month, e.g. 2026-07
$monthLabel = date('F Y');                             // e.g. "July 2026"
$nextAvailable = date('d M Y', strtotime('first day of next month')); // e.g. "01 Aug 2026"

// Ensure the guard row exists.
$pdo->exec("CREATE TABLE IF NOT EXISTS platform_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)");
$pdo->exec("INSERT IGNORE INTO platform_settings (config_key, config_value) VALUES ('manual_yield_run_month', NULL)");

$storedMonth = $pdo->query("SELECT config_value FROM platform_settings WHERE config_key = 'manual_yield_run_month'")->fetchColumn();
$alreadyRun = ($storedMonth === $month);

// Status-check mode: tell the UI whether the button is available this month.
if (isset($_GET['check'])) {
    echo json_encode([
        "status"         => "success",
        "already_run"    => $alreadyRun,
        "month"          => $month,
        "month_label"    => $monthLabel,
        "next_available" => $nextAvailable,
        "message"        => $alreadyRun
            ? "Cashback already processed for {$monthLabel}."
            : "Ready to process {$monthLabel}.",
    ]);
    exit;
}

// Atomically claim this month — only the first caller in the month wins the run.
$claim = $pdo->prepare("UPDATE platform_settings SET config_value = :month
                        WHERE config_key = 'manual_yield_run_month'
                        AND (config_value IS NULL OR config_value <> :month)");
$claim->execute([':month' => $month]);

if ($claim->rowCount() !== 1) {
    // Already processed this month — credit nothing, just report it.
    echo json_encode([
        "status"         => "success",
        "already_run"    => true,
        "processed"      => 0,
        "month"          => $month,
        "month_label"    => $monthLabel,
        "next_available" => $nextAvailable,
        "message"        => "Cashback for {$monthLabel} has already been processed. The button unlocks again on {$nextAvailable}.",
    ]);
    exit;
}

// We hold this month's claim — run the engine.
$result = run_daily_yield($pdo);

// Keep the monthly lock ONLY if this run actually credited something. If it failed,
// or nothing was due yet (processed = 0), release the claim so the admin can still
// process later in the month once installments come due.
if (($result['status'] ?? '') !== 'success' || (int)($result['processed'] ?? 0) <= 0) {
    $pdo->prepare("UPDATE platform_settings SET config_value = NULL WHERE config_key = 'manual_yield_run_month'")->execute();
}

$processed = (int)($result['processed'] ?? 0);
$locked = (($result['status'] ?? '') === 'success' && $processed > 0);
$result['already_run']    = false;
$result['month']          = $month;
$result['month_label']    = $monthLabel;
$result['next_available'] = $nextAvailable;
$result['locked']         = $locked;
if (($result['status'] ?? '') === 'success') {
    $result['message'] = $processed > 0
        ? "{$processed} cycle(s) processed for {$monthLabel}. The button is now locked until {$nextAvailable}."
        : "No monthly installments were due yet — nothing to credit. You can run again when installments come due this month.";
}
echo json_encode($result);
?>
