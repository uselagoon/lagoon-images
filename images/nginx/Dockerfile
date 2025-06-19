ARG IMAGE_REPO
FROM ${IMAGE_REPO:-lagoon}/commons AS commons

FROM openresty/openresty:1.25.3.2-5-alpine AS brotli-module
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
RUN git clone --recursive https://github.com/google/ngx_brotli.git /tmp/ngx_brotli && \
    cd /tmp/ngx_brotli && git checkout a71f9312c2deb28875acc7bacfdd5695a111aa53

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

FROM openresty/openresty:1.25.3.2-5-alpine

ARG LAGOON_VERSION
ENV LAGOON_VERSION=$LAGOON_VERSION
LABEL org.opencontainers.image.authors="The Lagoon Authors"
LABEL org.opencontainers.image.source="https://github.com/uselagoon/lagoon-images/blob/main/images/nginx/Dockerfile"
LABEL org.opencontainers.image.url="https://github.com/uselagoon/lagoon-images"
LABEL org.opencontainers.image.version="${LAGOON_VERSION}"
LABEL org.opencontainers.image.description="OpenResty (Nginx) image optimised for running in Lagoon in production and locally"
LABEL org.opencontainers.image.title="uselagoon/nginx"
LABEL org.opencontainers.image.base.name="docker.io/openresty/openresty:1.25-alpine"

ENV LAGOON=nginx

# Copy commons files
COPY --from=commons /lagoon /lagoon
COPY --from=commons /bin/fix-permissions /bin/ep /bin/docker-sleep /bin/wait-for /bin/
COPY --from=commons /sbin/tini /sbin/
COPY --from=commons /home /home

RUN fix-permissions /etc/passwd \
    && mkdir -p /home

ENV TMPDIR=/tmp \
    TMP=/tmp \
    HOME=/home \
    # When Bash is invoked via `sh` it behaves like the old Bourne Shell and sources a file that is given in `ENV`
    ENV=/home/.bashrc \
    # When Bash is invoked as non-interactive (like `bash -c command`) it sources a file that is given in `BASH_ENV`
    BASH_ENV=/home/.bashrc

RUN apk update \
    && apk add --no-cache \
        openssl \
        rsync \
        tar \
    && rm -rf /var/cache/apk/*

RUN rm -Rf /etc/nginx && ln -s /usr/local/openresty/nginx/conf /etc/nginx

# Copy Brotli module
COPY --from=brotli-module "/usr/local/openresty/nginx/modules/ngx_http_brotli_filter_module.so" "/usr/lib/nginx/modules/ngx_http_brotli_filter_module.so"
COPY --from=brotli-module "/usr/local/openresty/nginx/modules/ngx_http_brotli_static_module.so" "/usr/lib/nginx/modules/ngx_http_brotli_static_module.so"

COPY nginx.conf /etc/nginx/nginx.conf
COPY fastcgi.conf /etc/nginx/fastcgi.conf
COPY fastcgi.conf /etc/nginx/fastcgi_params
COPY helpers/ /etc/nginx/helpers/
COPY static-files.conf /etc/nginx/conf.d/app.conf
COPY basic_auth.conf /etc/nginx/conf.d/basic_auth.conf
COPY redirects-map.conf /etc/nginx/redirects-map.conf
COPY healthcheck/healthz.locations healthcheck/healthz.locations.php.disable /etc/nginx/conf.d/

RUN mkdir -p /app \
    && mkdir -p /var/run/openresty/nginx-client-body \
    && rm -f /etc/nginx/conf.d/default.conf \
    && fix-permissions /usr/local/openresty/nginx \
    && fix-permissions /var/run/

COPY docker-entrypoint /lagoon/entrypoints/70-nginx-entrypoint
COPY matomo/80-nginx-matomo-config /lagoon/entrypoints/

WORKDIR /app

EXPOSE 8080

# tells the local development environment on which port we are running
ENV LAGOON_LOCALDEV_HTTP_PORT=8080

ENTRYPOINT ["/sbin/tini", "--", "/lagoon/entrypoints.sh"]
CMD ["nginx", "-g", "daemon off;"]
