#!/bin/bash      

# sudo apt update

# Install PHP

 sudo apt update
 sudo add-apt-repository ppa:ondrej/php -y

# Install php8.2
 sudo apt install php8.2 -y

# install some of php dependencies needed 
 sudo apt install php8.2-curl php8.2-dom php8.2-mbstring php8.2-xml php8.2-mysql zip unzip -y


#Install Apache web server

 sudo apt install apache2 -y
 sudo apt update
 sudo systemctl restart apache2

#Install Mysql-server

 sudo apt install mysql-server -y

# install composer
{
 cd ~

 if [ -d "$HOME/composer" ]; then

         echo "-Composer Directory Exists-"
 else
   mkdir composer
   cd composer

   echo "-Directory created successfully-"

   curl -sS https://getcomposer.org/installer | php
# move content of defaultt composer
   sudo mv composer.phar /usr/local/bin/composer

   echo "-Composer Added Successfully-"
 fi
}

# Setup Laravel app
{
 cd /var/www/

 sudo rm -r ./*
 sudo git clone https://github.com/laravel/laravel
 sudo chown -R $USER:$USER laravel
 cd laravel

#Install dependencies using composer
 composer install
# copy the content of the default env file to .env
 sudo cp .env.example .env

 php artisan key:generate
 sudo chown -R www-data bootstrap/cache
 sudo chown -R www-data storage

}

{
   cd /var/www/laravel

   echo "-Setup mysql database and user-"

# Configure MySQL database
sudo mysql -uroot -e "CREATE DATABASE laravel_db;"
sudo mysql -uroot -e "CREATE USER 'laravel_user'@'localhost' IDENTIFIED BY '000000';"
sudo mysql -uroot -e "GRANT ALL PRIVILEGES ON laravel_db.* TO 'laravel_user'@'localhost';"
sudo mysql -uroot -e "FLUSH PRIVILEGES;"




   sed -i 's/DB_CONNECTION=sqlite/DB_CONNECTION=mysql/' .env
   sed -i 's/# DB_HOST=127.0.0.1/DB_HOSTS=127.0.0.1/' .env
   sed -i 's/# DB_PORT=3306/DB_PORT=3306/' .env
   sed -i 's/# DB_DATABASE=laravel/DB_DATABASE=laravel_db/' .env
   sed -i 's/# DB_USERNAME=root/DB_USERNAME=laravel_user/' .env
   sed -i 's/# DB_PASSWORD=/DB_PASSWORD=000000/' .env


   php artisan cache:clear
   php artisan config:clear

   php artisan migrate

}

#Setup Virtual host for app
    cd ~
    sudo tee /etc/apache2/sites-available/laravel.conf <<EOF
    <VirtualHost *:80 *:3000>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/laravel/public/

    <Directory /var/www/laravel/public/>
            AllowOverride All
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
  </VirtualHost>
EOF

  cd ~
   sudo a2dissite 000-default.conf
   sudo a2enmod rewrite
   sudo a2ensite laravel.conf
   sudo systemctl restart apache2
