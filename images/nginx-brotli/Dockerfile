FROM openresty/openresty:1.25.3.2-5-alpine
ENV OPENRESTY_VERSION=1.25.3.2

# Install build dependencies
RUN apk add --no-cache \
    brotli-libs \
    brotli-dev \
    git \
    gcc \
    make \
    musl-dev \
    pcre-dev \
    openssl-dev \
    zlib-dev \
    perl

# Clone and prepare the Brotli module
RUN git clone --recursive https://github.com/google/ngx_brotli.git /tmp/ngx_brotli

# Download the OpenResty source for the same version
RUN wget -O /tmp/openresty-${OPENRESTY_VERSION}.tar.gz https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz && \
    tar -xzvf /tmp/openresty-${OPENRESTY_VERSION}.tar.gz -C /tmp/

# Configure and build OpenResty with Brotli module
WORKDIR /tmp/openresty-${OPENRESTY_VERSION}
RUN ./configure --with-compat --add-dynamic-module=/tmp/ngx_brotli \
    && make

# Copy the compiled Brotli module to the installed OpenResty modules directory
RUN cp ./build/nginx-*/objs/ngx_http_brotli_filter_module.so /usr/local/openresty/nginx/modules/
RUN cp ./build/nginx-*/objs/ngx_http_brotli_static_module.so /usr/local/openresty/nginx/modules/
