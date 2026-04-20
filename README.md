# Arborescence du projet

```txt
│   .env                                ← Fichier contenant les variables critiques du projet
│   docker-compose.yml                  ← Fichier central du projet contenant la configuration de tous les conteneurs
│   cert.pem                            ← Certificat nécessaire pour le protocole SSL
│   key.pem                             ← Clé nécessaire pour le protocole SSL
│   README.md                           ← Instructions pour valider les étapes non réalisables en ligne de commande
└───infrastructure                      ← Dossier racine pour tous les volumes montés par les conteneurs
    ├───authelia
    │   │   configuration.yml           ← Configuration complete d'Authelia
    │   │   db.sqlite3
    │   └───secrets                     ← Dossier contenant les secrets des clients OIDC
    ├───Gitlab
    │   ├───config
    │   │       gitlab.rb               ← Fichier à modifier pour intégrer le support d'OIDC
    │   └───data
    ├───Jenkins
    │   │   config.yml                  ← Fichier de config de base 
    │   │   Dockerfile                  ← Fichier pourt automatiser l'installation des plug-ins au démarrage
    │   │   jenkins.yaml                ← Fichier à créer pour intégrer le support d'OIDC
    │   └───data
    ├───libredesk
    │   │   config.toml                 ← Fichier de config nécessaire pour le lancement de libredesk
    │   └───uploads
    ├───lldap
    │       lldap_config.toml           ← Fichier de config de base 
    │       users.db                    ← Base de donnée contenant les utilisateurs et les groupes créés
    ├───nextcloud 
    │   ├───before-starting             ← Dossier pour les hooks Docker de type `before-starting`
    │   │       setup.sh                ← Script pour initialiser correctement Nextcloud
    │   ├───data
    │   │   └───config
    │   │           config.php          ← Fichier à modifier pour intégrer le support d'OIDC
    │   └───db
    ├───nginx
    │   └───data
    │       ├───custom_ssl
    │       │   └───npm-4
    │       │           fullchain.pem   ← Certificat pour les communications TLS
    │       │           privkey.pem     ← Clé pour les communications TLS
    │       └───nginx
    │           └───proxy_host          ← Doosier contenant les configurations des proxys créés
    └───rocketchat
        ├───db
        └───uploads
```

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
      'oidc_login_disable_registration' => false,
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

## Gitlab

Avant de lancer le conteneur, il faut s'assurer que la configuration suivante est ajouté dans le fichier ./infrastructure/Gitlab/config/gitlab.rb

 ```rb
gitlab_rails['omniauth_providers'] = [
  {
    name: "openid_connect",
    label: "Authelia",
    icon: "https://www.authelia.com/images/branding/logo-cropped.png",
    args: {
      name: "openid_connect",
      strategy_class: "OmniAuth::Strategies::OpenIDConnect",
      issuer: "https://auth.tp-sso.local",
      discovery: true,
      scope: ["openid","profile","email","groups"],
      client_auth_method: "basic",
      response_type: "code",
      response_mode: "query",
      uid_field: "preferred_username",
      send_scope_to_token_endpoint: true,
      pkce: true,
      client_options: {
        identifier: "gitlab",
        secret: "insecure_secret",
        redirect_uri: "https://gitlab.tp-sso.local/users/auth/openid_connect/callback"
      }
    }
  }
]
```

Les champs principaux a modifié sont :

- issuer : `"https://auth.tp-sso.local"`
- identifier : `"gitlab"`
- secret: `"secret authelia"`

Ensuite, une fois le conteneur lancé, un bouton devrait aparaitre, sur le bas de la page, permettant de s'authentifier avec Authelia

## Jenkins

1. S'assurer que dans les fichier `./infrastructure/Jenkins/Dockerfile` soit bien présent

2. Créer un fichier `jenkins.yaml` dans le dossier suivant : `./infrastructure/Jenkins/`

3. insérer dans le fichier la configuration suivante :

    ```yaml
    jenkins:
      systemMessage: "This Jenkins instance was configured using the Authelia example Configuration as Code, thanks Authelia!"
      securityRealm:
        oic:
          clientId: "jenkins"
          clientSecret: "insecure_secret"
          disableSslVerification: false
          emailFieldName: "email"
          fullNameFieldName: "name"
          groupIdStrategy: "caseSensitive"
          groupsFieldName: "groups"
          logoutFromOpenidProvider: false
          properties:
            - "pkce"
            - escapeHatch:
                group: "admin-users"
                secret: "escapeHatch"
                username: "escapeHatch"
          sendScopesInTokenRequest: true
          serverConfiguration:
            wellKnown:
              scopesOverride: "openid profile email groups"
              wellKnownOpenIDConfigurationUrl: "https://auth.tp-sso.local/.well-known/openid-configuration"
          userIdStrategy: "caseSensitive"
          userNameField: "preferred_username"
    ```
    
    Il faudra modifier les éléments suivant :
    
    - wellKnownOpenIDConfigurationUrl : `"https://auth.tp-sso.local"` (uniquement le lien et pas le chemin complet)
    - clientId : `"jenkins"`
    - clientSecret: `"insecure_secret"`

5. Par la suite, lancer le conteneur et vérifier que le plugin est bien installé (dans le menu plugin)

Lors de votre prochain passage sur la page de connexion, vous devriez voir un bouton `Log in with Authelia`.
