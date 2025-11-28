#!/bin/bash
set -e
amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
yum install -y httpd mariadb php-mysqlnd
systemctl start httpd && systemctl enable httpd

DB_HOST="${db_endpoint}"
DB_NAME="capstoneproject"
DB_USER="dbadmin"
DB_PASS="${db_password}"

cat > /var/www/html/config.php <<DBCONF
<?php
\$db_host = "$DB_HOST";
\$db_name = "$DB_NAME";
\$db_user = "$DB_USER";
\$db_pass = "$DB_PASS";
DBCONF

mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<'SQL'
CREATE TABLE IF NOT EXISTS cars (id INT AUTO_INCREMENT PRIMARY KEY,make VARCHAR(50),model VARCHAR(50),year INT,price INT,category VARCHAR(20),type VARCHAR(20),engine VARCHAR(30),horsepower INT,color VARCHAR(20),image_url VARCHAR(255));
DELETE FROM cars;
INSERT INTO cars (make,model,year,price,category,type,engine,horsepower,color,image_url) VALUES
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
('Lucid','Air',2024,169000,'Electric','Sedan','Dual-Motor',1111,'Green','https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?w=400');
SQL

cat > /var/www/html/index.php <<'PHP'
<?php
include 'config.php';
$conn=new mysqli($db_host,$db_user,$db_pass,$db_name);
if($conn->connect_error)die("DB Error");
$fm=isset($_GET['make'])?$_GET['make']:'';$ft=isset($_GET['type'])?$_GET['type']:'';$fc=isset($_GET['category'])?$_GET['category']:'';
$pmin=(int)(isset($_GET['min_price'])?$_GET['min_price']:0);$pmax=(int)(isset($_GET['max_price'])?$_GET['max_price']:999999);
$sort=isset($_GET['sort'])?$_GET['sort']:'price_desc';
$where="WHERE price>=$pmin AND price<=$pmax";
if($fm)$where.=" AND make='".mysqli_real_escape_string($conn,$fm)."'";
if($ft)$where.=" AND type='".mysqli_real_escape_string($conn,$ft)."'";
if($fc)$where.=" AND category='".mysqli_real_escape_string($conn,$fc)."'";
if($sort=='price_asc')$order='price ASC';elseif($sort=='hp_desc')$order='horsepower DESC';elseif($sort=='name_asc')$order='make ASC';else $order='price DESC';
$cars=$conn->query("SELECT * FROM cars $where ORDER BY $order");
$total=$conn->query("SELECT COUNT(*) as c FROM cars")->fetch_assoc()['c'];
$makes=$conn->query("SELECT DISTINCT make FROM cars ORDER BY make");
$types=$conn->query("SELECT DISTINCT type FROM cars ORDER BY type");
$cats=$conn->query("SELECT DISTINCT category FROM cars ORDER BY category");
?><!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Capstone Project</title>
<style>*{margin:0;padding:0;box-sizing:border-box}body{font-family:system-ui;background:linear-gradient(135deg,#0f0c29,#302b63,#24243e);color:#fff;min-height:100vh}.c{max-width:1400px;margin:0 auto;padding:20px}header{background:rgba(255,255,255,.1);backdrop-filter:blur(10px);padding:20px 40px;border-radius:15px;margin-bottom:30px}.logo{font-size:2em;font-weight:bold;background:linear-gradient(45deg,#f093fb,#f5576c);-webkit-background-clip:text;-webkit-text-fill-color:transparent}.hero{text-align:center;padding:40px}.hero h1{font-size:2.5em;background:linear-gradient(45deg,#f093fb,#f5576c,#ffd700);-webkit-background-clip:text;-webkit-text-fill-color:transparent}.hero p{color:#aaa;margin-top:10px}.filters{background:rgba(255,255,255,.1);padding:25px;border-radius:15px;margin-bottom:30px}.filters h3{margin-bottom:15px;color:#f5576c}.fg{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:15px}.fg select,.fg input{padding:10px;border-radius:8px;border:1px solid rgba(255,255,255,.2);background:rgba(255,255,255,.1);color:#fff}.fg select option{background:#302b63}.btn{background:linear-gradient(45deg,#f093fb,#f5576c);color:#fff;border:none;padding:12px 25px;border-radius:25px;cursor:pointer}.cars{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:25px}.card{background:rgba(255,255,255,.1);border-radius:20px;overflow:hidden;transition:.3s;border:1px solid rgba(255,255,255,.1)}.card:hover{transform:translateY(-10px);box-shadow:0 20px 40px rgba(0,0,0,.3)}.card img{width:100%;height:200px;object-fit:cover}.badge{position:absolute;top:15px;right:15px;background:linear-gradient(45deg,#f093fb,#f5576c);padding:5px 15px;border-radius:20px;font-size:.8em}.imgc{position:relative}.info{padding:20px}.info h3{font-size:1.2em;margin-bottom:8px}.specs{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin:15px 0;font-size:.9em;color:#aaa}.price{font-size:1.5em;font-weight:bold;color:#f5576c}.ri{display:flex;justify-content:space-between;margin-bottom:20px;padding:15px;background:rgba(255,255,255,.05);border-radius:10px}</style></head>
<body><div class="c"><header><div class="logo">☁️ Capstone Project</div></header>
<div class="hero"><h1>Luxury & Performance Vehicles</h1><p>Discover <?=$total?> premium automobiles</p></div>
<div class="filters"><h3>🔍 Filter Vehicles</h3><form method="GET"><div class="fg">
<select name="make"><option value="">All Makes</option><?php while($m=$makes->fetch_assoc()):?><option value="<?=$m['make']?>"<?=$fm==$m['make']?' selected':''?>><?=$m['make']?></option><?php endwhile;?></select>
<select name="category"><option value="">All Categories</option><?php while($c=$cats->fetch_assoc()):?><option value="<?=$c['category']?>"<?=$fc==$c['category']?' selected':''?>><?=$c['category']?></option><?php endwhile;?></select>
<select name="type"><option value="">All Types</option><?php while($t=$types->fetch_assoc()):?><option value="<?=$t['type']?>"<?=$ft==$t['type']?' selected':''?>><?=$t['type']?></option><?php endwhile;?></select>
<input type="number" name="min_price" placeholder="Min $" value="<?=$pmin?$pmin:''?>">
<input type="number" name="max_price" placeholder="Max $" value="<?=$pmax<999999?$pmax:''?>">
<select name="sort"><option value="price_desc"<?=$sort=='price_desc'?' selected':''?>>Price ↓</option><option value="price_asc"<?=$sort=='price_asc'?' selected':''?>>Price ↑</option><option value="hp_desc"<?=$sort=='hp_desc'?' selected':''?>>HP ↓</option><option value="name_asc"<?=$sort=='name_asc'?' selected':''?>>Name A-Z</option></select>
<button type="submit" class="btn">Apply</button></div></form></div>
<div class="ri"><span>Showing <?=$cars->num_rows?> of <?=$total?></span><a href="?" style="color:#f5576c;text-decoration:none">Clear Filters</a></div>
<div class="cars"><?php while($c=$cars->fetch_assoc()):?><div class="card"><div class="imgc"><img src="<?=$c['image_url']?>" alt="<?=$c['make']?>"><span class="badge"><?=$c['category']?></span></div><div class="info"><h3><?=$c['year']?> <?=$c['make']?> <?=$c['model']?></h3><div class="specs"><span>⚡ <?=$c['horsepower']?> HP</span><span>🔧 <?=$c['engine']?></span><span>🎨 <?=$c['color']?></span><span>📦 <?=$c['type']?></span></div><div class="price">$<?=number_format($c['price'])?></div></div></div><?php endwhile;?></div>
</div></body></html>
PHP
rm -f /var/www/html/index.html
chown -R apache:apache /var/www/html && chmod -R 755 /var/www/html && systemctl restart httpd
