# ============================================================================
# Stage 1: Builder - Compile dependencies only
# ============================================================================
FROM php:7.4-apache AS builder

ENV INSTALL_DIR=/var/www/html \
    COMPOSER_HOME=/var/www/.composer \
    COMPOSER_MEMORY_LIMIT=-1 \
    npm_config_cache=/tmp/.npm \
    BABEL_DISABLE_CACHE=1

WORKDIR ${INSTALL_DIR}

# Install only Composer build requirements
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    unzip \
    libonig-dev \
    && rm -rf /var/lib/apt/lists/*

# Install minimal PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring opcache

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# Install Modern Node.js (which includes modern NPM) cleanly via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Copy composer and npm files
COPY composer.json package.json ./
COPY app ./app
COPY database ./database

# Install Node dependencies
RUN npm install

# Install PHP dependencies
RUN composer update --prefer-source --no-dev --no-scripts --no-progress --no-interaction --no-audit \
    --optimize-autoloader --classmap-authoritative

# Copy all application files and build assets
COPY . .
RUN npm run production && \
    rm -rf node_modules

# ============================================================================
# Stage 2: Runtime - Minimal Apache production image
# ============================================================================
FROM php:7.4-apache AS runtime

ENV INSTALL_DIR=/var/www/html \
    PHP_MEMORY_LIMIT=2048M \
    PHP_MAX_EXECUTION_TIME=60 \
    APP_ENV=production

WORKDIR ${INSTALL_DIR}

# Install only runtime libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    libonig5 \
    && rm -rf /var/lib/apt/lists/*

# Copy precompiled PHP extensions from builder (no recompilation needed)
COPY --from=builder /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=builder /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d

# Copy PHP configuration
COPY docker/app/php.ini /usr/local/etc/php/php.ini

# Configure Apache
COPY docker/app/vhost.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite headers deflate

# Copy the entire built application (PHP dependencies + compiled assets) from the builder stage
COPY --from=builder --chown=www-data:www-data /var/www/html ${INSTALL_DIR}/

# Create required directories and fix apache permissions
RUN mkdir -p ${INSTALL_DIR}/storage ${INSTALL_DIR}/bootstrap/cache /var/log/apache2 /var/run/apache2 && \
    chown -R www-data:www-data ${INSTALL_DIR}/storage ${INSTALL_DIR}/bootstrap/cache /var/log/apache2 /var/run/apache2 && \
    chmod -R 775 ${INSTALL_DIR}/storage ${INSTALL_DIR}/bootstrap/cache /var/log/apache2 /var/run/apache2 && \
    chmod -R 755 ${INSTALL_DIR}/public

EXPOSE 80

CMD ["apache2-foreground"]