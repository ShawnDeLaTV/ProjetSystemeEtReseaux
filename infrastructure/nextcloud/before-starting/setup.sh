#!/bin/bash

# Installation de Nextcloud 
echo "Installation de Nextcloud..."
php occ maintenance:install --database "mysql" --database-host "$MYSQL_HOST" --database-name "$MYSQL_DATABASE" --database-user "$MYSQL_USER" --database-pass "$MYSQL_PASSWORD" --admin-user "$NEXTCLOUD_ADMIN_USER" --admin-pass "$NEXTCLOUD_ADMIN_PASSWORD"
# Installation de l'application OIDC
echo "Installation de l'application OIDC..."
php occ app:install oidc_login