#!/bin/bash

# This script will automated the deployment of a LAMP (Linux, Apache, MySQL, PHP) stack. And clone a PHP application from Github, install all necessary packages, and configure Apache web server and mysql database.

# Update and upgrade the system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install Apache web server
sudo apt-get install apache2 -y

# Configure Apache web server
sudo sed -i 's/Options Indexes FollowSymLinks/Options FollowSymLinks/' /etc/apache2/apache2.conf
sudo sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# Install MySQL database server
export MYSQL_PWD=c03Di09s19Tc03o15P
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password $MYSQL_PWD'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password $MYSQL_PWD'
sudo apt-get install mysql-server -y

# Install PHP
sudo apt-get install php libapache2-mod-php php-mcrypt php-mysql php-zip php-xml php-curl php-cli php-mbstring -y

# Install Composer
sudo curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

# Move the downloaded composer.phar file to /usr/local/bin/composer
sudo mv composer.phar /usr/local/bin/composer

# Make the composer.phar executable
sudo chmod +x /usr/local/bin/composer

# Install unzip
sudo apt-get install unzip -y

# Install curl
sudo apt-get install curl -y

# Enable PHP module in Apache
sudo a2enmod php

# Restart Apache web server to apply changes
sudo systemctl restart apache2

# Install git
sudo apt-get install git -y

# Navigate to the Apache web server root directory
cd /var/www/html || exit

# Remove the default index.html file
sudo rm -rf index.html

# Change the ownership of the /var/www/html directory to the Apache web server user
sudo chown -R www-data:www-data /var/www/html/*

# Clone the PHP application from Github
git clone https://github.com/laravel/laravel.git

# Navigate to the application directory
cd laravel || exit

# Install the necessary packages using Composer
sudo composer install

# copy .env.example to .env
sudo cp .env.example .env

# Generate application key
sudo php artisan key:generate

# Edit .env file and set the database connection details
sudo sed -i 's/DB_DATABASE=homestead/DB_DATABASE=laravel/g' .env
sudo sed -i 's/DB_USERNAME=homestead/DB_USERNAME=root/g' .env
sudo sed -i 's/DB_PASSWORD=secret/DB_PASSWORD=$MYSQL_PWD/g' .env

# Create a database for the application
sudo mysql -u root -p$MYSQL_PWD -e "create database laravel"

# Migrate the database
sudo php artisan migrate

# Generate a symbolic link for storage
sudo php artisan storage:link

# Set the application folder permission
sudo chown -R www-data:www-data storage bootstrap/cache

# Generate the optimized class loader
sudo composer dump-autoload -o

# Restart Apache web server to apply changes
sudo systemctl restart apache2

# Set firewall rules
sudo apt-get install ufw -y
sudo ufw enable
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3306/tcp

# Log the output of each command in the script into a file called deploy.log
exec &> >(tee -a deploy.log) || exit

# End of the script