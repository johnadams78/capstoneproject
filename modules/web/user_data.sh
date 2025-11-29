#!/bin/bash
# User data script - pulls application code from GitHub
exec > >(tee /var/log/user-data.log) 2>&1
echo "Starting user data script at $(date)"

# Install dependencies
echo "Installing packages..."
amazon-linux-extras install -y php7.4
yum install -y httpd php php-mysqlnd git
systemctl start httpd && systemctl enable httpd

# Clone the application from GitHub
echo "Cloning application from GitHub..."
cd /tmp
git clone https://github.com/johnadams78/capstoneproject.git app
cp /tmp/app/webapp/index.php /var/www/html/index.php

# Create database config with actual credentials
echo "Creating database configuration..."
cat > /var/www/html/config.php <<DBCONF
<?php
\$db_host = "${db_endpoint}";
\$db_name = "capstonedb";
\$db_user = "admin";
\$db_pass = "${db_password}";
DBCONF

# Set permissions
rm -f /var/www/html/index.html
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html
systemctl restart httpd

echo "Setup complete at $(date)"
