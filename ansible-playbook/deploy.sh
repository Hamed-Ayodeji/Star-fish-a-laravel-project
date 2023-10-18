#!/bin/bash
# Automated Ubuntu LAMP Stack Deployment with Laravel

# Log all outputs to deploy.log
exec > >(tee -i /home/vagrant/deploy.log)
exec 2>&1

# Check if the script is being run with root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run with superuser privileges. Attempting to run with sudo..."
  exec sudo "$0" "$@"
  exit 1
fi

# Generate a random secure password for MySQL root user
mysql_root_password=$(date +%s | sha256sum | base64 | head -c 16)

# Update and upgrade the system
echo "Updating and upgrading the system..."
apt update
apt upgrade -y

# Add PHP repository and install PHP 8.0
echo "Adding PHP repository and installing PHP 8.0..."
add-apt-repository ppa:ondrej/php
apt update
apt install -y php8.0

# Set PHP 8.0 as the default PHP version
update-alternatives --set php /usr/bin/php8.0

# Add this line to allow running Composer as superuser
export COMPOSER_ALLOW_SUPERUSER=1

# Install Apache web server
echo "Installing Apache web server..."
apt install -y apache2

# Enable Apache and start the service
echo "Enabling and starting Apache..."
systemctl enable apache2
systemctl start apache2

# Remove the default Apache configuration
echo "Removing default Apache configurations..."
a2dissite 000-default.conf
rm /etc/apache2/sites-available/000-default.conf

# Remove the default Apache page from /var/www/html
echo "Removing the default Apache page..."
rm /var/www/html/index.html

# Create a new VirtualHost configuration for Laravel
echo "Creating new Apache configuration for Laravel..."
cat > /etc/apache2/sites-available/laravel.conf <<EOL
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/laravel/public
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

# Enable the new VirtualHost
a2ensite laravel.conf

# Enable the Apache rewrite module
a2enmod rewrite

# Set up firewall rules (allow HTTP traffic)
echo "Setting up firewall rules (allowing HTTP traffic)..."
ufw allow 80/tcp
ufw --force enable

# Install PHP and necessary modules
echo "Installing PHP and required modules..."
apt install -y libapache2-mod-php php-mysql php-curl php-json php-gd php-mbstring php-xml php-zip

# Check if Git is installed and install/upgrade it
if [ -x "$(command -v git)" ]; then
    echo "Git is already installed. Checking for updates..."
    apt update
    apt install --only-upgrade git
else
    echo "Git is not installed. Installing the latest version..."
    apt install -y git
fi

# Install Composer (a PHP package manager)
echo "Installing Composer..."
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Clone the Laravel Git repository
echo "Cloning the Laravel Git repository..."
cd /var/www/html
git clone https://github.com/laravel/laravel.git

# Install MySQL server and set the root password
echo "Installing MySQL server and setting the root password..."
debconf-set-selections <<< "mysql-server mysql-server/root_password password $mysql_root_password"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $mysql_root_password"
apt install -y mysql-server

# Securely display the MySQL root password
echo "The MySQL root password is: $mysql_root_password"

# Install Laravel dependencies using Composer
echo "Installing Laravel dependencies..."
cd /var/www/html/laravel
composer install

# Set appropriate ownership for the Laravel project
echo "Setting ownership for Laravel project..."
chown -R www-data:www-data /var/www/html/laravel

# Copy the .env.example to .env
echo "Copying .env.example to .env..."
cp /var/www/html/laravel/.env.example /var/www/html/laravel/.env

# Generate the Laravel application key
echo "Generating Laravel application key..."
php /var/www/html/laravel/artisan key:generate

# Edit the .env file to set the database connection details
echo "Editing .env file to set database connection details..."
sed -i 's/DB_USERNAME=/DB_USERNAME=root/g' /var/www/html/laravel/.env
sed -i 's/DB_PASSWORD=/DB_PASSWORD='$mysql_root_password'/g' /var/www/html/laravel/.env

# Create a new MySQL database for the Laravel application
echo "Creating a new MySQL database for the Laravel application..."
mysql -u root -p$mysql_root_password -e "CREATE DATABASE laravel_db;"

# Set the Laravel application to use the new database
echo "Configuring Laravel to use the new database..."
sed -i 's/DB_DATABASE=/DB_DATABASE=laravel_db/g' /var/www/html/laravel/.env

# Run Laravel database migrations
echo "Running Laravel database migrations..."
php /var/www/html/laravel/artisan migrate

# Generate a symbolic link for the storage directory
echo "Generating a symbolic link for the storage directory..."
php /var/www/html/laravel/artisan storage:link

# Set permissions for the Laravel application directory
echo "Setting permissions for the Laravel application directory..."
chown -R www-data:www-data /var/www/html/laravel
chmod -R 755 /var/www/html/laravel/storage
chmod -R 755 /var/www/html/laravel/bootstrap/cache

# Generate the optimized class loader
echo "Generating the optimized class loader..."
php /var/www/html/laravel/artisan optimize

# Restart Apache to apply all changes
echo "Restarting Apache to apply all changes..."
systemctl restart apache2

# End of script
echo "Laravel setup completed. Apache has been restarted."