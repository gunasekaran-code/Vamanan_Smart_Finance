<?php
// api/admin/gst_filing.php
// Real-time GST filing report built from actual orders (cashback_cycles).
// GST is split equally into CGST + SGST (intra-state). Returns a slab-wise summary
// (for GSTR-1 style filing), an overall summary, and the per-order breakdown.
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

require_once '../config.php';
$db = $pdo;

try {
    // Optional period filter: ?month=YYYY-MM  (defaults to all valid orders)
    $month = isset($_GET['month']) && preg_match('/^\d{4}-\d{2}$/', $_GET['month']) ? $_GET['month'] : null;

    $where = "cc.status <> 'rejected'";   // rejected orders carry no GST liability
    $params = [];
    if ($month) {
        $where .= " AND DATE_FORMAT(cc.created_at, '%Y-%m') = :month";
        $params['month'] = $month;
    }

    $sql = "SELECT cc.id, cc.created_at, cc.status, cc.asset_type, cc.product_name,
                   cc.total_value,
                   COALESCE(NULLIF(cc.product_amount,0), cc.cashback_eligible_amount, cc.total_value) AS taxable,
                   COALESCE(cc.gst_amount, 0) AS gst_amount,
                   COALESCE(NULLIF(cc.total_amount,0), cc.total_value) AS total_amount,
                   cc.transaction_id,
                   u.name AS customer_name, u.customer_id AS customer_code
            FROM cashback_cycles cc
            LEFT JOIN users u ON u.id = cc.user_id
            WHERE $where
            ORDER BY cc.id DESC";
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Fetch default GST rates from platform_settings
    $sStmt = $db->query("SELECT config_key, config_value FROM platform_settings");
    $settings = $sStmt ? $sStmt->fetchAll(PDO::FETCH_KEY_PAIR) : [];
    $defaultGoldGst = isset($settings['gold_gst']) ? (float)$settings['gold_gst'] : (isset($settings['gst_percentage']) ? (float)$settings['gst_percentage'] : 3);
    $defaultGeneralGst = isset($settings['general_gst']) ? (float)$settings['general_gst'] : 18;

    $orders = [];
    $slabs  = [];   // keyed by GST rate
    $sumTaxable = 0; $sumGst = 0; $sumCgst = 0; $sumSgst = 0; $sumTotal = 0;

    foreach ($rows as $r) {
        $total = (float)$r['total_amount'];
        if ($total <= 0) $total = (float)$r['total_value'];

        $storedGst   = (float)$r['gst_amount'];
        $productAmt  = (float)($r['product_amount'] ?? 0);
        $eligibleAmt = (float)($r['cashback_eligible_amount'] ?? 0);

        // Fetch product-specific GST rate from `products` table if available
        $productGstRate = null;
        if (!empty($r['product_name'])) {
            $pStmt = $db->prepare("SELECT gst_rate FROM products WHERE name = ? OR name LIKE ? LIMIT 1");
            $pStmt->execute([$r['product_name'], '%' . $r['product_name'] . '%']);
            $pRow = $pStmt->fetch(PDO::FETCH_ASSOC);
            if ($pRow && isset($pRow['gst_rate']) && $pRow['gst_rate'] !== null && $pRow['gst_rate'] !== '') {
                $productGstRate = (float)$pRow['gst_rate'];
            }
        }

        if ($productAmt > 0 && $productAmt < $total) {
            $taxable = $productAmt;
            $gst     = round($total - $taxable, 2);
            $rate    = round(($gst / $taxable) * 100, 2);
        } elseif ($eligibleAmt > 0 && $eligibleAmt < $total) {
            $taxable = $eligibleAmt;
            $gst     = round($total - $taxable, 2);
            $rate    = round(($gst / $taxable) * 100, 2);
        } elseif ($productGstRate !== null && $productGstRate > 0) {
            $rate    = $productGstRate;
            $taxable = round($total / (1 + ($rate / 100)), 2);
            $gst     = round($total - $taxable, 2);
        } elseif ($storedGst > 0) {
            $gst     = $storedGst;
            $taxable = round($total - $gst, 2);
            $rate    = $taxable > 0 ? round(($gst / $taxable) * 100, 2) : 0;
        } else {
            $asset   = strtolower((string)$r['asset_type']);
            $rate    = ($asset === 'gold' || $asset === 'silver') ? $defaultGoldGst : $defaultGeneralGst;
            $taxable = round($total / (1 + ($rate / 100)), 2);
            $gst     = round($total - $taxable, 2);
        }

        $cgst = round($gst / 2, 2);
        $sgst = round($gst - $cgst, 2);

        $sumTaxable += $taxable; $sumGst += $gst; $sumCgst += $cgst; $sumSgst += $sgst; $sumTotal += $total;

        // slab grouping
        $key = (string)$rate;
        if (!isset($slabs[$key])) {
            $slabs[$key] = ['rate' => $rate, 'taxable' => 0, 'cgst' => 0, 'sgst' => 0, 'gst' => 0, 'orders' => 0];
        }
        $slabs[$key]['taxable'] += $taxable;
        $slabs[$key]['cgst']    += $cgst;
        $slabs[$key]['sgst']    += $sgst;
        $slabs[$key]['gst']     += $gst;
        $slabs[$key]['orders']  += 1;

        $orders[] = [
            'id'            => (int)$r['id'],
            'invoice_no'    => 'INV-' . $r['id'],
            'created_at'    => $r['created_at'],
            'status'        => $r['status'],
            'customer_name' => $r['customer_name'],
            'customer_code' => $r['customer_code'],
            'product_name'  => $r['product_name'] ?: ($r['asset_type'] === 'silver' ? 'Pure Silver Asset' : ($r['asset_type'] === 'gold' ? '22K Gold Asset' : 'Product')),
            'taxable'       => round($taxable, 2),
            'rate'          => $rate,
            'cgst'          => round($cgst, 2),
            'sgst'          => round($sgst, 2),
            'gst'           => round($gst, 2),
            'total'         => round($total, 2),
        ];
    }

    // Sort slabs by rate ascending
    $slabList = array_values($slabs);
    usort($slabList, fn($a, $b) => $a['rate'] <=> $b['rate']);
    foreach ($slabList as &$s) {
        $s['taxable'] = round($s['taxable'], 2);
        $s['cgst']    = round($s['cgst'], 2);
        $s['sgst']    = round($s['sgst'], 2);
        $s['gst']     = round($s['gst'], 2);
    }
    unset($s);

    // Available months for the filter dropdown
    $months = $db->query("SELECT DISTINCT DATE_FORMAT(created_at, '%Y-%m') AS m
                          FROM cashback_cycles WHERE status <> 'rejected'
                          ORDER BY m DESC")->fetchAll(PDO::FETCH_COLUMN);

    echo json_encode([
        "status" => "success",
        "data" => [
            "period"  => $month ?: 'All Time',
            "summary" => [
                "orders"        => count($orders),
                "taxable"       => round($sumTaxable, 2),
                "cgst"          => round($sumCgst, 2),
                "sgst"          => round($sumSgst, 2),
                "total_gst"     => round($sumGst, 2),
                "total_invoice" => round($sumTotal, 2),
            ],
            "gstr1"   => [
                "b2c_outward_supplies" => $orders,
                "rate_slabs"           => $slabList,
            ],
            "gstr3b"  => [
                "outward_taxable_supplies" => round($sumTaxable, 2),
                "cgst_liability"          => round($sumCgst, 2),
                "sgst_liability"          => round($sumSgst, 2),
                "total_tax_liability"     => round($sumGst, 2),
            ],
            "slabs"   => $slabList,
            "orders"  => $orders,
            "months"  => $months,
        ]
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "GST_FILING_ERR: " . $e->getMessage()]);
}
?>
