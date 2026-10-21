<?php
// api/config/json_response.php
// Safe JSON output. json_encode() returns false (and PHP echoes an empty body with
// a 200 status) the moment any string in the payload is not valid UTF-8 — which is
// exactly how a legacy/latin1 row in `products` silently blanked the inventory API.
// Everything here repairs the payload instead of letting it vanish.

if (!function_exists('json_utf8_fix')) {
    /**
     * Recursively coerce every string in $value to valid UTF-8.
     * Already-valid UTF-8 is left byte-for-byte untouched; anything else is
     * re-interpreted as Windows-1252/latin1 (the usual source of stray bytes),
     * so "Rolex Daytona 40mm ±" survives instead of being dropped.
     */
    function json_utf8_fix($value) {
        if (is_string($value)) {
            if ($value === '' || mb_check_encoding($value, 'UTF-8')) return $value;
            $fixed = @mb_convert_encoding($value, 'UTF-8', 'Windows-1252');
            return ($fixed !== false && mb_check_encoding($fixed, 'UTF-8'))
                ? $fixed
                : mb_convert_encoding($value, 'UTF-8', 'UTF-8');
        }
        if (is_array($value)) {
            $out = [];
            foreach ($value as $k => $v) {
                $key = is_string($k) ? json_utf8_fix($k) : $k;
                $out[$key] = json_utf8_fix($v);
            }
            return $out;
        }
        if (is_float($value) && !is_finite($value)) return null; // NAN/INF also break json_encode
        if (is_object($value)) return json_utf8_fix((array)$value);
        return $value;
    }
}

if (!function_exists('send_json')) {
    /** Encode and emit $payload, never an empty body. */
    function send_json($payload, $status = 200) {
        if (!headers_sent()) {
            http_response_code($status);
            header('Content-Type: application/json; charset=UTF-8');
        }
        $flags = JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES;

        // Fast path: clean payloads encode as-is.
        $json = json_encode($payload, $flags);
        // Repair pass: recovers the real characters (latin1 "\xE9" -> "e-acute"),
        // which is why it runs before the lossy substitute flag below.
        if ($json === false) {
            $json = json_encode(json_utf8_fix($payload), $flags);
        }
        // Last resort: replace whatever is still undecodable with U+FFFD.
        if ($json === false && defined('JSON_INVALID_UTF8_SUBSTITUTE')) {
            $json = json_encode($payload, $flags | JSON_INVALID_UTF8_SUBSTITUTE);
        }
        if ($json === false) {
            if (!headers_sent()) http_response_code(500);
            $json = json_encode([
                'status'  => 'error',
                'message' => 'Response could not be encoded: ' . json_last_error_msg(),
            ]);
        }
        echo $json;
    }
}

if (!function_exists('register_json_fatal_handler')) {
    /** Turn PHP fatals into a JSON error instead of a blank 200/500 page. */
    function register_json_fatal_handler() {
        register_shutdown_function(function () {
            $err = error_get_last();
            if (!$err || !in_array($err['type'], [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR], true)) return;
            if (headers_sent()) return;
            http_response_code(500);
            header('Content-Type: application/json; charset=UTF-8');
            echo json_encode([
                'status'  => 'error',
                'message' => 'Server error: ' . $err['message'],
                'file'    => basename($err['file']) . ':' . $err['line'],
            ]);
        });
    }
}
