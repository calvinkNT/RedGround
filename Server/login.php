<?php
header("Content-Type: application/json");

if (stripos($_SERVER['CONTENT_TYPE'], 'application/json') !== 0) {
    echo json_encode(["success" => false, "message" => "Expected application/json"]);
    exit;
}

$input = json_decode(file_get_contents("php://input"), true);
if ($input === null) {
    echo json_encode(["success" => false, "message" => "Malformed JSON"]);
    exit;
}
if ($_SERVER['REQUEST_METHOD'] !== 'POST' || !isset($input['user']) || !isset($input['pass'])) {
    echo json_encode(["success" => false, "message" => "Invalid request."]);
    exit;
}

$username = $input['user'];
$password = $input['pass'];

$usersFile = 'users.json';
$users = json_decode(file_get_contents($usersFile), true);

foreach ($users as $user) {
    if ($user['username'] === $username && $user['pass'] === $password) {
        $found = true;
        break;
    }
}

if (!$found) {
    echo json_encode(["success" => false, "message" => "Invalid username or password."]);
    exit;
}

$tokenFile = 'tokens.json';
$tokenStore = file_exists($tokenFile) ? json_decode(file_get_contents($tokenFile), true) : [];

$token = bin2hex(random_bytes(16));

// I know the login system of the app doesn't make tokens useful.

$expires = time() + 2592000;
$tokenEntry = [
    "username" => $username,
    "token" => $token,
    "expires" => $expires
];

$tokenData = file_exists($tokenFile) ? json_decode(file_get_contents($tokenFile), true) : [];
if (!is_array($tokenData)) {
    $tokenData = [];
}

$tokenData = array_filter($tokenData, fn($entry) => $entry['username'] !== $username);
$tokenData[] = $tokenEntry;
file_put_contents($tokenFile, json_encode(array_values($tokenData), JSON_PRETTY_PRINT));

echo json_encode([
    "success" => true,
    "message" => "Login successful.",
    "token" => $token
]);
?>
