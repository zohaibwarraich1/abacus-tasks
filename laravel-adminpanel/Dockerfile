# ============================================================================
# Stage 1: Builder - Compile dependencies only
# ============================================================================
FROM php:7.4-fpm-alpine AS builder

ENV INSTALL_DIR=/var/www/html \
    COMPOSER_HOME=/var/www/.composer \
    COMPOSER_MEMORY_LIMIT=-1 \
    npm_config_cache=/tmp/.npm \
    BABEL_DISABLE_CACHE=1

WORKDIR ${INSTALL_DIR}

# Install only Composer build requirements
RUN apk add --no-cache \
    git \
    curl \
    unzip \
    oniguruma-dev \
    autoconf \
    build-base

# Install minimal PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring opcache

# Install Composer & Node.js
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
RUN apk add --no-cache nodejs npm

# Copy composer files and application code required for classmap & helper autoloading
COPY composer.json ./
COPY app ./app
COPY database ./database

# Install PHP dependencies
RUN composer update --prefer-source --no-dev --no-scripts --no-progress --no-interaction --no-audit \
    --optimize-autoloader --classmap-authoritative

# ============================================================================
# Stage 2: Runtime - Minimal Alpine production image
# ============================================================================
FROM php:7.4-fpm-alpine AS runtime

ENV INSTALL_DIR=/var/www/html \
    PHP_MEMORY_LIMIT=2048M \
    PHP_MAX_EXECUTION_TIME=60 \
    APP_ENV=production

WORKDIR ${INSTALL_DIR}

# Install only runtime libraries
RUN apk add --no-cache \
    ca-certificates \
    curl \
    oniguruma

# Copy precompiled PHP extensions from builder (no recompilation needed)
COPY --from=builder /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=builder /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d

# Copy PHP configuration
COPY docker/app/php.ini /usr/local/etc/php/php.ini
COPY docker/app/www.conf /usr/local/etc/php-fpm.d/www.conf

# Copy compiled dependencies and assets from builder stage
COPY --from=builder --chown=www-data:www-data /var/www/html/vendor ${INSTALL_DIR}/vendor

# Copy application files
COPY --chown=www-data:www-data . ${INSTALL_DIR}/

# Create required directories
RUN mkdir -p ${INSTALL_DIR}/storage ${INSTALL_DIR}/bootstrap/cache /var/log/php-fpm && \
    chown -R www-data:www-data ${INSTALL_DIR}/storage ${INSTALL_DIR}/bootstrap/cache /var/log/php-fpm && \
    chmod -R 775 ${INSTALL_DIR}/storage ${INSTALL_DIR}/bootstrap/cache /var/log/php-fpm && \
    chmod -R 755 ${INSTALL_DIR}/public

USER www-data

EXPOSE 9000

CMD ["php-fpm", "-F"]