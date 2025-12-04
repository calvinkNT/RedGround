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

$file = "posts.json";
$data = json_decode(file_get_contents($file), true);
$id = isset($_GET['id']) ? intval($_GET['id']) : 0;
$user = isset($_GET['username']) ? $_GET['username'] : "";

if ($id && $user && is_array($data)) {
    foreach ($data as &$post) {
        if ($post['id'] == $id) {

            if (!isset($post['likes'])) {
                $post['likes'] = 0;
            }
            if (!isset($post['liked_by']) || !is_array($post['liked_by'])) {
                $post['liked_by'] = [];
            }

            if (!in_array($user, $post['liked_by'])) {
                $post['likes'] += 1;
                $post['liked_by'][] = $user;
                $response = "Liked";
            } else {
                $post['likes'] = max(0, $post['likes'] - 1);
                $post['liked_by'] = array_values(array_diff($post['liked_by'], [$user]));
                $response = "Unliked";
            }
            break;
        }
    }
    file_put_contents($file, json_encode($data, JSON_PRETTY_PRINT));
    echo $response ?? "OK";
} else {
    echo "Missing id or username";
}
?>