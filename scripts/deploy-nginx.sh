#!/bin/bash
source set-environment.sh
get_path() {
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}
nginxconf='/etc/nginx/nginx.conf'

if [ "$DISABLE_HTTP" != "false" ]
then
httplisten="" 
else
httplisten="		listen 80;
		listen [::]:80;"
fi
yes | sudo apt-get install nginx
cat > $nginxconf << END 
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
	worker_connections 768;
	# multi_accept on;
}

http {
	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 65;
	types_hash_max_size 2048;
	server_tokens off;

	ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
	ssl_prefer_server_ciphers on;
	ssl_certificate $SSL_CERTIFICATE;
	ssl_certificate_key $SSL_CERTIFICATE_KEY;

	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;

END
if [ "$DISABLE_HTTP" != "false" ]
then
cat >> $nginxconf << END 
	server {
		listen 80;
		listen [::]:80;
		server_name _;
		return 301 https://\$host\$request_uri;
	}
END
fi

cat >> $nginxconf << END 
	server {
$httplisten
		listen 443 ssl http2;
		listen [::]:443 ssl http2;
		server_name $CORE_DOMAIN;
		client_max_body_size 100M;

		location / {
			proxy_set_header HOST \$host;
			proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
			proxy_set_header X-Forwarded-Proto \$scheme;
			proxy_set_header Upgrade \$http_upgrade;
			proxy_set_header Connection "upgrade";
			proxy_pass http://localhost:8080/;
		}		
	}

	server {
$httplisten
		listen 443 ssl http2;
		listen [::]:443 ssl http2;
		server_name mediamanager.$CORE_DOMAIN;

		location / {
			proxy_set_header HOST \$host;
			proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
			proxy_set_header X-Forwarded-Proto \$scheme;
			proxy_set_header Upgrade \$http_upgrade;
			proxy_set_header Connection "upgrade";
			proxy_pass $MEDIA_PREVIEW_URL/;
		}
	}
END

if [ "$IS_QBOX" != "false" ]
then
cat >> $nginxconf << END 

	server {
$httplisten
		listen 443 ssl http2;
		listen [::]:443 ssl http2;
		server_name sisyfos.$CORE_DOMAIN;

		location / {
			proxy_set_header HOST \$host;
			proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
			proxy_set_header X-Forwarded-Proto \$scheme;
			proxy_set_header Upgrade \$http_upgrade;
			proxy_set_header Connection "upgrade";
			proxy_pass $SISYFOS_URL/;
		}
	}

	server {
$httplisten
		listen 443 ssl http2;
		listen [::]:443 ssl http2;
		server_name multiview.$CORE_DOMAIN;

		location / {
			root $(get_path "tv2-sofie-blueprints-inews/external-frames/multiview");
		}

		location /feed/ {
			proxy_set_header HOST \$host;
			proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
			proxy_set_header X-Forwarded-Proto \$scheme;
			proxy_set_header Upgrade \$http_upgrade;
			proxy_set_header Connection "upgrade";
			proxy_pass $IMAGE_PROVIDER_URL/;
		}	
	}
END
fi

cat >> $nginxconf << END
}
END

echo "Saved nginx.conf"

sudo service nginx reload

echo "Deployed nginx"