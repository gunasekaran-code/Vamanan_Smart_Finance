<?php
// api/config/db.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

class Database {
    private $host;
    private $db_name;
    private $username;
    private $password;
    private $port;

    public $conn;

    public function getConnection() {
        $this->conn = null;

        // Candidate configurations to attempt in order
        $candidates = [];

        // 1. Environment variables if specified
        if (getenv('DB_HOST')) {
            $candidates[] = [
                'host' => getenv('DB_HOST'),
                'port' => getenv('DB_PORT') ?: '3306',
                'db_name' => getenv('DB_NAME') ?: 'makkal_gold',
                'username' => getenv('DB_USER') ?: 'root',
                'password' => getenv('DB_PASS') !== false ? getenv('DB_PASS') : ''
            ];
        }

        // 2. MAMP default (port 8889)
        $candidates[] = [
            'host' => '127.0.0.1',
            'port' => '8889',
            'db_name' => 'makkal_gold',
            'username' => 'root',
            'password' => 'root'
        ];

        // 3. Local standard MySQL (port 3306) - root / root
        $candidates[] = [
            'host' => '127.0.0.1',
            'port' => '3306',
            'db_name' => 'makkal_gold',
            'username' => 'root',
            'password' => 'root'
        ];

        // 4. Local standard MySQL - root / anantha
        $candidates[] = [
            'host' => 'localhost',
            'port' => '3306',
            'db_name' => 'makkal_gold',
            'username' => 'root',
            'password' => 'anantha'
        ];

        // 5. Local standard MySQL - root / empty
        $candidates[] = [
            'host' => '127.0.0.1',
            'port' => '3306',
            'db_name' => 'makkal_gold',
            'username' => 'root',
            'password' => ''
        ];

        // 6. Remote / Production server fallback
        $candidates[] = [
            'host' => 'localhost',
            'port' => '3306',
            'db_name' => 'cwhycofr_makkal_gold',
            'username' => 'cwhycofr_admin',
            'password' => 'vamanan@gold123'
        ];

        foreach ($candidates as $config) {
            try {
                $portStr = !empty($config['port']) ? ";port=" . $config['port'] : "";
                $temp_pdo = new PDO("mysql:host=" . $config['host'] . $portStr, $config['username'], $config['password'], [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_TIMEOUT => 2
                ]);
                $temp_pdo->exec("CREATE DATABASE IF NOT EXISTS `" . $config['db_name'] . "`");

                $this->conn = new PDO("mysql:host=" . $config['host'] . $portStr . ";dbname=" . $config['db_name'], $config['username'], $config['password'], [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
                ]);

                $this->host = $config['host'];
                $this->port = $config['port'];
                $this->db_name = $config['db_name'];
                $this->username = $config['username'];
                $this->password = $config['password'];
                return $this->conn;
            } catch (PDOException $e) {
                continue;
            }
        }

        return null;
    }
}
?>
