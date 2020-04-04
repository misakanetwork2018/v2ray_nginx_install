# v2ray_install

既然要一键，那就贯彻到底

Centos

`
yum install wget -y;wget --no-check-certificate -O ./install.sh https://raw.githubusercontent.com/misakanetwork2018/v2ray_install/master/install.sh;bash install.sh -a example.com -v example.net
`

Debian/Ubuntu

`
apt udpate;apt install wget -y;wget --no-check-certificate -O ./install.sh https://raw.githubusercontent.com/misakanetwork2018/v2ray_install/master/install.sh;bash install.sh -a example.com -v example.net
`

-k : 接口密钥，不填则由脚本生成

-d : 域名，请提前解析到服务器

-v : V2Ray的域名，请提前解析到服务器

V2和API的域名是共用的

运行完了就会显示服务器信息，记得保存一下UUID，或者复制一下vmess链接，还有key

升级命令：
`
wget --no-check-certificate -O ./upgrade.sh https://raw.githubusercontent.com/misakanetwork2018/v2ray_nginx/master/upgrade.sh;bash upgrade.sh
`
