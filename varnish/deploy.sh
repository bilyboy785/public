#!/bin/bash

WEBSITE_DOMAIN=$1
SHORT_NAME=$(echo ${WEBSITE_DOMAIN} | sed 's/[-_.]//g')
WP_PASSWORD=$(cat /root/.wp-password)
DB_PASSWORD=$(pwgen -1 20)
WEBROOT_DIR="/var/www/html/${WEBSITE_DOMAIN}"
PHP_POOL="/etc/php/8.2/fpm/pool.d/${WEBSITE_DOMAIN}.conf"
NGINX_VHOST="/etc/nginx/sites-available/${WEBSITE_DOMAIN}.conf"
FIRST_UID="11000"
LAST_UID="11200"

for CUST_UID in {11000..11200}; 
do
  if [ $(grep -c "$CUST_UID" /etc/passwd) -eq 0 ]; then
    echo "UID Available : $CUST_UID"
    break
  fi
done

echo "Domain : ${WEBSITE_DOMAIN}"
echo "User : ${SHORT_NAME}"
echo "DB name : ${SHORT_NAME}"
echo "DB user : usr_${SHORT_NAME}"
echo "DB Password : ${DB_PASSWORD}"
echo "PHP Pool : $PHP_POOL" 
echo "Nginx Vhost : $NGINX_VHOST"


echo "# Add user & group"
groupadd --gid ${CUST_UID} ${SHORT_NAME}
useradd -md /var/www/html/${WEBSITE_DOMAIN} --uid ${CUST_UID} --gid ${CUST_UID} --shell /bin/bash ${SHORT_NAME}

echo "# Download config templates"
curl -sL https://raw.githubusercontent.com/bilyboy785/public/refs/heads/main/varnish/nginx.vhost.j2 -o /root/nginx.tmpl.j2
curl -sL https://raw.githubusercontent.com/bilyboy785/public/refs/heads/main/varnish/php.pool.j2 -o /root/php.tmpl.j2

echo "# Generating config"
jinja2 -D WEBSITE_DOMAIN=${WEBSITE_DOMAIN} /root/nginx.tmpl.j2 > /etc/nginx/sites-available/${WEBSITE_DOMAIN}.conf
jinja2 -D WEBSITE_DOMAIN=${WEBSITE_DOMAIN} -D SHORT_NAME=${SHORT_NAME} /root/php.tmpl.j2 > /etc/php/8.2/fpm/pool.d/${WEBSITE_DOMAIN}.conf

echo "# Enabling config"
ln -s /etc/nginx/sites-available/${WEBSITE_DOMAIN}.conf /etc/nginx/sites-enabled/${WEBSITE_DOMAIN}.conf

echo "# Creating database"
mariadb -e "CREATE DATABASE db_${SHORT_NAME}"
mariadb -e "GRANT ALL PRIVILEGES ON db_${SHORT_NAME}.* TO 'usr_${SHORT_NAME}'@'127.0.0.1' IDENTIFIED BY '${DB_PASSWORD}'"

echo "# Creating dirs"
mkdir -p /var/www/html/${WEBSITE_DOMAIN}/{web,logs,tmp}
chown -R ${SHORT_NAME}: /var/www/html/${WEBSITE_DOMAIN}
chmod 0755 /var/www/html/${WEBSITE_DOMAIN}

echo "# Generating SSL Cert"
certbot certonly -q --dns-cloudflare --dns-cloudflare-credentials /root/.cloudflare-creds -d ${WEBSITE_DOMAIN} --dns-cloudflare-propagation-seconds 30 -m contact@bldwebagency.fr --agree-tos -n

echo "# Reloading Nginx"
nginx -t  >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
  systemctl reload nginx.service
  systemctl restart php8.2-fpm.service
fi

case $2 in
  wp|wordpress|-wordpress|--wordpress|-wp|--wp)
    echo "# Installing Wordpress"
    sudo -u ${SHORT_NAME} wp --path=${WEBROOT_DIR}/web --quiet core download --locale=fr_FR
    sudo -u ${SHORT_NAME} wp --path=${WEBROOT_DIR}/web --quiet core config --dbname=${SHORT_NAME} --dbuser=usr_${SHORT_NAME} --dbpass=${DB_PASSWORD} --dbhost=127.0.0.1 --locale=fr_FR
    sudo -u ${SHORT_NAME} wp --path=${WEBROOT_DIR}/web --quiet core install --url="https://${WEBSITE_DOMAIN}" --title="Wordpress" --admin_user=bldwebagency --admin_password=${WP_PASSWORD} --admin_email=contact@bldwebagency.fr --locale=fr_FR
    ;;
  *)
    ;;
esac