<?php
require_once __DIR__ . '/check_token.php';

$headers = getallheaders();
$token = $headers['Authorization'] ?? ($_GET['token'] ?? null);

$username = check_token($token);

if (!$username) {
    echo json_encode(["success" => false, "message" => "Invalid token."]);
    exit;
}

$jsonFile = "posts.json";
$data = json_decode(file_get_contents($jsonFile), true);
if (!is_array($data)) $data = [];

$message = isset($_GET['message']) ? $_GET['message'] : "";

if (strlen($message) > 255) {
    echo json_encode(["success" => false, "message" => "Message can't be longer than 255 characters."]);
    exit;
}

if ($message) {
    $newPost = [
        "id" => rand(10000000, 99999999),
        "username" => $username,
        "message" => $message,
        "likes" => 0,
        "liked_by" => [],
        "replies" => [],
        "timestamp" => time()
    ];
    array_unshift($data, $newPost);
    file_put_contents($jsonFile, json_encode($data, JSON_PRETTY_PRINT));
    echo json_encode(["success" => true, "message" => ""]);
} else {
    echo json_encode(["success" => false, "message" => "Missing fields."]);
}
?>
