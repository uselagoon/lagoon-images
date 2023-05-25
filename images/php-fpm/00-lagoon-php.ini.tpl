[PHP]
short_open_tag = On
realpath_cache_ttl = 3600
expose_php = Off
max_execution_time = ${PHP_MAX_EXECUTION_TIME:-900}
max_input_time = ${PHP_MAX_INPUT_TIME:-900}
max_input_vars = ${PHP_MAX_INPUT_VARS:-2000}
post_max_size = ${PHP_POST_MAX_SIZE:-2048M}
cgi.fix_pathinfo = 0
upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE:-2048M}
max_file_uploads = ${PHP_MAX_FILE_UPLOADS:-20}
memory_limit = ${PHP_MEMORY_LIMIT:-400M}
display_errors = ${PHP_DISPLAY_ERRORS:-Off}
display_startup_errors = ${PHP_DISPLAY_STARTUP_ERRORS:-Off}
auto_prepend_file = ${PHP_AUTO_PREPEND_FILE:-none}
auto_append_file = ${PHP_AUTO_APPEND_FILE:-none}
error_reporting = ${PHP_ERROR_REPORTING:-E_ALL & ~E_DEPRECATED & ~E_STRICT}

[Date]
date.timezone = UTC

[Pcre]
pcre.jit = 0

[mail function]
sendmail_path = /usr/sbin/sendmail -t -i
mail.add_x_header = On

[Session]
session.cookie_lifetime = 2000000
session.gc_maxlifetime = 200000

[opcache]
opcache.memory_consumption = 256
opcache.enable_file_override = 1
opcache.huge_code_pages = 1

[APC]
apc.shm_size = ${PHP_APC_SHM_SIZE:-32m}
apc.enabled = ${PHP_APC_ENABLED:-1}

[xdebug]
xdebug.mode = debug
