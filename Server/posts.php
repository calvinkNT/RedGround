<?php
header("Content-Type: application/json");

require_once __DIR__ . '/check_token.php';

$headers = getallheaders();
$token = $headers['Authorization'] ?? ($_GET['token'] ?? null);

$username = check_token($token);

if (!$username) {
    http_response_code(401);
    echo json_encode(["success" => false, "message" => "Invalid or expired token."]);
    exit;
}

$postsFile = __DIR__ . '/posts.json';
if (!file_exists($postsFile)) {
    echo json_encode([]);
    exit;
}

$posts = json_decode(file_get_contents($postsFile), true);
if (!is_array($posts)) $posts = [];

if (isset($_GET['id']) && is_numeric($_GET['id'])) {
    $id = (int)$_GET['id'];
    foreach ($posts as $post) {
        if ($post['id'] === $id) {
            // Ensure keys exist
            $post['liked_by'] = $post['liked_by'] ?? [];
            $post['replies']  = $post['replies'] ?? [];
            echo json_encode($post, JSON_PRETTY_PRINT);
            exit;
        }
    }
    echo json_encode(null);
    exit;
}

foreach ($posts as &$p) {
    $p['liked_by'] = $p['liked_by'] ?? [];
    $p['replies']  = $p['replies'] ?? [];
}
unset($p);

echo json_encode($posts, JSON_PRETTY_PRINT);
