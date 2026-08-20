# Docker Setup & Troubleshooting Guide

This document explains the Dockerization of the Laravel Admin Panel, the infrastructure configuration, the problems we faced during setup, and how to start the application from scratch.

---

## 1. Initial Setup Commands

When setting up the project for the very first time on a new machine, you need to build the images, generate keys, migrate the database, and compile the frontend assets. Run the following commands in order:

```bash
# 1. Build the Docker images (this uses the Dockerfile to install PHP extensions and composer packages)
docker-compose build

# 2. Start the containers in the background
docker-compose up -d

# 3. Generate Laravel application encryption key
docker exec laravel-container php artisan key:generate

# 4. Run database migrations (creates tables in the MySQL container)
docker exec laravel-container php artisan migrate

# 5. Install Laravel Passport encryption keys for API authentication
docker exec laravel-container php artisan passport:install

# 6. Seed the database with initial admin users/data
docker exec laravel-container php artisan db:seed

# 7. Install frontend Node.js dependencies (Run on HOST machine)
npm i

# 8. Compile frontend assets with legacy OpenSSL provider (Run on HOST machine)
NODE_OPTIONS=--openssl-legacy-provider npm run dev
```

---

## 2. Architectural Paradigm Shift: From PHP-FPM to Apache Native

### The Old Approach (PHP-FPM)
Previously, the Docker container was built using `php:7.4-fpm-alpine`. 
In that architecture, the Docker container ONLY executed PHP code on port `9000`. It did not have a web server. This meant the host machine's Apache server had to act as a reverse proxy, explicitly forwarding `.php` requests into the container using `ProxyPassMatch fcgi://127.0.0.1:9000`, while simultaneously trying to serve the static frontend assets itself. This created massive complexities with volume mounts, read-only filesystems, and path resolution.

**The Old Dockerfile (FastCGI):**
```dockerfile
FROM php:7.4-fpm-alpine AS builder
RUN apk add --no-cache git curl unzip oniguruma-dev autoconf build-base
RUN docker-php-ext-install pdo_mysql mbstring opcache
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
COPY composer.json ./
COPY app ./app
COPY database ./database
RUN composer update --prefer-source --no-dev --no-scripts --no-progress --no-interaction --no-audit --optimize-autoloader --classmap-authoritative

FROM php:7.4-fpm-alpine AS runtime
COPY --from=builder /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=builder /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d
COPY --from=builder --chown=www-data:www-data /var/www/html/vendor ${INSTALL_DIR}/vendor
COPY --chown=www-data:www-data . ${INSTALL_DIR}/
RUN mkdir -p ${INSTALL_DIR}/storage ${INSTALL_DIR}/bootstrap/cache /var/log/php-fpm && \
    chmod -R 775 ${INSTALL_DIR}/storage ${INSTALL_DIR}/bootstrap/cache /var/log/php-fpm
USER www-data
```

**The Old Apache Config (Host Reverse Proxy):**
```apache
    # ==========================================================
    # LARAVEL APP 2 — /laravel-app-2 subpath
    # ==========================================================
    Alias /laravel-app-2 /var/abacus-projects/laravel-adminpanel/public

    # 1. Proxy all PHP requests in this alias to the container.
    # This must be placed OUTSIDE the <Directory> block.
    # It explicitly maps the URL to the container's path (/var/www/html/public/)
    # and overrides the host-level PHP handlers.
    ProxyPassMatch "^/laravel-app-2/(.*\.php(/.*)?)$" "fcgi://127.0.0.1:9000/var/www/html/public/$1"

    <Directory /var/abacus-projects/laravel-adminpanel/public>
        AllowOverride All
        Require all granted

        RewriteEngine On
        RewriteBase /laravel-app-2
        
        # 2. Standard Laravel rewrite for non-existent routes (like /login)
        # We just internally rewrite to index.php locally.
        # After the internal redirect, the ProxyPassMatch rule above will catch it 
        # and forward the request to the Docker container!
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [L]
    </Directory>

    <DirectoryMatch "^/var/abacus-projects/laravel-adminpanel/(storage|bootstrap/cache|\.env|\.git)">
        Require all denied
    </DirectoryMatch>
```

