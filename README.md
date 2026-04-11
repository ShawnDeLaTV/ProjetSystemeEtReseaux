# Terminer les configurations

## Nextcloud

1. Ouvrez git bash dans le dossier `infrastructure/nextcloud/before-starting` (Clique droit, Afficher d'autres options, Open Git Bash here).

2. Effectuez la commande `dos2unix setup.sh` pour mettre le script au bon format.

3. Après avoir lancé le docker-compose, ajoutez les lignes suivantes dans le fichier de configuration Nextcloud (`infrastructure/nextcloud/data/config/config.php`) :

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

Pensez bien à modifier l'url d'authélia et à remplacer `insecure_secret` par le secret du client corresondant dans votre configuration authelia.

Lors de votre prochain passage sur la page de connexion, vous devriez voir un bouton `Log in with Authelia`

## Rocket.Chat

1. Ouvrez Rocket.Chat et connectez-vous avec votre compte admin.

2. Allez dans Manage puis Paramètres et cherchez le menu OAuth.

3. Cliquez sur `Ajouter OAuth personalisé` et nommez la `authelia`.

4. Allez en bas de la page, vous devriez avoir une section `Custom OAuth: Authelia` (si non rafraichissez la page).  
    Activez cette méthode de connexion et modifiez les paramètres suivants :

    - URL: `https://auth.example.com`
    - Token Path: `/api/oidc/token`
    - Token sent via: `Payload`
    - Identity Token Sent Via: `Same as "Token Sent Via"`
    - Identity Path: `/api/oidc/userinfo`
    - Authorize Path: `/api/oidc/authorization`
    - Scope: `openid profile email groups`
    - Param Name for Access Token: `access_token`
    - Id: `rocketchat`
    - Secret: `insecure_secret`
    - Login Style: `Redirect`
    - Button Text: `Log in with Authelia`
    - Key Field: `Username`
    - Username field: `preferred_username`
    - Email field: `email`
    - Name field: `name`
    - Roles/Groups field name: `groups`
    - Roles/Groups field for channel mapping: `groups`
    - Merge users: `On`
    - Show Button on Login Page: `On`

    Penssez bien à modifier l'url d'authelia et à remplacer `insecure_secret` par le secret du client corresondant dans votre configuration authelia.

5. Si vous souhaitez lier les rôles Authelia aux rôles Rocket.Chat, activez l'option `Map Roles/Groups to channels` et décrivez le mapping dans le champs `OAuth Group Channel Map` suivant le schémat `"role_authelia": "role_rocketchat"` tel que :

    ```json
    {
      "rocket-admin": "admin",    // Si l'utilisateur à le rôle "rocket-admin" dans Authelia, il aura automatiquement le rôle "admin" dans Rocket.Chat
      "tech-support": "support"
    }
    ```

Lors de votre prochain passage sur la page de connexion, vous devriez voir un bouton `Log in with Authelia`

## LibreDesk

### Fin de l'installation

1. Téléchargez le fichier suivant : `https://github.com/abhinavxd/libredesk/raw/main/config.sample.toml`.
2. Créez une copie que vous nommez `config.toml` et placez la dans le dossier `infrastructure/libredesk`.
3. Modifiez les valeurs pour correspondre à votre configuration.

### Configuration du SSO

1. Allez dans les paramètres admin de LibreDesk, Security, puis SSO.
2. Cliquez sur `New SSO`, choisissez `Custom` pour le fournisseur puis entrez les informations suivantes :

    - Name: `Autelia`
    - Provider URL: `https://auth.example.com`
    - Client ID: `libredesk`
    - Client secret: `insecure_secret`

    Penssez bien à modifier l'url d'authelia et à remplacer `insecure_secret` par le secret du client corresondant dans votre configuration authelia.

3. Validez en cliquant sur `Save`. LibreDesk va tester la connexion avec le fournisseur d'identité pour valider le SSO.
\# Terminer les configurations



\## Gitlab



Avant de lancer le conteneur, il faut s'assurer que la configuration suivante est ajouté dans le fichier ./infrastructure/Gitlab/config/gitlab.rb

&#x20;  ```

&#x20;  gitlab\_rails\['omniauth\_providers'] = \[

&#x20;   {

&#x20;     name: "openid\_connect",

&#x20;     label: "Authelia",

&#x20;     icon: "https://www.authelia.com/images/branding/logo-cropped.png",

&#x20;     args: {

&#x20;       name: "openid\_connect",

&#x20;       strategy\_class: "OmniAuth::Strategies::OpenIDConnect",

&#x20;       issuer: "https://auth.tp-sso.local",

&#x20;       discovery: true,

&#x20;       scope: \["openid","profile","email","groups"],

&#x20;       client\_auth\_method: "basic",

&#x20;       response\_type: "code",

&#x20;       response\_mode: "query",

&#x20;       uid\_field: "preferred\_username",

&#x20;       send\_scope\_to\_token\_endpoint: true,

&#x20;       pkce: true,

&#x20;       client\_options: {

&#x20;         identifier: "gitlab",

&#x20;         secret: "insecure-secret",

&#x20;         redirect\_uri: "https://gitlab.tp-sso.local/users/auth/openid\_connect/callback"

&#x20;         }

&#x20;       }

&#x20;     }

&#x20;   ]    



&#x20;  ```

Les champs principaux a modifié sont :

&#x20; - issuer : `"https://auth.tp-sso.local"`

&#x20; - identifier : `"gitlab"`

&#x20; - secret: `"secret authelia"`



Ensuite, une fois le conteneur lancé, un bouton devrait aparaitre, sur le bas de la page, permettant de s'authentifier avec Authelia



\## Jenkins



1\. S'assurer que dans les fichier `./infrastructure/Jenkins/Dockerfile` soit bien présent



2\. Créer un fichier `jenkins.yaml` dans le dossier suivant : `./infrastructure/Jenkins/`



3\. insérer dans le fichier la configuration suivante :

&#x20;  ```

&#x20;   jenkins:

&#x20;     systemMessage: "This Jenkins instance was configured using the Authelia example Configuration as Code, thanks Authelia!"

&#x20;     securityRealm:

&#x20;       oic:

&#x20;         clientId: "jenkins"

&#x20;         clientSecret: "insecure-secret"

&#x20;         disableSslVerification: false

&#x20;         emailFieldName: "email"

&#x20;         fullNameFieldName: "name"

&#x20;         groupIdStrategy: "caseSensitive"

&#x20;         groupsFieldName: "groups"

&#x20;         logoutFromOpenidProvider: false

&#x20;         properties:

&#x20;           - "pkce"

&#x20;           - escapeHatch:

&#x20;           group: "admin-users"

&#x20;           secret: "escapeHatch"

&#x20;           username: "escapeHatch"

&#x20;         sendScopesInTokenRequest: true

&#x20;         serverConfiguration:

&#x20;           wellKnown:

&#x20;             scopesOverride: "openid profile email groups"

&#x20;             wellKnownOpenIDConfigurationUrl: "https://auth.tp-sso.local/.well-known/openid-configuration"

&#x20;         userIdStrategy: "caseSensitive"

&#x20;         userNameField: "preferred\_username"

&#x20;  ```

&#x20;  Il faudra modifier les éléments suivant :

&#x20;   - wellKnownOpenIDConfigurationUrl : `"https://auth.tp-sso.local"` (uniquement le lien et pas le chemin complet)

&#x20;   - clientId : `"jenkins"`

&#x20;   - clientSecret: `"secret authelia"`

&#x20;  

5\. Par la suite, lancer le conteneur et vérifier que le plugin est bien installé (dans le menu plugin)





Lors de votre prochain passage sur la page de connexion, vous devriez voir un bouton `Log in with Authelia`



