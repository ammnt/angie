ARG BASE_VERSION=3.21.2
ARG BASE_HASH=56fa17d2a7e7f168a043a2712e63aed1f8543aeafdcee47c58dcffe38ed51099
FROM docker.io/library/alpine:${BASE_VERSION}@sha256:${BASE_HASH} AS builder
ARG OPENSSL_VERSION=openssl-3.4.1
ARG APP_VERSION=Angie-1.8.2
ARG NJS_VERSION=0.8.9

RUN NB_CORES="${BUILD_CORES-$(getconf _NPROCESSORS_CONF)}" \
&& set -ex && addgroup -S angie && adduser -S angie -s /sbin/nologin -G angie --uid 101 --no-create-home \
&& apk -U upgrade && apk add --no-cache \
    openssl \
    pcre \
    libgcc \
    libstdc++ \
    g++ \
    make \
    build-base \
    linux-headers \
    ca-certificates \
    automake \
    autoconf \
    git \
    talloc \
    talloc-dev \
    libtool \
    pcre-dev \
    binutils \
    gnupg \
    cmake \
    go \
    libxslt \
    libxslt-dev \
    tini \
    musl-dev \
    ncurses-libs \
    gd-dev \
    brotli-libs \
    ca-certificates \
&& update-ca-certificates && cd /tmp \
&& git clone --depth 1 --recursive --single-branch -b "${APP_VERSION}" https://github.com/webserver-llc/angie && rm -rf /tmp/angie/html/* \
&& sed -i -e 's@"nginx/"@" "@g' /tmp/angie/src/core/nginx.h \
&& sed -i -e 's@"Angie/"@" "@g' /tmp/angie/src/core/angie.h \
&& sed -i -e 's@"Angie version: "@" "@g' /tmp/angie/src/core/nginx.c \
&& sed -i -e 's@"nginx version: "@" "@g' /tmp/angie/src/core/nginx.c \
&& sed -i -e 's@r->headers_out.server == NULL@0@g' /tmp/angie/src/http/ngx_http_header_filter_module.c \
&& sed -i -e 's@r->headers_out.server == NULL@0@g' /tmp/angie/src/http/v2/ngx_http_v2_filter_module.c \
&& sed -i -e 's@r->headers_out.server == NULL@0@g' /tmp/angie/src/http/v3/ngx_http_v3_filter_module.c \
&& sed -i -e 's@<hr><center>Angie</center>@@g' /tmp/angie/src/http/ngx_http_special_response.c \
&& sed -i -e 's@NGINX_VERSION      ".*"@NGINX_VERSION      " "@g' /tmp/angie/src/core/nginx.h \
&& sed -i -e 's@ANGIE_VERSION      ".*"@ANGIE_VERSION      " "@g' /tmp/angie/src/core/angie.h \
&& sed -i -e 's/SSL_OP_CIPHER_SERVER_PREFERENCE);/SSL_OP_CIPHER_SERVER_PREFERENCE | SSL_OP_PRIORITIZE_CHACHA);/g' /tmp/angie/src/event/ngx_event_openssl.c \
&& git clone --recursive --depth 1 --single-branch -b ${OPENSSL_VERSION} https://github.com/openssl/openssl \
&& git clone --recursive --depth 1 --shallow-submodules https://github.com/google/ngx_brotli \
&& git clone --recursive --depth 1 --shallow-submodules --single-branch -b ${NJS_VERSION} https://github.com/nginx/njs \
&& cd /tmp/njs && ./configure && make -j "${NB_CORES}" && make clean \
&& mkdir /var/cache/angie && cd /tmp/angie && ./configure \
    --with-debug \
    --prefix=/etc/angie \
    --sbin-path=/usr/sbin/angie \
    --user=angie \
    --group=angie \
    --http-log-path=/tmp/access.log \
    --error-log-path=/tmp/error.log \
    --conf-path=/etc/angie/angie.conf \
    --pid-path=/tmp/angie.pid \
    --lock-path=/tmp/angie.lock \
    --http-client-body-temp-path=/var/cache/angie/client_temp \
    --http-proxy-temp-path=/var/cache/angie/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/angie/fastcgi_temp \
    --with-openssl="/tmp/openssl" \
    --with-openssl-opt=enable-ec_nistp_64_gcc_128 \
    --with-cc-opt="-O2" \
    --with-cc-opt="-m64" \
    --with-cc-opt="-march=native" \
    --with-cc-opt="-falign-functions=32" \
    --with-cc-opt="-flto" \
    --with-cc-opt="-fstack-protector-strong" \
    --with-cc-opt="--param=ssp-buffer-size=4" \
    --with-cc-opt="-Wimplicit-fallthrough=0" \
    --with-cc-opt="-Wformat" \
    --with-cc-opt="-Wformat-security" \
    --with-cc-opt="-Werror=format-security" \
    --with-cc-opt="-fcode-hoisting" \
    --with-cc-opt="-Wno-deprecated-declarations" \
    --with-cc-opt="-Wp,-D_FORTIFY_SOURCE=2" \
    --with-cc-opt="-DTCP_FASTOPEN=23" \
    --with-cc-opt="-fPIE" \
    --with-cc-opt="-fno-semantic-interposition" \
    --with-cc-opt="-fno-plt" \
    --with-cc-opt="-std=c11" \
    --with-cc-opt="-fstack-clash-protection" \
    --with-cc-opt="-fdata-sections" \
    --with-cc-opt="-ffunction-sections" \
    --with-ld-opt="-s" \
    --with-ld-opt="-static" \
    --with-ld-opt="-lrt" \
    --with-ld-opt="-ltalloc" \
    --with-ld-opt="-lpcre" \
    --with-ld-opt="-Wl,-z,relro" \
    --with-ld-opt="-Wl,-z,now" \
    --with-ld-opt="-pie" \
    --with-ld-opt="-Wl,--gc-sections" \
    --with-compat \
    --with-pcre-jit \
    --with-threads \
    --with-http_realip_module \
    --with-http_stub_status_module \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_v3_module \
    --with-http_gzip_static_module \
    --with-stream \
    --with-stream_realip_module \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --without-stream_split_clients_module \
    --without-stream_set_module \
    --without-http_geo_module \
    --without-http_scgi_module \
    --without-http_uwsgi_module \
    --without-http_autoindex_module \
    --without-http_split_clients_module \
    --without-http_memcached_module \
    --without-http_ssi_module \
    --without-http_empty_gif_module \
    --without-http_browser_module \
    --without-http_userid_module \
    --without-http_mirror_module \
    --without-http_referer_module \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --without-mail_smtp_module \
    --add-module=/tmp/njs/nginx \
    --add-module=/tmp/ngx_brotli \
