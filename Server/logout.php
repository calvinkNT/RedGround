<?php
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    echo json_encode(["success" => false, "message" => "Only GET method is allowed."]);
    exit;
}

$headers = getallheaders();
if (!isset($headers['Authorization'])) {
    echo json_encode(["success" => false, "message" => "Authorization token missing."]);
    exit;
}

$providedToken = trim($headers['Authorization']);

$tokenFile = 'tokens.json';
if (!file_exists($tokenFile)) {
    echo json_encode(["success" => false, "message" => "No active sessions found."]);
    exit;
}

$tokenData = json_decode(file_get_contents($tokenFile), true);
if (!is_array($tokenData)) {
    echo json_encode(["success" => false, "message" => "Invalid token storage."]);
    exit;
}

$matched = false;
$filteredTokens = [];

foreach ($tokenData as $entry) {
    if ($entry['token'] === $providedToken) {
        $matched = true;
        continue;
    }
    $filteredTokens[] = $entry;
}

if ($matched) {
    file_put_contents($tokenFile, json_encode(array_values($filteredTokens), JSON_PRETTY_PRINT));
    echo json_encode(["success" => true, "message" => "Successfully logged out."]);
} else {
    echo json_encode(["success" => false, "message" => "Token not found or already logged out."]);
}
?>
