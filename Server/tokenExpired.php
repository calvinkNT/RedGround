<?php
require_once __DIR__ . '/check_token.php';

$headers = getallheaders();
$token = $headers['Authorization'] ?? ($_GET['token'] ?? null);

// Check token
$username = check_token($token);

if (!$username) {
    echo json_encode(["success" => false, "message" => "Invalid or expired token."]);
    exit;
} else {
    echo json_encode(["success" => true, "message" => "Token is valid."]);
    exit;
}
?>