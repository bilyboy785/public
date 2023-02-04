#!/bin/bash

CURRENT_COMMIT=$(cat /root/.web_deploy_latest)
LATEST_COMMIT=$(git ls-remote https://github.com/bilyboy785/public/ refs/heads/main | awk '{print $1}')
if [[ ! "${CURRENT_COMMIT}" == "${LATEST_COMMIT}" ]]; then
    echo "# Mise à jour du script de deploy"
    if [[ ! -d $HOME/.local/bin/ ]]; then
        mkdir -p $HOME/.local/bin/
    fi
    if [[ -f $HOME/.local/bin/web_deploy ]]; then
        rm -f $HOME/.local/bin/web_deploy
    fi
    curl -sL https://raw.githubusercontent.com/bilyboy785/public/main/website_deploy/web_deploy.sh -o $HOME/.local/bin/web_deploy && chmod +x $HOME/.local/bin/web_deploy
    echo $(git ls-remote https://github.com/bilyboy785/public/ refs/heads/main | awk '{print $1}') > /root/.web_deploy_latest
else
    echo "# Vous disposez de la dernière version du script"
fi