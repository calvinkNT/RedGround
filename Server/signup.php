<?php
header("Content-Type: application/json");

$username = isset($_GET['user']) ? trim($_GET['user']) : '';
$password = isset($_GET['pass']) ? trim($_GET['pass']) : '';

if ($username === '' || $password === '') {
    echo json_encode(["success" => false, "message" => "Username and password cannot be empty."]);
    exit;
}

if (!preg_match('/^[A-Za-z0-9\-_]+$/', $username)) {
    echo json_encode(["success" => false, "message" => "Username can only contain letters (A-Z), numbers (0-9), dash (-), and underscore (_). No spaces or other characters allowed."]);
    exit;
}

if (strlen($username) < 4) {
    echo json_encode(["success" => false, "message" => "Username must be at least 4 characters."]);
    exit;
}

if (strlen($username) > 20) {
    echo json_encode(["success" => false, "message" => "Username must be shorter than 20 characters."]);
    exit;
}

if (strlen($username) > 100) {
    echo json_encode(["success" => false, "message" => "Password must be shorter than 100 characters."]);
    exit;
}

if (strlen($password) < 8) {
    echo json_encode(["success" => false, "message" => "Password must be at least 8 characters."]);
    exit;
}

$file = 'users.json';

if (file_exists($file)) {
    $jsonData = file_get_contents($file);
    $userList = json_decode($jsonData, true);
    if (!is_array($userList)) {
        $userList = [];
    }
} else {
    $userList = [];
}

$usernameLower = strtolower($username);

// Check if username already exists (case-insensitive)
foreach ($userList as $user) {
    if (strtolower($user['username']) === $usernameLower) {
        echo json_encode(["success" => false, "message" => "Username already exists."]);
        exit;
    }
}

// recc. check. try later.
/*
$usernameLower = strtolower(trim($username));

foreach ($userList as $user) {
    if (isset($user['username']) && strtolower(trim($user['username'])) === $usernameLower) {
        echo json_encode(["success" => false, "message" => "Username already exists."]);
        exit;
    }
}
*/

$newUser = [
    "username" => $username,
    "pass" => $password
];
$userList[] = $newUser;

if (file_put_contents($file, json_encode($userList, JSON_PRETTY_PRINT)) === false) {
    echo json_encode(["success" => false, "message" => "Failed to save user data. Please ping me on Discord."]);
    exit;
}

// Success response
echo json_encode(["success" => true, "message" => "Account created."]);
?>
