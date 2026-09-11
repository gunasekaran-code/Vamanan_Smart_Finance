<?php
// api/admin/invoices.php
// Real-time invoice register backed by the immutable `invoices` table.
// Each purchase freezes one invoice snapshot at Buy Now time (see models/Invoice.php).
// Financial fields (taxable / GST / CGST / SGST / total / customer) are the FROZEN
// snapshot; the status column is joined live from cashback_cycles so admins see the
// current order state (active / pending / cancelled …) against the fixed invoice.
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

require_once '../config.php';
require_once '../models/Invoice.php';
$db = $pdo;

try {
    // Make sure every purchase (incl. ones made before the invoices table existed)
    // has a frozen invoice. Idempotent — only creates the missing ones.
    backfill_invoices($db);

    $status = isset($_GET['status']) && $_GET['status'] !== '' ? $_GET['status'] : null;
    $search = isset($_GET['search']) ? trim($_GET['search']) : '';

    $where = [];
    $params = [];
    if ($status !== null && $status !== 'all') {
        // Filter on the live order status where available, else the invoice's own status.
        $where[] = "COALESCE(c.status, i.status) = ?";
        $params[] = $status;
    }
    if ($search !== '') {
        $where[] = "(i.customer_name LIKE ? OR i.customer_code LIKE ? OR i.customer_phone LIKE ? OR i.product_name LIKE ? OR i.transaction_id LIKE ? OR i.invoice_no LIKE ?)";
        $like = "%{$search}%";
        array_push($params, $like, $like, $like, $like, $like, $like);
    }
    $whereSql = $where ? ('WHERE ' . implode(' AND ', $where)) : '';

    $sql = "SELECT i.*, c.status AS order_status, c.weight AS cycle_weight
            FROM invoices i
            LEFT JOIN cashback_cycles c ON c.id = i.cycle_id
            $whereSql
            ORDER BY i.created_at DESC, i.id DESC";
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $invoices = [];
    $sumTaxable = 0.0; $sumGst = 0.0; $sumTotal = 0.0;

    foreach ($rows as $r) {
        $base  = (float)$r['taxable_amount'];
        $gst   = (float)$r['gst_amount'];
        $total = (float)$r['total_amount'];

        $sumTaxable += $base;
        $sumGst     += $gst;
        $sumTotal   += $total;

        $invoices[] = [
            'id'             => (int)$r['id'],
            'invoice_no'     => $r['invoice_no'],
            'cycle_id'       => $r['cycle_id'] !== null ? (int)$r['cycle_id'] : null,
            'date'           => $r['created_at'],
            'user_id'        => $r['user_id'] !== null ? (int)$r['user_id'] : null,
            'customer_name'  => $r['customer_name'],
            'customer_id'    => $r['customer_code'],
            'phone'          => $r['customer_phone'],
            'email'          => $r['customer_email'],
            'asset_type'     => $r['asset_type'],
            'weight'         => (float)($r['cycle_weight'] ?? 0),
            'product_name'   => $r['product_name'],
            'taxable'        => round($base, 2),
            'product_amount' => round($base, 2),
            'gst_rate'       => (float)$r['gst_rate'],
            'gst_amount'     => round($gst, 2),
            'cgst'           => (float)$r['cgst_amount'],
            'sgst'           => (float)$r['sgst_amount'],
            'total_amount'   => round($total, 2),
            'payment_method' => $r['payment_method'],
            'transaction_id' => $r['transaction_id'],
            'invoice_status' => $r['status'],                              // 'issued' / 'cancelled'
            'status'         => $r['order_status'] ?: $r['status'],        // live order state for the chip
        ];
    }

    echo json_encode([
        'status' => 'success',
        'data'   => $invoices,
        'summary' => [
            'count'         => count($invoices),
            'total_taxable' => round($sumTaxable, 2),
            'total_gst'     => round($sumGst, 2),
            'total_cgst'    => round($sumGst / 2, 2),
            'total_sgst'    => round($sumGst - ($sumGst / 2), 2),
            'total_value'   => round($sumTotal, 2),
        ],
    ]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
?>
