<?php
header('Content-Type: application/json');

$tokensFile = __DIR__ . '/tokens.json';
$postsFile  = __DIR__ . '/posts.json';
$modsFile   = __DIR__ . '/mods.json';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["error" => "Only POST requests allowed"]);
    exit;
}

$input  = json_decode(file_get_contents('php://input'), true);
$postId = isset($input['id']) ? intval($input['id']) : null;

$headers   = getallheaders();
$authToken = isset($headers['Authorization']) ? trim($headers['Authorization']) : null;

if (!$authToken || !$postId) {
    echo json_encode(["error" => "Missing auth token or post ID"]);
    exit;
}

$tokens = json_decode(file_get_contents($tokensFile), true);
if (!is_array($tokens)) $tokens = [];

$username = null;
foreach ($tokens as $entry) {
    if ($entry['token'] === $authToken && $entry['expires'] > time()) {
        $username = $entry['username'];
        break;
    }
}

if (!$username) {
    echo json_encode(["error" => "Invalid or expired token"]);
    exit;
}

$mods = json_decode(file_get_contents($modsFile), true);
if (!is_array($mods)) $mods = [];
$isMod = in_array($username, $mods, true);

$posts = json_decode(file_get_contents($postsFile), true);
if (!is_array($posts)) $posts = [];

$postIndex = null;
foreach ($posts as $index => $post) {
    if ($post['id'] == $postId) {
        // Allow delete if owner OR mod
        if ($post['username'] !== $username && !$isMod) {
            echo json_encode(["error" => "Not authorized to delete this post"]);
            exit;
        }
        $postIndex = $index;
        break;
    }
}

if ($postIndex === null) {
    echo json_encode(["error" => "Post not found"]);
    exit;
}

array_splice($posts, $postIndex, 1);

file_put_contents($postsFile, json_encode($posts, JSON_PRETTY_PRINT));

echo json_encode(["success" => true, "message" => "Post deleted"]);
