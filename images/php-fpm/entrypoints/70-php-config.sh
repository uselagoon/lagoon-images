#!/bin/sh

# In order for our custom PHP ini file to be loaded after the default PHP ini
# configuration, we need to ensure it appears alphabetically after `php.ini`.
# The filename `zz-php-lagoon.ini` was chosen to make this obvious.
#
# The default `php.ini` is seeded from the default production values PHP
# recommends.
#
# @see https://github.com/php/php-src/blob/PHP-8.2/php.ini-production

mv "$PHP_INI_DIR/conf.d/00-lagoon-php.ini.tpl" "$PHP_INI_DIR/conf.d/zz-php-lagoon.ini"
ep "$PHP_INI_DIR/conf.d/zz-php-lagoon.ini"
ep /usr/local/etc/php-fpm.conf
ep /usr/local/etc/php-fpm.d/*
