#!/bin/bash
# Update system and install LAMP stack
yum update -y
yum install -y httpd php php-sqlite3
systemctl start httpd
systemctl enable httpd

# Create simplified car dealership website
cat > /var/www/html/index.php << 'EOFPHP'
<?php
$dbFile = '/var/www/html/cars.db';
try {
    $pdo = new PDO("sqlite:$dbFile");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $pdo->exec("CREATE TABLE IF NOT EXISTS cars (id INTEGER PRIMARY KEY, make TEXT, model TEXT, year INTEGER, price DECIMAL(10,2), mileage INTEGER, color TEXT, description TEXT, image_url TEXT)");
    
    $count = $pdo->query("SELECT COUNT(*) FROM cars")->fetchColumn();
    if ($count == 0) {
        $cars = [
            ['Toyota', 'Camry', 2023, 32500, 8000, 'White', 'Excellent condition', 'https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?w=300&h=200&fit=crop&auto=format'],
            ['Honda', 'Civic', 2023, 26500, 11000, 'Blue', 'Reliable compact car', 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=300&h=200&fit=crop&auto=format'],
            ['Ford', 'F-150', 2023, 45000, 6000, 'Black', 'Best-selling truck', 'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=300&h=200&fit=crop&auto=format'],
            ['Chevrolet', 'Silverado', 2023, 43000, 7500, 'White', 'Heavy-duty pickup', 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=300&h=200&fit=crop&auto=format'],
            ['BMW', '3 Series', 2023, 48000, 5000, 'Gray', 'Luxury sports sedan', 'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=300&h=200&fit=crop&auto=format'],
            ['Mercedes-Benz', 'C-Class', 2023, 51000, 6000, 'Silver', 'Luxury compact', 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=300&h=200&fit=crop&auto=format'],
            ['Audi', 'A4', 2023, 46900, 7500, 'Blue', 'Luxury sedan', 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=300&h=200&fit=crop&auto=format'],
            ['Nissan', 'Altima', 2023, 29500, 9000, 'Red', 'Mid-size sedan', 'https://images.unsplash.com/photo-1502877338535-766e1452684a?w=300&h=200&fit=crop&auto=format'],
            ['Hyundai', 'Elantra', 2023, 25900, 7000, 'Blue', 'Compact sedan', 'https://images.unsplash.com/photo-1494905998402-395d579af36f?w=300&h=200&fit=crop&auto=format'],
            ['Kia', 'Forte', 2023, 24500, 8500, 'Red', 'Value sedan', 'https://images.unsplash.com/photo-1502877338535-766e1452684a?w=300&h=200&fit=crop&auto=format'],
            ['Volkswagen', 'Jetta', 2023, 27900, 6000, 'White', 'German engineering', 'https://images.unsplash.com/photo-1549924231-f129b911e442?w=300&h=200&fit=crop&auto=format'],
            ['Subaru', 'Impreza', 2023, 26500, 8000, 'Orange', 'AWD standard', 'https://images.unsplash.com/photo-1533473359331-0518f9dbf4f4?w=300&h=200&fit=crop&auto=format'],
            ['Toyota', 'Corolla', 2022, 24900, 15000, 'Silver', 'Great fuel economy', 'https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?w=300&h=200&fit=crop&auto=format'],
            ['Honda', 'Accord', 2022, 31000, 14000, 'Black', 'Mid-size sedan', 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=300&h=200&fit=crop&auto=format'],
            ['Ford', 'Mustang', 2022, 39900, 13000, 'Red', 'Iconic sports car', 'https://images.unsplash.com/photo-1584345604476-8ec5e12e42dd?w=300&h=200&fit=crop&auto=format'],
            ['Chevrolet', 'Malibu', 2022, 27500, 16000, 'Silver', 'Modern technology', 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=300&h=200&fit=crop&auto=format'],
            ['BMW', 'X3', 2022, 52000, 12000, 'Black', 'Luxury compact SUV', 'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=300&h=200&fit=crop&auto=format'],
            ['Mercedes-Benz', 'GLC', 2022, 55900, 11000, 'White', 'Luxury SUV', 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=300&h=200&fit=crop&auto=format'],
            ['Audi', 'Q5', 2022, 52500, 13000, 'White', 'Premium SUV', 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=300&h=200&fit=crop&auto=format'],
            ['Nissan', 'Sentra', 2022, 22900, 14000, 'White', 'Fuel efficient', 'https://images.unsplash.com/photo-1502877338535-766e1452684a?w=300&h=200&fit=crop&auto=format'],
            ['Hyundai', 'Sonata', 2022, 31500, 12000, 'White', 'Mid-size sedan', 'https://images.unsplash.com/photo-1494905998402-395d579af36f?w=300&h=200&fit=crop&auto=format'],
            ['Kia', 'Sportage', 2022, 30500, 13500, 'Black', 'Compact SUV', 'https://images.unsplash.com/photo-1502877338535-766e1452684a?w=300&h=200&fit=crop&auto=format'],
            ['Volkswagen', 'Passat', 2022, 32500, 14000, 'Blue', 'Spacious interior', 'https://images.unsplash.com/photo-1549924231-f129b911e442?w=300&h=200&fit=crop&auto=format'],
            ['Subaru', 'Legacy', 2022, 31900, 12500, 'Silver', 'AWD sedan', 'https://images.unsplash.com/photo-1533473359331-0518f9dbf4f4?w=300&h=200&fit=crop&auto=format'],
            ['Toyota', 'RAV4', 2022, 36900, 12000, 'Blue', 'AWD SUV', 'https://images.unsplash.com/photo-1549924231-f129b911e442?w=300&h=200&fit=crop&auto=format'],
            ['Honda', 'CR-V', 2022, 34900, 7000, 'White', 'Compact SUV', 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=300&h=200&fit=crop&auto=format'],
            ['Ford', 'Explorer', 2022, 42500, 9500, 'Black', '7-seater SUV', 'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=300&h=200&fit=crop&auto=format'],
            ['Chevrolet', 'Equinox', 2022, 31900, 10000, 'Blue', 'Compact SUV', 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=300&h=200&fit=crop&auto=format'],
            ['Nissan', 'Rogue', 2022, 33900, 8000, 'Silver', 'Family SUV', 'https://images.unsplash.com/photo-1502877338535-766e1452684a?w=300&h=200&fit=crop&auto=format'],
            ['Hyundai', 'Tucson', 2022, 32900, 6500, 'Gray', 'Bold design', 'https://images.unsplash.com/photo-1494905998402-395d579af36f?w=300&h=200&fit=crop&auto=format'],
            ['Volkswagen', 'Tiguan', 2022, 35900, 7500, 'Gray', 'European style', 'https://images.unsplash.com/photo-1549924231-f129b911e442?w=300&h=200&fit=crop&auto=format'],
            ['Subaru', 'Forester', 2022, 32900, 16000, 'Blue', 'Excellent visibility', 'https://images.unsplash.com/photo-1533473359331-0518f9dbf4f4?w=300&h=200&fit=crop&auto=format'],
            ['Toyota', 'Prius', 2021, 27500, 22000, 'Green', 'Hybrid efficiency', 'https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?w=300&h=200&fit=crop&auto=format'],
            ['Honda', 'Pilot', 2021, 41500, 19000, 'Silver', '8-seater SUV', 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=300&h=200&fit=crop&auto=format'],
            ['Ford', 'Edge', 2021, 32000, 28000, 'Gray', 'Mid-size SUV', 'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=300&h=200&fit=crop&auto=format'],
            ['Chevrolet', 'Camaro', 2021, 37500, 21000, 'Yellow', 'Muscle car', 'https://images.unsplash.com/photo-1584345604476-8ec5e12e42dd?w=300&h=200&fit=crop&auto=format'],
            ['BMW', 'X5', 2021, 65000, 20000, 'Blue', 'Luxury SUV', 'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=300&h=200&fit=crop&auto=format'],
            ['Audi', 'Q7', 2021, 63000, 18000, 'Gray', '7-seater luxury', 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=300&h=200&fit=crop&auto=format'],
            ['Nissan', 'Pathfinder', 2021, 41000, 16000, 'Blue', '8-seater SUV', 'https://images.unsplash.com/photo-1502877338535-766e1452684a?w=300&h=200&fit=crop&auto=format'],
            ['Hyundai', 'Santa Fe', 2021, 37500, 15000, 'Green', '3-row SUV', 'https://images.unsplash.com/photo-1494905998402-395d579af36f?w=300&h=200&fit=crop&auto=format'],
            ['Kia', 'Optima', 2021, 28900, 22000, 'Silver', 'Mid-size sedan', 'https://images.unsplash.com/photo-1502877338535-766e1452684a?w=300&h=200&fit=crop&auto=format'],
            ['Volkswagen', 'Atlas', 2021, 42000, 17000, 'Black', '7-seater SUV', 'https://images.unsplash.com/photo-1549924231-f129b911e442?w=300&h=200&fit=crop&auto=format'],
            ['Subaru', 'Outback', 2021, 35500, 9000, 'Green', 'Adventure ready', 'https://images.unsplash.com/photo-1533473359331-0518f9dbf4f4?w=300&h=200&fit=crop&auto=format'],
            ['Toyota', 'Highlander', 2021, 42000, 18000, 'Black', '8-seater SUV', 'https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?w=300&h=200&fit=crop&auto=format'],
            ['Honda', 'Ridgeline', 2021, 37000, 25000, 'Gray', 'Unique pickup', 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=300&h=200&fit=crop&auto=format'],
            ['Ford', 'Escape', 2021, 28900, 17000, 'White', 'Compact SUV', 'https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=300&h=200&fit=crop&auto=format'],
            ['Chevrolet', 'Tahoe', 2021, 58000, 15000, 'Black', 'Full-size SUV', 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=300&h=200&fit=crop&auto=format'],
            ['BMW', '5 Series', 2021, 58900, 7000, 'Gray', 'Executive sedan', 'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=300&h=200&fit=crop&auto=format'],
            ['Mercedes-Benz', 'E-Class', 2021, 61500, 4000, 'Black', 'Luxury sedan', 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=300&h=200&fit=crop&auto=format'],
            ['Audi', 'A6', 2021, 59900, 5500, 'Black', 'Tech features', 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=300&h=200&fit=crop&auto=format'],
            ['Nissan', 'Frontier', 2021, 35500, 10000, 'Black', 'Mid-size pickup', 'https://images.unsplash.com/photo-1502877338535-766e1452684a?w=300&h=200&fit=crop&auto=format'],
            ['Kia', 'Sorento', 2021, 36900, 9500, 'White', '3-row SUV', 'https://images.unsplash.com/photo-1502877338535-766e1452684a?w=300&h=200&fit=crop&auto=format']
        ];
        
        $stmt = $pdo->prepare("INSERT INTO cars (make, model, year, price, mileage, color, description, image_url) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
        foreach ($cars as $car) {
            $stmt->execute($car);
        }
    }
} catch(PDOException $e) {
    echo "Database error: " . $e->getMessage();
}

// Handle search and filters
$searchTerm = $_GET['search'] ?? '';
$filterMake = $_GET['make'] ?? '';
$filterYear = $_GET['year'] ?? '';
$filterPriceMin = $_GET['price_min'] ?? '';
$filterPriceMax = $_GET['price_max'] ?? '';
$filterColor = $_GET['color'] ?? '';
$sortBy = $_GET['sort'] ?? 'year_desc';

// Build dynamic query
$conditions = [];
$params = [];

if ($searchTerm) {
    $conditions[] = "(make LIKE ? OR model LIKE ? OR description LIKE ?)";
    $searchParam = '%' . $searchTerm . '%';
    $params = array_merge($params, [$searchParam, $searchParam, $searchParam]);
}

if ($filterMake) {
    $conditions[] = "make = ?";
    $params[] = $filterMake;
}

if ($filterYear) {
    $conditions[] = "year = ?";
    $params[] = $filterYear;
}

if ($filterPriceMin) {
    $conditions[] = "price >= ?";
    $params[] = $filterPriceMin;
}

if ($filterPriceMax) {
    $conditions[] = "price <= ?";
    $params[] = $filterPriceMax;
}

if ($filterColor) {
    $conditions[] = "color = ?";
    $params[] = $filterColor;
}

// Build WHERE clause
$whereClause = '';
if (!empty($conditions)) {
    $whereClause = 'WHERE ' . implode(' AND ', $conditions);
}

// Build ORDER BY clause
$orderBy = 'ORDER BY ';
switch ($sortBy) {
    case 'price_asc': $orderBy .= 'price ASC'; break;
    case 'price_desc': $orderBy .= 'price DESC'; break;
    case 'year_asc': $orderBy .= 'year ASC'; break;
    case 'mileage_asc': $orderBy .= 'mileage ASC'; break;
    case 'mileage_desc': $orderBy .= 'mileage DESC'; break;
    default: $orderBy .= 'year DESC';
}

$sql = "SELECT * FROM cars $whereClause $orderBy";
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$cars = $stmt->fetchAll(PDO::FETCH_ASSOC);

// Get filter options
$makes = $pdo->query("SELECT DISTINCT make FROM cars ORDER BY make")->fetchAll(PDO::FETCH_COLUMN);
$years = $pdo->query("SELECT DISTINCT year FROM cars ORDER BY year DESC")->fetchAll(PDO::FETCH_COLUMN);
$colors = $pdo->query("SELECT DISTINCT color FROM cars ORDER BY color")->fetchAll(PDO::FETCH_COLUMN);
?>
<!DOCTYPE html>
<html>
<head>
    <title>Capstone Project Car Dealer</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f4f4f4; }
        .header { background: linear-gradient(135deg, #2c3e50, #3498db); color: white; padding: 1rem; margin: -20px -20px 20px -20px; }
        .search { background: white; padding: 20px; margin-bottom: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); text-align: center; }
        .search input, .search select { padding: 8px; border: 1px solid #ddd; border-radius: 4px; margin: 2px; }
        .search button, .clear-btn { padding: 8px 15px; background: #3498db; color: white; border: none; border-radius: 4px; cursor: pointer; margin: 2px; text-decoration: none; }
        .search button:hover, .clear-btn:hover { background: #2980b9; }
        .results-info { text-align: center; margin-top: 15px; }
        .filter-tag { display: inline-block; background: #e74c3c; color: white; padding: 2px 6px; border-radius: 3px; font-size: 11px; margin: 0 2px; }
        .cars { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 20px; }
        .car { background: white; padding: 20px; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); transition: transform 0.3s, box-shadow 0.3s; }
        .car:hover { transform: translateY(-5px); box-shadow: 0 8px 25px rgba(0,0,0,0.15); }
        .car h3 { color: #2c3e50; margin-bottom: 10px; font-size: 1.3rem; }
        .price { font-size: 1.5rem; font-weight: bold; color: #27ae60; margin: 10px 0; }
        .info { display: grid; grid-template-columns: 1fr 1fr; gap: 5px; margin: 10px 0; font-size: 0.9rem; color: #666; }
        .contact-btn { width: 100%; padding: 12px; background: #27ae60; color: white; border: none; border-radius: 6px; cursor: pointer; font-size: 16px; }
        footer { background: #2c3e50; color: white; text-align: center; padding: 20px; margin: 20px -20px -20px -20px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚗 Capstone Project Car Dealer</h1>
        <p>Premium Quality Used Vehicles</p>
    </div>

    <div class="search">
        <form method="GET">
            <input type="text" name="search" placeholder="Search cars..." value="<?= htmlspecialchars($searchTerm) ?>" style="width:200px;">
            <select name="make"><option value="">Make</option><?php foreach ($makes as $make): ?><option value="<?= $make ?>" <?= $filterMake === $make ? 'selected' : '' ?>><?= $make ?></option><?php endforeach; ?></select>
            <select name="year"><option value="">Year</option><?php foreach ($years as $year): ?><option value="<?= $year ?>" <?= $filterYear === (string)$year ? 'selected' : '' ?>><?= $year ?></option><?php endforeach; ?></select>
            <select name="color"><option value="">Color</option><?php foreach ($colors as $color): ?><option value="<?= $color ?>" <?= $filterColor === $color ? 'selected' : '' ?>><?= $color ?></option><?php endforeach; ?></select>
            <input type="number" name="price_min" placeholder="Min $" value="<?= $filterPriceMin ?>" min="0" step="1000" style="width:100px;">
            <input type="number" name="price_max" placeholder="Max $" value="<?= $filterPriceMax ?>" min="0" step="1000" style="width:100px;">
            <select name="sort"><option value="year_desc" <?= $sortBy === 'year_desc' ? 'selected' : '' ?>>Newest</option><option value="price_asc" <?= $sortBy === 'price_asc' ? 'selected' : '' ?>>Low Price</option><option value="price_desc" <?= $sortBy === 'price_desc' ? 'selected' : '' ?>>High Price</option></select>
            <button type="submit">Filter</button><a href="?" class="clear-btn">Clear</a>
        </form>
        
        <div class="results-info">
            <p><strong><?= count($cars) ?></strong> vehicles found
            <?php if ($searchTerm || $filterMake || $filterYear || $filterColor || $filterPriceMin || $filterPriceMax): ?>
                <?php if ($searchTerm): ?><span class="filter-tag">"<?= $searchTerm ?>"</span><?php endif; ?>
                <?php if ($filterMake): ?><span class="filter-tag"><?= $filterMake ?></span><?php endif; ?>
                <?php if ($filterYear): ?><span class="filter-tag"><?= $filterYear ?></span><?php endif; ?>
                <?php if ($filterColor): ?><span class="filter-tag"><?= $filterColor ?></span><?php endif; ?>
                <?php if ($filterPriceMin): ?><span class="filter-tag">$<?= number_format($filterPriceMin) ?>+</span><?php endif; ?>
                <?php if ($filterPriceMax): ?><span class="filter-tag">≤$<?= number_format($filterPriceMax) ?></span><?php endif; ?>
            <?php endif; ?>
            </p>
        </div>
    </div>

    <div class="cars">
        <?php foreach ($cars as $car): ?>
        <div class="car">
            <?php if (!empty($car['image_url'])): ?>
            <img src="<?= htmlspecialchars($car['image_url']) ?>" alt="<?= htmlspecialchars($car['year'] . ' ' . $car['make'] . ' ' . $car['model']) ?>" style="width: 100%; height: 200px; object-fit: cover; border-radius: 8px; margin-bottom: 15px;">
            <?php endif; ?>
            <h3><?= $car['year'] . ' ' . $car['make'] . ' ' . $car['model'] ?></h3>
            <div class="price">$<?= number_format($car['price'], 0) ?></div>
            <div class="info">
                <div><strong>Mileage:</strong> <?= number_format($car['mileage']) ?> miles</div>
                <div><strong>Color:</strong> <?= $car['color'] ?></div>
            </div>
            <p style="color: #666; font-style: italic;"><?= $car['description'] ?></p>
            <button class="contact-btn" onclick="alert('Thank you for your interest! Call (555) 123-4567 or visit our showroom.')">Contact Dealer</button>
        </div>
        <?php endforeach; ?>
    </div>

    <footer>
        <p>&copy; <?= date('Y') ?> Capstone Project Car Dealer. All rights reserved.</p>
        <p>🚗 Powered by AWS EC2 | Database: <?= count($cars) ?> vehicles in inventory</p>
    </footer>
</body>
</html>
EOFPHP

# Create health check endpoint
cat > /var/www/html/health.php << 'EOFHEALTH'
<?php
header('Content-Type: application/json');
echo json_encode([
    'status' => 'healthy',
    'timestamp' => date('Y-m-d H:i:s'),
    'server' => $_SERVER['SERVER_NAME'] ?? 'localhost'
]);
?>
EOFHEALTH

# Set permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html
touch /var/www/html/cars.db
chown apache:apache /var/www/html/cars.db
chmod 664 /var/www/html/cars.db

# Restart Apache
systemctl restart httpd

echo "Capstone Project Car Dealer setup completed successfully!"