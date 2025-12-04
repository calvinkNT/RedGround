<?php

require_once __DIR__ . '/check_token.php';

$headers = getallheaders();
$token = $headers['Authorization'] ?? ($_GET['token'] ?? null);

$username = check_token($token);

if (!$username) {
    http_response_code(401);
    echo json_encode(["success" => false, "message" => "Invalid or expired token."]);
    exit;
}

if (!isset($_GET['id']) || !isset($_GET['username']) || !isset($_GET['text'])) {
    http_response_code(400);
    echo "Missing parameters";
    exit;
}

$id = intval($_GET['id']);
$username = strip_tags($_GET['username']);
$text = strip_tags($_GET['text']);

$filepath = "posts.json";

if (!file_exists($filepath)) {
    echo "No data";
    exit;
}

$data = json_decode(file_get_contents($filepath), true);
foreach ($data as &$post) {
    if ($post['id'] == $id) {
        if (!isset($post['replies']) || !is_array($post['replies'])) {
            $post['replies'] = array();
        }
        $post['replies'][] = array("username" => $username, "text" => $text);
        break;
    }
}
file_put_contents($filepath, json_encode($data, JSON_PRETTY_PRINT));
echo "OK";
?>