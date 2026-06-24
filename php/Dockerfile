ARG PHP_WORDPRESS_VERSION=php8.2-fpm
FROM wordpress:${PHP_WORDPRESS_VERSION}

# Add the phpredis extension so the Redis Object Cache plugin uses the
# native client (falls back to bundled Predis if absent).
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends $PHPIZE_DEPS; \
    pecl install redis; \
    docker-php-ext-enable redis; \
    apt-get purge -y --auto-remove $PHPIZE_DEPS; \
    rm -rf /var/lib/apt/lists/*
