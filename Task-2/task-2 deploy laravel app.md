# Task: Deploy laravel application on EC2s

## Installing and configuring apache server:

1. First of all install apache using following commands:
    ```yaml
    sudo apt update
    sudo apt install apache2 -y
    sudo systemctl status apache2
    ```

2. Install apache modules to enable reverse proxy in apache server otherwise apache's reverse proxy configurations will be failed. There are many modules you can install accoding to your apache configs requirements.
    ```yaml
    sudo a2enmod proxy
    sudo a2enmod proxy_http
    sudo systemctl restart apache2
    sudo a2enmod proxy_wstunnel             (optional: if web sockets are being used in application)
    ```

3. Create the ***Virtual Host config*** file in the directory: **/etc/apache2/sites-available/myapp.conf**

4. **/etc/apache2/sites-available/** stores the config files that are available for apache to be served. It contains all the configs of different domains like if we have 2 applications being served by apache then we will create 2 configs for it and store it in site-available directory.

5. **/etc/apache2/sites-enabled/** stores the actual configs that are enabled for apache to be served. It contains the soft links of the files that are stored in site-available directory. Because apache only watches **/etc/apache2/sites-enabled/** directory for serving not **/etc/apache2/sites-available/** itself.

6. We can enable and disable config files that we want to be served/not served by apache server using the following commands:
    ```yaml
    sudo a2ensite myapp.conf          (to enable config file. on enabling it will create softlink in sites-enabled folder and enable the config file for apache to be served.)
    sudo a2dissite myapp.conf         (to disable config file. on disabling it will remove softlink from sites-enabled folder and disable the config file for apache to be served.)
    sudo apache2ctl -S                (to check which config files are activated)
    ```

7. **/etc/apache2/mods-available/** contains all the modules that we can enable and disable accordingly. 
We can enable and disable modules using the following commands:
    ```yaml
    sudo a2enmod proxy                (to enable module. on enabling it will create softlink in mods-enabled folder and enable the module for apache to be served.)
    sudo a2dismod proxy               (to disable module. on disabling module its soft link will be removed from mods-enabled folder.)
    ```

8. **/etc/apache2/mods-enabled/** stores the soft links of the actual module files that are stored in **/etc/apache2/mods-available/** directory. Because apache only watches **/etc/apache2/mods-enabled/** directory for enabling modules not **/etc/apache2/mods-available/** itself.

9. **/etc/apache2/apache2.conf** -- Main/Global config file. It includes all the settings that are applied to whole apache server, its not specific to any domain/site:
    - Timeout settings
    - Log format defaults
    - Kaunse modules load honge (indirectly, via includes)
    - Kaunse directories include honi chahiye (yehi wo jagah hai jahan ye sites-enabled ko "include" karta hai — neeche explain karunga)

## Deploying Laravel Application: 

1. Install ***php8.3*** on ***Ubuntu 26 LTS (resolute release)*** for compatibility using following commands:
    ```yaml
   sudo apt install -y lsb-release ca-certificates curl gnupg2
   
   sudo curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
   echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
   sudo apt update
   
   # Installing extensions + php8.3 at system-level
   sudo apt install php8.3 php8.3-fpm php8.3-cli php8.3-mbstring php8.3-xml php8.3-curl php8.3-mysql php8.3-zip php8.3-bcmath php8.3-sqlite3 unzip -y 

   # Verify version
   php8.3 -v
    ```

2. Install composer
    ```yaml
    sudo apt install composer -y
    ```

3. Move the application source code to /var/www/.
Note: /var/www/ is the default directory where Apache serves files from but it is not necessary to move the application code to /var/www/. You can move it to any other directory as well but you need to configure the Apache configuration file accordingly. For now, we will move it to /var/www/ as it is the default directory where Apache serves files from.
    ```yaml
    sudo mv /path/to/your/laravel-app /var/www/laravel
    ```

4. Install packages using composer
    ```yaml
    cd /var/www/laravel
    composer install --optimize-autoloader --no-dev (this installs all the packages listed in composer.json file)
    ```
    
5. Copy .env file from .env.example to provide environment variables for application
    ```yaml
    cp .env.example .env
    vim .env        # (set envs)
    php artisan key:generate    # (this generates a unique key in APP_KEY variable in .env file for the application and it is required for the application to run. it is same as node's APP_SECRET or jwt secret key)

    # Clear and cache the application configuration.
    php artisan config:clear
    php artisan config:cache
    ```

6. Now build and compile nodejs. ***If modern laravel uses vite to compile and bundle front-end assets (css, js, images, etc.) for production.***
    ```yaml
    sudo apt install nodejs npm -y
    npm install
    npm run build
    ```

7. Configure permissions so Apache can write to storage and bootstrap/cache directories
    ```yaml
    sudo chown -R www-data:www-data /var/www/laravel
    sudo chmod -R 775 storage bootstrap/cache
    ```

8. Framework optimization (optional: for production)
    ```yaml
    cd /var/www/laravel
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    ```
    
9. Run migration to create database tables. 
    ```yaml
    cd /var/www/laravel
    sudo php8.3 artisan migrate
    ```

10. Application is running because there is no need to run the application like npm start or PM2 in node. We just need to start php-fpm service to serve PHP scripts. ***As we have already installed php-fpm extension in step 1***. **php-fpm** is a php process manager that is used to serve PHP scripts. It is a fast and efficient way to serve PHP scripts.

11. While configuring Apache configuration for Laravel application we need to configure **SetHandler** for **.php** files to serve them through **php-fpm**. Otherwise Apache will not be able to serve PHP scripts.
There is no proxy pass needed in laravel's apache configuration. Because we are serving the application through php-fpm directly. Which is handling all the PHP processing. And Apache is just acting as a reverse proxy. 

11. Also, we forward the client request to php-fpm's unix socket using fast-cgi protocol because unix socket is more faster and efficient way to serve PHP scripts and php-fpm doesn't use IP and port for communication by default (it uses IP and port only when we configure it to use them).

12. Check out the [*Apache Config file for laravel application*](laravel-apache.conf) for detailed configuration.

13. **Enable Modules for apache configuration (if not enabled)**
    ```yaml
    sudo a2enmod proxy proxy_http proxy_fcgi setenvif rewrite headers deflate
    sudo a2enconf php8.3-fpm
    ```
    **Check config**
    ```yaml
    sudo apache2ctl configtest
    ```
    **Restart Apache**
    ```yaml
    sudo systemctl restart apache2
    ```