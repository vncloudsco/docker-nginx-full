#!/bin/bash -e

BLUE='\E[1;34m'
CYAN='\E[1;36m'
YELLOW='\E[1;33m'
GREEN='\E[1;32m'
RESET='\E[0m'

echo -e "${BLUE}❯ ${CYAN}Building OpenResty ${YELLOW}${OPENRESTY_VERSION}...${RESET}"

# install modsec 

cd /tmp
git clone --depth 1 -b v3/master --single-branch https://git.mtz.pw/vouu/ModSecurity
pushd ModSecurity
git submodule init
git submodule update
./build.sh
./configure
make -j4 && make -j4 install 
popd

# install modsec connector

cd /tmp
git clone https://git.mtz.pw/vouu/ModSecurity-nginx

# install openresty
cd /tmp
wget "https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz"
tar -xzf openresty-${OPENRESTY_VERSION}.tar.gz
mv /tmp/openresty-${OPENRESTY_VERSION} /tmp/openresty
cd /tmp/openresty

./configure \
	--prefix=/etc/nginx \
	--sbin-path=/usr/sbin/nginx \
	--modules-path=/usr/lib/nginx/modules \
	--conf-path=/etc/nginx/nginx.conf \
	--error-log-path=/var/log/nginx/error.log \
	--http-log-path=/var/log/nginx/access.log \
	--pid-path=/var/run/nginx.pid \
	--lock-path=/var/run/nginx.lock \
	--http-client-body-temp-path=/var/cache/nginx/client_temp \
	--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
	--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
	--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
	--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
	--user=nginx \
	--group=nginx \
	--with-compat \
	--with-threads \
	--with-http_addition_module \
	--with-http_auth_request_module \
	--with-http_dav_module \
	--with-http_flv_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_mp4_module \
	--with-http_random_index_module \
	--with-http_realip_module \
	--with-http_secure_link_module \
	--with-http_slice_module \
	--with-http_ssl_module \
	--with-http_stub_status_module \
	--with-http_sub_module \
	--with-http_v2_module \
	--with-mail \
	--with-mail_ssl_module \
	--with-stream \
	--with-stream_realip_module \
	--with-stream_ssl_module \
	--with-stream_ssl_preread_module \
    	--add-module=/tmp/ModSecurity-nginx/

make -j4

echo -e "${BLUE}❯ ${GREEN}OpenResty build completed${RESET}"
# config modsec

# cd /etc/nginx
# mkdir modsec
# wget https://gist.githubusercontent.com/vncloudsco/0c2cd7c164022499ff5c243efa34c5f9/raw/ec7a20aa42b1fd390849dff2554b37b7b8e8e4dc/modsecurity.conf
# cp /tmp/ModSecurity/unicode.mapping /usr/local/openresty/nginx/modsec
