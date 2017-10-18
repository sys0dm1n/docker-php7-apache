FROM php:7.0-apache

LABEL maintainer="sys0dm1n" \
      description="Wordpress Container"

ENV APACHE_RUN_USER='www-data' \
    APACHE_RUN_GROUP='www-data' \
    APACHE_LOG_DIR='/var/log/apache2' \
    APACHE_PID_FILE='/var/run/apache2.pid' \
    APACHE_RUN_DIR='/var/run/apache2' \
    APACHE_LOCK_DIR='/var/lock/apache2' \
    APACHE_SERVERADMIN='admin@localhost' \
    APACHE_SERVERNAME='localhost' \
    APACHE_SERVERALIAS='docker.localhost' \
    APACHE_DOCUMENT_ROOT='/srv' \
    APACHE_LOG_DIR='/var/log/apache2'

# Apache enable mod_rewrite and headers
RUN a2enmod rewrite headers ssl

# Install dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq\
        libpng12-dev \
        libjpeg-dev \
        libmcrypt-dev \
        zlib1g-dev \
        locales \
        build-essential \
        ca-certificates \
        libcurl4-openssl-dev \
        libffi-dev \
        libgdbm-dev \
        libpq-dev \
        libreadline6-dev \
        libssl-dev \
        libtool \
        libxml2-dev \
        libxslt-dev \
        libyaml-dev \
        software-properties-common \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-install -j$(nproc) iconv mcrypt \
    && docker-php-ext-configure gd --with-png-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd mysqli mbstring zip


#Install and enable xdebug
RUN pecl install -o -f xdebug \
    && rm -rf /tmp/pear \
    && docker-php-ext-enable xdebug

# Install intl
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y libicu-dev \
    && docker-php-ext-install -j$(nproc) intl

# Configure timezone and locale
RUN echo "Europe/Paris" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata

# Set the locale
RUN locale-gen
ENV LANGUAGE=en_US.UTF-8
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV locale-gen=en_US.UTF-8

# Allow the use of .htaccess
RUN sed -ri -e 's!AllowOverride None!AllowOverride All!g' /etc/apache2/apache2.conf

#COPY website.conf /etc/apache2/sites-available/
#COPY php.ini /usr/local/etc/php/conf.d/
#RUN ln -s /etc/apache2/sites-available/website.conf /etc/apache2/sites-enabled/
#RUN rm /etc/apache2/sites-enabled/000-default.conf
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Changing DocumentRoot
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Create selfsigned certificate
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/ssl-cert-snakeoil.key -out /etc/ssl/certs/ssl-cert-snakeoil.pem -subj "/C=AT/ST=Paris/L=Paris/O=Security/OU=Development/CN=example.com"

# Enable https virtualhost
RUN a2ensite default-ssl

# Clean up APT and temporary files when done
RUN apt-get clean -qq && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR ${APACHE_DOCUMENT_ROOT}
VOLUME ["${APACHE_DOCUMENT_ROOT}"]
EXPOSE 80 443
