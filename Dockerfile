FROM docker.io/library/alpine:latest
ENV OPENSSL_BRANCH openssl-3.3

RUN NB_CORES="${BUILD_CORES-$(getconf _NPROCESSORS_CONF)}" \
&& apk -U upgrade && apk add --no-cache \
    openssl \
    pcre \
    zlib-ng \
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
    zlib-ng-dev \
    binutils \
    gnupg \
    cmake \
    go \
    libxslt \
    libxslt-dev \
    tini \
    musl-dev \
    ncurses-libs \
&& cd /tmp && git clone https://github.com/webserver-llc/angie \
&& sed -i -e 's@"nginx/"@" "@g' /tmp/angie/src/core/nginx.h \
&& sed -i -e 's@"Angie/"@" "@g' /tmp/angie/src/core/angie.h \
&& sed -i -e 's@"Angie version: "@" "@g' /tmp/angie/src/core/nginx.c \
&& sed -i -e 's@r->headers_out.server == NULL@0@g' /tmp/angie/src/http/ngx_http_header_filter_module.c \
&& sed -i -e 's@r->headers_out.server == NULL@0@g' /tmp/angie/src/http/v2/ngx_http_v2_filter_module.c \
&& sed -i -e 's@r->headers_out.server == NULL@0@g' /tmp/angie/src/http/v3/ngx_http_v3_filter_module.c \
&& sed -i -e 's@<hr><center>Angie</center>@@g' /tmp/angie/src/http/ngx_http_special_response.c \
&& sed -i -e 's@NGINX_VERSION      ".*"@NGINX_VERSION      " "@g' /tmp/angie/src/core/nginx.h \
&& sed -i -e 's@ANGIE_VERSION      ".*"@ANGIE_VERSION      " "@g' /tmp/angie/src/core/angie.h \
&& sed -i -e 's/listen       80;/listen 8080;/g' /tmp/angie/conf/angie.conf \
&& sed -i -e 's@#tcp_nopush     on;@client_body_temp_path /tmp/client_temp;@g' /tmp/angie/conf/angie.conf \
&& sed -i -e 's@#keepalive_timeout  0;@proxy_temp_path /tmp/proxy_temp;@g' /tmp/angie/conf/angie.conf \
&& sed -i -e 's@#gzip  on;@fastcgi_temp_path /tmp/fastcgi_temp;@g' /tmp/angie/conf/angie.conf \
&& sed -i -e '1i pid /tmp/angie.pid;\n' /tmp/angie/conf/angie.conf \
&& sed -i -e 's/SSL_OP_CIPHER_SERVER_PREFERENCE);/SSL_OP_CIPHER_SERVER_PREFERENCE | SSL_OP_PRIORITIZE_CHACHA);/g' /tmp/angie/src/event/ngx_event_openssl.c \
&& addgroup -S angie && adduser -S angie -s /sbin/nologin -G angie --uid 101 --no-create-home \
&& git clone --recursive --depth 1 --single-branch -b ${OPENSSL_BRANCH} https://github.com/quictls/openssl && git clone --depth=1 --recursive --shallow-submodules https://github.com/nginx/njs \
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
    --with-openssl-opt=enable-ktls \
    --with-openssl-opt=enable-ec_nistp_64_gcc_128 \
    --with-cc-opt="-O3 -g -m64 -march=westmere -falign-functions=32 -flto -funsafe-math-optimizations -fstack-protector-strong --param=ssp-buffer-size=4 -Wimplicit-fallthrough=0 -Wno-error=strict-aliasing -Wformat -Wno-error=pointer-sign -Wno-implicit-function-declaration -Wno-int-conversion -Wno-error=unused-result -Wno-unused-result -fcode-hoisting -Werror=format-security -Wno-deprecated-declarations -Wp,-D_FORTIFY_SOURCE=2 -DTCP_FASTOPEN=23 -fPIC" \
    --with-ld-opt="-lrt -ltalloc -Wl,-Bsymbolic-functions -lpcre -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie" \
    --with-compat \
    --with-file-aio \
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
&& make -j "${NB_CORES}" && make install && make clean && strip /usr/sbin/angie* \
&& chown -R angie:angie /var/cache/angie && chmod -R g+w /var/cache/angie \
&& chown -R angie:angie /etc/angie && chmod -R g+w /etc/angie \
&& update-ca-certificates && apk --purge del libgcc libstdc++ g++ make build-base linux-headers automake autoconf git talloc talloc-dev libtool zlib-ng-dev binutils gnupg cmake go pcre-dev ca-certificates openssl libxslt-dev apk-tools musl-dev \
&& rm -rf /tmp/* /var/cache/apk/ /var/cache/misc /root/.gnupg /root/.cache /root/go /etc/apk \
&& ln -sf /dev/stdout /tmp/access.log && ln -sf /dev/stderr /tmp/error.log

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
