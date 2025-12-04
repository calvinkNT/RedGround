<?php
function check_token($token) {
    $sessionFile = __DIR__ . '/tokens.json';

    if (!$token || !file_exists($sessionFile)) {
        return false;
    }

    $sessions = json_decode(file_get_contents($sessionFile), true);

    foreach ($sessions as $session) {
        if (
            isset($session['token'], $session['expires'], $session['username']) &&
            $session['token'] === $token &&
            $session['expires'] > time()
        ) {
            return $session['username']; // valid token, return username
        }
    }

    return false;
}
?>
