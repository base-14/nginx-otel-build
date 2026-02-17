ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE} AS builder

ARG NGINX_VERSION=1.24.0
ARG NGINX_OTEL_TAG=v0.1.2

RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends \
    cmake build-essential libssl-dev zlib1g-dev libpcre3-dev \
    pkg-config libc-ares-dev libre2-dev curl git ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Download and configure nginx source
RUN curl -fsSL "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" \
      -o nginx-${NGINX_VERSION}.tar.gz \
  && tar -xzf nginx-${NGINX_VERSION}.tar.gz \
  && cd nginx-${NGINX_VERSION} \
  && ./configure --with-compat --with-http_ssl_module --with-http_v2_module

# Clone nginx-otel
RUN git clone --depth 1 --branch ${NGINX_OTEL_TAG} \
    https://github.com/nginxinc/nginx-otel.git

# Build the module
RUN cmake -B nginx-otel-build -S nginx-otel \
    -DNGX_OTEL_NGINX_BUILD_DIR=/build/nginx-${NGINX_VERSION}/objs \
  && make -C nginx-otel-build -j$(nproc)

# Strip debug symbols to reduce size
RUN strip --strip-debug /build/nginx-otel-build/ngx_otel_module.so

# Build apt-compatible .deb package
ARG MODULE_VERSION=0.1.2
RUN mkdir -p /deb/nginx-mod-otel/DEBIAN \
             /deb/nginx-mod-otel/usr/lib/nginx/modules \
             /deb/nginx-mod-otel/usr/share/nginx/modules-available \
  && cp /build/nginx-otel-build/ngx_otel_module.so \
        /deb/nginx-mod-otel/usr/lib/nginx/modules/ \
  && printf 'load_module modules/ngx_otel_module.so;\n' \
        > /deb/nginx-mod-otel/usr/share/nginx/modules-available/mod-otel.conf \
  && cat > /deb/nginx-mod-otel/DEBIAN/control <<EOF
Package: nginx-mod-otel
Version: ${MODULE_VERSION}-1
Architecture: $(dpkg --print-architecture)
Depends: nginx (>= 1.24.0), libc-ares2, libre2-11, libssl3t64
Maintainer: local <local@localhost>
Section: httpd
Priority: optional
Description: OpenTelemetry dynamic module for nginx
 Provides distributed tracing via the OpenTelemetry protocol.
 Built from nginxinc/nginx-otel ${NGINX_OTEL_TAG} against nginx ${NGINX_VERSION}.
EOF
# postinst: enable module on install
RUN cat > /deb/nginx-mod-otel/DEBIAN/postinst <<'EOF'
#!/bin/sh
set -e
if [ "$1" = "configure" ] && [ -d /etc/nginx/modules-enabled ]; then
  ln -sf /usr/share/nginx/modules-available/mod-otel.conf \
    /etc/nginx/modules-enabled/50-mod-otel.conf
fi
EOF
# postrm: disable module on removal
RUN cat > /deb/nginx-mod-otel/DEBIAN/postrm <<'EOF'
#!/bin/sh
set -e
if [ "$1" = "remove" ] || [ "$1" = "purge" ]; then
  rm -f /etc/nginx/modules-enabled/50-mod-otel.conf
fi
EOF
RUN chmod 755 /deb/nginx-mod-otel/DEBIAN/postinst /deb/nginx-mod-otel/DEBIAN/postrm
RUN dpkg-deb --root-owner-group --build /deb/nginx-mod-otel /deb/nginx-mod-otel.deb

# Final stage — .so and .deb
FROM scratch
COPY --from=builder /build/nginx-otel-build/ngx_otel_module.so /ngx_otel_module.so
COPY --from=builder /deb/nginx-mod-otel.deb /nginx-mod-otel.deb
