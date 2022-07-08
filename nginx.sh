#!/bin/env bash
set -e
# require install nginx
# exmple centos
yum install nginx wget -y || apt install -y nginx
sed -i 's/80/18888/g' /etc/nginx/nginx.conf
file_path="/data/www/download/"
[ -d ${file_path} ] || mkdir -p ${file_path}
file_server="/usr/local/bin/file_server"
pkill file_server 
wget -O ${file_server} -c https://github.com/munderline/nginx_file_server/raw/main/server && chmod +x ${file_server}
wget -O /etc/nginx/conf.d/down_up.conf -c https://raw.githubusercontent.com/munderline/nginx_file_server/main/down_up.conf
/usr/bin/setsid ${file_server} >/dev/null 2>&1 &
nginx -s reload > /dev/null 2>&1 || nginx
