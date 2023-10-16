#!/bin/bash

# This script will automated the deployment of a LAMP (Linux, Apache, MySQL, PHP) stack. And clone a PHP application from Github, install all necessary packages, and configure Apache web server and mysql database.

# Update the system
sudo apt-get update -y

# Upgrade the system
sudo apt-get upgrade -y

# Install Apache web server
sudo apt-get install apache2 -y

# Install MySQL database
sudo apt-get install mysql-server -y

# Secure MySQL database
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password cisco123'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password cisco123'

# Install PHP
sudo apt-get install php libapache2-mod-php php-mcrypt php-mysql -y

# Enable PHP module in Apache
sudo a2enmod php

# Restart Apache web server to apply changes
sudo systemctl restart apache2

# Install git
sudo apt-get install git -y

# Clone the PHP application from Github
sudo git clone https://github.com/laravel/laravel.git

# Navigate to the application directory
cd laravel || exit

# Install the necessary packages using Composer
sudo composer install

# copy .env.example to .env
sudo cp .env.example .env

# Generate application key
sudo php artisan key:generate

# Edit .env file and set the database connection details
cat > .env << EOF
DB_CONNECTION=mysql
DB_HOST=localhost
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=root
DB_PASSWORD=cisco123
EOF

# Create a database for the application
sudo mysql -u root -pcisco123 -e "create database laravel"

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

# End of the script