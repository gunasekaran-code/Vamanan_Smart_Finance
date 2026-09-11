<?php
// api/auditor/reconciliation.php — wallet balance vs ledger reconciliation.
// computed = SUM(credits) − SUM(debits) over wallet-affecting completed transactions;
// mismatch = stored balance − computed. Flags any wallet that doesn't reconcile.
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

require_once __DIR__ . '/../config.php';
$db = $pdo;

try {
    // Wallet-affecting categories only (purchases are paid externally, not from the wallet).
    $affecting = "('cashback','referral','payout','withdrawal','manual','deposit','liquidation')";

    $stmt = $db->query("SELECT w.id AS wallet_id, w.user_id, w.balance, w.total_earned, w.total_withdrawn,
        u.name, u.customer_id,
        COALESCE(SUM(CASE WHEN t.type='credit' AND t.status='completed' AND t.category IN $affecting THEN t.amount ELSE 0 END),0) credits,
        COALESCE(SUM(CASE WHEN t.type='debit'  AND t.status='completed' AND t.category IN $affecting THEN t.amount ELSE 0 END),0) debits
        FROM wallets w
        JOIN users u ON u.id = w.user_id
        LEFT JOIN transactions t ON t.wallet_id = w.id
        GROUP BY w.id, w.user_id, w.balance, w.total_earned, w.total_withdrawn, u.name, u.customer_id
        ORDER BY u.name ASC");
    $wallets = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $rows = []; $mismatches = [];
    $totBalance = 0; $totComputed = 0;
    foreach ($wallets as $w) {
        $credits = (float)$w['credits']; $debits = (float)$w['debits'];
        $computed = round($credits - $debits, 2);
        $balance = round((float)$w['balance'], 2);
        $diff = round($balance - $computed, 2);
        $ok = abs($diff) < 0.01;
        $row = [
            'wallet_id'   => (int)$w['wallet_id'],
            'user_id'     => (int)$w['user_id'],
            'name'        => $w['name'],
            'customer_id' => $w['customer_id'],
            'balance'     => $balance,
            'ledger_credits' => round($credits, 2),
            'ledger_debits'  => round($debits, 2),
            'computed'    => $computed,
            'difference'  => $diff,
            'reconciled'  => $ok,
        ];
        $rows[] = $row;
        if (!$ok) $mismatches[] = $row;
        $totBalance += $balance; $totComputed += $computed;
    }

    // Platform-level: liability vs revenue collected.
    $revenue = (float)($db->query("SELECT COALESCE(SUM(total_amount),0) FROM invoices")->fetchColumn() ?: 0);
    $withdrawn = (float)($db->query("SELECT COALESCE(SUM(amount),0) FROM withdrawals WHERE status IN ('completed','approved','paid')")->fetchColumn() ?: 0);

    echo json_encode(["status" => "success", "data" => $rows, "mismatches" => $mismatches,
        "summary" => [
            "wallets"          => count($rows),
            "mismatch_count"   => count($mismatches),
            "total_balance"    => round($totBalance, 2),
            "total_computed"   => round($totComputed, 2),
            "total_difference" => round($totBalance - $totComputed, 2),
            "platform_liability" => round($totBalance, 2),
            "revenue_collected"  => round($revenue, 2),
            "total_withdrawn"    => round($withdrawn, 2),
        ]]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
