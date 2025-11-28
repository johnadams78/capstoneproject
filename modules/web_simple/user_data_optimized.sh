#!/bin/bash
# Optimized car dealership setup
yum update -y
yum install -y httpd php php-sqlite3
systemctl start httpd
systemctl enable httpd

# Create car dealership website
cat > /var/www/html/index.php << 'EOFPHPINNER'
<?php
$dbFile = '/var/www/html/capstone_db.sqlite';
try {
    $pdo = new PDO("sqlite:$dbFile");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $pdo->exec("CREATE TABLE IF NOT EXISTS cars (id INTEGER PRIMARY KEY, make TEXT, model TEXT, year INTEGER, price DECIMAL(10,2), mileage INTEGER, color TEXT, description TEXT, image_url TEXT)");
    
    $count = $pdo->query("SELECT COUNT(*) FROM cars")->fetchColumn();
    if ($count == 0) {
        $cars = [
            ['Toyota','Camry',2023,32500,8000,'White','Excellent','https://loremflickr.com/400/300/toyota,camry,sedan?lock=1'],
            ['Honda','Civic',2023,26500,11000,'Blue','Reliable','https://loremflickr.com/400/300/honda,civic,car?lock=2'],
            ['Ford','F-150',2023,45000,6000,'Black','Best seller','https://loremflickr.com/400/300/ford,truck,pickup?lock=3'],
            ['BMW','3 Series',2023,48000,5000,'Gray','Luxury','https://loremflickr.com/400/300/bmw,sedan,car?lock=4'],
            ['Mercedes','C-Class',2023,51000,6000,'Silver','Premium','https://loremflickr.com/400/300/mercedes,benz,luxury?lock=5'],
            ['Audi','A4',2023,46900,7500,'Blue','Tech','https://loremflickr.com/400/300/audi,sedan,car?lock=6'],
            ['Nissan','Altima',2023,29500,9000,'Red','Mid-size','https://loremflickr.com/400/300/nissan,altima,sedan?lock=7'],
            ['Hyundai','Elantra',2023,25900,7000,'Blue','Compact','https://loremflickr.com/400/300/hyundai,car,sedan?lock=8'],
            ['Kia','Forte',2023,24500,8500,'Red','Value','https://loremflickr.com/400/300/kia,forte,sedan?lock=9'],
            ['VW','Jetta',2023,27900,6000,'White','German','https://loremflickr.com/400/300/volkswagen,jetta,car?lock=10'],
            ['Subaru','Impreza',2023,26500,8000,'Orange','AWD','https://loremflickr.com/400/300/subaru,impreza,car?lock=11'],
            ['Toyota','Corolla',2022,24900,15000,'Silver','Efficient','https://loremflickr.com/400/300/toyota,corolla,sedan?lock=12'],
            ['Honda','Accord',2022,31000,14000,'Black','Popular','https://loremflickr.com/400/300/honda,accord,sedan?lock=13'],
            ['Ford','Mustang',2022,39900,13000,'Red','Sports','https://loremflickr.com/400/300/ford,mustang,sports?lock=14'],
            ['BMW','X3',2022,52000,12000,'Black','SUV','https://loremflickr.com/400/300/bmw,x3,suv?lock=15'],
            ['Mercedes','GLC',2022,55900,11000,'White','Luxury SUV','https://loremflickr.com/400/300/mercedes,suv,luxury?lock=16'],
            ['Audi','Q5',2022,52500,13000,'White','Premium SUV','https://loremflickr.com/400/300/audi,q5,suv?lock=17'],
            ['Nissan','Sentra',2022,22900,14000,'White','Efficient','https://loremflickr.com/400/300/nissan,sentra,sedan?lock=18'],
            ['Hyundai','Sonata',2022,31500,12000,'White','Spacious','https://loremflickr.com/400/300/hyundai,sonata,sedan?lock=19'],
            ['Kia','Sportage',2022,30500,13500,'Black','Compact SUV','https://loremflickr.com/400/300/kia,sportage,suv?lock=20'],
            ['Toyota','RAV4',2022,36900,12000,'Blue','AWD','https://loremflickr.com/400/300/toyota,rav4,suv?lock=21'],
            ['Honda','CR-V',2022,34900,7000,'White','Family','https://loremflickr.com/400/300/honda,crv,suv?lock=22'],
            ['Ford','Explorer',2022,42500,9500,'Black','7-seater','https://loremflickr.com/400/300/ford,explorer,suv?lock=23'],
            ['Nissan','Rogue',2022,33900,8000,'Silver','Family SUV','https://loremflickr.com/400/300/nissan,rogue,suv?lock=24'],
            ['Toyota','Prius',2021,27500,22000,'Green','Hybrid','https://loremflickr.com/400/300/toyota,prius,hybrid?lock=25'],
            ['Honda','Pilot',2021,41500,19000,'Silver','8-seater','https://loremflickr.com/400/300/honda,pilot,suv?lock=26'],
            ['Ford','Edge',2021,32000,28000,'Gray','Mid SUV','https://loremflickr.com/400/300/ford,edge,suv?lock=27'],
            ['BMW','X5',2021,65000,20000,'Blue','Luxury SUV','https://loremflickr.com/400/300/bmw,x5,luxury?lock=28'],
            ['Audi','Q7',2021,63000,18000,'Gray','7-seater','https://loremflickr.com/400/300/audi,q7,suv?lock=29'],
            ['Nissan','Pathfinder',2021,41000,16000,'Blue','8-seater','https://loremflickr.com/400/300/nissan,pathfinder,suv?lock=30'],
            ['Toyota','Highlander',2021,42000,18000,'Black','8-seater','https://loremflickr.com/400/300/toyota,highlander,suv?lock=31'],
            ['Ford','Escape',2021,28900,17000,'White','Compact','https://loremflickr.com/400/300/ford,escape,suv?lock=32'],
            ['Mazda','CX-5',2021,35900,15000,'Blue','Fun SUV','https://loremflickr.com/400/300/mazda,cx5,suv?lock=33'],
            ['Jeep','Cherokee',2021,38900,14000,'Red','Off-road','https://loremflickr.com/400/300/jeep,cherokee,suv?lock=34'],
            ['Lexus','RX',2021,58900,12000,'Pearl','Luxury','https://loremflickr.com/400/300/lexus,rx,luxury?lock=35'],
            ['Acura','MDX',2021,52900,16000,'Black','Premium','https://loremflickr.com/400/300/acura,mdx,suv?lock=36'],
            ['Infiniti','QX60',2021,49900,18000,'Silver','7-seater','https://loremflickr.com/400/300/infiniti,qx60,suv?lock=37'],
            ['Cadillac','XT5',2021,55900,13000,'White','American Luxury','https://loremflickr.com/400/300/cadillac,xt5,luxury?lock=38'],
            ['Lincoln','Aviator',2021,62900,11000,'Black','Premium SUV','https://loremflickr.com/400/300/lincoln,aviator,suv?lock=39'],
            ['Volvo','XC90',2021,57900,14000,'Blue','Safety first','https://loremflickr.com/400/300/volvo,xc90,suv?lock=40'],
            ['Genesis','GV70',2021,54900,9000,'Gray','Luxury brand','https://loremflickr.com/400/300/genesis,gv70,suv?lock=41'],
            ['Alfa Romeo','Stelvio',2021,48900,12000,'Red','Italian style','https://loremflickr.com/400/300/alfa,romeo,stelvio?lock=42'],
            ['Tesla','Model Y',2021,67900,8000,'White','Electric SUV','https://loremflickr.com/400/300/tesla,modely,electric?lock=43'],
            ['Porsche','Macan',2021,72900,5000,'Black','Sports SUV','https://loremflickr.com/400/300/porsche,macan,sports?lock=44'],
            ['Land Rover','Discovery',2021,68900,13000,'Green','Adventure ready','https://loremflickr.com/400/300/landrover,discovery,suv?lock=45'],
            ['Jaguar','F-PACE',2021,59900,11000,'Gray','British luxury','https://loremflickr.com/400/300/jaguar,fpace,luxury?lock=46'],
            ['Maserati','Levante',2021,89900,7000,'Blue','Italian luxury','https://loremflickr.com/400/300/maserati,levante,luxury?lock=47'],
            ['Bentley','Bentayga',2021,229900,3000,'Black','Ultra luxury','https://loremflickr.com/400/300/bentley,bentayga,luxury?lock=48'],
            ['Rolls-Royce','Cullinan',2021,389900,2000,'Silver','Peak luxury','https://loremflickr.com/400/300/rollsroyce,cullinan,luxury?lock=49'],
            ['Ferrari','Purosangue',2023,449900,500,'Red','Sports SUV','https://loremflickr.com/400/300/ferrari,purosangue,sports?lock=50'],
            ['Lamborghini','Urus',2022,249900,1500,'Yellow','Super SUV','https://loremflickr.com/400/300/lamborghini,urus,supercar?lock=51'],
            ['McLaren','GT',2022,219900,1200,'Orange','British supercar','https://loremflickr.com/400/300/mclaren,gt,supercar?lock=52']
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
$search = $_GET['search'] ?? '';
$make = $_GET['make'] ?? '';
$year = $_GET['year'] ?? '';
$pmin = $_GET['price_min'] ?? '';
$pmax = $_GET['price_max'] ?? '';
$color = $_GET['color'] ?? '';
$sort = $_GET['sort'] ?? 'year_desc';

$conditions = [];
$params = [];

if ($search) {
    $conditions[] = "(make LIKE ? OR model LIKE ? OR description LIKE ?)";
    $sp = '%' . $search . '%';
    $params = array_merge($params, [$sp, $sp, $sp]);
}
if ($make) { $conditions[] = "make = ?"; $params[] = $make; }
if ($year) { $conditions[] = "year = ?"; $params[] = $year; }
if ($pmin) { $conditions[] = "price >= ?"; $params[] = $pmin; }
if ($pmax) { $conditions[] = "price <= ?"; $params[] = $pmax; }
if ($color) { $conditions[] = "color = ?"; $params[] = $color; }

$where = empty($conditions) ? '' : 'WHERE ' . implode(' AND ', $conditions);

$orderBy = 'ORDER BY ';
switch ($sort) {
    case 'price_asc': $orderBy .= 'price ASC'; break;
    case 'price_desc': $orderBy .= 'price DESC'; break;
    default: $orderBy .= 'year DESC';
}

$sql = "SELECT * FROM cars $where $orderBy";
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
            <input type="text" name="search" placeholder="Search cars..." value="<?= htmlspecialchars($search) ?>" style="width:200px;">
            <select name="make"><option value="">Make</option><?php foreach ($makes as $m): ?><option value="<?= $m ?>" <?= $make === $m ? 'selected' : '' ?>><?= $m ?></option><?php endforeach; ?></select>
            <select name="year"><option value="">Year</option><?php foreach ($years as $y): ?><option value="<?= $y ?>" <?= $year === (string)$y ? 'selected' : '' ?>><?= $y ?></option><?php endforeach; ?></select>
            <select name="color"><option value="">Color</option><?php foreach ($colors as $c): ?><option value="<?= $c ?>" <?= $color === $c ? 'selected' : '' ?>><?= $c ?></option><?php endforeach; ?></select>
            <input type="number" name="price_min" placeholder="Min $" value="<?= $pmin ?>" min="0" step="1000" style="width:100px;">
            <input type="number" name="price_max" placeholder="Max $" value="<?= $pmax ?>" min="0" step="1000" style="width:100px;">
            <select name="sort"><option value="year_desc" <?= $sort === 'year_desc' ? 'selected' : '' ?>>Newest</option><option value="price_asc" <?= $sort === 'price_asc' ? 'selected' : '' ?>>Low Price</option><option value="price_desc" <?= $sort === 'price_desc' ? 'selected' : '' ?>>High Price</option></select>
            <button type="submit">Filter</button><a href="?" class="clear-btn">Clear</a>
        </form>
        
        <div class="results-info">
            <p><strong><?= count($cars) ?></strong> vehicles found
            <?php if ($search || $make || $year || $color || $pmin || $pmax): ?>
                <?php if ($search): ?><span class="filter-tag">"<?= $search ?>"</span><?php endif; ?>
                <?php if ($make): ?><span class="filter-tag"><?= $make ?></span><?php endif; ?>
                <?php if ($year): ?><span class="filter-tag"><?= $year ?></span><?php endif; ?>
                <?php if ($color): ?><span class="filter-tag"><?= $color ?></span><?php endif; ?>
                <?php if ($pmin): ?><span class="filter-tag">$<?= number_format($pmin) ?>+</span><?php endif; ?>
                <?php if ($pmax): ?><span class="filter-tag">≤$<?= number_format($pmax) ?></span><?php endif; ?>
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
        <p>🚗 Powered by AWS EC2 | Capstone DB: <?= count($cars) ?> vehicles in inventory</p>
    </footer>
</body>
</html>
EOFPHPINNER

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
touch /var/www/html/capstone_db.sqlite
chown apache:apache /var/www/html/capstone_db.sqlite
chmod 664 /var/www/html/capstone_db.sqlite

# Restart Apache
systemctl restart httpd

echo "Capstone Project Car Dealer setup completed successfully!"
