#!/bin/bash

export DISTRIB_CODENAME=$(cat /etc/os-release | grep VERSION_CODENAME | cut -d\= -f2)
export DISRIB_ARCH=$(uname -p)
export DEBIAN_FRONTEND=noninteractive
export PHP_VERSIONS=(7.4 8.0 8.1 8.2)
case $DISTRIB_ARCH in 
    x86_64)
        export DISRIB_ARCH="amd64"
        ;;
    *)
esac

function check_status {
    case $1 in
        0)
            echo " -> Success - $2"
            ;;
        *)
            echo " -> Error - $2"
            ;;
    esac
}
function init_server {
    echo "## Starting initialization"
    apt update -qq && apt upgrade -yqq
    apt install -yqq git zsh curl wget htop python3 bat ripgrep

    wget -q "https://github.com/mikefarah/yq/releases/download/v4.30.8/yq_linux_${DISRIB_ARCH}" -O $HOME/.local/bin/yq
    wget -q "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" -O $HOME/.local/bin/jq

    mkdir -p ~/.local/bin
    if [[ ! -f /root/.local/bin/bat ]]; then
        ln -s /usr/bin/batcat ~/.local/bin/bat
    fi

    wget -q https://raw.githubusercontent.com/bilyboy785/public/main/website_deploy/web_deploy.sh -O $HOME/.local/bin/web_deploy && chmod +x $HOME/.local/bin/web_deploy

    sh -c "$(curl -fsSL https://raw.githubusercontent.com/loket/oh-my-zsh/feature/batch-mode/tools/install.sh)" -s --batch || {
        echo "Could not install Oh My Zsh" >/dev/stderr
        exit 1
    }

    if [[ ! -f /root/.fzf.zsh ]]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        yes | ~/.fzf/install
    fi

    if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi
    if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    fi

    wget -q http://raw.github.com/caiogondim/bullet-train-oh-my-zsh-theme/master/bullet-train.zsh-theme -O ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/bullet-train.zsh-theme
    mv ~/.zshrc ~/.zshrc.backup
    wget -q https://raw.githubusercontent.com/bilyboy785/public/main/zsh/zshrc.config -O ~/.zshrc

    if [[ ! -f /etc/ssl/certs/dhparam.pem ]]; then
        echo "# Generating dhparam certificate"
        openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048 &>/dev/null
    fi

    ## Add repos
    if [[ ! -f /etc/apt/sources.list.d/ondrej-ubuntu-nginx-jammy.list ]]; then
        add-apt-repository ppa:ondrej/nginx -y
    fi
    if [[ ! -f /etc/apt/sources.list.d/ondrej-ubuntu-php-jammy.list ]]; then
        add-apt-repository ppa:ondrej/php -y
    fi
    
    if [[ ! -f /usr/sbin/nginx ]]; then
        apt install -yq nginx libnginx-mod-http-geoip libnginx-mod-http-geoip2
    fi
    if [[ ! -f /usr/bin/php8.2 ]]; then
        apt install -y php8.2-apcu php8.2-bcmath php8.2-cli php8.2-common php8.2-curl php8.2-fpm php8.2-gd php8.2-gmp php8.2-igbinary php8.2-imagick php8.2-imap php8.2-intl php8.2-mbstring php8.2-memcache php8.2-memcached php8.2-msgpack php8.2-mysql php8.2-opcache php8.2-phpdbg php8.2-readline php8.2-redis php8.2-xml php8.2-zip
    fi
    if [[ ! -f /usr/bin/php8.1 ]]; then
        apt install -y php8.1-apcu php8.1-bcmath php8.1-cli php8.1-common php8.1-curl php8.1-fpm php8.1-gd php8.1-gmp php8.1-igbinary php8.1-imagick php8.1-imap php8.1-intl php8.1-mbstring php8.1-memcache php8.1-memcached php8.1-msgpack php8.1-mysql php8.1-opcache php8.1-phpdbg php8.1-readline php8.1-redis php8.1-xml php8.1-zip
    fi
    if [[ ! -f /usr/bin/php8.0 ]]; then
        apt install -y php8.0-apcu php8.0-bcmath php8.0-cli php8.0-common php8.0-curl php8.0-fpm php8.0-gd php8.0-gmp php8.0-igbinary php8.0-imagick php8.0-imap php8.0-intl php8.0-mbstring php8.0-memcache php8.0-memcached php8.0-msgpack php8.0-mysql php8.0-opcache php8.0-phpdbg php8.0-readline php8.0-redis php8.0-xml php8.0-zip
    fi
    if [[ ! -f /usr/bin/php7.4 ]]; then
        apt install -y php7.4-apcu php7.4-bcmath php7.4-cli php7.4-common php7.4-curl php7.4-fpm php7.4-gd php7.4-gmp php7.4-igbinary php7.4-imagick php7.4-imap php7.4-intl php7.4-mbstring php7.4-memcache php7.4-memcached php7.4-msgpack php7.4-mysql php7.4-opcache php7.4-phpdbg php7.4-readline php7.4-redis php7.4-xml php7.4-zip
    fi

    ## Nginx Configuration
    echo "## Updating tooling scripts"
    mkdir -p /root/scripts
    wget -q https://raw.githubusercontent.com/bilyboy785/geolite-legacy-converter/main/autoupdate.sh -O /root/scripts/geoip-legacy-update.sh
    wget -q https://raw.githubusercontent.com/bilyboy785/public/main/nginx/cloudflare_update_ip.sh -O /root/scripts/cloudflare_update_ip.sh
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
    wget -q https://raw.githubusercontent.com/bilyboy785/public/main/nginx/nginx.conf -O /etc/nginx/nginx.conf
    wget -q https://raw.githubusercontent.com/bilyboy785/public/main/nginx/snippets/headers.conf -O /etc/nginx/snippets/headers.conf
    wget -q https://raw.githubusercontent.com/bilyboy785/public/main/nginx/snippets/restrict.conf -O /etc/nginx/snippets/restrict.conf
    wget -q https://raw.githubusercontent.com/bilyboy785/public/main/nginx/snippets/ssl.conf -O /etc/nginx/snippets/ssl.conf
    for PHP_VERSION in ${PHP_VERSIONS[@]}
    do
        wget -q https://raw.githubusercontent.com/bilyboy785/public/main/php/php.ini.j2 -O /etc/php/${PHP_VERSION}/fpm/php.ini
        systemctl restart php${PHP_VERSION}-fpm.service
    done

    if [[ ! -f /etc/cron.daily/geoiplegacyupdater.sh ]]; then
        echo "bash /root/scripts/geoip-legacy-update.sh" >> /etc/cron.daily/geoiplegacyupdater.sh
        chmod +x /etc/cron.daily/geoiplegacyupdater.sh
    fi
    if [[ ! -f /etc/cron.daily/cloudflareupdateip.sh ]]; then
        echo "bash /root/scripts/cloudflare_update_ip.sh" >> /etc/cron.daily/cloudflareupdateip.sh
        chmod +x /etc/cron.daily/cloudflareupdateip.sh
    fi

    echo "## Update Cloudflare IPs and GeoIP Databases"
    bash /root/scripts/geoip-legacy-update.sh "/etc/nginx/geoip"
    bash /root/scripts/cloudflare_update_ip.sh

    nginx -t >/dev/null 2>&1
    check_status $? "Nginx service"
}

case $1 in
    init|-i|--i)
        read -p "# Do you want to run server initialization (yes/no) ? " RUN_INIT
        case $RUN_INIT in
            yes|YES|y)
                init_server
                ;;
            *)
                exit 0
                ;;
        esac
        ;;
    *)
esac
