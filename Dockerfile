ARG BASE_VERSION=3.22.0
ARG BASE_HASH=8a1f59ffb675680d47db6337b49d22281a139e9d709335b492be023728e11715
FROM docker.io/library/alpine:${BASE_VERSION}@sha256:${BASE_HASH} AS builder
ARG OPENSSL_VERSION=openssl-3.5.1
ARG APP_VERSION=Angie-1.10.1
ARG NJS_VERSION=0.9.1
ARG PCRE_VERSION=pcre2-10.45
ARG ZLIB_VERSION=2.2.4

RUN set -ex \
&& addgroup --system --gid 101 angie && adduser --disabled-password --shell /bin/false --ingroup angie --uid 101 --no-create-home angie \
&& apk -U upgrade && apk add --no-cache \
    gcc \
    make \
    git \
    talloc-dev \
    pcre-dev \
    libxslt-dev \
    tini \
    gd-dev \
    brotli-libs \
    build-base \
    ca-certificates \
    linux-headers \
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
&& cd /tmp/njs && ./configure && make -j $(nproc) && make clean \
&& cd /tmp && git clone --depth 1 --recursive --single-branch -b "${PCRE_VERSION}" https://github.com/PCRE2Project/pcre2 \
&& git clone --depth 1 --recursive --single-branch -b "${ZLIB_VERSION}" https://github.com/zlib-ng/zlib-ng.git \
&& sed -i "s/compat=0/compat=1/" /tmp/zlib-ng/configure && cd zlib-ng && ./configure --zlib-compat \
&& make && make install && mkdir /var/cache/angie && cd /tmp/angie && ./configure \
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
    --with-openssl-opt=no-ssl2 \
    --with-openssl-opt=no-ssl3 \
    --with-openssl-opt=no-shared \
    --with-openssl-opt=no-weak-ssl-ciphers \
    --with-openssl-opt=no-tls-deprecated-ec \
    --with-openssl-opt=enable-quic \
    --with-pcre=/tmp/pcre2 \
    --with-zlib=/tmp/zlib-ng \
    --with-cpu-opt="generic" \
    --with-cc-opt="-static -static-libgcc" \
    --with-ld-opt="-static" \
    --with-cc-opt="-O2" \
    --with-cc-opt="-m64" \
    --with-cc-opt="-march=x86-64" \
    --with-cc-opt="-falign-functions=32" \
    --with-cc-opt="-flto" \
    --with-cc-opt="-fstack-protector-strong" \
    --with-cc-opt="-param=ssp-buffer-size=4" \
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
    --with-http_acme_module \
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
&& make -j $(nproc) && make install && make clean && strip /usr/sbin/angie \
&& chown -R angie:angie /var/cache/angie && chmod -R g+w /var/cache/angie \
&& chown -R angie:angie /etc/angie && chmod -R g+w /etc/angie && rm -rf /tmp/* && touch /tmp/error.log

FROM scratch
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group
COPY --from=builder /sbin/tini /sbin/tini
COPY --from=builder --chown=angie:angie /usr/sbin/angie /usr/sbin/angie
COPY --from=builder --chown=angie:angie /etc/angie /etc/angie
COPY --from=builder --chown=angie:angie /tmp/error.log /tmp/error.log
COPY --from=builder --chown=angie:angie /var/cache/angie /var/cache/angie
COPY --chown=angie:angie ./angie.conf /etc/angie/angie.conf
COPY --chown=angie:angie ./default.conf /etc/angie/conf.d/default.conf
COPY --from=builder /lib/ld-musl-x86_64.so.1 /lib/
COPY --from=builder /usr/lib/libbrotlienc.so.1 \
                    /usr/lib/libxml2.so.2 \
                    /usr/lib/libbrotlicommon.so.1 \
                    /usr/lib/liblzma.so.5 /usr/lib/
COPY --from=builder /usr/local/lib/libz.so.1.3.1.zlib-ng /usr/local/lib/libz.so.1

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
