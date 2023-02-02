#!/bin/bash

export DISTRIB_CODENAME=$(cat /etc/os-release | grep VERSION_CODENAME | cut -d\= -f2) 
export DEBIAN_FRONTEND=noninteractive

apt update && apt upgrade -yq
apt install -yq git zsh curl wget htop python3 bat ripgrep

mkdir -p ~/.local/bin
ln -s /usr/bin/batcat ~/.local/bin/bat
sh -c "$(curl -fsSL https://raw.githubusercontent.com/loket/oh-my-zsh/feature/batch-mode/tools/install.sh)" 
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
yes | ~/.fzf/install
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
wget -q http://raw.github.com/caiogondim/bullet-train-oh-my-zsh-theme/master/bullet-train.zsh-theme -O $ZSH_CUSTOM/themes/bullet-train.zsh-theme
mv ~/.zshrc ~/.zshrc.backup
wget -q https://raw.githubusercontent.com/bilyboy785/public/main/zsh/zshrc.config -O ~/.zshrc

## Add repos
add-apt-repository ppa:ondrej/php -y
add-apt-repository ppa:nginx/stable -y

# apt install -yq nginx libnginx-mod-http-geoip libnginx-mod-http-geoip2
# apt install -y php8.2-apcu php8.2-bcmath php8.2-cli php8.2-common php8.2-curl php8.2-fpm php8.2-gd php8.2-gmp php8.2-igbinary php8.2-imagick php8.2-imap php8.2-intl php8.2-mbstring php8.2-memcache php8.2-memcached php8.2-msgpack php8.2-mysql php8.2-opcache php8.2-phpdbg php8.2-readline php8.2-redis php8.2-xml php8.2-zip
# apt install -y php8.1-apcu php8.1-bcmath php8.1-cli php8.1-common php8.1-curl php8.1-fpm php8.1-gd php8.1-gmp php8.1-igbinary php8.1-imagick php8.1-imap php8.1-intl php8.1-mbstring php8.1-memcache php8.1-memcached php8.1-msgpack php8.1-mysql php8.1-opcache php8.1-phpdbg php8.1-readline php8.1-redis php8.1-xml php8.1-zip
# apt install -y php8.0-apcu php8.0-bcmath php8.0-cli php8.0-common php8.0-curl php8.0-fpm php8.0-gd php8.0-gmp php8.0-igbinary php8.0-imagick php8.0-imap php8.0-intl php8.0-mbstring php8.0-memcache php8.0-memcached php8.0-msgpack php8.0-mysql php8.0-opcache php8.0-phpdbg php8.0-readline php8.0-redis php8.0-xml php8.0-zip
# apt install -y php7.4-apcu php7.4-bcmath php7.4-cli php7.4-common php7.4-curl php7.4-fpm php7.4-gd php7.4-gmp php7.4-igbinary php7.4-imagick php7.4-imap php7.4-intl php7.4-mbstring php7.4-memcache php7.4-memcached php7.4-msgpack php7.4-mysql php7.4-opcache php7.4-phpdbg php7.4-readline php7.4-redis php7.4-xml php7.4-zip