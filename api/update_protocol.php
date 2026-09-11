<?php
require_once 'config.php';
// Flat single-level referral model (no tree): 2% referral + 2% daily cashback.
$rates = [
    'referral_commission_rate' => '2',
    'referral_commission_l1'   => '2',
    'daily_cashback_rate'      => '2'
];

foreach ($rates as $key => $val) {
    $stmt = $pdo->prepare("INSERT INTO platform_settings (config_key, config_value) VALUES (?, ?) ON DUPLICATE KEY UPDATE config_value = ?");
    $stmt->execute([$key, $val, $val]);
}

echo "Protocol Updated Successfully.";
?>
