#!/bin/sh

# Suppress notices on production by default to avoid excessive logs.
#
# @see https://github.com/php/php-src/blob/PHP-8.2/php.ini-production#L107-L110

if [[ -z "${PHP_ERROR_REPORTING}" ]]; then
    if [[ "${LAGOON_ENVIRONMENT_TYPE}" == "production" ]]; then
        export PHP_ERROR_REPORTING="E_ALL & ~E_DEPRECATED & ~E_STRICT & ~E_NOTICE"
    fi
fi
