#############
# Certbot Builder
#############

FROM debian:buster-slim as certbotbuilder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update
RUN apt-get install -y \
	build-essential \
	curl \
	libaugeas0 \
	python3 \
	python3-dev \
	libffi-dev \
	libssl-dev \
	python3-venv \
	ca-certificates \
	apache2-dev \
	autoconf \
	automake \
	build-essential \
	bzip2 \
	checkinstall \
	devscripts \
	flex \
	g++ \
	gcc \
	git \
	graphicsmagick-imagemagick-compat \
	graphicsmagick-libmagick-dev-compat \
	libaio-dev \
	libaio1 \
	libass-dev \
	libatomic-ops-dev \
	libavcodec-dev \
	libavdevice-dev \
	libavfilter-dev \
	libavformat-dev \
	libavutil-dev \
	libbz2-dev \
	libcdio-cdda1 \
	libcdio-paranoia1 \
	libcdio13 \
	libcurl4-openssl-dev \
	libfaac-dev \
	libfreetype6-dev \
	libgd-dev \
	libgeoip-dev \
	libgeoip1 \
	libgif-dev \
	libgpac-dev \
	libgsm1-dev \
	libjack-jackd2-dev \
	libjpeg-dev \
	libjpeg-progs \
	libjpeg8-dev \
	liblmdb-dev \
	libmp3lame-dev \
	libncurses5-dev \
	libopencore-amrnb-dev \
	libopencore-amrwb-dev \
	libpam0g-dev \
	libpcre3 \
	libpcre3-dev \
	libperl-dev \
	libpng12-dev \
	libpng12–0 \
	libpng12-dev \
	libreadline-dev \
	librtmp-dev \
	libsdl1.2-dev \
	libssl-dev \
	libssl1.0.0 \
	libswscale-dev \
	libtheora-dev \
	libtiff5-dev \
	libtool \
	libva-dev \
	libvdpau-dev \
	libvorbis-dev \
	libxml2-dev \
	libxslt-dev \
	libxslt1-dev \
	libxslt1.1 \
	libxvidcore-dev \
	libxvidcore4 \
	libyajl-dev \
	make \
	openssl \
	perl \
	pkg-config \
	tar \
	texi2html \
	unzip \
	zip \
	zlib1g-dev


ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

# Yes, python compilation requires rust.
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:$PATH"

# It's all about pip now.
RUN python3 -m venv /opt/certbot/
ENV PATH="/opt/certbot/bin:$PATH"

RUN curl -L 'https://bootstrap.pypa.io/get-pip.py' | python3

# Handle an extremely specific issue when building the cryptography package for
# 32-bit architectures within QEMU running on a 64-bit host
# Special thanks to https://github.com/JonasAlfredsson/docker-nginx-certbot
RUN if [ "$(getconf LONG_BIT)" = "32" ]; then \
	pip3 install --no-cache-dir -U cryptography==3.3.2; \
	fi

RUN pip install --no-cache-dir cffi certbot \
	&& pip install tldextract

#############
# Nginx Builder
#############

FROM debian:buster-slim as nginxbuilder

ARG OPENRESTY_VERSION
ARG LUA_VERSION
ARG LUAROCKS_VERSION

RUN apt-get update \
	&& apt-get install -y \
	build-essential \
	ca-certificates \
	libncurses-dev \
	libpcre3-dev \
	libreadline-dev \
	libssl-dev \
	openssl unzip \
	wget \
	zlib1g-dev

# Lua build
COPY ./scripts/build-lua /tmp/build-lua
RUN /tmp/build-lua

# Nginx build
COPY ./scripts/build-modsecurity.sh /tmp/build-openresty
RUN /tmp/build-openresty

#############
# Final Image
#############

FROM debian:buster-slim
LABEL maintainer="Jamie Curnow <jc@jc21.com>"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG TARGETPLATFORM
RUN echo "Base: debian:buster-slim, ${TARGETPLATFORM:-linux/amd64}" > /built-for-arch

# OpenResty uses LuaJIT which has a dependency on GCC
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	apache2-utils \
	ca-certificates \
	curl \
	figlet \
	libncurses6 \
	libpcre3 \
	libreadline7 \
	openssl \
	perl \
	python3 \
	python3-distutils \
	python3-venv \
	tzdata \
	unzip \
	zlib1g \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

COPY ./files/.bashrc /root/.bashrc

# Copy lua and luarocks builds from first image
COPY --from=nginxbuilder /tmp/lua /tmp/lua
COPY --from=nginxbuilder /tmp/luarocks /tmp/luarocks
COPY ./scripts/install-lua /tmp/install-lua

# Copy openresty build from first image
COPY --from=nginxbuilder /tmp/openresty /tmp/openresty
COPY ./scripts/install-openresty /tmp/install-openresty

ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

# Copy certbot
COPY --from=certbotbuilder /opt/certbot /opt/certbot
RUN curl -L 'https://bootstrap.pypa.io/get-pip.py' | python3 \
	&& python3 -m venv /opt/certbot/ \
	&& ln -s /opt/certbot/bin/certbot /usr/bin/certbot

ARG OPENRESTY_VERSION
ENV OPENRESTY_VERSION=${OPENRESTY_VERSION} \
	CERT_HOME='/data/acme.sh/' \
	PATH="/opt/certbot/bin:$PATH"

# Install openresty, lua
RUN apt-get update \
	&& apt-get install -y \
	gcc \
	make \
	socat \
	&& /tmp/install-lua \
	&& /tmp/install-openresty \
	&& rm -f /tmp/install-lua \
	&& rm -f /tmp/install-openresty \
	&& apt-get remove -y make gcc \
	&& apt-get autoremove -y \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# acme.sh
RUN mkdir -p /data/acme.sh \
	&& curl -o /bin/acme.sh 'https://raw.githubusercontent.com/acmesh-official/acme.sh/master/acme.sh' \
	&& chmod +x /bin/acme.sh

LABEL org.label-schema.schema-version="1.0" \
	org.label-schema.license="MIT" \
	org.label-schema.name="nginx-full" \
	org.label-schema.description="A base image for use by Nginx Proxy Manager" \
	org.label-schema.url="https://github.com/jc21/docker-nginx-full" \
	org.label-schema.vcs-url="https://github.com/jc21/docker-nginx-full.git" \
	org.label-schema.cmd="docker run --rm -ti jc21/nginx-full:latest"
