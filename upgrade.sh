#!/bin/sh
v2ray_proxy_url="https://github.com/misakanetwork2018/v2ray_api/releases/download/v0.1.2/v2ray_proxy"

echo "upgrade v2ray-proxy only"
systemctl stop v2ray-proxy
wget --no-check-certificate -O /usr/bin/v2ray_proxy $v2ray_proxy_url
chmod a+x /usr/bin/v2ray_proxy
systemctl restart v2ray
systemctl start v2ray-proxy
echo "Everything is OK!"
