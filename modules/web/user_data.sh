#!/bin/bash
# User data script for Capstone Project web server
# This script installs Apache, PHP, and sets up the car dealership application

exec > >(tee /var/log/user-data.log) 2>&1
echo "Starting user data script at $(date)"

# Install PHP and Apache
echo "Installing PHP and Apache..."
amazon-linux-extras install -y php7.4
yum install -y httpd php php-mysqlnd
systemctl start httpd && systemctl enable httpd

# Database configuration
DB_HOST="${db_endpoint}"
DB_NAME="capstonedb"
DB_USER="admin"
DB_PASS="${db_password}"

echo "Database endpoint: $DB_HOST"

# Create PHP config file
cat > /var/www/html/config.php <<DBCONF
<?php
\$db_host = "$DB_HOST";
\$db_name = "$DB_NAME";
\$db_user = "$DB_USER";
\$db_pass = "$DB_PASS";
DBCONF

# Create the main application PHP file with embedded DB seeding
cat > /var/www/html/index.php <<'PHPCODE'
<?php
include 'config.php';

// Connect to database
$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);
if ($conn->connect_error) {
    echo "<h1>Database Connection Error</h1>";
    echo "<p>Unable to connect to database: " . htmlspecialchars($conn->connect_error) . "</p>";
    echo "<p>Please ensure the database is running and accessible.</p>";
    exit;
}

// Create table and seed data if empty
$conn->query("CREATE TABLE IF NOT EXISTS cars (
    id INT AUTO_INCREMENT PRIMARY KEY,
    make VARCHAR(50),
    model VARCHAR(50),
    year INT,
    price INT,
    category VARCHAR(20),
    type VARCHAR(20),
    engine VARCHAR(30),
    horsepower INT,
    color VARCHAR(20),
    image_url VARCHAR(255)
)");

