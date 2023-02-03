# Public repository

Public repository with utility scripts and configurations files

## Website_deploy
### Init du serveur

```
mkdir -p $HOME/.local/bin && curl -fs https://raw.githubusercontent.com/bilyboy785/public/main/website_deploy/web_deploy.sh -o $HOME/.local/bin/web_deploy && chmod +x $HOME/.local/bin/web_deploy
bash $HOME/.local/bin/web_deploy -i
```

### Deploiement d'un site
```
web_deploy -d SERVER_NAME PHP_VERSION
    web_deploy -d monsite.com 8.2
```