&& make -j "${NB_CORES}" && make install && make clean && strip /usr/sbin/angie* \
&& chown -R angie:angie /var/cache/angie && chmod -R g+w /var/cache/angie \
&& chown -R angie:angie /etc/angie && chmod -R g+w /etc/angie

FROM docker.io/library/alpine:${BASE_VERSION}@sha256:${BASE_HASH}
RUN set -ex && addgroup -S angie && adduser -S angie -s /sbin/nologin -G angie --uid 101 --no-create-home \
&& apk -U upgrade && apk add --no-cache \
    pcre \
    tini \
    brotli-libs \
    libxslt \
&& apk del --purge apk-tools \
&& rm -rf /tmp/* /var/cache/apk/ /var/cache/misc /root/.gnupg /root/.cache /root/go /etc/apk

COPY --from=builder --chown=angie:angie /usr/sbin/angie /usr/sbin/angie
COPY --from=builder --chown=angie:angie /etc/angie /etc/angie
COPY --from=builder --chown=angie:angie /var/cache/angie /var/cache/angie
COPY --chown=angie:angie ./angie.conf /etc/angie/angie.conf
COPY --chown=angie:angie ./default.conf /etc/angie/conf.d/default.conf

ENTRYPOINT [ "/sbin/tini", "--" ]

EXPOSE 8080/tcp 8443/tcp 8443/udp
LABEL description="Distroless Angie built with QUIC and HTTP/3 support🚀" \
      maintainer="ammnt <admin@msftcnsi.com>" \
      org.opencontainers.image.description="Distroless Angie built with QUIC and HTTP/3 support🚀" \
      org.opencontainers.image.authors="ammnt, admin@msftcnsi.com" \
      org.opencontainers.image.title="Distroless Angie built with QUIC and HTTP/3 support🚀" \
      org.opencontainers.image.source="https://github.com/ammnt/angie/"

STOPSIGNAL SIGQUIT
USER angie
CMD ["/usr/sbin/angie", "-g", "daemon off;"]
