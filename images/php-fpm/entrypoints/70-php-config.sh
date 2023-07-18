#!/bin/sh

# In order for our custom PHP ini file to be loaded after the default PHP ini
# configuration, we include this in the `conf.d` directory, this is read after
# the default `php.ini` file.
#
# The file name is `00-lagoon-php.ini`, so if you want to override any further
# values, you can craft any other `.ini` file in the `conf.d` directory to do
# this. e.g.:
#
# $PHP_INI_DIR/
#  ├─ php.ini
#  ├─ conf.d/
#  │  ├─ 00-lagoon-php.ini
#  │  ├─ 01-your-further-overrides.ini
#
# The default `php.ini` is seeded from the default production values PHP
# recommends.
#
# @see https://github.com/php/php-src/blob/PHP-8.2/php.ini-production

ep -d "$PHP_INI_DIR/conf.d/00-lagoon-php.ini.tpl" > "$PHP_INI_DIR/conf.d/00-lagoon-php.ini"
ep /usr/local/etc/php-fpm.conf
ep /usr/local/etc/php-fpm.d/*
echo "configured lagoon-php.ini"
