<?php

header('Content-Type: application/json');

$dataFile = __DIR__ . '/posts.json';

if (!isset($_GET['id']) || !is_numeric($_GET['id'])) {
    echo json_encode(["error" => "Missing or invalid ID"]);
    exit;
}
$postId = (int)$_GET['id'];

if (!file_exists($dataFile)) {
    echo json_encode(["error" => "Data file not found"]);
    exit;
}

$jsonData = file_get_contents($dataFile);
$posts = json_decode($jsonData, true);

if (!is_array($posts)) {
    echo json_encode(["error" => "Invalid JSON data"]);
    exit;
}

foreach ($posts as $post) {
    if ((int)$post['id'] === $postId) {
        $replies = isset($post['replies']) && is_array($post['replies']) ? $post['replies'] : [];

        $result = [
            "count"   => count($replies),
            "replies" => $replies
        ];

        echo json_encode($result, JSON_PRETTY_PRINT);
        exit;
    }
}


echo json_encode([]);
?>
