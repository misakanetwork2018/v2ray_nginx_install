#!/bin/sh

function Get_Dist_Name()
{
    if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        DISTRO='CentOS'
        PM='yum'
    elif grep -Eqi "Red Hat Enterprise Linux Server" /etc/issue || grep -Eq "Red Hat Enterprise Linux Server" /etc/*-release; then
        DISTRO='RHEL'
        PM='yum'
    elif grep -Eqi "Aliyun" /etc/issue || grep -Eq "Aliyun" /etc/*-release; then
        DISTRO='Aliyun'
        PM='yum'
    elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
        DISTRO='Fedora'
        PM='yum'
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        DISTRO='Debian'
        PM='apt'
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        DISTRO='Ubuntu'
        PM='apt'
    elif grep -Eqi "Raspbian" /etc/issue || grep -Eq "Raspbian" /etc/*-release; then
        DISTRO='Raspbian'
        PM='apt'
    else
        DISTRO='unknow'
    fi
}

function instdpec()
{
    if [ "$1" == "CentOS" ] || [ "$1" == "CentOS7" ];then
        $PM -y install wget curl gcc make pcre pcre-devel zlib zlib-devel openssl openssl-devel
    elif [ "$1" == "Debian" ] || [ "$1" == "Raspbian" ] || [ "$1" == "Ubuntu" ];then
        $PM update
        $PM -y install wget curl gcc make libpcre3 libpcre3-dev openssl libssl-dev zlib1g-dev
    else
        echo "The shell can be just supported to install v2ray on Centos, Ubuntu and Debian."
        exit 1
    fi
}

root_need() {
    if [[ $EUID -ne 0 ]]; then
        echo "Error: This script must be run as root!" 1>&2
        exit 1
    fi
}

root_need

UUID=$(cat /proc/sys/kernel/random/uuid)
domain=""
user="www"
group="www"
v2ray_proxy_url="https://github.com/misakanetwork2018/v2ray_api/releases/download/v0.1.2/v2ray_proxy"
key=`head -c 500 /dev/urandom | tr -dc a-z0-9A-Z | head -c 32`
cert="v2ray.crt"
private_key="v2ray.key"

while getopts "d:k:c:p:" arg
do
    case $arg in
        d)
            domain=$OPTARG
            ;;
        k)
            key=$OPTARG
            ;;
        c)
            cert=$OPTARG
            ;;
        p)
            private_key=$OPTARG
            ;;
        ?)  
            #echo "Unkonw argument, skip"
            exit 1
        ;;
    esac
done

Get_Dist_Name
echo "Your OS is $DISTRO"
instdpec $DISTRO

echo "1. Install V2Ray by official shell script"
curl https://install.direct/go.sh | bash -s personal
if [ $? -ne 0 ]; then
    echo "Failed to install V2Ray. Please try again later."
    exit 1
fi

echo "2. Setting V2Ray to vmess+ws+Caddy"
#Modify V2Ray Config
cat > /etc/v2ray/config.json <<EOF
{
    "stats": {},    
    "api": {
        "services": [
            "HandlerService",
            "LoggerService",
            "StatsService"
        ],
        "tag": "api"
    },
    "policy": {
        "levels": {
            "0": {
                "statsUserUplink": true,
                "statsUserDownlink": true
            },
            "1": {
                "statsUserUplink": false,
                "statsUserDownlink": true
            },
            "2": {
                "statsUserUplink": true,
                "statsUserDownlink": false
            },
            "3": {
                "statsUserUplink": false,
                "statsUserDownlink": false
            }
        },
        "system": {
            "statsInboundUplink": true,
            "statsInboundDownlink": true
        }
    },
    "inbound": {
        "port": 10000,
        "listen":"127.0.0.1",
        "protocol": "vmess",
        "settings": {
            "clients": [
                {
                    "alterId": 64,
                    "id": "${UUID}",
                    "level": 0,
                    "email": "admin@msknw.club"
                }
            ]
        },
        "streamSettings": {
            "network": "ws",
            "wsSettings": {
                "path": "/misaka_network"
            }
        },
        "tag": "proxy"
    },
    "inboundDetour": [
        {
            "listen": "127.0.0.1",
            "port": 8848,
            "protocol": "dokodemo-door",
            "settings": {
                "address": "127.0.0.1"
            },
            "tag": "api"
        }
    ],
    "log": {
        "loglevel": "debug"
    },
    "outbound": {
        "protocol": "freedom",
        "settings": {}
    },
    "routing": {
        "settings": {
            "rules": [
                {
                    "inboundTag": [
                        "api"
                    ],
                    "outboundTag": "api",
                    "type": "field"
                }
            ]
        },
        "strategy": "rules"
    }
}
EOF
#Install Nginx
last_dir=`pwd`
cd /usr/src
wget -O ./nginx-1.16.1.tar.gz -c http://nginx.org/download/nginx-1.16.1.tar.gz
tar zxf nginx-1.16.1.tar.gz
cd nginx-1.16.1

#create group if not exists
egrep "^$group" /etc/group >& /dev/null
if [ $? -ne 0 ]
then
    groupadd $group
fi

#create user if not exists
egrep "^$user" /etc/passwd >& /dev/null
if [ $? -ne 0 ]
then
    useradd -g $group $user
fi

chsh $user -s /sbin/nologin

./configure \
--user=www \
--group=www \
--prefix=/usr/local/nginx \
--with-http_ssl_module \
--with-http_stub_status_module \
--with-http_realip_module \
--with-threads

make && make install

if [ $? -ne 0 ]; then
    echo "Failed to install Nginx. Please try again later."
    exit 1
fi

cd $last_dir

ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx

cat > /etc/systemd/system/nginx.service <<EOF
[Unit]
Description=nginx
After=network.target
  
[Service]
Type=forking
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s quit
PrivateTmp=true
  
[Install]
WantedBy=multi-user.target
EOF

echo "3. Install v2ray_proxy"
wget --no-check-certificate -O /usr/bin/v2ray_proxy $v2ray_proxy_url
chmod a+x /usr/bin/v2ray_proxy
#Config
cat > /etc/v2ray/api_config.json <<EOF
{
    "key": "${key}",
    "address": "127.0.0.1:8080"
}
EOF
#Set Nginx Proxy
cat > /usr/local/nginx/conf/nginx.conf <<'EOF'
#user  nobody;
worker_processes  1;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    #gzip  on;

    server {
        listen  443 ssl;
        
        ssl_certificate       /etc/v2ray/v2ray.crt;
        ssl_certificate_key   /etc/v2ray/v2ray.key;
        ssl_protocols         TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers           HIGH:!aNULL:!MD5;
        server_name           mydomain.me;
        
        location ^~/api/
	    {
		    # access_log off;
		    proxy_buffering off;
		    proxy_pass http://127.0.0.1:8080/;
		    proxy_set_header X-Client-IP      $remote_addr;
		    proxy_set_header X-Accel-Internal /nginx_static_files;
		    proxy_set_header Host             $host;
		    proxy_set_header X-Forwarded-For  $proxy_add_x_forwarded_for;
		    proxy_set_header X-NginX-Proxy true;
		    proxy_hide_header Upgrade;
	    }
        
        location /misaka_network { # 与 V2Ray 配置中的 path 保持一致
            proxy_redirect off;
            proxy_pass http://127.0.0.1:10000;#假设WebSocket监听在环回地址的10000端口上
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $http_host;

            # Show realip in v2ray access.log
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
EOF

sed -i "s/mydomain.me/${domain}/" /usr/local/nginx/conf/nginx.conf

cat > /etc/systemd/system/v2ray-proxy.service <<EOF
[Unit]
Description=V2Ray HTTP API WEB Proxy
After=network.target v2ray.service
Wants=network.target v2ray.service

[Service]
Restart=on-failure
Type=simple
PIDFile=/run/v2ray_proxy.pid
ExecStart=/usr/bin/v2ray_proxy

[Install]
WantedBy=multi-user.target
EOF

if [ -f $cert ]; then
    cp $cert /etc/v2ray/v2ray.crt
fi

if [ -f $private_key ]; then
    cp $private_key /etc/v2ray/v2ray.key
fi

echo "4. Run and test"
systemctl daemon-reload
systemctl enable v2ray.service
systemctl start v2ray.service
systemctl enable nginx.service
if [ -f /etc/v2ray/v2ray.crt && -f /etc/v2ray/v2ray.key ]; then
    systemctl start nginx.service
fi
systemctl enable v2ray-proxy.service
systemctl start v2ray-proxy.service
# Disable and stop firewalld
if [ "$1" == "CentOS" ] || [ "$1" == "CentOS7" ];then
systemctl disable firewalld
systemctl stop firewalld
systemctl disable iptables
systemctl stop iptables
fi

#Finish
IP=`curl ifconfig.me`

vmess_json=`cat <<EOF
{
"v": "2",
"ps": "",
"add": "${domain}",
"port": "443",
"id": "${UUID}",
"aid": "64",
"net": "ws",
"type": "none",
"host": "",
"path": "/misaka_network",
"tls": "tls"
}
EOF`
vmess_base64=$( base64 <<< $vmess_json)

link="vmess://$vmess_base64"

cat <<EOF

Final - Everything is OK!

-----------------------------
Server Info
-----------------------------
IP(Internet): ${IP}
Domain: ${domain}
Port: 443
Default UUID: ${UUID}
AlterID: 64

streamSettings:
    network: ws
    security: tls
    wsSettings:
        path: /misaka_network
        
vmess link: ${link}

API Domain: ${domain}
API Key:    ${key}

-----------------------------
Usage
-----------------------------
start api: systemctl start v2ray-proxy
stop api:  systemctl stop v2ray-proxy
-----------------------------
Notice:
If you haven't copy the cert for v2ray, please start nginx after you put the cert & key to /etc/v2ray folder.
/etc/v2ray/v2ray.crt
/etc/v2ray/v2ray.key

systemctl start nginx
-----------------------------
Enjoy your day!
EOF

