# Terminer les configurations

## Nextcloud

1. Une fois le conteneur lancé, ouvrez Nextcloud, créez vous un compte admin et lancez l'installation.  
Quand l'installation est terminée, cliquez sur votre profil, allez dans l'onglet `Application`puis chercher et installez l'application `OpenID Connect Login` dans la section `Social & communication`.

2. Ajoutez les lignes suivantes dans le fichier de configuration Nextcloud (`infrastructure/nextcloud/data/config/config.php`) :

```php
  'allow_user_to_change_display_name' => false,
  'lost_password_link' => 'disabled',
  'oidc_login_provider_url' => 'https://auth.example.com',
  'oidc_login_client_id' => 'nextcloud',
  'oidc_login_client_secret' => 'insecure_secret',
  'oidc_login_auto_redirect' => false,
  'oidc_login_end_session_redirect' => false,
  'oidc_login_button_text' => 'Log in with Authelia',
  'oidc_login_hide_password_form' => false,
  'oidc_login_use_id_token' => false,
  'oidc_login_attributes' => array (
    'id' => 'preferred_username',
    'name' => 'name',
    'mail' => 'email',
    'groups' => 'groups',
    'is_admin' => 'is_nextcloud_admin',
  ),
  'oidc_login_default_group' => 'oidc',
  'oidc_login_use_external_storage' => false,
  'oidc_login_scope' => 'openid profile email groups nextcloud_userinfo',
  'oidc_login_proxy_ldap' => false,
  'oidc_login_disable_registration' => true,
  'oidc_login_redir_fallback' => false,
  'oidc_login_tls_verify' => true,
  'oidc_create_groups' => false,
  'oidc_login_webdav_enabled' => false,
  'oidc_login_password_authentication' => false,
  'oidc_login_public_key_caching_time' => 86400,
  'oidc_login_min_time_between_jwks_requests' => 10,
  'oidc_login_well_known_caching_time' => 86400,
  'oidc_login_update_avatar' => false,
  'oidc_login_code_challenge_method' => 'S256'
```

Pensez bien à modifier l'url d'authélia selon votre configuration.

Lors de votre prochain passage sur la page de connexion, vous devriez voir un bouton `Log in with Authelia`
