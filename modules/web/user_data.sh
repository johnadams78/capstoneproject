#!/bin/bash
exec > >(tee /var/log/user-data.log) 2>&1
amazon-linux-extras install -y php7.4
yum install -y httpd php php-mysqlnd
systemctl start httpd && systemctl enable httpd
cat > /var/www/html/config.php <<DBCONF
<?php
\$db_host = "${db_endpoint}";
\$db_name = "capstonedb";
\$db_user = "admin";
\$db_pass = "${db_password}";
DBCONF
cat > /var/www/html/index.php <<'PHPCODE'
<?php
include 'config.php';
$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);
if ($conn->connect_error) { echo "<h1>DB Error</h1><p>".htmlspecialchars($conn->connect_error)."</p>"; exit; }
$conn->query("CREATE TABLE IF NOT EXISTS cars (id INT AUTO_INCREMENT PRIMARY KEY,make VARCHAR(50),model VARCHAR(50),year INT,price INT,category VARCHAR(20),type VARCHAR(20),engine VARCHAR(30),horsepower INT,color VARCHAR(20),image_url VARCHAR(255))");
$count = $conn->query("SELECT COUNT(*) as c FROM cars")->fetch_assoc()['c'];
if ($count == 0) {
    $conn->query("INSERT INTO cars (make,model,year,price,category,type,engine,horsepower,color,image_url) VALUES
    ('Mercedes-Benz','S-Class',2024,114000,'Luxury','Sedan','V8',496,'Black','https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=400'),
    ('BMW','7 Series',2024,95000,'Luxury','Sedan','I6',375,'White','https://images.unsplash.com/photo-1555215695-3004980ad54e?w=400'),
    ('Porsche','911 Turbo S',2024,218000,'Sports','Coupe','Flat-6',640,'Red','https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=400'),
    ('Ferrari','Roma',2024,245000,'Sports','Coupe','V8',612,'Red','https://images.unsplash.com/photo-1592198084033-aade902d1aae?w=400'),
    ('Tesla','Model S',2024,108990,'Electric','Sedan','Tri-Motor',1020,'White','https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=400'),
    ('Range Rover','Autobiography',2024,185000,'Luxury','SUV','V8',523,'Black','https://images.unsplash.com/photo-1606016159991-dfe4f2746ad5?w=400'),
    ('Lamborghini','Huracan',2024,268000,'Sports','Coupe','V10',631,'Yellow','https://images.unsplash.com/photo-1544636331-e26879cd4d9b?w=400'),
    ('Rolls-Royce','Ghost',2024,340000,'Luxury','Sedan','V12',563,'Black','https://images.unsplash.com/photo-1563720360172-67b8f3dce741?w=400'),
    ('Rivian','R1S',2024,84500,'Electric','SUV','Quad-Motor',835,'Blue','https://images.unsplash.com/photo-1617788138017-80ad40651399?w=400'),
    ('Lucid','Air',2024,169000,'Electric','Sedan','Dual-Motor',1111,'Green','https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?w=400')");
}
$fm = isset($_GET['make']) ? trim($_GET['make']) : '';
$fc = isset($_GET['category']) ? trim($_GET['category']) : '';
$where = "WHERE 1=1";
if ($fm != '') $where .= " AND make = '" . mysqli_real_escape_string($conn, $fm) . "'";
if ($fc != '') $where .= " AND category = '" . mysqli_real_escape_string($conn, $fc) . "'";
$cars = $conn->query("SELECT * FROM cars $where ORDER BY price DESC");
$total = $conn->query("SELECT COUNT(*) as c FROM cars")->fetch_assoc()['c'];
$makeList = []; $r = $conn->query("SELECT DISTINCT make FROM cars ORDER BY make"); while ($row = $r->fetch_assoc()) $makeList[] = $row['make'];
$catList = []; $r = $conn->query("SELECT DISTINCT category FROM cars ORDER BY category"); while ($row = $r->fetch_assoc()) $catList[] = $row['category'];
?>
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Capstone Car Dealership</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}body{font-family:system-ui;background:linear-gradient(135deg,#0f0c29,#302b63,#24243e);color:#fff;min-height:100vh}.c{max-width:1400px;margin:0 auto;padding:20px}header{background:rgba(255,255,255,.1);backdrop-filter:blur(10px);padding:20px 40px;border-radius:15px;margin-bottom:30px}.logo{font-size:2em;font-weight:bold;background:linear-gradient(45deg,#f093fb,#f5576c);-webkit-background-clip:text;-webkit-text-fill-color:transparent}.hero{text-align:center;padding:40px}.hero h1{font-size:2.5em;background:linear-gradient(45deg,#f093fb,#f5576c,#ffd700);-webkit-background-clip:text;-webkit-text-fill-color:transparent}.filters{background:rgba(255,255,255,.1);padding:25px;border-radius:15px;margin-bottom:30px}.fg{display:flex;gap:15px;flex-wrap:wrap}.fg select{padding:10px;border-radius:8px;border:1px solid rgba(255,255,255,.2);background:rgba(255,255,255,.1);color:#fff}.fg select option{background:#302b63}.btn{background:linear-gradient(45deg,#f093fb,#f5576c);color:#fff;border:none;padding:12px 25px;border-radius:25px;cursor:pointer}.cars{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:25px}.card{background:rgba(255,255,255,.1);border-radius:20px;overflow:hidden;transition:.3s;border:1px solid rgba(255,255,255,.1);cursor:pointer}.card:hover{transform:translateY(-10px);box-shadow:0 20px 40px rgba(0,0,0,.3)}.card img{width:100%;height:200px;object-fit:cover}.badge{position:absolute;top:15px;right:15px;background:linear-gradient(45deg,#f093fb,#f5576c);padding:5px 15px;border-radius:20px;font-size:.8em}.imgc{position:relative}.info{padding:20px}.info h3{font-size:1.2em;margin-bottom:8px}.specs{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin:15px 0;font-size:.9em;color:#aaa}.price{font-size:1.5em;font-weight:bold;color:#f5576c}.btns{display:flex;gap:10px;margin-top:15px}.btn-c{background:linear-gradient(45deg,#00c851,#007e33);flex:1;padding:10px;border:none;border-radius:20px;color:#fff;cursor:pointer;font-size:.85em}.btn-d{background:linear-gradient(45deg,#f093fb,#f5576c);flex:1;padding:10px;border:none;border-radius:20px;color:#fff;cursor:pointer;font-size:.85em}.modal{display:none;position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,.8);z-index:1000;justify-content:center;align-items:center}.modal.active{display:flex}.mc{background:linear-gradient(135deg,#1a1a2e,#16213e);border-radius:20px;max-width:600px;width:90%;max-height:90vh;overflow-y:auto;position:relative;border:1px solid rgba(255,255,255,.1)}.mx{position:absolute;top:15px;right:20px;font-size:2em;cursor:pointer;color:#fff;z-index:10}.mb{padding:30px}.mt{font-size:1.5em;margin-bottom:10px}.mp{font-size:1.8em;color:#f5576c;font-weight:bold;margin-bottom:20px}.ms{display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:20px}.si{background:rgba(255,255,255,.1);padding:12px;border-radius:8px}.sl{font-size:.75em;color:#aaa}.sv{font-weight:bold}.cf{display:flex;flex-direction:column;gap:12px}.cf input,.cf textarea{padding:12px;border-radius:8px;border:1px solid rgba(255,255,255,.2);background:rgba(255,255,255,.1);color:#fff}.cf textarea{min-height:80px}.ph{margin-top:15px;padding:12px;background:rgba(255,255,255,.05);border-radius:8px;text-align:center}.ph p{color:#00c851;font-size:1.2em;font-weight:bold}
</style></head><body>
<div class="c">
<header><div class="logo">☁️ Capstone Project</div></header>
<div class="hero"><h1>Luxury & Performance Vehicles</h1><p>Discover <?= $total ?> premium automobiles</p></div>
<div class="filters"><h3>🔍 Filter</h3><form method="GET"><div class="fg">
<select name="make"><option value="">All Makes</option><?php foreach ($makeList as $m): ?><option value="<?= $m ?>" <?= $fm == $m ? 'selected' : '' ?>><?= $m ?></option><?php endforeach; ?></select>
<select name="category"><option value="">All Categories</option><?php foreach ($catList as $c): ?><option value="<?= $c ?>" <?= $fc == $c ? 'selected' : '' ?>><?= $c ?></option><?php endforeach; ?></select>
<button type="submit" class="btn">Apply</button><a href="?" style="color:#f5576c;padding:12px">Clear</a>
</div></form></div>
<div class="cars">
<?php while ($c = $cars->fetch_assoc()): $j = htmlspecialchars(json_encode($c), ENT_QUOTES, 'UTF-8'); ?>
<div class="card" onclick='showD(<?= $j ?>)'><div class="imgc"><img src="<?= $c['image_url'] ?>" alt="<?= $c['make'] ?>"><span class="badge"><?= $c['category'] ?></span></div>
<div class="info"><h3><?= $c['year'] ?> <?= $c['make'] ?> <?= $c['model'] ?></h3>
<div class="specs"><span>⚡ <?= $c['horsepower'] ?> HP</span><span>🔧 <?= $c['engine'] ?></span><span>🎨 <?= $c['color'] ?></span><span>📦 <?= $c['type'] ?></span></div>
<div class="price">$<?= number_format($c['price']) ?></div>
<div class="btns"><button class="btn-c" onclick="event.stopPropagation();showC(<?= $j ?>)">📞 Contact</button><button class="btn-d" onclick="event.stopPropagation();showD(<?= $j ?>)">ℹ️ Details</button></div>
</div></div>
<?php endwhile; ?>
</div>
</div>
<div id="dm" class="modal" onclick="if(event.target===this)closeM('dm')"><div class="mc"><span class="mx" onclick="closeM('dm')">&times;</span><div class="mb">
<h2 id="dt" class="mt"></h2><div id="dp" class="mp"></div>
<div class="ms"><div class="si"><div class="sl">Engine</div><div id="de" class="sv"></div></div><div class="si"><div class="sl">Horsepower</div><div id="dh" class="sv"></div></div><div class="si"><div class="sl">Color</div><div id="dc" class="sv"></div></div><div class="si"><div class="sl">Type</div><div id="dy" class="sv"></div></div></div>
<p id="dd" style="color:#ccc;line-height:1.6;margin-bottom:20px"></p>
<button class="btn" style="width:100%" onclick="closeM('dm');showC(cc)">📞 Contact Dealer</button>
</div></div></div>
<div id="cm" class="modal" onclick="if(event.target===this)closeM('cm')"><div class="mc"><span class="mx" onclick="closeM('cm')">&times;</span><div class="mb">
<h2 class="mt">📞 Contact Dealer</h2><p id="cn" style="color:#f5576c;margin-bottom:20px"></p>
<form class="cf" onsubmit="subC(event)"><input type="text" placeholder="Your Name" required><input type="email" placeholder="Your Email" required><input type="tel" placeholder="Phone Number"><textarea placeholder="Message..."></textarea><button type="submit" class="btn">📧 Send Inquiry</button></form>
<div class="ph"><p>📞 1-800-CAPSTONE</p></div>
</div></div></div>
<script>
let cc=null;
function showD(c){cc=c;document.getElementById('dt').textContent=c.year+' '+c.make+' '+c.model;document.getElementById('dp').textContent='$'+parseInt(c.price).toLocaleString();document.getElementById('de').textContent=c.engine;document.getElementById('dh').textContent=c.horsepower+' HP';document.getElementById('dc').textContent=c.color;document.getElementById('dy').textContent=c.type;document.getElementById('dd').textContent='This '+c.year+' '+c.make+' '+c.model+' features a '+c.engine+' engine with '+c.horsepower+' HP. A stunning '+c.category.toLowerCase()+' '+c.type.toLowerCase()+' in '+c.color+'.';document.getElementById('dm').classList.add('active');document.body.style.overflow='hidden';}
function showC(c){cc=c;document.getElementById('cn').textContent='Inquiring about: '+c.year+' '+c.make+' '+c.model;document.getElementById('cm').classList.add('active');document.body.style.overflow='hidden';}
function closeM(id){document.getElementById(id).classList.remove('active');document.body.style.overflow='auto';}
function subC(e){e.preventDefault();alert('Thank you! We will contact you about the '+cc.year+' '+cc.make+' '+cc.model+'.');closeM('cm');}
document.addEventListener('keydown',function(e){if(e.key==='Escape'){closeM('dm');closeM('cm');}});
</script>
</body></html>
PHPCODE
rm -f /var/www/html/index.html
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html
systemctl restart httpd
echo "Done!"
