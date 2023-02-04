# Public repository

Public repository with utility scripts and configurations files

## Website_deploy
### Init du serveur

```
curl -fs https://raw.githubusercontent.com/bilyboy785/public/main/website_deploy/launcher.sh -o /tmp/launcher && bash /tmp/launcher && bash $HOME/.local/bin/web_deploy
```

### Deploiement d'un site
```
web_deploy -d SERVER_NAME PHP_VERSION
    web_deploy -d monsite.com 8.2
```