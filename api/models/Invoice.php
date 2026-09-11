<?php
// api/models/Invoice.php
// Immutable tax-invoice writer. Freezes a snapshot of a purchase (customer +
// amounts + CGST/SGST split) into the `invoices` table at issue time.
//
// issue_invoice_for_cycle($pdo, $cycleId):
//   - Idempotent: if an invoice already exists for the cycle, returns it unchanged
//     (an issued invoice is NEVER rewritten — audit trail).
//   - Otherwise snapshots the current cashback_cycles + users row and inserts it.
//   - Returns the invoice_no (e.g. "INV-000004") or null on failure.

if (!function_exists('issue_invoice_for_cycle')) {
    function issue_invoice_for_cycle(PDO $pdo, int $cycleId): ?string {
        try {
            // Already issued? Return the frozen record — do not overwrite.
            $existing = $pdo->prepare("SELECT invoice_no FROM invoices WHERE cycle_id = ? LIMIT 1");
            $existing->execute([$cycleId]);
            $found = $existing->fetchColumn();
            if ($found) return $found;

            $cStmt = $pdo->prepare("
                SELECT c.*, u.name AS customer_name, u.customer_id AS customer_code, u.phone AS customer_phone, u.email AS customer_email
                FROM cashback_cycles c
                JOIN users u ON u.id = c.user_id
                WHERE c.id = ?");
            $cStmt->execute([$cycleId]);
            $c = $cStmt->fetch(PDO::FETCH_ASSOC);
            if (!$c) return null;

            $total = (float)($c['total_amount'] ?? 0);
            if ($total <= 0) $total = (float)($c['total_value'] ?? 0);

            $storedGst   = (float)($c['gst_amount'] ?? 0);
            $productAmt  = (float)($c['product_amount'] ?? 0);
            $eligibleAmt = (float)($c['cashback_eligible_amount'] ?? 0);

            // Fetch product-specific GST rate from `products` table if available
            $productGstRate = null;
            if (!empty($c['product_name'])) {
                $pStmt = $pdo->prepare("SELECT gst_rate FROM products WHERE name = ? OR name LIKE ? LIMIT 1");
                $pStmt->execute([$c['product_name'], '%' . $c['product_name'] . '%']);
                $pRow = $pStmt->fetch(PDO::FETCH_ASSOC);
                if ($pRow && isset($pRow['gst_rate']) && $pRow['gst_rate'] !== null && $pRow['gst_rate'] !== '') {
                    $productGstRate = (float)$pRow['gst_rate'];
                }
            }

            if ($productAmt > 0 && $productAmt < $total) {
                $base    = $productAmt;
                $gst     = round($total - $base, 2);
                $gstRate = round(($gst / $base) * 100, 2);
            } elseif ($eligibleAmt > 0 && $eligibleAmt < $total) {
                $base    = $eligibleAmt;
                $gst     = round($total - $base, 2);
                $gstRate = round(($gst / $base) * 100, 2);
            } elseif ($productGstRate !== null && $productGstRate > 0) {
                $gstRate = $productGstRate;
                $base    = round($total / (1 + ($gstRate / 100)), 2);
                $gst     = round($total - $base, 2);
            } elseif ($storedGst > 0) {
                $gst     = $storedGst;
                $base    = round($total - $gst, 2);
                $gstRate = $base > 0 ? round(($gst / $base) * 100, 2) : 0;
            } else {
                $asset   = strtolower((string)($c['asset_type'] ?? 'gold'));
                $gstRate = ($asset === 'gold' || $asset === 'silver') ? 3.0 : 18.0;
                $base    = round($total / (1 + ($gstRate / 100)), 2);
                $gst     = round($total - $base, 2);
            }

            $cgst = round($gst / 2, 2);
            $sgst = round($gst - $cgst, 2);

            $productName = $c['product_name'] ?: ('Order #' . $c['id']);
            $items = [[
                'name'    => $productName,
                'qty'     => ((float)$c['weight'] > 1 ? (float)$c['weight'] : 1),
                'rate'    => round($base, 2),
                'base'    => round($base, 2),
                'gstRate' => $gstRate,
            ]];

            // Insert first (invoice_no set from the auto-increment id → collision-free & sequential).
            $ins = $pdo->prepare("INSERT INTO invoices
                (invoice_no, cycle_id, user_id, customer_name, customer_code, customer_phone, customer_email,
                 asset_type, product_name, items_json, taxable_amount, gst_rate, cgst_amount, sgst_amount,
                 gst_amount, total_amount, payment_method, transaction_id, status, created_at)
                VALUES (NULL, :cycle_id, :user_id, :cname, :ccode, :cphone, :cemail,
                 :asset, :pname, :items, :taxable, :grate, :cgst, :sgst,
                 :gst, :total, :pmethod, :txn, 'issued', :created)");
            $ins->execute([
                'cycle_id' => $c['id'],
                'user_id'  => $c['user_id'],
                'cname'    => $c['customer_name'],
                'ccode'    => $c['customer_code'],
                'cphone'   => $c['customer_phone'],
                'cemail'   => $c['customer_email'],
                'asset'    => $c['asset_type'],
                'pname'    => $productName,
                'items'    => json_encode($items),
                'taxable'  => round($base, 2),
                'grate'    => $gstRate,
                'cgst'     => $cgst,
                'sgst'     => $sgst,
                'gst'      => round($gst, 2),
                'total'    => round($total, 2),
                'pmethod'  => $c['payment_method'] ?? 'Bank Transfer',
                'txn'      => $c['transaction_id'] ?? null,
                // Preserve original purchase date so backfilled invoices keep chronological order.
                'created'  => $c['created_at'] ?? date('Y-m-d H:i:s'),
            ]);
            $newId = (int)$pdo->lastInsertId();
            $invoiceNo = 'INV-' . str_pad((string)$newId, 6, '0', STR_PAD_LEFT);
            $pdo->prepare("UPDATE invoices SET invoice_no = ? WHERE id = ?")->execute([$invoiceNo, $newId]);

            return $invoiceNo;
        } catch (Throwable $e) {
            // Never let invoice writing break the host request (purchase must still succeed).
            error_log('issue_invoice_for_cycle failed: ' . $e->getMessage());
            return null;
        }
    }
}

if (!function_exists('backfill_invoices')) {
    // Ensure every purchase (cashback_cycle) has a frozen invoice. Safe to call
    // repeatedly — issue_invoice_for_cycle() skips cycles already invoiced.
    function backfill_invoices(PDO $pdo): int {
        $created = 0;
        try {
            $rows = $pdo->query("
                SELECT c.id FROM cashback_cycles c
                LEFT JOIN invoices i ON i.cycle_id = c.id
                WHERE i.id IS NULL
                ORDER BY c.created_at ASC, c.id ASC");
            foreach ($rows->fetchAll(PDO::FETCH_COLUMN) as $cid) {
                if (issue_invoice_for_cycle($pdo, (int)$cid)) $created++;
            }
        } catch (Throwable $e) {
            error_log('backfill_invoices failed: ' . $e->getMessage());
        }
        return $created;
    }
}
?>
