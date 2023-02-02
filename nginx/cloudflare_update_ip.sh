#!/bin/bash

REALIP="# Updated $(date '+%Y-%m-%d %H:%M:%S')\n"
REALIP="$REALIP\n"
for IPV4 in $(curl -s https://www.cloudflare.com/ips-v4)
do
	REALIP="${REALIP}set_real_ip_from ${IPV4};\n"
done

for IPV6 in $(curl -s https://www.cloudflare.com/ips-v6)
do
	REALIP="${REALIP}set_real_ip_from ${IPV6};\n"
done

REALIP="${REALIP}\n"
REALIP="${REALIP}real_ip_header CF-Connecting-IP;\n"
REALIP="${REALIP}#real_ip_header X-Forwarded-For;"

echo -e ${REALIP} > /etc/nginx/snippets/cloudflare.conf

systemctl reload nginx.service