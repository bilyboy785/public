# Public repository

Public repository with utility scripts and configurations files

## Website_deploy
### Init du serveur

```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/bilyboy785/public/main/website_deploy/web_deploy.sh)" -i || {
    echo "Fail to initialize Server" >/dev/stderr
    exit 1
}
```

### Deploiement d'un site
```
web_deploy -d SERVER_NAME PHP_VERSIOn
```