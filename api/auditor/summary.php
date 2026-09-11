<?php
// api/auditor/summary.php — read-only audit dashboard KPIs + monthly financial statement.
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

require_once __DIR__ . '/../config.php';
$db = $pdo;

try {
    $q = fn($sql) => (float)($db->query($sql)->fetchColumn() ?: 0);

    // Revenue (ex-GST base + GST) from immutable invoices.
    $revenue      = $q("SELECT COALESCE(SUM(total_amount),0) FROM invoices");
    $taxable      = $q("SELECT COALESCE(SUM(taxable_amount),0) FROM invoices");
    $gstCollected = $q("SELECT COALESCE(SUM(gst_amount),0) FROM invoices");
    $cgst         = $q("SELECT COALESCE(SUM(cgst_amount),0) FROM invoices");
    $sgst         = $q("SELECT COALESCE(SUM(sgst_amount),0) FROM invoices");
    $invoiceCount = (int)$q("SELECT COUNT(*) FROM invoices");

    // Incentive payouts (credited cashback + referral) with TDS / charges withheld.
    $inc = $db->query("SELECT
        COALESCE(SUM(amount),0) net,
        COALESCE(SUM(COALESCE(gross_amount,amount)),0) gross,
        COALESCE(SUM(COALESCE(tds_amount,0)),0) tds,
        COALESCE(SUM(COALESCE(charges_amount,0)),0) charges
        FROM transactions WHERE type='credit' AND category IN ('cashback','referral') AND status='completed'")->fetch(PDO::FETCH_ASSOC);

    $cashbackNet  = $q("SELECT COALESCE(SUM(amount),0) FROM transactions WHERE type='credit' AND category='cashback' AND status='completed'");
    $referralNet  = $q("SELECT COALESCE(SUM(amount),0) FROM transactions WHERE type='credit' AND category='referral' AND status='completed'");

    // Wallet liability + withdrawals.
    $walletLiability = $q("SELECT COALESCE(SUM(balance),0) FROM wallets");
    $withdrawnPaid   = $q("SELECT COALESCE(SUM(amount),0) FROM withdrawals WHERE status IN ('completed','approved','paid')");
    $withdrawPending = $q("SELECT COALESCE(SUM(amount),0) FROM withdrawals WHERE status='pending'");

    // Counts.
    $users        = (int)$q("SELECT COUNT(*) FROM users WHERE role='customer'");
    $activeCycles = (int)$q("SELECT COUNT(*) FROM cashback_cycles WHERE status='active'");
    $txCount      = (int)$q("SELECT COUNT(*) FROM transactions");

    // Last yield run guards.
    $lastMonthly = $db->query("SELECT config_value FROM platform_settings WHERE config_key='manual_yield_run_month'")->fetchColumn();
    $lastDaily   = $db->query("SELECT config_value FROM platform_settings WHERE config_key='last_yield_run'")->fetchColumn();

    // Monthly statement — last 12 months (invoiced revenue / GST + incentive payouts + TDS).
    $months = [];
    $rev = $db->query("SELECT DATE_FORMAT(created_at,'%Y-%m') m, SUM(total_amount) rev, SUM(gst_amount) gst, SUM(taxable_amount) tax
                       FROM invoices WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
                       GROUP BY m")->fetchAll(PDO::FETCH_ASSOC);
    $pay = $db->query("SELECT DATE_FORMAT(created_at,'%Y-%m') m,
                       SUM(amount) net, SUM(COALESCE(tds_amount,0)+COALESCE(charges_amount,0)) ded
                       FROM transactions WHERE type='credit' AND category IN ('cashback','referral') AND status='completed'
                       AND created_at >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH) GROUP BY m")->fetchAll(PDO::FETCH_ASSOC);
    $revMap = []; foreach ($rev as $r) $revMap[$r['m']] = $r;
    $payMap = []; foreach ($pay as $r) $payMap[$r['m']] = $r;
    $keys = array_unique(array_merge(array_keys($revMap), array_keys($payMap)));
    sort($keys);
    foreach ($keys as $k) {
        $months[] = [
            'month'    => $k,
            'revenue'  => round((float)($revMap[$k]['rev'] ?? 0), 2),
            'gst'      => round((float)($revMap[$k]['gst'] ?? 0), 2),
            'taxable'  => round((float)($revMap[$k]['tax'] ?? 0), 2),
            'payouts'  => round((float)($payMap[$k]['net'] ?? 0), 2),
            'deductions' => round((float)($payMap[$k]['ded'] ?? 0), 2),
        ];
    }

    echo json_encode(["status" => "success", "data" => [
        "revenue"           => round($revenue, 2),
        "taxable"           => round($taxable, 2),
        "gst_collected"     => round($gstCollected, 2),
        "cgst"              => round($cgst, 2),
        "sgst"              => round($sgst, 2),
        "invoice_count"     => $invoiceCount,
        "payouts_net"       => round((float)$inc['net'], 2),
        "payouts_gross"     => round((float)$inc['gross'], 2),
        "tds_withheld"      => round((float)$inc['tds'], 2),
        "charges_withheld"  => round((float)$inc['charges'], 2),
        "cashback_net"      => round($cashbackNet, 2),
        "referral_net"      => round($referralNet, 2),
        "wallet_liability"  => round($walletLiability, 2),
        "withdrawn_paid"    => round($withdrawnPaid, 2),
        "withdraw_pending"  => round($withdrawPending, 2),
        "customers"         => $users,
        "active_cycles"     => $activeCycles,
        "transactions"      => $txCount,
        "last_monthly_run"  => $lastMonthly ?: null,
        "last_daily_run"    => $lastDaily ?: null,
        "monthly_statement" => $months,
    ]]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
