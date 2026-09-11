<?php
// api/auditor/profile.php — the logged-in auditor's own profile (view + edit).
//   GET  ?user_id=N            → returns the auditor's profile
//   POST {user_id,name,email,phone,password?} → updates it (password optional)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

require_once __DIR__ . '/../config.php';
$db = $pdo;

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $data = json_decode(file_get_contents("php://input"), true) ?: [];
        $id    = (int)($data['user_id'] ?? 0);
        $name  = trim($data['name'] ?? '');
        $email = trim($data['email'] ?? '');
        $phone = trim($data['phone'] ?? '');
        $pass  = $data['password'] ?? '';

        if ($id <= 0)        throw new Exception("User id required.");
        if ($name === '')    throw new Exception("Name is required.");
        if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) throw new Exception("A valid email is required.");

        // Only operate on an actual auditor account (safety).
        $roleChk = $db->prepare("SELECT role FROM users WHERE id = ?");
        $roleChk->execute([$id]);
        $role = $roleChk->fetchColumn();
        if ($role !== 'auditor') throw new Exception("Not an auditor account.");

        // Email must be unique to another user.
        $dupe = $db->prepare("SELECT id FROM users WHERE email = ? AND id <> ?");
        $dupe->execute([$email, $id]);
        if ($dupe->fetchColumn()) throw new Exception("That email is already used by another account.");

        if ($pass !== '') {
            $db->prepare("UPDATE users SET name=?, email=?, phone=?, password=? WHERE id=? AND role='auditor'")
               ->execute([$name, $email, $phone, $pass, $id]);
        } else {
            $db->prepare("UPDATE users SET name=?, email=?, phone=? WHERE id=? AND role='auditor'")
               ->execute([$name, $email, $phone, $id]);
        }

        $row = $db->prepare("SELECT id, name, email, phone, customer_id, role, created_at FROM users WHERE id=?");
        $row->execute([$id]);
        echo json_encode(["status" => "success", "message" => "Profile updated.", "data" => $row->fetch(PDO::FETCH_ASSOC)]);
        exit;
    }

    // GET
    $id = (int)($_GET['user_id'] ?? 0);
    if ($id <= 0) throw new Exception("User id required.");
    $stmt = $db->prepare("SELECT id, name, email, phone, customer_id, role, status, created_at,
        (SELECT COALESCE(balance,0) FROM wallets WHERE user_id=users.id LIMIT 1) AS wallet_balance
        FROM users WHERE id=?");
    $stmt->execute([$id]);
    $u = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$u) throw new Exception("Profile not found.");
    echo json_encode(["status" => "success", "data" => $u]);
} catch (Throwable $e) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
