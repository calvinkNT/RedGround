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
if (!is_array($posts)) {
    echo json_encode([]);
    exit;
}

$timeLimit = time() - (48 * 60 * 60);

$recentPosts = array_filter($posts, function($post) use ($timeLimit) {
    return isset($post['timestamp']) && $post['timestamp'] >= $timeLimit;
});

usort($recentPosts, function($a, $b) {
    $commentsA = isset($a['replies']) ? count($a['replies']) : 0;
    $commentsB = isset($b['replies']) ? count($b['replies']) : 0;
    $likesA = isset($a['likes']) ? $a['likes'] : 0;
    $likesB = isset($b['likes']) ? $b['likes'] : 0;

    if ($commentsB !== $commentsA) {
        return $commentsB - $commentsA;
    }
    return $likesB - $likesA;
});

echo json_encode(array_values($recentPosts), JSON_PRETTY_PRINT);
?>