$count = $conn->query("SELECT COUNT(*) as c FROM cars")->fetch_assoc()['c'];
if ($count == 0) {
    $conn->query("INSERT INTO cars (make,model,year,price,category,type,engine,horsepower,color,image_url) VALUES
    ('Mercedes-Benz','S-Class',2024,114000,'Luxury','Sedan','V8',496,'Black','https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=400'),
    ('BMW','7 Series',2024,95000,'Luxury','Sedan','I6',375,'White','https://images.unsplash.com/photo-1555215695-3004980ad54e?w=400'),
    ('Audi','A8 L',2024,87400,'Luxury','Sedan','V6',335,'Silver','https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=400'),
    ('Lexus','LS 500',2024,76900,'Luxury','Sedan','V6',416,'Blue','https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?w=400'),
    ('Porsche','911 Turbo S',2024,218000,'Sports','Coupe','Flat-6',640,'Red','https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=400'),
    ('Ferrari','Roma',2024,245000,'Sports','Coupe','V8',612,'Red','https://images.unsplash.com/photo-1592198084033-aade902d1aae?w=400'),
    ('Lamborghini','Huracan',2024,268000,'Sports','Coupe','V10',631,'Yellow','https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=400'),
    ('McLaren','720S',2024,299000,'Sports','Coupe','V8',710,'Orange','https://images.unsplash.com/photo-1621135802920-133df287f89c?w=400'),
    ('Tesla','Model S',2024,108990,'Electric','Sedan','Tri-Motor',1020,'White','https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=400'),
    ('Porsche','Taycan',2024,187400,'Electric','Sedan','Dual-Motor',750,'Gray','https://images.unsplash.com/photo-1619767886558-efdc259cde1a?w=400'),
    ('Range Rover','Autobiography',2024,185000,'Luxury','SUV','V8',523,'Black','https://images.unsplash.com/photo-1606016159991-dfe4f2746ad5?w=400'),
    ('Mercedes-Benz','G63 AMG',2024,179000,'Luxury','SUV','V8',577,'White','https://images.unsplash.com/photo-1520031441872-265e4ff70366?w=400'),
    ('BMW','X7 M60i',2024,112000,'Luxury','SUV','V8',523,'Gray','https://images.unsplash.com/photo-1619682817481-e994891cd1f5?w=400'),
    ('Cadillac','Escalade V',2024,152000,'Luxury','SUV','V8',682,'Black','https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?w=400'),
    ('Aston Martin','DB12',2024,245000,'Sports','Coupe','V8',671,'Silver','https://images.unsplash.com/photo-1596468138838-0f34c2d0773b?w=400'),
    ('Bentley','Continental GT',2024,235000,'Luxury','Coupe','W12',650,'Green','https://images.unsplash.com/photo-1580414057403-c5f451f30e1c?w=400'),
    ('Maserati','MC20',2024,215000,'Sports','Coupe','V6',621,'Blue','https://images.unsplash.com/photo-1618843479619-f3d0d81e4d10?w=400'),
    ('Rolls-Royce','Ghost',2024,340000,'Luxury','Sedan','V12',563,'Black','https://images.unsplash.com/photo-1563720360172-67b8f3dce741?w=400'),
    ('Rivian','R1S',2024,84500,'Electric','SUV','Quad-Motor',835,'Blue','https://images.unsplash.com/photo-1617788138017-80ad40651399?w=400'),
    ('Lucid','Air',2024,169000,'Electric','Sedan','Dual-Motor',1111,'Green','https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?w=400')");
}

// Handle filters
$fm = isset($_GET['make']) && $_GET['make'] != '' ? trim($_GET['make']) : '';
$ft = isset($_GET['type']) && $_GET['type'] != '' ? trim($_GET['type']) : '';
$fc = isset($_GET['category']) && $_GET['category'] != '' ? trim($_GET['category']) : '';
$pmin = isset($_GET['min_price']) && $_GET['min_price'] != '' ? (int)$_GET['min_price'] : 0;
$pmax = isset($_GET['max_price']) && $_GET['max_price'] != '' ? (int)$_GET['max_price'] : 999999999;
$sort = isset($_GET['sort']) ? $_GET['sort'] : 'price_desc';

$where = "WHERE 1=1";
if ($pmin > 0) $where .= " AND price >= $pmin";
if ($pmax < 999999999) $where .= " AND price <= $pmax";
if ($fm != '') $where .= " AND make = '" . mysqli_real_escape_string($conn, $fm) . "'";
if ($ft != '') $where .= " AND type = '" . mysqli_real_escape_string($conn, $ft) . "'";
if ($fc != '') $where .= " AND category = '" . mysqli_real_escape_string($conn, $fc) . "'";

if ($sort == 'price_asc') $order = 'price ASC';
elseif ($sort == 'hp_desc') $order = 'horsepower DESC';
elseif ($sort == 'name_asc') $order = 'make ASC';
else $order = 'price DESC';

$cars = $conn->query("SELECT * FROM cars $where ORDER BY $order");
$total = $conn->query("SELECT COUNT(*) as c FROM cars")->fetch_assoc()['c'];

$makeList = array();
$r = $conn->query("SELECT DISTINCT make FROM cars ORDER BY make");
while ($row = $r->fetch_assoc()) $makeList[] = $row['make'];

$typeList = array();
$r = $conn->query("SELECT DISTINCT type FROM cars ORDER BY type");
while ($row = $r->fetch_assoc()) $typeList[] = $row['type'];

$catList = array();
$r = $conn->query("SELECT DISTINCT category FROM cars ORDER BY category");
while ($row = $r->fetch_assoc()) $catList[] = $row['category'];
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Capstone Project - Car Dealership</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: system-ui; background: linear-gradient(135deg, #0f0c29, #302b63, #24243e); color: #fff; min-height: 100vh; }
        .c { max-width: 1400px; margin: 0 auto; padding: 20px; }
        header { background: rgba(255,255,255,.1); backdrop-filter: blur(10px); padding: 20px 40px; border-radius: 15px; margin-bottom: 30px; }
        .logo { font-size: 2em; font-weight: bold; background: linear-gradient(45deg, #f093fb, #f5576c); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
        .hero { text-align: center; padding: 40px; }
        .hero h1 { font-size: 2.5em; background: linear-gradient(45deg, #f093fb, #f5576c, #ffd700); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
        .hero p { color: #aaa; margin-top: 10px; }
        .filters { background: rgba(255,255,255,.1); padding: 25px; border-radius: 15px; margin-bottom: 30px; }
        .filters h3 { margin-bottom: 15px; color: #f5576c; }
        .fg { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 15px; }
        .fg select, .fg input { padding: 10px; border-radius: 8px; border: 1px solid rgba(255,255,255,.2); background: rgba(255,255,255,.1); color: #fff; }
        .fg select option { background: #302b63; }
        .btn { background: linear-gradient(45deg, #f093fb, #f5576c); color: #fff; border: none; padding: 12px 25px; border-radius: 25px; cursor: pointer; }
        .cars { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 25px; }
        .card { background: rgba(255,255,255,.1); border-radius: 20px; overflow: hidden; transition: .3s; border: 1px solid rgba(255,255,255,.1); }
        .card:hover { transform: translateY(-10px); box-shadow: 0 20px 40px rgba(0,0,0,.3); }
        .card img { width: 100%; height: 200px; object-fit: cover; }
        .badge { position: absolute; top: 15px; right: 15px; background: linear-gradient(45deg, #f093fb, #f5576c); padding: 5px 15px; border-radius: 20px; font-size: .8em; }
        .imgc { position: relative; }
        .info { padding: 20px; }
        .info h3 { font-size: 1.2em; margin-bottom: 8px; }
        .specs { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin: 15px 0; font-size: .9em; color: #aaa; }
        .price { font-size: 1.5em; font-weight: bold; color: #f5576c; }
        .ri { display: flex; justify-content: space-between; margin-bottom: 20px; padding: 15px; background: rgba(255,255,255,.05); border-radius: 10px; }
        .card { cursor: pointer; }
        .card-actions { display: flex; gap: 10px; margin-top: 15px; }
        .btn-contact { background: linear-gradient(45deg, #00c851, #007e33); color: #fff; border: none; padding: 10px 15px; border-radius: 20px; cursor: pointer; font-size: .85em; display: flex; align-items: center; gap: 5px; transition: .3s; flex: 1; justify-content: center; }
        .btn-contact:hover { transform: scale(1.05); box-shadow: 0 5px 15px rgba(0,200,81,.3); }
        .btn-details { background: linear-gradient(45deg, #f093fb, #f5576c); color: #fff; border: none; padding: 10px 15px; border-radius: 20px; cursor: pointer; font-size: .85em; display: flex; align-items: center; gap: 5px; transition: .3s; flex: 1; justify-content: center; }
        .btn-details:hover { transform: scale(1.05); }
        .modal { display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,.8); z-index: 1000; justify-content: center; align-items: center; backdrop-filter: blur(5px); }
        .modal.active { display: flex; }
        .modal-content { background: linear-gradient(135deg, #1a1a2e, #16213e); border-radius: 20px; max-width: 800px; width: 90%; max-height: 90vh; overflow-y: auto; position: relative; border: 1px solid rgba(255,255,255,.1); }
        .modal-close { position: absolute; top: 15px; right: 20px; font-size: 2em; cursor: pointer; color: #fff; z-index: 10; background: rgba(0,0,0,.5); width: 40px; height: 40px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
        .modal-close:hover { background: #f5576c; }
        .modal-img { width: 100%; height: 300px; object-fit: cover; border-radius: 20px 20px 0 0; }
        .modal-body { padding: 30px; }
        .modal-title { font-size: 1.8em; margin-bottom: 10px; }
        .modal-price { font-size: 2em; color: #f5576c; font-weight: bold; margin-bottom: 20px; }
        .modal-specs { display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; margin-bottom: 25px; }
        .spec-item { background: rgba(255,255,255,.1); padding: 15px; border-radius: 10px; }
        .spec-label { font-size: .8em; color: #aaa; margin-bottom: 5px; }
        .spec-value { font-size: 1.1em; font-weight: bold; }
        .modal-desc { color: #ccc; line-height: 1.6; margin-bottom: 25px; padding: 20px; background: rgba(255,255,255,.05); border-radius: 10px; }
        .modal-actions { display: flex; gap: 15px; }
        .modal-btn { flex: 1; padding: 15px; border-radius: 25px; border: none; cursor: pointer; font-size: 1em; font-weight: bold; transition: .3s; display: flex; align-items: center; justify-content: center; gap: 8px; }
        .modal-btn.primary { background: linear-gradient(45deg, #00c851, #007e33); color: #fff; }
        .modal-btn.secondary { background: linear-gradient(45deg, #f093fb, #f5576c); color: #fff; }
        .modal-btn:hover { transform: translateY(-3px); box-shadow: 0 10px 20px rgba(0,0,0,.3); }
        .contact-modal .modal-content { max-width: 500px; }
        .contact-form { display: flex; flex-direction: column; gap: 15px; }
        .contact-form input, .contact-form textarea { padding: 15px; border-radius: 10px; border: 1px solid rgba(255,255,255,.2); background: rgba(255,255,255,.1); color: #fff; font-size: 1em; }
        .contact-form textarea { min-height: 100px; resize: vertical; }
        .contact-form input::placeholder, .contact-form textarea::placeholder { color: #888; }
    </style>
</head>
<body>
<div class="c">
    <header><div class="logo">☁️ Capstone Project</div></header>
    <div class="hero">
        <h1>Luxury & Performance Vehicles</h1>
        <p>Discover <?= $total ?> premium automobiles</p>
    </div>
    <div class="filters">
        <h3>🔍 Filter Vehicles</h3>
        <form method="GET">
            <div class="fg">
                <select name="make">
                    <option value="">All Makes</option>
                    <?php foreach ($makeList as $m): ?>
                        <option value="<?= $m ?>" <?= $fm == $m ? ' selected' : '' ?>><?= $m ?></option>
                    <?php endforeach; ?>
                </select>
                <select name="category">
                    <option value="">All Categories</option>
                    <?php foreach ($catList as $c): ?>
                        <option value="<?= $c ?>" <?= $fc == $c ? ' selected' : '' ?>><?= $c ?></option>
                    <?php endforeach; ?>
                </select>
                <select name="type">
                    <option value="">All Types</option>
                    <?php foreach ($typeList as $t): ?>
                        <option value="<?= $t ?>" <?= $ft == $t ? ' selected' : '' ?>><?= $t ?></option>
                    <?php endforeach; ?>
                </select>
                <input type="number" name="min_price" placeholder="Min $" value="<?= $pmin ? $pmin : '' ?>">
                <input type="number" name="max_price" placeholder="Max $" value="<?= $pmax < 999999 ? $pmax : '' ?>">
                <select name="sort">
                    <option value="price_desc" <?= $sort == 'price_desc' ? ' selected' : '' ?>>Price ↓</option>
                    <option value="price_asc" <?= $sort == 'price_asc' ? ' selected' : '' ?>>Price ↑</option>
                    <option value="hp_desc" <?= $sort == 'hp_desc' ? ' selected' : '' ?>>HP ↓</option>
                    <option value="name_asc" <?= $sort == 'name_asc' ? ' selected' : '' ?>>Name A-Z</option>
                </select>
                <button type="submit" class="btn">Apply</button>
            </div>
        </form>
    </div>
    <div class="ri">
        <span>Showing <?= $cars->num_rows ?> of <?= $total ?></span>
        <a href="?" style="color:#f5576c;text-decoration:none">Clear Filters</a>
    </div>
    <div class="cars">
        <?php while ($c = $cars->fetch_assoc()): ?>
            <div class="card" onclick="showDetails(<?= htmlspecialchars(json_encode($c), ENT_QUOTES, 'UTF-8') ?>)">
                <div class="imgc">
                    <img src="<?= $c['image_url'] ?>" alt="<?= $c['make'] ?>">
                    <span class="badge"><?= $c['category'] ?></span>
                </div>
                <div class="info">
                    <h3><?= $c['year'] ?> <?= $c['make'] ?> <?= $c['model'] ?></h3>
                    <div class="specs">
                        <span>⚡ <?= $c['horsepower'] ?> HP</span>
                        <span>🔧 <?= $c['engine'] ?></span>
                        <span>🎨 <?= $c['color'] ?></span>
                        <span>📦 <?= $c['type'] ?></span>
                    </div>
                    <div class="price">$<?= number_format($c['price']) ?></div>
                    <div class="card-actions">
                        <button class="btn-contact" onclick="event.stopPropagation(); showContact(<?= htmlspecialchars(json_encode($c), ENT_QUOTES, 'UTF-8') ?>)">📞 Contact Dealer</button>
                        <button class="btn-details" onclick="event.stopPropagation(); showDetails(<?= htmlspecialchars(json_encode($c), ENT_QUOTES, 'UTF-8') ?>)">ℹ️ Details</button>
                    </div>
                </div>
            </div>
        <?php endwhile; ?>
    </div>

    <!-- Car Details Modal -->
    <div id="detailsModal" class="modal" onclick="if(event.target===this)closeModal('detailsModal')">
        <div class="modal-content">
            <span class="modal-close" onclick="closeModal('detailsModal')">&times;</span>
            <img id="modalImg" class="modal-img" src="" alt="">
            <div class="modal-body">
                <h2 id="modalTitle" class="modal-title"></h2>
                <div id="modalPrice" class="modal-price"></div>
                <div class="modal-specs">
                    <div class="spec-item"><div class="spec-label">Engine</div><div id="specEngine" class="spec-value"></div></div>
                    <div class="spec-item"><div class="spec-label">Horsepower</div><div id="specHp" class="spec-value"></div></div>
                    <div class="spec-item"><div class="spec-label">Color</div><div id="specColor" class="spec-value"></div></div>
                    <div class="spec-item"><div class="spec-label">Body Type</div><div id="specType" class="spec-value"></div></div>
                    <div class="spec-item"><div class="spec-label">Category</div><div id="specCategory" class="spec-value"></div></div>
                    <div class="spec-item"><div class="spec-label">Year</div><div id="specYear" class="spec-value"></div></div>
                </div>
                <div class="modal-desc">
                    <strong>About this vehicle:</strong><br><br>
                    <span id="modalDesc"></span>
                </div>
                <div class="modal-actions">
                    <button class="modal-btn primary" onclick="closeModal('detailsModal'); showContact(currentCar)">📞 Contact Dealer</button>
                    <button class="modal-btn secondary" onclick="closeModal('detailsModal')">✕ Close</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Contact Dealer Modal -->
    <div id="contactModal" class="modal contact-modal" onclick="if(event.target===this)closeModal('contactModal')">
        <div class="modal-content">
            <span class="modal-close" onclick="closeModal('contactModal')">&times;</span>
            <div class="modal-body">
                <h2 class="modal-title">📞 Contact Dealer</h2>
                <p id="contactCar" style="color:#f5576c; margin-bottom: 20px; font-size: 1.1em;"></p>
                <form class="contact-form" onsubmit="submitContact(event)">
                    <input type="text" placeholder="Your Name" required>
                    <input type="email" placeholder="Your Email" required>
                    <input type="tel" placeholder="Your Phone Number">
                    <textarea placeholder="Message (e.g., I'm interested in this vehicle, schedule a test drive...)"></textarea>
                    <button type="submit" class="modal-btn primary" style="margin-top: 10px;">📧 Send Inquiry</button>
                </form>
                <div style="margin-top: 20px; padding: 15px; background: rgba(255,255,255,.05); border-radius: 10px; text-align: center;">
                    <p style="color: #aaa; margin-bottom: 10px;">Or call us directly:</p>
                    <p style="font-size: 1.3em; color: #00c851; font-weight: bold;">📞 1-800-CAPSTONE</p>
                </div>
            </div>
        </div>
    </div>

    <script>
        let currentCar = null;
        
        function showDetails(car) {
            currentCar = car;
            document.getElementById('modalImg').src = car.image_url;
            document.getElementById('modalTitle').textContent = car.year + ' ' + car.make + ' ' + car.model;
            document.getElementById('modalPrice').textContent = '$' + parseInt(car.price).toLocaleString();
            document.getElementById('specEngine').textContent = car.engine;
            document.getElementById('specHp').textContent = car.horsepower + ' HP';
            document.getElementById('specColor').textContent = car.color;
            document.getElementById('specType').textContent = car.type;
            document.getElementById('specCategory').textContent = car.category;
            document.getElementById('specYear').textContent = car.year;
            
            // Generate description based on car data
            let desc = 'This stunning ' + car.year + ' ' + car.make + ' ' + car.model + ' features a powerful ' + car.engine + ' engine producing ' + car.horsepower + ' horsepower. ';
            desc += 'Finished in beautiful ' + car.color + ', this ' + car.category.toLowerCase() + ' ' + car.type.toLowerCase() + ' offers an exceptional driving experience. ';
            if (car.category === 'Luxury') {
                desc += 'Enjoy premium comfort, cutting-edge technology, and refined elegance in every detail.';
            } else if (car.category === 'Sports') {
                desc += 'Experience thrilling performance, precise handling, and head-turning style on every drive.';
            } else if (car.category === 'Electric') {
                desc += 'Embrace the future with instant torque, zero emissions, and innovative technology.';
            }
            document.getElementById('modalDesc').textContent = desc;
            
            document.getElementById('detailsModal').classList.add('active');
            document.body.style.overflow = 'hidden';
        }
        
        function showContact(car) {
            currentCar = car;
            document.getElementById('contactCar').textContent = 'Inquiring about: ' + car.year + ' ' + car.make + ' ' + car.model;
            document.getElementById('contactModal').classList.add('active');
            document.body.style.overflow = 'hidden';
        }
        
        function closeModal(id) {
            document.getElementById(id).classList.remove('active');
            document.body.style.overflow = 'auto';
        }
        
        function submitContact(e) {
            e.preventDefault();
            alert('Thank you for your inquiry! Our team will contact you shortly about the ' + currentCar.year + ' ' + currentCar.make + ' ' + currentCar.model + '.');
            closeModal('contactModal');
        }
        
        // Close modal with Escape key
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                closeModal('detailsModal');
                closeModal('contactModal');
            }
        });
    </script>
</div>
</body>
</html>
PHPCODE

# Remove default index.html
rm -f /var/www/html/index.html

# Set proper permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Restart Apache
systemctl restart httpd

echo "User data script completed at $(date)"
echo "Web server is ready!"
