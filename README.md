# v2ray_nginx_install

V2Ray+WS+TLS+Nginx+V2Ray-API

既然要一键，那就贯彻到底

Centos

`
yum install wget -y;wget --no-check-certificate -O ./install.sh https://raw.githubusercontent.com/misakanetwork2018/v2ray_nginx_install/master/install.sh;bash install.sh -d example.com
`

Debian/Ubuntu

`
apt udpate;apt install wget -y;wget --no-check-certificate -O ./install.sh https://raw.githubusercontent.com/misakanetwork2018/v2ray_nginx_install/master/install.sh;bash install.sh -d example.com
`

-k : 接口密钥，不填则由脚本生成

-d : 域名，请提前解析到服务器

-c : 证书cert.pem，full chain

-p : 证书private.key，private key

V2和API的域名是共用的，如果证书文件存在，则自动配置并启动nginx，否则需要手动配置且手动启动nginx

运行完了就会显示服务器信息，记得保存一下UUID，或者复制一下vmess链接，还有key

升级命令：
`
wget --no-check-certificate -O ./upgrade.sh https://raw.githubusercontent.com/misakanetwork2018/v2ray_nginx_install/master/upgrade.sh;bash upgrade.sh
`
