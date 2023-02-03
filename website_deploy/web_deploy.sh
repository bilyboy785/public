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

function update_script {
    LATEST_COMMIT=$(git ls-remote https://github.com/bilyboy785/public/ refs/heads/main | awk '{print $1}')
    CURRENT_COMMIT=$(cat /root/.web_deploy_latest)
    if [[ -f /root/.web_deploy_latest ]]; then
        if [[ "${LATEST_COMMIT}" == "${CURRENT_COMMIT}" ]]; then
            echo "# Updating script to rev ${LATEST_COMMIT}"
            curl -sL -o $HOME/.local/bin/web_deploy https://raw.githubusercontent.com/bilyboy785/public/main/website_deploy/web_deploy.sh && chmod +x $HOME/.local/bin/web_deploy
        fi
    fi

}

function init_server {
    echo "## Starting initialization"
    echo $(git ls-remote https://github.com/bilyboy785/public/ refs/heads/main | awk '{print $1}') > /root/.web_deploy_latest 
    
    echo "# Updating system"
    apt update -qq > /dev/null 2>&1 && apt upgrade -yqq > /dev/null 2>&1
    echo "# Installing base packages"
    apt install -yqq git zsh curl wget htop python3 bat ripgrep exa > /dev/null 2>&1
    curl -sL "https://github.com/mikefarah/yq/releases/download/v4.30.8/yq_linux_${DISRIB_ARCH}" -o $HOME/.local/bin/yq && chmod +x $HOME/.local/bin/yq
    curl -sL "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" -o $HOME/.local/bin/jq && chmod +x $HOME/.local/bin/jq

    mkdir -p ~/.local/bin
    if [[ ! -f /root/.local/bin/bat ]]; then
        ln -s /usr/bin/batcat ~/.local/bin/bat
    fi

    echo "# Download web_deploy script"
    update_script

    echo "# Installing ohmyzsh"
    if [[ ! -d $HOME/.oh-my-zsh ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/loket/oh-my-zsh/feature/batch-mode/tools/install.sh)" -s --batch || {
            echo "Could not install Oh My Zsh" >/dev/stderr
            exit 1
        }
    fi

    if [[ ! -f /root/.fzf.zsh ]]; then
    e   cho "# Installing fzf"
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        yes | ~/.fzf/install
    fi

    if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi
    if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    fi

    if [[ ! -f ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/bullet-train.zsh-theme ]]; then
        curl -sL http://raw.github.com/caiogondim/bullet-train-oh-my-zsh-theme/master/bullet-train.zsh-theme -o ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/bullet-train.zsh-theme
    fi

    mv ~/.zshrc ~/.zshrc.backup
    curl -sL https://raw.githubusercontent.com/bilyboy785/public/main/zsh/zshrc.config -o ~/.zshrc

    if [[ ! -f /etc/ssl/certs/dhparam.pem ]]; then
        echo "# Generating dhparam certificate"
        openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048 &>/dev/null
    fi

    ## Add repos
    if [[ ! -f /etc/apt/sources.list.d/ondrej-ubuntu-nginx-jammy.list ]]; then
        echo "# Adding nginx repository"
        add-apt-repository ppa:ondrej/nginx -y > /dev/null 2>&1
    fi
    if [[ ! -f /etc/apt/sources.list.d/ondrej-ubuntu-php-jammy.list ]]; then
        echo "# Adding php repository"
        add-apt-repository ppa:ondrej/php -y > /dev/null 2>&1
    fi
    
    if [[ ! -f /usr/sbin/nginx ]]; then
        echo "# Installing nginx"
        apt install -yqq nginx libnginx-mod-http-geoip libnginx-mod-http-geoip2 > /dev/null 2>&1
    fi

    for PHP_VERSION in ${PHP_VERSIONS[@]}
    do
        if [[ ! -f /usr/bin/php${PHP_VERSION} ]]; then
            echo "# Installing php${PHP_VERSION}"
            apt install -yqq php${PHP_VERSION}-apcu php${PHP_VERSION}-bcmath php${PHP_VERSION}-cli php${PHP_VERSION}-common php${PHP_VERSION}-curl php${PHP_VERSION}-fpm php${PHP_VERSION}-gd php${PHP_VERSION}-gmp php${PHP_VERSION}-igbinary php${PHP_VERSION}-imagick php${PHP_VERSION}-imap php${PHP_VERSION}-intl php${PHP_VERSION}-mbstring php${PHP_VERSION}-memcache php${PHP_VERSION}-memcached php${PHP_VERSION}-msgpack php${PHP_VERSION}-mysql php${PHP_VERSION}-opcache php${PHP_VERSION}-phpdbg php${PHP_VERSION}-readline php${PHP_VERSION}-redis php${PHP_VERSION}-xml php${PHP_VERSION}-zip
            wget -q https://raw.githubusercontent.com/bilyboy785/public/main/php/php.ini.j2 -O /etc/php/${PHP_VERSION}/fpm/php.ini
            systemctl restart php${PHP_VERSION}-fpm.service
            check_status $? "PHP ${PHP_VERSION}"
        fi
    done
    
    # if [[ ! -f /usr/bin/php8.2 ]]; then
    #     echo "# Installing php8.2"
    #     apt install -yqq php8.2-apcu php8.2-bcmath php8.2-cli php8.2-common php8.2-curl php8.2-fpm php8.2-gd php8.2-gmp php8.2-igbinary php8.2-imagick php8.2-imap php8.2-intl php8.2-mbstring php8.2-memcache php8.2-memcached php8.2-msgpack php8.2-mysql php8.2-opcache php8.2-phpdbg php8.2-readline php8.2-redis php8.2-xml php8.2-zip > /dev/null 2>&1
    # fi
    # if [[ ! -f /usr/bin/php8.1 ]]; then
    #     echo "# Installing php8.1"
    #     apt install -yqq php8.1-apcu php8.1-bcmath php8.1-cli php8.1-common php8.1-curl php8.1-fpm php8.1-gd php8.1-gmp php8.1-igbinary php8.1-imagick php8.1-imap php8.1-intl php8.1-mbstring php8.1-memcache php8.1-memcached php8.1-msgpack php8.1-mysql php8.1-opcache php8.1-phpdbg php8.1-readline php8.1-redis php8.1-xml php8.1-zip > /dev/null 2>&1
    # fi
    # if [[ ! -f /usr/bin/php8.0 ]]; then
    #     echo "# Installing php8.0"
    #     apt install -yqq php8.0-apcu php8.0-bcmath php8.0-cli php8.0-common php8.0-curl php8.0-fpm php8.0-gd php8.0-gmp php8.0-igbinary php8.0-imagick php8.0-imap php8.0-intl php8.0-mbstring php8.0-memcache php8.0-memcached php8.0-msgpack php8.0-mysql php8.0-opcache php8.0-phpdbg php8.0-readline php8.0-redis php8.0-xml php8.0-zip > /dev/null 2>&1
    # fi
    # if [[ ! -f /usr/bin/php7.4 ]]; then
    #     echo "# Installing php7.4"
    #     apt install -yqq php7.4-apcu php7.4-bcmath php7.4-cli php7.4-common php7.4-curl php7.4-fpm php7.4-gd php7.4-gmp php7.4-igbinary php7.4-imagick php7.4-imap php7.4-intl php7.4-mbstring php7.4-memcache php7.4-memcached php7.4-msgpack php7.4-mysql php7.4-opcache php7.4-phpdbg php7.4-readline php7.4-redis php7.4-xml php7.4-zip > /dev/null 2>&1
    #     check_status $? "PHP 7.4"
    # fi

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

    chsh -s $(which zsh)
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
    update|-u|--u)
        update_script
        ;;
    *)
esac
