# Project Documentation

## Table of Contents

1. [Introduction](#introduction)
2. [Project Overview](#project-overview)
   - [Objective](#objective)
   - [Requirements](#requirements)
3. [Deployment Instructions](#deployment-instructions)
   - [Provisioning Servers with Vagrant](#provisioning-servers-with-vagrant)
   - [Automating Deployment with Bash Script](#automating-deployment-with-bash-script)
   - [Executing the Ansible Playbook](#executing-the-ansible-playbook)
4. [Code Files](#code-files)
   - [Vagrant Configuration File - Vagrantfile](#vagrant-configuration-file---vagrantfile)
   - [Bash Script - deploy.sh](#bash-script---deploysh)
   - [Ansible Playbook - playbook.yml](#ansible-playbook---playbookyml)
   - [Ansible Configuration - ansible.cfg](#ansible-configuration---ansiblecfg)
   - [Ansible Inventory - inventory.ini](#ansible-inventory---inventoryini)
5. [Log Files](#log-files)
   - [Bash Script Log - deploy.log](#bash-script-log---deploylog)
   - [Ansible Playbook Log - ansible.log](#ansible-playbook-log---ansiblelog)
   - [Cron Job Log - uptime.log](#cron-job-log---uptimelog)
6. [Screenshots](#screenshots-evidence)
   - [Screenshots of the laravel application deployed with Bash script on the Master](#screenshots-master-node)
   - [Screenshots of the laravel application deployed with Ansible on the Slave](#screenshots-slave-node)
7. [Usage](#usage)
8. [Important Notes](#important-notes)
9. [Contributing](#contributing)
10. [References](#references)

## [Introduction](introduction)

Welcome to the documentation for the Cloud Engineering Second Semester Examination Project (Deploy LAMP Stack). This documentation provides a comprehensive guide to automating the provisioning and deployment of a LAMP (Linux, Apache, MySQL, PHP) stack using Vagrant, a bash script, Ansible and a PHP application (Laravel). The project aims to streamline the process of setting up a web server environment for hosting PHP applications in this case a Laravel application, which will be cloned from the official Laravel repository [GitHub Repository for Laravel](https://github.com/laravel/laravel).

## [Project Overview](project-overview)

### [Objective](objective)

The primary objective of this project is to automate the provisioning of two Ubuntu-based servers, referred to as "Master" and "Slave," using Vagrant. The automation involves the following steps:

1. Create a bash script to automate the deployment of a LAMP stack on the "Master" node.
2. Clone a PHP application from GitHub.
3. Install all necessary packages.
4. Configure the Apache web server and MySQL.
5. Ensure the bash script is reusable and readable.

In addition to the bash script, an Ansible playbook is used to:

1. Execute the bash script on the "Slave" node.
2. Create a cron job to check the server's uptime every day at 12 am.

It is also important to verify that the PHP application is accessible through the VM's IP address and take a screenshot as evidence.

### [Requirements](requirements)

To successfully complete the project, the following requirements must be met:

1. Submit the bash script and Ansible playbook to a publicly accessible GitHub repository.
2. Document the steps in Markdown files, including screenshots where necessary.
3. Use either the VM's IP address or a domain name as the URL.

## [Deployment Instructions](deployment-instructions)

In this section, we'll cover the steps to deploy the LAMP stack using Vagrant, the bash script, and the Ansible playbook.

### [Provisioning Servers with Vagrant](provisioning-servers-with-vagrant)

To provision servers using Vagrant, we use the `Vagrantfile` provided. This file defines the configuration for both the "Master" and "Slave" servers. It specifies the base box, networking settings, and provisioning steps.

1. **Vagrant Configuration File**: The `Vagrantfile` specifies the configuration for the "Master" and "Slave" servers.

```ruby
# Deployment of two Ubuntu-based servers, named Master and Slave using Vagrant.

Vagrant.configure("2") do |config|
  # Configuration for Master server
  config.vm.box = "bento/ubuntu-20.04"
  config.vm.define "Master" do |master|
    # Master server settings
    # ...
  end

  # Configuration for Slave server
  config.vm.define "Slave" do |slave|
    # Slave server settings
    # ...
  end
end
```

2. **Server Provisioning**: The Vagrant configuration provisions the servers and ensures that SSH is properly configured. It also executes the `deploy.sh` script on the "Master" server.

3. **Network Configuration**: The servers are connected to a private network to allow communication between them.

Detailed instructions for provisioning servers using Vagrant can be found in the provided [Vagrant Configuration File - Vagrantfile](#vagrant-configuration-file---vagrantfile).

### [Automating Deployment with Bash Script](automating-deployment-with-bash-script)

The `deploy.sh` script automates the deployment of the LAMP stack. It performs the following tasks:

1. Adds important repositories to the APT package manager.
2. Updates and upgrades installed packages.
3. Installs Apache, MySQL, PHP, and other necessary packages.
4. Configures Apache for a Laravel application.
5. Installs Composer and sets permissions.
6. Clones the Laravel application from GitHub and configures it.
7. Sets up the MySQL database and updates the `.env` file.
8. Caches configuration values and runs database migrations.

The script also adds firewall rules to allow necessary ports.

The `deploy.sh` script is thoroughly documented in the

- [deploy.sh](#bash-script---deploysh)

### [Executing the Ansible Playbook](executing-the-ansible-playbook)

The Ansible playbook, `playbook.yml`, automates the execution of the `deploy.sh` script on the "Slave" server and sets up a cron job to check server uptime.

1. **Copying Deployment Script**: The playbook copies the `deploy.sh` script to the "Slave" server.

2. **Executing Deployment Script**: It then executes the script and logs the output.

3. **Permissions and Cron Job**: The playbook ensures correct permissions for directories and creates a cron job to check the server's uptime.

The Ansible playbook and its configurations are documented in the

- [Ansible Playbook - playbook.yml](#ansible-playbook---playbookyml)

- [Ansible Configuration - ansible.cfg](#ansible-configuration---ansiblecfg)

- [Ansible Inventory - inventory.ini](#ansible-inventory---inventoryini)

## [Code Files](code-files)

In this section, we provide the content of the code files used in the project.

### [Vagrant Configuration File - Vagrantfile](vagrant-configuration-file---vagrantfile)

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

# Deployment of two Ubuntu-based servers, named Master and Slave using vagrant.

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-20.04"
  config.vm.define "Master" do |master|
    master.vm.hostname = "Master"
    master.vm.network "private_network", ip: "192.168.56.20"
    master.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = "1"
    end
    master.vm.provision "shell", inline: <<-SHELL
    ssh_config_file="/etc/ssh/sshd_config"
    sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' "$ssh_config_file"
    sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' "$ssh_config_file"
    sudo systemctl restart ssh || sudo service ssh restart
    sudo apt-get install -y avahi-daemon
    SHELL
    master.vm.provision "shell", path: "./ansible-playbook/deploy.sh"
  end
  config.vm.define "Slave" do |slave|
    slave.vm.hostname = "Slave"
    slave.vm.network "private_network", ip: "192.168.56.21"
    slave.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = "2"
    end
    slave.vm.provision "shell", inline: <<-SHELL
      ssh_config_file="/etc/ssh/sshd_config"
      sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' "$ssh_config_file"
      sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' "$ssh_config_file"
      sudo systemctl restart ssh || sudo service ssh restart
      sudo apt-get install -y avahi-daemon
    SHELL
  end
end
```

### [Bash Script - deploy.sh](bash-script---deploysh)

```bash
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
```

### [Ansible Playbook - playbook.yml](ansible-playbook---playbookyml)

```yaml
# The playbook.yml file automates the execution of the deploy.sh script on the Slave server.

- name: Execute deployment script
  hosts: Slave
  become: yes

  tasks:
    - name: Copy deployment script
      copy:
        src: ./deploy.sh
        dest: /tmp/deploy.sh
        mode: 0755

    - name: Execute deployment script
      shell: /tmp/deploy.sh >> /vagrant/ansible.log 2>&1

    - name: Ensure correct permissions for /vagrant directory
      file:
        path: /vagrant
        state: directory
        mode: 0755
      when: not ansible_check_mode

    - name: Ensure correct permissions for uptime.log file
      file:
        path: /vagrant/uptime.log
        state: touch
        mode: 0644
      when: not ansible_check_mode

    - name: Create a cron job to check the server's uptime every 12 am
      cron:
        name: "Check server uptime"
        minute: "0"
        hour: "0"
        job: "uptime >> /vagrant/uptime.log"
        user: vagrant
```

The `playbook.yml` file automates the deployment and can be found in the provided file.

### [Ansible Configuration - ansible.cfg](ansible-configuration---ansiblecfg)

```ini
[defaults]
inventory = inventory.ini
private_key_file = ~/.ssh/ansible
host_key_checking = False
```

The `ansible.cfg` file contains the configuration settings for Ansible.

### [Ansible Inventory - inventory.ini](ansible-inventory---inventoryini)

```ini
Master ansible_host=192.168.56.20 ansible_user=vagrant ansible_connection=ssh
Slave ansible_host=192.168.56.21 ansible_user=vagrant ansible_connection=ssh
```

The `inventory.ini` file defines the servers and their connection details for Ansible.

That concludes the code files used in the project. In the next section, we'll discuss log files and their purposes.

## [Log Files](log-files)

The project generates several log files that provide insights into the deployment and operations:

### [Bash Script Log - deploy.log](bash-script-log---deploylog)

The `deploy.log` file contains detailed logs of the deployment process using the `deploy.sh` script. This log helps in debugging and tracking the execution of the script. The script generates this log to document each step and capture any errors that may occur.

The `deploy.log` file can be found in the project directory.

### [Ansible Playbook Log - ansible.log](ansible-playbook-log---ansiblelog)

The `ansible.log` file captures the output of the Ansible playbook execution. It logs the tasks performed by the playbook, including copying the `deploy.sh`

 script and executing it on the "Slave" server. This log is essential for troubleshooting and verifying the automation process.

The `ansible.log` file can be found in the project directory.

### [Cron Job Log - uptime.log](cron-job-log---uptimelog)

The `uptime.log` file records server uptime data. A cron job is scheduled to run daily at 12 am to check and record the server's uptime. The `uptime.log` file accumulates these records over time and serves as evidence of server availability.

The `uptime.log` file can be found in the project directory.

In the next section, we will provide instructions on how to use the project, including the deployment and maintenance of the LAMP stack.

## [Screenshots](screenshots-evidence)

### [Screenshots of the laravel application deployed with Bash script on the Master](screenshots-master-node)

### [Screenshots of the laravel application deployed with Ansible on the Slave](screenshots-slave-node)

## [Usage](usage)

This section provides instructions on how to use the project to deploy the LAMP stack and maintain the server environment.

To use this project:

1. Clone the project's GitHub repository: [GitHub Repository Link](https://github.com/your-username/your-repo).

2. Configure the `Vagrantfile` to set up the desired server configurations and network settings. Customize the parameters as needed for your environment.

3. Provision the servers using Vagrant. Run the following command in the project directory:

```bash
vagrant up
```

4. The provisioning process will set up the "Master" and "Slave" servers with the LAMP stack. Review the logs in the `deploy.log` file for details on the deployment.

5. Access the PHP application by using the VM's IP address or domain name.

6. Use the provided Ansible playbook, `playbook.yml`, to automate the execution of the `deploy.sh` script on the "Slave" server. Run the following command in the project directory:

```bash
ansible-playbook playbook.yml
```

7. The playbook will execute the deployment script and create a cron job to check server uptime.

8. Monitor the logs in the `ansible.log` and `uptime.log` files for the playbook's execution and uptime records.

## [Important Notes](important-notes)

- Regularly check the log files (`deploy.log`, `ansible.log`, and `uptime.log`) for any errors or issues.

- Ensure that you have the necessary credentials and permissions to deploy and configure servers.

- Customization: Adjust the project configurations, such as network settings and server parameters, to suit your specific requirements.

## [Contributing](contributing)

We welcome contributions to this project. If you would like to contribute, follow these steps:

1. Fork the project's GitHub repository.

2. Create a new branch for your feature or bug fix.

3. Make your changes and commit them to your branch.

4. Submit a pull request to the main repository for review and integration.

## [References](references)

For more information and helpful resources, consider exploring the following references:

- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [Ansible Documentation](https://docs.ansible.com)
- [Laravel PHP Framework](https://laravel.com)
- [GitHub Repository for Laravel](https://github.com/laravel/laravel)
- [GitHub Repository for Vagrant](https://github.com/hashicorp/vagrant)

This concludes the documentation for the Cloud Engineering Second Semester Examination Project. It is my hope that this comprehensive guide assists you in successfully deploying a LAMP stack and managing server automation.

If you have any questions or need further assistance, please don't hesitate to reach out to the project maintainers or contributors.

Thank you for using this project, and best of luck with your cloud engineering endeavors!
