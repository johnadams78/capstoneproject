<?php
/**
 * Capstone Project - Car Dealership Application
 * This file is pulled from GitHub during EC2 boot
 */

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
    mileage INT DEFAULT 0,
    transmission VARCHAR(20) DEFAULT 'Automatic',
    fuel_type VARCHAR(20) DEFAULT 'Gasoline',
    description TEXT,
    image_url VARCHAR(255)
)");

$count = $conn->query("SELECT COUNT(*) as c FROM cars")->fetch_assoc()['c'];
if ($count == 0) {
    $conn->query("INSERT INTO cars (make,model,year,price,category,type,engine,horsepower,color,mileage,transmission,fuel_type,description,image_url) VALUES
    ('Mercedes-Benz','S-Class',2024,114000,'Luxury','Sedan','4.0L V8 Twin-Turbo',496,'Obsidian Black',1250,'9-Speed Automatic','Premium Gasoline','The pinnacle of luxury sedans featuring cutting-edge technology, supreme comfort, and timeless elegance. Equipped with MBUX infotainment, Burmester 4D surround sound, and active suspension.','https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=400'),
    ('BMW','7 Series',2024,95000,'Luxury','Sedan','3.0L I6 Twin-Turbo',375,'Alpine White',890,'8-Speed Automatic','Premium Gasoline','Experience ultimate driving luxury with BMW flagship sedan. Features iDrive 8, Executive Lounge seating, and Sky Lounge panoramic roof.','https://images.unsplash.com/photo-1555215695-3004980ad54e?w=400'),
    ('Audi','A8 L',2024,87400,'Luxury','Sedan','3.0L V6 TFSI',335,'Glacier White',1100,'8-Speed Tiptronic','Premium Gasoline','Sophisticated luxury meets advanced technology. Featuring Audi Virtual Cockpit, Matrix LED headlights, and Bang & Olufsen 3D sound.','https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=400'),
    ('Lexus','LS 500',2024,76900,'Luxury','Sedan','3.5L V6 Twin-Turbo',416,'Liquid Platinum',750,'10-Speed Automatic','Premium Gasoline','Japanese craftsmanship at its finest. Hand-pleated door panels, Kiriko glass accents, and 28-way power front seats.','https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?w=400'),
    ('Porsche','911 Turbo S',2024,218000,'Sports','Coupe','3.7L Flat-6 Twin-Turbo',640,'Guards Red',320,'8-Speed PDK','Premium Gasoline','The ultimate 911 combines breathtaking performance with everyday usability. 0-60 in 2.6 seconds with launch control.','https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=400'),
    ('Ferrari','Roma',2024,245000,'Sports','Coupe','3.9L V8 Twin-Turbo',612,'Rosso Corsa',180,'8-Speed DCT','Premium Gasoline','La Nuova Dolce Vita - elegant GT styling meets Ferrari performance. Features SF90 Stradale-derived technology.','https://images.unsplash.com/photo-1592198084033-aade902d1aae?w=400'),
    ('Lamborghini','Huracán EVO',2024,268000,'Sports','Coupe','5.2L V10',631,'Giallo Orion',290,'7-Speed LDF','Premium Gasoline','Naturally aspirated perfection with predictive logic. LDVI system reads driver intent for perfect response.','https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=400'),
    ('McLaren','720S',2024,299000,'Sports','Coupe','4.0L V8 Twin-Turbo',710,'Papaya Spark',410,'7-Speed SSG','Premium Gasoline','Proactive Chassis Control II delivers telepathic handling. Dihedral doors and carbon fiber monocoque construction.','https://images.unsplash.com/photo-1621135802920-133df287f89c?w=400'),
    ('Tesla','Model S Plaid',2024,108990,'Electric','Sedan','Tri-Motor AWD',1020,'Pearl White',650,'Single-Speed','Electric','The quickest production car ever made. 0-60 in under 2 seconds with 390+ miles of range.','https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=400'),
    ('Porsche','Taycan Turbo S',2024,187400,'Electric','Sedan','Dual-Motor AWD',750,'Frozen Blue',520,'2-Speed Automatic','Electric','Electric performance without compromise. 800V architecture enables 270kW DC fast charging.','https://images.unsplash.com/photo-1619767886558-efdc259cde1a?w=400'),
    ('Range Rover','Autobiography',2024,185000,'Luxury','SUV','4.4L V8 Twin-Turbo',523,'Santorini Black',980,'8-Speed Automatic','Premium Gasoline','The original luxury SUV, elevated. Features Executive Class rear seats and Meridian Signature Sound.','https://images.unsplash.com/photo-1606016159991-dfe4f2746ad5?w=400'),
    ('Mercedes-Benz','G63 AMG',2024,179000,'Luxury','SUV','4.0L V8 Biturbo',577,'Manufaktur White',1450,'9-Speed Automatic','Premium Gasoline','Iconic design meets AMG performance. Handcrafted engine with 627 lb-ft of torque.','https://images.unsplash.com/photo-1520031441872-265e4ff70366?w=400'),
    ('BMW','X7 M60i',2024,112000,'Luxury','SUV','4.4L V8 Twin-Turbo',523,'Carbon Black',870,'8-Speed Automatic','Premium Gasoline','Ultimate luxury meets commanding presence. Panoramic Sky Lounge LED roof and Bowers & Wilkins Diamond audio.','https://images.unsplash.com/photo-1619682817481-e994891cd1f5?w=400'),
    ('Cadillac','Escalade V',2024,152000,'Luxury','SUV','6.2L Supercharged V8',682,'Black Raven',620,'10-Speed Automatic','Premium Gasoline','Supercharged American luxury. 38-inch curved OLED display and Super Cruise hands-free driving.','https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?w=400'),
    ('Aston Martin','DB12',2024,245000,'Sports','Coupe','4.0L V8 Twin-Turbo',671,'Q Midnight Blue',150,'8-Speed Automatic','Premium Gasoline','The worlds first super tourer. Bespoke interior by Q and 198 mph top speed.','https://images.unsplash.com/photo-1596468138838-0f34c2d0773b?w=400'),
    ('Bentley','Continental GT',2024,235000,'Luxury','Coupe','6.0L W12 Twin-Turbo',650,'Barnato Green',430,'8-Speed DCT','Premium Gasoline','Grand touring perfected. Hand-stitched interior takes 150 hours to complete.','https://images.unsplash.com/photo-1580414057403-c5f451f30e1c?w=400'),
    ('Maserati','MC20',2024,215000,'Sports','Coupe','3.0L V6 Nettuno',621,'Bianco Audace',280,'8-Speed DCT','Premium Gasoline','100% Maserati with revolutionary Nettuno engine featuring F1-derived pre-chamber combustion.','https://images.unsplash.com/photo-1618843479619-f3d0d81e4d10?w=400'),
    ('Rolls-Royce','Ghost',2024,340000,'Luxury','Sedan','6.75L V12 Twin-Turbo',563,'Arctic White',890,'8-Speed Automatic','Premium Gasoline','Post Opulent design philosophy. Features Illuminated Fascia and Starlight Headliner with 1,340 fiber optic lights.','https://images.unsplash.com/photo-1563720360172-67b8f3dce741?w=400'),
    ('Rivian','R1S',2024,84500,'Electric','SUV','Quad-Motor AWD',835,'Rivian Blue',1200,'Single-Speed','Electric','Adventure-ready electric SUV with 316 miles range. Gear Guard security system and Camp Mode included.','https://images.unsplash.com/photo-1617788138017-80ad40651399?w=400'),
    ('Lucid','Air Grand Touring',2024,169000,'Electric','Sedan','Dual-Motor AWD',1111,'Stellar White',580,'Single-Speed','Electric','Longest range EV at 516 miles. DreamDrive Pro semi-autonomous driving and Glass Cockpit display.','https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?w=400')");
}

// Handle customer inquiries if submitted
if ($_POST['action'] ?? '' == 'submit_inquiry') {
    $inquiry_car = $_POST['car_id'] ?? 'General';
    $inquiry_name = $_POST['name'] ?? '';
    $inquiry_email = $_POST['email'] ?? '';
    $inquiry_phone = $_POST['phone'] ?? '';
    $inquiry_message = $_POST['message'] ?? '';
    
    // Create inquiries table if not exists
    $conn->query("CREATE TABLE IF NOT EXISTS inquiries (
        id INT AUTO_INCREMENT PRIMARY KEY,
        car_id VARCHAR(100),
        customer_name VARCHAR(100),
        email VARCHAR(100),
        phone VARCHAR(20),
        message TEXT,
        inquiry_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        status VARCHAR(20) DEFAULT 'new'
    )");
    
    // Insert inquiry
    $stmt = $conn->prepare("INSERT INTO inquiries (car_id, customer_name, email, phone, message) VALUES (?, ?, ?, ?, ?)");
    $stmt->bind_param("sssss", $inquiry_car, $inquiry_name, $inquiry_email, $inquiry_phone, $inquiry_message);
    $stmt->execute();
    $inquiry_success = true;
}

// Handle filters
$fm = isset($_GET['make']) && $_GET['make'] != '' ? trim($_GET['make']) : '';
$ft = isset($_GET['type']) && $_GET['type'] != '' ? trim($_GET['type']) : '';
$fc = isset($_GET['category']) && $_GET['category'] != '' ? trim($_GET['category']) : '';
$pmin = isset($_GET['min_price']) && $_GET['min_price'] != '' ? (int)$_GET['min_price'] : 0;
$pmax = isset($_GET['max_price']) && $_GET['max_price'] != '' ? (int)$_GET['max_price'] : 999999999;
$sort = isset($_GET['sort']) ? $_GET['sort'] : 'price_desc';
$search = isset($_GET['search']) && $_GET['search'] != '' ? trim($_GET['search']) : '';

$where = "WHERE 1=1";
if ($pmin > 0) $where .= " AND price >= $pmin";
if ($pmax < 999999999) $where .= " AND price <= $pmax";
if ($fm != '') $where .= " AND make = '" . mysqli_real_escape_string($conn, $fm) . "'";
if ($ft != '') $where .= " AND type = '" . mysqli_real_escape_string($conn, $ft) . "'";
if ($fc != '') $where .= " AND category = '" . mysqli_real_escape_string($conn, $fc) . "'";
if ($search != '') {
    $search_term = mysqli_real_escape_string($conn, $search);
    $where .= " AND (make LIKE '%$search_term%' OR model LIKE '%$search_term%' OR description LIKE '%$search_term%' OR engine LIKE '%$search_term%' OR color LIKE '%$search_term%')";
}

if ($sort == 'price_asc') $order = 'price ASC';
elseif ($sort == 'hp_desc') $order = 'horsepower DESC';
elseif ($sort == 'name_asc') $order = 'make ASC';
elseif ($sort == 'year_desc') $order = 'year DESC';
elseif ($sort == 'mileage_asc') $order = 'mileage ASC';
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
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Capstone Project - Premium Car Dealership</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Inter', system-ui, -apple-system, sans-serif; 
            background: linear-gradient(135deg, #0f0c29 0%, #302b63 50%, #24243e 100%); 
            color: #fff; 
            min-height: 100vh;
            line-height: 1.6;
        }
        .container { max-width: 1400px; margin: 0 auto; padding: 20px; }
        
        /* Header */
        header { 
            background: rgba(255,255,255,0.08); 
            backdrop-filter: blur(20px); 
            padding: 20px 40px; 
            border-radius: 20px; 
            margin-bottom: 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border: 1px solid rgba(255,255,255,0.1);
        }
        .logo { 
            font-size: 1.8em; 
            font-weight: 700; 
            background: linear-gradient(45deg, #f093fb, #f5576c, #ffd700); 
            -webkit-background-clip: text; 
            -webkit-text-fill-color: transparent;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .nav-links { display: flex; gap: 30px; }
        .nav-links a { 
            color: rgba(255,255,255,0.8); 
            text-decoration: none; 
            font-weight: 500;
            transition: color 0.3s;
        }
        .nav-links a:hover { color: #f5576c; }
        
        /* Hero */
        .hero { 
            text-align: center; 
            padding: 60px 20px;
            background: rgba(255,255,255,0.03);
            border-radius: 30px;
            margin-bottom: 30px;
        }
        .hero h1 { 
            font-size: 3em; 
            font-weight: 700;
            background: linear-gradient(45deg, #f093fb, #f5576c, #ffd700); 
            -webkit-background-clip: text; 
            -webkit-text-fill-color: transparent;
            margin-bottom: 15px;
        }
        .hero p { color: rgba(255,255,255,0.7); font-size: 1.2em; }
        .hero .stats {
            display: flex;
            justify-content: center;
            gap: 50px;
            margin-top: 30px;
        }
        .hero .stat {
            text-align: center;
        }
        .hero .stat-number {
            font-size: 2.5em;
            font-weight: 700;
            color: #f5576c;
        }
        .hero .stat-label {
            color: rgba(255,255,255,0.6);
            font-size: 0.9em;
        }
        
        /* Filters */
        .filters { 
            background: rgba(255,255,255,0.08); 
            padding: 30px; 
            border-radius: 20px; 
            margin-bottom: 30px;
            border: 1px solid rgba(255,255,255,0.1);
        }
        .filters h3 { 
            margin-bottom: 20px; 
            color: #f5576c;
            font-size: 1.3em;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .filter-grid { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); 
            gap: 15px; 
        }
        .filter-grid select, .filter-grid input { 
            padding: 12px 15px; 
            border-radius: 12px; 
            border: 1px solid rgba(255,255,255,0.2); 
            background: rgba(255,255,255,0.1); 
            color: #fff;
            font-size: 0.95em;
            transition: all 0.3s;
        }
        .filter-grid select:focus, .filter-grid input:focus {
            outline: none;
            border-color: #f5576c;
            background: rgba(255,255,255,0.15);
        }
        .filter-grid select option { background: #302b63; }
        .btn { 
            background: linear-gradient(45deg, #f093fb, #f5576c); 
            color: #fff; 
            border: none; 
            padding: 12px 30px; 
            border-radius: 25px; 
            cursor: pointer;
            font-weight: 600;
            font-size: 0.95em;
            transition: all 0.3s;
        }
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 30px rgba(245, 87, 108, 0.4);
        }
        
        /* Results Info */
        .results-info { 
            display: flex; 
            justify-content: space-between; 
            align-items: center;
            margin-bottom: 25px; 
            padding: 20px 25px; 
            background: rgba(255,255,255,0.05); 
            border-radius: 15px;
        }
        .results-info span { color: rgba(255,255,255,0.8); }
        .results-info a { color: #f5576c; text-decoration: none; font-weight: 500; }
        
        /* Car Grid */
        .cars { 
            display: grid; 
            grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); 
            gap: 30px; 
        }
        .card { 
            background: rgba(255,255,255,0.08); 
            border-radius: 24px; 
            overflow: hidden; 
            transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275); 
            border: 1px solid rgba(255,255,255,0.1);
            cursor: pointer;
        }
        .card:hover { 
            transform: translateY(-15px) scale(1.02); 
            box-shadow: 0 30px 60px rgba(0,0,0,0.4);
            border-color: rgba(245, 87, 108, 0.3);
        }
        .card-image { position: relative; overflow: hidden; }
        .card-image img { 
            width: 100%; 
            height: 220px; 
            object-fit: cover;
            transition: transform 0.5s;
        }
        .card:hover .card-image img {
            transform: scale(1.1);
        }
        .badge { 
            position: absolute; 
            top: 15px; 
            right: 15px; 
            background: linear-gradient(45deg, #f093fb, #f5576c); 
            padding: 6px 16px; 
            border-radius: 20px; 
            font-size: 0.8em;
            font-weight: 600;
        }
        .fuel-badge {
            position: absolute;
            top: 15px;
            left: 15px;
            background: rgba(0,0,0,0.6);
            backdrop-filter: blur(10px);
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 0.75em;
        }
        .card-info { padding: 25px; }
        .card-info h3 { 
            font-size: 1.25em; 
            margin-bottom: 10px;
            font-weight: 600;
        }
        .specs { 
            display: grid; 
            grid-template-columns: 1fr 1fr; 
            gap: 10px; 
            margin: 18px 0; 
            font-size: 0.9em; 
            color: rgba(255,255,255,0.7);
        }
        .specs span {
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .price { 
            font-size: 1.6em; 
            font-weight: 700; 
            color: #f5576c;
            margin-bottom: 15px;
        }
        .card-actions {
            display: flex;
            gap: 12px;
        }
        .btn-contact { 
            background: linear-gradient(45deg, #00c851, #007e33); 
            color: #fff; 
            border: none; 
            padding: 12px 20px; 
            border-radius: 25px; 
            cursor: pointer; 
            font-size: 0.9em;
            font-weight: 600;
            display: flex; 
            align-items: center; 
            gap: 8px; 
            transition: all 0.3s;
            flex: 1;
            justify-content: center;
        }
        .btn-contact:hover { 
            transform: scale(1.05); 
            box-shadow: 0 8px 25px rgba(0,200,81,0.4);
        }
        .btn-details { 
            background: linear-gradient(45deg, #667eea, #764ba2); 
            color: #fff; 
            border: none; 
            padding: 12px 20px; 
            border-radius: 25px; 
            cursor: pointer; 
            font-size: 0.9em;
            font-weight: 600;
            display: flex; 
            align-items: center; 
            gap: 8px; 
            transition: all 0.3s;
            flex: 1;
            justify-content: center;
        }
        .btn-details:hover { 
            transform: scale(1.05);
        }
        
        /* Modal Styles */
        .modal { 
            display: none; 
            position: fixed; 
            top: 0; 
            left: 0; 
            width: 100%; 
            height: 100%; 
            background: rgba(0,0,0,0.85); 
            z-index: 1000; 
            justify-content: center; 
            align-items: center;
            backdrop-filter: blur(10px);
            padding: 20px;
        }
        .modal.active { display: flex; }
        .modal-content { 
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%); 
            border-radius: 24px; 
            max-width: 900px; 
            width: 100%; 
            max-height: 90vh; 
            overflow-y: auto; 
            position: relative;
            border: 1px solid rgba(255,255,255,0.1);
            animation: modalSlide 0.3s ease;
        }
        @keyframes modalSlide {
            from { opacity: 0; transform: translateY(-30px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .modal-close { 
            position: absolute; 
            top: 20px; 
            right: 25px; 
            font-size: 2em; 
            cursor: pointer; 
            color: #fff; 
            z-index: 10;
            background: rgba(0,0,0,0.5);
            width: 45px;
            height: 45px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.3s;
        }
        .modal-close:hover { background: #f5576c; }
        .modal-image { 
            width: 100%; 
            height: 350px; 
            object-fit: cover; 
            border-radius: 24px 24px 0 0;
        }
        .modal-body { padding: 35px; }
        .modal-title { 
            font-size: 2em; 
            margin-bottom: 10px;
            font-weight: 700;
        }
        .modal-price { 
            font-size: 2.2em; 
            color: #f5576c; 
            font-weight: 700; 
            margin-bottom: 25px;
        }
        .modal-specs { 
            display: grid; 
            grid-template-columns: repeat(3, 1fr); 
            gap: 15px; 
            margin-bottom: 30px;
        }
        .spec-item { 
            background: rgba(255,255,255,0.08); 
            padding: 18px; 
            border-radius: 15px;
            text-align: center;
        }
        .spec-label { font-size: 0.8em; color: rgba(255,255,255,0.6); margin-bottom: 5px; }
        .spec-value { font-size: 1.1em; font-weight: 600; }
        .modal-description { 
            color: rgba(255,255,255,0.8); 
            line-height: 1.8; 
            margin-bottom: 30px;
            padding: 25px;
            background: rgba(255,255,255,0.05);
            border-radius: 15px;
            font-size: 1.05em;
        }
        .modal-actions { display: flex; gap: 15px; }
        .modal-btn { 
            flex: 1; 
            padding: 18px; 
            border-radius: 30px; 
            border: none; 
            cursor: pointer; 
            font-size: 1.1em; 
            font-weight: 600;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
        }
        .modal-btn.primary { background: linear-gradient(45deg, #00c851, #007e33); color: #fff; }
        .modal-btn.secondary { background: linear-gradient(45deg, #f093fb, #f5576c); color: #fff; }
        .modal-btn:hover { 
            transform: translateY(-3px); 
            box-shadow: 0 15px 30px rgba(0,0,0,0.3);
        }
        
        /* Contact Modal */
        .contact-modal .modal-content { max-width: 550px; }
        .contact-form { display: flex; flex-direction: column; gap: 18px; }
        .contact-form input, .contact-form textarea { 
            padding: 16px 20px; 
            border-radius: 12px; 
            border: 1px solid rgba(255,255,255,0.2); 
            background: rgba(255,255,255,0.08); 
            color: #fff;
            font-size: 1em;
            transition: all 0.3s;
        }
        .contact-form input:focus, .contact-form textarea:focus {
            outline: none;
            border-color: #f5576c;
            background: rgba(255,255,255,0.12);
        }
        .contact-form textarea { min-height: 120px; resize: vertical; }
        .contact-form input::placeholder, .contact-form textarea::placeholder { color: rgba(255,255,255,0.5); }
        .dealer-info {
            margin-top: 25px;
            padding: 20px;
            background: rgba(255,255,255,0.05);
            border-radius: 15px;
            text-align: center;
        }
        .dealer-info p { color: rgba(255,255,255,0.7); margin-bottom: 10px; }
        .dealer-phone { 
            font-size: 1.5em; 
            color: #00c851; 
            font-weight: 700;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
        }
        
        /* Quick Action Buttons */
        .quick-btn {
            background: rgba(255,255,255,0.1);
            border: 1px solid rgba(255,255,255,0.2);
            border-radius: 8px;
            width: 35px;
            height: 35px;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.3s;
            font-size: 1.1em;
        }
        .quick-btn:hover {
            background: rgba(255,255,255,0.2);
            transform: scale(1.1);
        }
        
        /* Success Alert */
        .success-alert {
            position: fixed;
            top: 20px;
            right: 20px;
            background: linear-gradient(45deg, #00c851, #007e33);
            color: white;
            padding: 15px 25px;
            border-radius: 10px;
            z-index: 2000;
            animation: slideIn 0.3s ease;
            max-width: 300px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
        }
        @keyframes slideIn {
            from { transform: translateX(100%); opacity: 0; }
            to { transform: translateX(0); opacity: 1; }
        }
        
        /* Price Calculator */
        .calculator-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            margin: 20px 0;
        }
        .calc-result {
            background: rgba(255,255,255,0.08);
            padding: 20px;
            border-radius: 15px;
            text-align: center;
            margin-top: 20px;
        }
        .calc-monthly {
            font-size: 2.5em;
            color: #00c851;
            font-weight: 700;
        }
        
        /* Wishlist Counter */
        .wishlist-counter {
            position: absolute;
            top: -8px;
            right: -8px;
            background: #f5576c;
            color: white;
            border-radius: 50%;
            width: 20px;
            height: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 0.8em;
            font-weight: 600;
        }
        .wishlist-btn {
            position: relative;
            background: linear-gradient(45deg, #ff6b6b, #ee5a24);
            color: white;
            border: none;
            padding: 12px 20px;
            border-radius: 25px;
            cursor: pointer;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 8px;
            transition: all 0.3s;
        }
        
        /* Trade-in Form */
        .trade-form {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
        }
        .trade-form .full-width {
            grid-column: span 2;
        }
        
        /* Footer */
        footer {
            margin-top: 60px;
            padding: 40px;
            background: rgba(255,255,255,0.05);
            border-radius: 20px;
            text-align: center;
        }
        footer p { color: rgba(255,255,255,0.6); }
        
        /* Responsive */
        @media (max-width: 768px) {
            .hero h1 { font-size: 2em; }
            .hero .stats { flex-direction: column; gap: 20px; }
            .modal-specs { grid-template-columns: repeat(2, 1fr); }
            .nav-links { display: none; }
            header { padding: 15px 20px; }
        }
    </style>
</head>
<body>
<div class="container">
    <header>
        <div class="logo">🚗 Capstone Motors</div>
        <nav class="nav-links">
            <a href="/">🏠 Inventory</a>
            <a href="#" onclick="showFinanceModal()">💰 Financing</a>
            <a href="#" onclick="showTradeInModal()">🔄 Trade-In</a>
            <button class="wishlist-btn" onclick="showWishlistModal()">
                ❤️ Wishlist
                <span class="wishlist-counter" id="wishlistCounter" style="display:none;">0</span>
            </button>
            <a href="#" onclick="showContactGeneral()">📧 Contact Us</a>
            <a href="#" onclick="showAboutModal()">ℹ️ About</a>
        </nav>
    </header>
    
    <div class="hero">
        <h1>Premium Automotive Excellence</h1>
        <p>Discover our curated collection of luxury, sports, and electric vehicles</p>
        <div class="stats">
            <div class="stat">
                <div class="stat-number"><?= $total ?></div>
                <div class="stat-label">Vehicles Available</div>
            </div>
            <div class="stat">
                <div class="stat-number"><?= count($makeList) ?></div>
                <div class="stat-label">Premium Brands</div>
            </div>
            <div class="stat">
                <div class="stat-number">100%</div>
                <div class="stat-label">Satisfaction Guaranteed</div>
            </div>
        </div>
    </div>
    
    <div class="filters">
        <h3>🔍 Find Your Perfect Vehicle</h3>
        <form method="GET">
            <div class="filter-grid">
                <input type="text" name="search" placeholder="🔍 Search make, model, color..." value="<?= htmlspecialchars($search) ?>" style="grid-column: span 2;">
                <select name="make">
                    <option value="">All Makes</option>
                    <?php foreach ($makeList as $m): ?>
                        <option value="<?= $m ?>" <?= $fm == $m ? 'selected' : '' ?>><?= $m ?></option>
                    <?php endforeach; ?>
                </select>
                <select name="category">
                    <option value="">All Categories</option>
                    <?php foreach ($catList as $c): ?>
                        <option value="<?= $c ?>" <?= $fc == $c ? 'selected' : '' ?>><?= $c ?></option>
                    <?php endforeach; ?>
                </select>
                <select name="type">
                    <option value="">All Body Types</option>
                    <?php foreach ($typeList as $t): ?>
                        <option value="<?= $t ?>" <?= $ft == $t ? 'selected' : '' ?>><?= $t ?></option>
                    <?php endforeach; ?>
                </select>
                <input type="number" name="min_price" placeholder="Min Price $" value="<?= $pmin > 0 ? $pmin : '' ?>">
                <input type="number" name="max_price" placeholder="Max Price $" value="<?= $pmax < 999999999 ? $pmax : '' ?>">
                <select name="sort">
                    <option value="price_desc" <?= $sort == 'price_desc' ? 'selected' : '' ?>>💰 Price: High to Low</option>
                    <option value="price_asc" <?= $sort == 'price_asc' ? 'selected' : '' ?>>💰 Price: Low to High</option>
                    <option value="hp_desc" <?= $sort == 'hp_desc' ? 'selected' : '' ?>>⚡ Horsepower</option>
                    <option value="year_desc" <?= $sort == 'year_desc' ? 'selected' : '' ?>>📅 Newest First</option>
                    <option value="name_asc" <?= $sort == 'name_asc' ? 'selected' : '' ?>>🔤 Name A-Z</option>
                    <option value="mileage_asc" <?= $sort == 'mileage_asc' ? 'selected' : '' ?>>📏 Lowest Mileage</option>
                </select>
                <button type="submit" class="btn">🔍 Search</button>
            </div>
        </form>
    </div>
    
    <div class="results-info">
        <span>Showing <strong><?= $cars->num_rows ?></strong> of <strong><?= $total ?></strong> vehicles</span>
        <a href="?">✕ Clear All Filters</a>
    </div>
    
    <div class="cars">
        <?php while ($car = $cars->fetch_assoc()): ?>
            <div class="card" onclick="showDetails(<?= htmlspecialchars(json_encode($car), ENT_QUOTES, 'UTF-8') ?>)">
                <div class="card-image">
                    <img src="<?= $car['image_url'] ?>" alt="<?= $car['make'] ?> <?= $car['model'] ?>">
                    <span class="badge"><?= $car['category'] ?></span>
                    <span class="fuel-badge"><?= $car['fuel_type'] ?></span>
                </div>
                <div class="card-info">
                    <h3><?= $car['year'] ?> <?= $car['make'] ?> <?= $car['model'] ?></h3>
                    <div class="specs">
                        <span>⚡ <?= $car['horsepower'] ?> HP</span>
                        <span>🔧 <?= $car['engine'] ?></span>
                        <span>🎨 <?= $car['color'] ?></span>
                        <span>📦 <?= $car['type'] ?></span>
                    </div>
                    <div class="price">$<?= number_format($car['price']) ?></div>
                    <div class="card-actions">
                        <button class="btn-contact" onclick="event.stopPropagation(); showContact(<?= htmlspecialchars(json_encode($car), ENT_QUOTES, 'UTF-8') ?>)">
                            📞 Contact
                        </button>
                        <button class="btn-details" onclick="event.stopPropagation(); showDetails(<?= htmlspecialchars(json_encode($car), ENT_QUOTES, 'UTF-8') ?>)">
                            ℹ️ Details
                        </button>
                    </div>
                    <div class="quick-actions" style="display:flex;gap:8px;margin-top:10px;">
                        <button class="quick-btn" onclick="event.stopPropagation(); addToWishlist(<?= $car['id'] ?>)" title="Add to Wishlist">
                            ❤️
                        </button>
                        <button class="quick-btn" onclick="event.stopPropagation(); shareVehicle(<?= htmlspecialchars(json_encode($car), ENT_QUOTES, 'UTF-8') ?>)" title="Share">
                            📤
                        </button>
                        <button class="quick-btn" onclick="event.stopPropagation(); calculatePayment(<?= $car['price'] ?>)" title="Calculate Payment">
                            🧮
                        </button>
                    </div>
                </div>
            </div>
        <?php endwhile; ?>
    </div>
    
    <footer>
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 30px; margin-bottom: 30px;">
            <div>
                <h3 style="color: #f5576c; margin-bottom: 15px;">🚗 Capstone Motors</h3>
                <p style="color: rgba(255,255,255,0.7); line-height: 1.6;">
                    Your premier destination for luxury, sports, and electric vehicles. 
                    Experience automotive excellence with our curated collection.
                </p>
            </div>
            <div>
                <h4 style="color: #f5576c; margin-bottom: 15px;">Quick Links</h4>
                <div style="display: flex; flex-direction: column; gap: 8px;">
                    <a href="/" style="color: rgba(255,255,255,0.8); text-decoration: none;">🏠 Vehicle Inventory</a>
                    <a href="#" onclick="showFinanceModal()" style="color: rgba(255,255,255,0.8); text-decoration: none;">💰 Financing Options</a>
                    <a href="#" onclick="showTradeInModal()" style="color: rgba(255,255,255,0.8); text-decoration: none;">🔄 Trade-In Program</a>
                    <a href="#" onclick="showAboutModal()" style="color: rgba(255,255,255,0.8); text-decoration: none;">ℹ️ About Us</a>
                </div>
            </div>
            <div>
                <h4 style="color: #f5576c; margin-bottom: 15px;">Contact Info</h4>
                <div style="color: rgba(255,255,255,0.7); line-height: 1.8;">
                    📍 123 Luxury Auto Blvd<br>
                    Premium City, PC 12345<br>
                    📞 1-800-CAPSTONE<br>
                    ✉️ sales@capstonemotors.com
                </div>
            </div>
            <div>
                <h4 style="color: #f5576c; margin-bottom: 15px;">Business Hours</h4>
                <div style="color: rgba(255,255,255,0.7); line-height: 1.8;">
                    Mon-Sat: 9:00 AM - 8:00 PM<br>
                    Sunday: 10:00 AM - 6:00 PM<br>
                    <br>
                    <em>Service available by appointment</em>
                </div>
            </div>
        </div>
        <hr style="border: 1px solid rgba(255,255,255,0.1); margin: 30px 0;">
        <p style="text-align: center; color: rgba(255,255,255,0.6);">
            © 2024 Capstone Motors - Premium Automotive Excellence | Powered by AWS Cloud Infrastructure
        </p>
    </footer>
</div>

<!-- Car Details Modal -->
<div id="detailsModal" class="modal" onclick="if(event.target===this)closeModal('detailsModal')">
    <div class="modal-content">
        <span class="modal-close" onclick="closeModal('detailsModal')">&times;</span>
        <img id="modalImg" class="modal-image" src="" alt="">
        <div class="modal-body">
            <h2 id="modalTitle" class="modal-title"></h2>
            <div id="modalPrice" class="modal-price"></div>
            <div class="modal-specs">
                <div class="spec-item"><div class="spec-label">Engine</div><div id="specEngine" class="spec-value"></div></div>
                <div class="spec-item"><div class="spec-label">Horsepower</div><div id="specHp" class="spec-value"></div></div>
                <div class="spec-item"><div class="spec-label">Transmission</div><div id="specTrans" class="spec-value"></div></div>
                <div class="spec-item"><div class="spec-label">Color</div><div id="specColor" class="spec-value"></div></div>
                <div class="spec-item"><div class="spec-label">Mileage</div><div id="specMileage" class="spec-value"></div></div>
                <div class="spec-item"><div class="spec-label">Fuel Type</div><div id="specFuel" class="spec-value"></div></div>
            </div>
            <div id="modalDesc" class="modal-description"></div>
            <div class="modal-actions">
                <button class="modal-btn primary" onclick="closeModal('detailsModal'); showContact(currentCar)">
                    📞 Contact Dealer
                </button>
                <button class="modal-btn secondary" onclick="closeModal('detailsModal')">
                    ✕ Close
                </button>
            </div>
        </div>
    </div>
</div>

<!-- Contact Dealer Modal -->
<div id="contactModal" class="modal contact-modal" onclick="if(event.target===this)closeModal('contactModal')">
    <div class="modal-content">
        <span class="modal-close" onclick="closeModal('contactModal')">&times;</span>
        <div class="modal-body">
            <h2 class="modal-title">📞 Contact Our Sales Team</h2>
            <p id="contactCar" style="color:#f5576c; margin-bottom: 25px; font-size: 1.15em; font-weight: 500;"></p>
            <form class="contact-form" method="POST">
                <input type="hidden" name="action" value="submit_inquiry">
                <input type="hidden" name="car_id" id="formCarId">
                <input type="text" name="name" id="contactName" placeholder="Your Full Name" required>
                <input type="email" name="email" id="contactEmail" placeholder="Email Address" required>
                <input type="tel" name="phone" id="contactPhone" placeholder="Phone Number (Optional)">
                <textarea name="message" id="contactMessage" placeholder="Tell us about your interest in this vehicle, questions, or schedule a test drive..."></textarea>
                <button type="submit" class="modal-btn primary">📧 Send Inquiry</button>
            </form>
            <div class="dealer-info">
                <p>Prefer to talk? Call us directly:</p>
                <div class="dealer-phone">📞 1-800-CAPSTONE</div>
                <p style="margin-top: 15px; font-size: 0.9em;">Mon-Sat: 9AM-8PM | Sun: 10AM-6PM</p>
            </div>
        </div>
    </div>
</div>

<!-- Financing Modal -->
<div id="financeModal" class="modal" onclick="if(event.target===this)closeModal('financeModal')">
    <div class="modal-content">
        <span class="modal-close" onclick="closeModal('financeModal')">&times;</span>
        <div class="modal-body">
            <h2 class="modal-title">💰 Financing Calculator</h2>
            <div class="calculator-grid">
                <div>
                    <label>Vehicle Price ($)</label>
                    <input type="number" id="calcPrice" placeholder="Vehicle Price" value="100000">
                </div>
                <div>
                    <label>Down Payment ($)</label>
                    <input type="number" id="calcDown" placeholder="Down Payment" value="20000">
                </div>
                <div>
                    <label>Interest Rate (%)</label>
                    <input type="number" step="0.1" id="calcRate" placeholder="Interest Rate" value="4.5">
                </div>
                <div>
                    <label>Loan Term (months)</label>
                    <select id="calcTerm">
                        <option value="36">36 months</option>
                        <option value="48">48 months</option>
                        <option value="60" selected>60 months</option>
                        <option value="72">72 months</option>
                        <option value="84">84 months</option>
                    </select>
                </div>
            </div>
            <button class="modal-btn primary" onclick="calculateMonthlyPayment()">🧮 Calculate Payment</button>
            <div id="calcResults" class="calc-result" style="display:none;">
                <div>Estimated Monthly Payment:</div>
                <div class="calc-monthly" id="monthlyPayment">$0</div>
                <p style="color: rgba(255,255,255,0.7); margin-top: 10px;">
                    This is an estimate. Actual rates may vary based on credit score and other factors.
                </p>
            </div>
        </div>
    </div>
</div>

<!-- Trade-In Modal -->
<div id="tradeModal" class="modal" onclick="if(event.target===this)closeModal('tradeModal')">
    <div class="modal-content">
        <span class="modal-close" onclick="closeModal('tradeModal')">&times;</span>
        <div class="modal-body">
            <h2 class="modal-title">🔄 Trade-In Your Vehicle</h2>
            <p style="margin-bottom: 25px; color: rgba(255,255,255,0.8);">
                Get an instant estimate for your current vehicle's trade-in value.
            </p>
            <form class="trade-form">
                <input type="text" placeholder="Year" required>
                <input type="text" placeholder="Make" required>
                <input type="text" placeholder="Model" required>
                <input type="number" placeholder="Mileage" required>
                <select required>
                    <option value="">Condition</option>
                    <option value="excellent">Excellent</option>
                    <option value="good">Good</option>
                    <option value="fair">Fair</option>
                    <option value="poor">Poor</option>
                </select>
                <input type="text" placeholder="ZIP Code" required>
                <textarea class="full-width" placeholder="Additional details about your vehicle's condition..."></textarea>
                <button type="button" class="modal-btn primary full-width" onclick="estimateTradeValue()">
                    💵 Get Instant Estimate
                </button>
            </form>
            <div id="tradeResult" style="display:none; margin-top: 25px; text-align: center;">
                <div style="color: #00c851; font-size: 1.8em; font-weight: 700;">
                    Estimated Trade Value: $<span id="tradeValue">0</span>
                </div>
                <p style="margin-top: 10px; color: rgba(255,255,255,0.7);">
                    Bring your vehicle for a detailed appraisal to confirm this estimate.
                </p>
            </div>
        </div>
    </div>
</div>

<!-- About Modal -->
<div id="aboutModal" class="modal" onclick="if(event.target===this)closeModal('aboutModal')">
    <div class="modal-content">
        <span class="modal-close" onclick="closeModal('aboutModal')">&times;</span>
        <div class="modal-body">
            <h2 class="modal-title">ℹ️ About Capstone Motors</h2>
            <div style="line-height: 1.8; color: rgba(255,255,255,0.8);">
                <p style="margin-bottom: 20px;">
                    <strong style="color: #f5576c;">Capstone Motors</strong> has been serving automotive enthusiasts for over 25 years, 
                    specializing in premium luxury, sports, and electric vehicles from the world's most prestigious manufacturers.
                </p>
                
                <h3 style="color: #f5576c; margin: 25px 0 15px 0;">🏆 Why Choose Us?</h3>
                <ul style="margin-left: 20px;">
                    <li>✅ Certified pre-owned vehicles with comprehensive warranties</li>
                    <li>✅ Expert financing options with competitive rates</li>
                    <li>✅ Full-service facility with certified technicians</li>
                    <li>✅ White-glove delivery service available</li>
                    <li>✅ 7-day return policy for peace of mind</li>
                </ul>
                
                <h3 style="color: #f5576c; margin: 25px 0 15px 0;">📍 Visit Our Showroom</h3>
                <p>
                    <strong>Address:</strong> 123 Luxury Auto Blvd, Premium City, PC 12345<br>
                    <strong>Hours:</strong> Mon-Sat 9AM-8PM, Sunday 10AM-6PM<br>
                    <strong>Phone:</strong> 1-800-CAPSTONE<br>
                    <strong>Email:</strong> sales@capstonemotors.com
                </p>
                
                <div style="margin-top: 30px; text-align: center;">
                    <button class="modal-btn primary" onclick="closeModal('aboutModal'); showContactGeneral();">
                        📧 Contact Us Today
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Wishlist Modal -->
<div id="wishlistModal" class="modal" onclick="if(event.target===this)closeModal('wishlistModal')">
    <div class="modal-content">
        <span class="modal-close" onclick="closeModal('wishlistModal')">&times;</span>
        <div class="modal-body">
            <h2 class="modal-title">❤️ Your Wishlist</h2>
            <div id="wishlistContent">
                <p style="text-align: center; color: rgba(255,255,255,0.6); padding: 40px;">
                    Your wishlist is empty. Start adding vehicles you love!
                </p>
            </div>
        </div>
    </div>
</div>

<script>
let currentCar = null;
let wishlist = JSON.parse(localStorage.getItem('capstoneWishlist') || '[]');

// Display success message if inquiry was submitted
<?php if (isset($inquiry_success)): ?>
showSuccessAlert('✅ Thank you! Your inquiry has been submitted successfully. We\'ll contact you within 24 hours.');
<?php endif; ?>

function showDetails(car) {
    currentCar = car;
    document.getElementById('modalImg').src = car.image_url;
    document.getElementById('modalTitle').textContent = car.year + ' ' + car.make + ' ' + car.model;
    document.getElementById('modalPrice').textContent = '$' + parseInt(car.price).toLocaleString();
    document.getElementById('specEngine').textContent = car.engine;
    document.getElementById('specHp').textContent = car.horsepower + ' HP';
    document.getElementById('specTrans').textContent = car.transmission || 'Automatic';
    document.getElementById('specColor').textContent = car.color;
    document.getElementById('specMileage').textContent = (car.mileage || 0).toLocaleString() + ' mi';
    document.getElementById('specFuel').textContent = car.fuel_type || 'Gasoline';
    document.getElementById('modalDesc').textContent = car.description || 
        'Experience luxury and performance with this exceptional ' + car.year + ' ' + car.make + ' ' + car.model + 
        '. This ' + car.category.toLowerCase() + ' ' + car.type.toLowerCase() + ' delivers ' + car.horsepower + 
        ' horsepower from its ' + car.engine + ' engine. Finished in stunning ' + car.color + '.';
    
    document.getElementById('detailsModal').classList.add('active');
    document.body.style.overflow = 'hidden';
}

function showContact(car) {
    currentCar = car;
    if (car) {
        document.getElementById('contactCar').textContent = 'Inquiring about: ' + car.year + ' ' + car.make + ' ' + car.model;
        document.getElementById('contactMessage').placeholder = 'I\'m interested in the ' + car.year + ' ' + car.make + ' ' + car.model + '. Please contact me with more information...';
        document.getElementById('formCarId').value = car.year + ' ' + car.make + ' ' + car.model;
    } else {
        document.getElementById('contactCar').textContent = 'General Inquiry';
        document.getElementById('contactMessage').placeholder = 'How can we help you today?';
        document.getElementById('formCarId').value = 'General';
    }
    document.getElementById('contactModal').classList.add('active');
    document.body.style.overflow = 'hidden';
}

function showContactGeneral() {
    currentCar = null;
    showContact(null);
}

function showFinanceModal() {
    document.getElementById('financeModal').classList.add('active');
    document.body.style.overflow = 'hidden';
}

function showTradeInModal() {
    document.getElementById('tradeModal').classList.add('active');
    document.body.style.overflow = 'hidden';
}

function showAboutModal() {
    document.getElementById('aboutModal').classList.add('active');
    document.body.style.overflow = 'hidden';
}

function showWishlistModal() {
    updateWishlistDisplay();
    document.getElementById('wishlistModal').classList.add('active');
    document.body.style.overflow = 'hidden';
}

function updateWishlistDisplay() {
    const counter = document.getElementById('wishlistCounter');
    if (wishlist.length > 0) {
        counter.textContent = wishlist.length;
        counter.style.display = 'flex';
    } else {
        counter.style.display = 'none';
    }
}

function closeModal(id) {
    document.getElementById(id).classList.remove('active');
    document.body.style.overflow = 'auto';
}

function calculateMonthlyPayment() {
    const price = parseFloat(document.getElementById('calcPrice').value) || 0;
    const down = parseFloat(document.getElementById('calcDown').value) || 0;
    const rate = parseFloat(document.getElementById('calcRate').value) || 4.5;
    const term = parseInt(document.getElementById('calcTerm').value) || 60;
    
    const loanAmount = price - down;
    const monthlyRate = rate / 100 / 12;
    const payment = loanAmount * (monthlyRate * Math.pow(1 + monthlyRate, term)) / (Math.pow(1 + monthlyRate, term) - 1);
    
    document.getElementById('monthlyPayment').textContent = '$' + Math.round(payment).toLocaleString();
    document.getElementById('calcResults').style.display = 'block';
}

function calculatePayment(price) {
    document.getElementById('calcPrice').value = price;
    showFinanceModal();
}

function estimateTradeValue() {
    // Simple estimation algorithm
    const baseValue = Math.floor(Math.random() * 40000) + 10000;
    document.getElementById('tradeValue').textContent = baseValue.toLocaleString();
    document.getElementById('tradeResult').style.display = 'block';
}

function addToWishlist(carId) {
    if (!wishlist.includes(carId)) {
        wishlist.push(carId);
        localStorage.setItem('capstoneWishlist', JSON.stringify(wishlist));
        showSuccessAlert('❤️ Added to your wishlist!');
        updateWishlistDisplay();
    } else {
        showSuccessAlert('💝 Already in your wishlist!');
    }
}

function removeFromWishlist(carId) {
    wishlist = wishlist.filter(id => id !== carId);
    localStorage.setItem('capstoneWishlist', JSON.stringify(wishlist));
    updateWishlistDisplay();
    updateWishlistModal();
}

function shareVehicle(car) {
    if (navigator.share) {
        navigator.share({
            title: car.year + ' ' + car.make + ' ' + car.model,
            text: 'Check out this ' + car.year + ' ' + car.make + ' ' + car.model + ' at Capstone Motors!',
            url: window.location.href
        });
    } else {
        // Fallback for browsers that don't support Web Share API
        const shareText = 'Check out this ' + car.year + ' ' + car.make + ' ' + car.model + ' at Capstone Motors! ' + window.location.href;
        navigator.clipboard.writeText(shareText).then(() => {
            showSuccessAlert('📋 Link copied to clipboard!');
        });
    }
}

function showSuccessAlert(message) {
    const alert = document.createElement('div');
    alert.className = 'success-alert';
    alert.textContent = message;
    document.body.appendChild(alert);
    
    setTimeout(() => {
        alert.style.opacity = '0';
        setTimeout(() => {
            if (alert.parentNode) {
                document.body.removeChild(alert);
            }
        }, 300);
    }, 3000);
}

// Close modal with Escape key
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        closeModal('detailsModal');
        closeModal('contactModal');
        closeModal('financeModal');
        closeModal('tradeModal');
        closeModal('aboutModal');
        closeModal('wishlistModal');
    }
});

// Live search functionality
let searchTimeout;
document.addEventListener('DOMContentLoaded', function() {
    const searchInput = document.querySelector('input[name="search"]');
    if (searchInput) {
        searchInput.addEventListener('input', function() {
            clearTimeout(searchTimeout);
            searchTimeout = setTimeout(() => {
                if (this.value.length > 2 || this.value.length === 0) {
                    this.form.submit();
                }
            }, 500);
        });
    }
    
    // Initialize wishlist counter
    updateWishlistDisplay();
});

// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({ behavior: 'smooth' });
        }
    });
});
</script>
</body>
</html>
