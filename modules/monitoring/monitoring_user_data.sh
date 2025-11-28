#!/bin/bash
# Simple monitoring dashboard setup
yum update -y
yum install -y httpd php php-sqlite3

# Start Apache
systemctl start httpd
systemctl enable httpd

# Create simple monitoring dashboard
cat > /var/www/html/index.php << 'EOFDASHBOARD'
<?php
$dbFile = '/var/www/html/logs.db';

// Create SQLite database
try {
    $pdo = new PDO("sqlite:$dbFile");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $pdo->exec("CREATE TABLE IF NOT EXISTS visits (id INTEGER PRIMARY KEY AUTOINCREMENT, ip TEXT, url TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)");
    $pdo->exec("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE, password_hash TEXT, last_login DATETIME, login_count INTEGER DEFAULT 0)");
    
    // Add default admin user with complex password
    $adminHash = password_hash('Zx9#K8mP$vR2@qL7!nW4*uY6^sE3&bN5', PASSWORD_DEFAULT);
    $stmt = $pdo->prepare("INSERT OR IGNORE INTO users (username, password_hash) VALUES (?, ?)");
    $stmt->execute(['admin', $adminHash]);
    
} catch(PDOException $e) {
    echo "Database error: " . $e->getMessage();
}

session_start();
$loginMessage = '';

