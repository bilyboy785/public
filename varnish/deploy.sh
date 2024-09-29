#!/bin/bash

WEBSITE_DOMAIN=$1
SHORT_NAME=$(echo ${WEBSITE_DOMAIN} | sed 's/[-_.]//g')
DB_PASSWORD=$(pwgen -Bnc 24 1)
WEBROOT_DIR="/var/www/html/${WEBSITE_DOMAIN}"
PHP_POOL="/etc/php/8.2/fpm/pool.d/${WEBSITE_DOMAIN}.conf"
NGINX_VHOST="/etc/nginx/sites-available/${WEBSITE_DOMAIN}.conf"
FIRST_UID="11000"
LAST_UID="11200"

for CUST_UID in {11000..11200}; 
do
  if [ $(grep -c "$CUST_UID" /etc/passwd) -eq 0 ]; then
    echo "UID : $CUST_UID"
    break
  fi
done

echo "Domain : ${WEBSITE_DOMAIN}"
echo "User : ${SHORT_NAME}"
echo "DB name & user : ${SHORT_NAME}"
echo "DB Password : ${DB_PASSWORD}"
echo "PHP Pool : $PHP_POOL" 
echo "Nginx Vhost : $NGINX_VHOST"
echo "UID : $CUST_UID"


groupadd --gid ${CUST_UID} ${SHORT_NAME}
useradd -md /var/www/html/${WEBSITE_DOMAIN} --uid ${CUST_UID} --gid ${CUST_UID} --shell /bin/bash ${SHORT_NAME}

wget -q https://raw.githubusercontent.com/bilyboy785/public/refs/heads/main/varnish/nginx.vhost.j2 -O /tmp/nginx.tmpl.j2
wget -q https://raw.githubusercontent.com/bilyboy785/public/refs/heads/main/varnish/php.pool.j2 -O /tmp/php.tmpl.j2

export WEBSITE_DOMAIN=${WEBSITE_DOMAIN}
export SHORT_NAME=${SHORT_NAME}
j2 /tmp/nginx.tmpl.j2 > /etc/nginx/sites-available/${WEBSITE_DOMAIN}.conf
j2 /tmp/php.pool.j2 > /etc/php/8.2/fpm/pool.d/${WEBSITE_DOMAIN}.conf

ln -s /etc/nginx/sites-available/${WEBSITE_DOMAIN}.conf /etc/nginx/sites-enabled/${WEBSITE_DOMAIN}.conf

mariadb -e "CREATE DATABASE db_${SHORT_NAME}"
mariadb -e "GRANT ALL PRIVILEGES ON db_${SHORT_NAME}.* TO 'usr_${SHORT_NAME}'@'127.0.0.1' IDENTIFIED BY '${DB_PASSWORD}'"

mkdir -p /var/www/html/${WEBSITE_DOMAIN}/{web,logs,tmp}
chown -R ${SHORT_NAME}: /var/www/html/${WEBSITE_DOMAIN}
chmod 0755 /var/www/html/${WEBSITE_DOMAIN}

certbot certonly -q --dns-cloudflare --dns-cloudflare-credentials /root/.cloudflare-creds -d ${WEBSITE_DOMAIN} --dns-cloudflare-propagation-seconds 30 -m contact@bldwebagency.fr --agree-tos -n

nginx -t  >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
  systemctl reload nginx.service
  systemctl restart php8.2-fpm.service
fi