### The New Approach (All-in-One Apache)
To simplify the architecture and make the container fully self-contained for Kubernetes (K8s), we switched the base image to `php:7.4-apache` (Debian).
- **Static Files:** The Apache web server is built directly into the container and serves files perfectly from the `DocumentRoot`.
- **Backend Execution:** PHP is built into Apache as a native module (`mod_php`). There is no proxying, no port 9000, and no FastCGI. Apache executes the PHP code internally on the spot.
- **Result:** A completely isolated container that exposes standard port `80` and requires zero complex proxy configuration on the host.

**The New Dockerfile (Apache Native):**

> [Click here to see the new Dockerfile](./Dockerfile)

**The New Apache Config (Self-Contained Container vhost):**

> [Click here to see the new apache config file](./docker/app/vhost.conf)

---

## 3. Dockerfile Breakdown

Our `Dockerfile` uses a **Multi-Stage Build** to compile all dependencies (including frontend assets) securely.

### Stage 1: Builder
```dockerfile
FROM php:7.4-apache AS builder
```
- **What it means**: We start with Debian-based PHP Apache.

```dockerfile
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs
```
- **What it means**: Instead of hacking symlinks or copying Node binaries from other images, we use the official NodeSource installer to cleanly install Node 18 directly onto Debian.
- **Why it's mandatory**: Node 18 includes modern NPM (v9), which is smart enough to handle GitHub SSH shortcuts (`github:HubSpot/pace`) over HTTPS, bypassing legacy NPM bugs.

```dockerfile
COPY composer.json package.json ./
RUN npm install
RUN composer update ...
RUN npm run production
```
- **What it means**: We install both PHP and Frontend dependencies completely inside the Docker image.
- **Why it matters**: In the past, frontend assets were compiled on the host machine. Now, the Docker image is 100% reproducible and builds its own CSS/JS.

### Stage 2: Runtime (Production Image)
```dockerfile
FROM php:7.4-apache AS runtime
```
- **What it means**: Starts a fresh, clean Apache PHP image.

```dockerfile
COPY docker/app/vhost.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite headers deflate
```
- **What it means**: Copies our custom virtual host configuration and enables crucial Apache modules (URL rewriting, security headers, compression).

```dockerfile
COPY --from=builder --chown=www-data:www-data /var/www/html ${INSTALL_DIR}/
```
- **What it means**: Copies the fully built application (including `vendor` and compiled `public` assets) from the builder stage into the final image.

---

## 4. Problems Faced & Solutions

### Problem 1: NPM Git Clone & SSH Key Errors
**The Issue:** When moving `npm install` into the Dockerfile, NPM failed because the `HubSpot/pace` dependency was configured via a Git shortcut (`github:HubSpot/pace`). Older versions of NPM attempted to download this using SSH, which failed because the Docker container does not have the host's private SSH keys.
**The Fix:** We upgraded the Node installation inside the container to **Node 18 (NPM v9)** via NodeSource. Modern NPM intelligently resolves public GitHub shortcuts over standard HTTPS, bypassing the SSH requirement entirely without needing to modify the `package.json`.

### Problem 2: Subfolder Routing (404 Not Found)
**The Issue:** When trying to host the application at a subpath (`/laravel-app-2`), Laravel returned 404 errors for internal routes like `/login` because it didn't know how to strip the prefix. Furthermore, `AllowOverride All` caused Laravel's internal `.htaccess` to break the Apache alias routing.
**The Fix:** We decided to adhere to Docker best practices: **Containers should not know where they are hosted.** We removed all hardcoded path configurations from the container's `vhost.conf`. The container now serves the application purely at the root directory (`/`). If the app needs to be accessed at `/laravel-app-2` externally, the Kubernetes Ingress or Host Reverse Proxy handles the URL mapping, keeping the container simple and standard.

### Problem 3: Namespace Mismatch (Class Not Found)
**The Issue:** `Target class [App\Http\Requests\RegisterRequest] does not exist.`
**The Cause:** Laravel uses PSR-4 autoloading. The `RegisterRequest.php` file was physically located in `app/Http/Requests/Frontend/Auth/`, but its internal code said `namespace App\Http\Requests;`.
**The Fix:** We moved the physical file to `app/Http/Requests/RegisterRequest.php`.

### Problem 4: Database DNS Resolution
**The Issue:** `php_network_getaddresses: getaddrinfo failed: Try again`
**The Cause:** The host machine's DNS doesn't know what `mysql-container` is (that's an internal Docker hostname).
**The Fix:** Once the code was executing inside the container (instead of the host), it resolved the database perfectly via the Docker bridge network using `DB_HOST=mysql`.