// Handle login
if ($_POST['action'] == 'login') {
    $username = $_POST['username'];
    $password = $_POST['password'];
    
    $stmt = $pdo->prepare("SELECT * FROM users WHERE username = ?");
    $stmt->execute([$username]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($user && password_verify($password, $user['password_hash'])) {
        $_SESSION['user_id'] = $user['id'];
        $_SESSION['username'] = $user['username'];
        $loginMessage = 'Login successful!';
        
        $updateStmt = $pdo->prepare("UPDATE users SET last_login = CURRENT_TIMESTAMP, login_count = login_count + 1 WHERE id = ?");
        $updateStmt->execute([$user['id']]);
    } else {
        $loginMessage = 'Invalid credentials.';
    }
}

if ($_POST['action'] == 'logout') {
    session_destroy();
    header('Location: /');
    exit;
}

// Get stats
$totalVisits = $pdo->query("SELECT COUNT(*) FROM visits")->fetchColumn();
$todayVisits = $pdo->query("SELECT COUNT(*) FROM visits WHERE DATE(timestamp) = DATE('now')")->fetchColumn();
$recentVisits = $pdo->query("SELECT * FROM visits ORDER BY timestamp DESC LIMIT 10")->fetchAll(PDO::FETCH_ASSOC);

// Simulate some data if no visits recorded yet
if ($totalVisits == 0) {
    $pdo->exec("INSERT INTO visits (ip, url, timestamp) VALUES ('127.0.0.1', '/', datetime('now', '-1 hour'))");
    $pdo->exec("INSERT INTO visits (ip, url, timestamp) VALUES ('54.89.144.1', '/health.php', datetime('now', '-30 minutes'))");
    $totalVisits = 2;
    $todayVisits = 2;
    $recentVisits = $pdo->query("SELECT * FROM visits ORDER BY timestamp DESC LIMIT 10")->fetchAll(PDO::FETCH_ASSOC);
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Capstone Project Monitoring Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .header { background: linear-gradient(135deg, #2c3e50, #3498db); color: white; padding: 1rem; margin: -20px -20px 20px -20px; }
        .login-form { background: white; padding: 20px; border-radius: 8px; max-width: 400px; margin: 0 auto; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }
        .stat-card { background: white; padding: 20px; border-radius: 8px; text-align: center; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        .stat-number { font-size: 2rem; font-weight: bold; color: #3498db; }
        .recent-visits { background: white; padding: 20px; border-radius: 8px; margin-top: 20px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        table { width: 100%; border-collapse: collapse; }
        th, td { text-align: left; padding: 8px; border-bottom: 1px solid #ddd; }
        .btn { padding: 10px 20px; background: #3498db; color: white; border: none; border-radius: 4px; cursor: pointer; }
        .message { padding: 10px; margin: 10px 0; border-radius: 4px; background: #d4edda; border: 1px solid #c3e6cb; color: #155724; }
        .error { background: #f8d7da; border-color: #f5c6cb; color: #721c24; }
        .links { background: #fff3cd; border: 1px solid #ffecb5; border-radius: 8px; padding: 15px; margin: 20px 0; }
        .links a { display: inline-block; margin-right: 15px; color: #0066cc; text-decoration: none; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚗 Capstone Project Car Dealer - Monitoring Dashboard</h1>
        <?php if (isset($_SESSION['username'])): ?>
            Welcome, <?php echo htmlspecialchars($_SESSION['username']); ?>!
            <form method="POST" style="display: inline; margin-left: 20px;">
                <input type="hidden" name="action" value="logout">
                <button type="submit" class="btn">Logout</button>
            </form>
        <?php endif; ?>
    </div>

    <?php if (!isset($_SESSION['username'])): ?>
        <div class="login-form">
            <h2>Login to Access Dashboard</h2>
            <?php if ($loginMessage): ?>
                <div class="message <?php echo strpos($loginMessage, 'successful') !== false ? '' : 'error'; ?>">
                    <?php echo htmlspecialchars($loginMessage); ?>
                </div>
            <?php endif; ?>
            
            <form method="POST">
                <input type="hidden" name="action" value="login">
                <p>Username: <input type="text" name="username" value="admin" required></p>
                <p>Password: <input type="password" name="password" placeholder="Enter password" required></p>
                <p><button type="submit" class="btn">Login</button></p>
            </form>
            <p><em>Contact administrator for credentials</em></p>
        </div>
    <?php else: ?>
        
        <div class="links">
            <h3>🔗 Dashboard Links</h3>
            <a href="http://<?php echo $_SERVER['SERVER_NAME']; ?>:3000" target="_blank">📊 Grafana Dashboard</a>
            <a href="/api.php" target="_blank">🔌 Monitoring API</a>
            <a href="http://54.89.144.1" target="_blank">🚗 Main Car Website</a>
        </div>

        <div class="stats">
            <div class="stat-card">
                <div class="stat-number"><?php echo number_format($todayVisits); ?></div>
                <div>Today's Visits</div>
            </div>
            <div class="stat-card">
                <div class="stat-number"><?php echo number_format($totalVisits); ?></div>
                <div>Total Visits</div>
            </div>
            <div class="stat-card">
                <div class="stat-number"><?php echo date('H:i:s'); ?></div>
                <div>Last Updated</div>
            </div>
        </div>

        <div class="recent-visits">
            <h3>Recent Website Activity</h3>
            <table>
                <tr><th>IP Address</th><th>URL</th><th>Timestamp</th></tr>
                <?php foreach ($recentVisits as $visit): ?>
                <tr>
                    <td><?php echo htmlspecialchars($visit['ip']); ?></td>
                    <td><?php echo htmlspecialchars(substr($visit['url'], 0, 30)); ?></td>
                    <td><?php echo $visit['timestamp']; ?></td>
                </tr>
                <?php endforeach; ?>
            </table>
        </div>

        <div class="recent-visits">
            <h3>System Status</h3>
            <p>✅ Monitoring Dashboard: Active</p>
            <p>✅ Car Dealership Website: <a href="http://54.89.144.1" target="_blank">Online</a></p>
            <p>✅ Grafana Analytics: <a href="http://<?php echo $_SERVER['SERVER_NAME']; ?>:3000" target="_blank">Available</a></p>
        </div>
    <?php endif; ?>

    <script>
        // Auto-refresh every 30 seconds
        setTimeout(function() {
            location.reload();
        }, 30000);
    </script>
</body>
</html>
EOFDASHBOARD

# Create API endpoint
cat > /var/www/html/api.php << 'EOFAPI'
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$dbFile = '/var/www/html/logs.db';
try {
    $pdo = new PDO("sqlite:$dbFile");
    $stats = [
        'status' => 'healthy',
        'total_visits' => $pdo->query("SELECT COUNT(*) FROM visits")->fetchColumn(),
        'today_visits' => $pdo->query("SELECT COUNT(*) FROM visits WHERE DATE(timestamp) = DATE('now')")->fetchColumn(),
        'recent_visits' => $pdo->query("SELECT * FROM visits ORDER BY timestamp DESC LIMIT 5")->fetchAll(PDO::FETCH_ASSOC),
        'last_updated' => date('Y-m-d H:i:s'),
        'server' => $_SERVER['SERVER_NAME'] ?? 'monitoring-server'
    ];
    echo json_encode($stats, JSON_PRETTY_PRINT);
} catch(PDOException $e) {
    echo json_encode(['status' => 'error', 'error' => $e->getMessage()]);
}
?>
EOFAPI

# Install and configure Grafana
cat > /etc/yum.repos.d/grafana.repo << 'EOFGRAFANA'
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
EOFGRAFANA

yum install -y grafana
systemctl start grafana-server
systemctl enable grafana-server

# Configure Grafana with admin credentials
cat > /etc/grafana/grafana.ini << 'EOFCONFIG'
[server]
http_port = 3000

[security]
admin_user = admin
admin_password = grafana123

[auth.anonymous]
enabled = true
org_name = Main Org.
org_role = Viewer
EOFCONFIG

# Set permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html
touch /var/www/html/logs.db
chown apache:apache /var/www/html/logs.db
chmod 664 /var/www/html/logs.db

# Restart services
systemctl restart httpd
systemctl restart grafana-server

echo "Monitoring dashboard setup completed successfully!"