#!/bin/bash

# This script will automatically deploy a LAMP stack and clone a PHP application from a GitHub repository (https://github.com/laravel/laravel.git) and configure the Apache web server and MySQL database.

# Check if the script is being run as root, if not run as root
if [[ "$(id -u)" -ne 0 ]]; then
    sudo -E "$0" "$@"
    exit
fi

# Log the all the commands and the output to a file called deploy.log in the shared directory
shared_dir="/vagrant"
log_file="$shared_dir/deploy.log"
exec > >(tee -a "$log_file") 2>&1

# Get server IP address
server_ip=$(ip addr show eth1 | awk '/inet / {print $2}' | cut -d/ -f1)

# Define variables for configurations
server_admin_email="ayodejihamed@gmail.com"
laravel_repo_url="https://github.com/laravel/laravel.git"

#######################################################################################################
#######################################################################################################

# Start logging the script
echo "========== Deployment started at $(date) =========="

#######################################################################################################
#######################################################################################################

# Add important repositories to the APT package manager
echo "========== Adding important repositories to the APT package manager =========="
apt-get install -y software-properties-common
add-apt-repository -y ppa:ondrej/php

# Update the package list to ensure you download the latest versions of the packages
echo "========== Updating the package list =========="
apt-get update -y

# Upgrade the installed packages to the latest versions
echo "========== Upgrading the installed packages =========="
apt-get upgrade -y

#######################################################################################################
#######################################################################################################

## Install and setup AMP (Apache, MySQL, PHP) and other packages

# Install the Apache web server
echo "========== Installing the Apache web server =========="
apt-get install -y apache2

# Start and Enable Apache web server
echo "========== Starting and enabling the Apache web server =========="
systemctl start apache2
systemctl enable apache2

# Generate a random secure password for MySQL root user
echo "========== Generating a random secure password for MySQL root user =========="
mysql_root_password=$(date +%s | sha256sum | base64 | head -c 16)

# Install MySQL Server in a Non-Interactive mode. Default root password will be set to the one you set in the previous step
echo "========== Installing MySQL Server =========="
debconf-set-selections <<< "mysql-server mysql-server/root_password password $mysql_root_password"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $mysql_root_password"
apt-get install -y mysql-server

# Display the MySQL root password
echo "========== MySQL root password: $mysql_root_password =========="

# Disallow remote root login
echo "========== Disallowing remote root login =========="
sed -i "s/.*bind-address.*/bind-address = 127.0.0.1/" /etc/mysql/mysql.conf.d/mysqld.cnf

# Remove the test database
echo "========== Removing the test database =========="
mysql -uroot -p"$mysql_root_password" -e "DROP DATABASE IF EXISTS test;" || true

# Restart MySQL
echo "========== Restarting MySQL =========="
systemctl restart mysql

# Install PHP and some of the most common PHP extensions
echo "========== Installing PHP and some of the most common PHP extensions =========="
apt-get install -y php8.2 libapache2-mod-php8.2 php8.2-common php8.2-mysql php8.2-gmp php8.2-curl php8.2-intl php8.2-mbstring php8.2-xmlrpc php8.2-gd php8.2-xml php8.2-cli php8.2-zip php8.2-tokenizer php8.2-bcmath php8.2-soap php8.2-imap unzip zip

# Configure PHP
echo "========== Configuring PHP =========="
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/8.2/apache2/php.ini

# Restart Apache web server
echo "========== Restarting Apache web server =========="
systemctl restart apache2

# Install Composer
echo "========== Installing Composer =========="
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Configure Apache web server
echo "========== Configuring Apache web server =========="

# Create a new Apache configuration file for Laravel
echo "========== Creating a new Apache configuration file for Laravel =========="
cat > /etc/apache2/sites-available/laravel.conf <<EOL
<VirtualHost *:80>
    ServerAdmin $server_admin_email
    ServerName $server_ip
    DocumentRoot /var/www/html/laravel/public

    <Directory /var/www/html/laravel>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

# Disable the default Apache configuration file
echo "========== Disabling the default Apache configuration file =========="
a2dissite 000-default.conf

# Enable the new Laravel configuration file
echo "========== Enabling the new Laravel configuration file =========="
a2enmod rewrite
a2ensite laravel.conf

# Enable the PHP module in Apache
echo "========== Enabling the PHP module in Apache =========="
a2enmod php8.2

# Restart Apache web server
echo "========== Restarting Apache web server =========="
systemctl restart apache2

# Install git if it is not already installed and update it to the latest version
echo "========== Installing git =========="
# Check if Git is installed and install/upgrade it
if [ -x "$(command -v git)" ]; then
    echo "Git is already installed. Checking for updates..."
    apt-get update
    apt-get install --only-upgrade git
else
    echo "Git is not installed. Installing the latest version..."
    apt-get install -y git
fi

#######################################################################################################
#######################################################################################################

## Set up Laravel application
# Navigate to the web root directory
echo "========== Navigating to the web root directory =========="
cd /var/www/html || exit

# Clone the Laravel repository from GitHub
echo "========== Cloning the Laravel repository from GitHub =========="
git clone $laravel_repo_url

# Navigate to the Laravel application directory
echo "========== Navigating to the Laravel application directory =========="
cd laravel || exit

# Install the Laravel application dependencies
echo "========== Installing the Laravel application dependencies =========="
composer install --no-interaction --optimize-autoloader --no-dev
composer update --no-interaction --optimize-autoloader --no-dev
# Set Laravel permissions
echo "========== Setting Laravel permissions =========="
chown -R www-data:www-data /var/www/html/laravel
chmod -R 755 /var/www/html/laravel
chmod -R 755 /var/www/html/laravel/storage
chmod -R 755 /var/www/html/laravel/bootstrap/cache

# Create a new .env file from the .env.example file
echo "========== Creating a new .env file from the .env.example file =========="
cp .env.example .env

# Generate an application key
echo "========== Generating an application key =========="
php artisan key:generate

# Mysql Database Setup
echo "========== Database Setup =========="
db_name="laravel"
mysql_user="root"

mysql -u $mysql_user -p"$mysql_root_password" <<MYSQL_SCRIPT
CREATE DATABASE $db_name;
GRANT ALL PRIVILEGES ON $db_name.* TO '$mysql_user'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Update the .env file with the database connection details
echo "========== Updating the .env file with the database connection details =========="
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD='$mysql_root_password'/" .env


# Cache the configuration values
echo "========== Caching the configuration values =========="
php artisan config:cache

# Run the database migrations
echo "========== Running the database migrations =========="
php artisan migrate --force

# Restart Apache web server
echo "========== Restarting Apache web server =========="
systemctl restart apache2

#######################################################################################################
#######################################################################################################

# End logging the script
echo "========== Deployment ended at $(date) =========="

#######################################################################################################
#######################################################################################################

# Add firewall rules

#  Check if ufw is installed and active
if ! dpkg -l | grep -q "ufw"; then
    echo "ufw is not installed. Installing..."
    apt-get install -y ufw
    echo "ufw installed."
fi

# Enable ufw
echo "========== Enabling ufw =========="
ufw --force enable

echo "========== Adding firewall rules =========="
ufw allow openssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3306/tcp

#######################################################################################################
#######################################################################################################

# Access the application in a browser using the server IP address
echo "========== Access the application in a browser using the server IP address =========="
echo "========== Server IP address: $server_ip =========="

# End of script

#######################################################################################################