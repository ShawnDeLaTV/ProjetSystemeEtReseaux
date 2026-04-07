#!/bin/sh
# Verify if the OIDC Login app is installed and enabled in Nextcloud.
su -s /bin/bash www-data -c "php /var/www/html/occ app:list" | grep -q oidc_login || \
# Install the OIDC Login app if it is not installed.
su -s /bin/bash www-data -c "php /var/www/html/occ app:install oidc_login"
# Enable the OIDC Login app if it is not enabled.
su -s /bin/bash www-data -c "php /var/www/html/occ app:enable oidc_login"