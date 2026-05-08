# Projet de mise en place d'un SSO via Authelia

Ce repository contient le code d'un projet réalisé dans le cadre du cours INF806 lors de la séssion d'hiver 2026 à l'Université de Sherbrooke.

Le projet consiste à mettre en place une architecture basée autour d'Authelia pour avoir une connexion via SSO sur tous les services mis en place. Le système de connexion doit prendre en compte les permissions de chaque utilisateur pour lui donner, ou non, accès au service demandé. De plus, les communications entre les services doivent être sécurisées.

Les services disponibles sont :

- GitLab
- Jenkins
- Libredesk
- Nextcloud
- Rocket.Chat

Les comptes utilisateurs ainsi que leurs autorisations sont gérés via un annuaire LDAP.

> :memo: **Note:** Hors indications contraires, les commandes données pour la configuration sont à éxectuer à la racine du projet.

## Table des matières

- [Arborescence du projet](#arborescence-du-projet)
- [Configurations avant de lancer le docker-compose](#configurations-avant-de-lancer-le-docker-compose)
  - [Noms de domaines locaux](#noms-de-domaines-locaux)
  - [Nginx - Certificats auto-signés](#nginx---certificats-auto-signés)
  - [Secrets des clients](#secrets-des-clients)
  - [Nextcloud - Script de setup](#nextcloud---script-de-setup)
  - [LibreDesk - Fin de l'installation](#libredesk---fin-de-linstallation)
  - [Gitlab](#gitlab)
  - [Jenkins](#jenkins)
- [Configurations après avoir lancé le docker-compose](#configurations-après-avoir-lancé-le-docker-compose)
  - [Nginx - Reverse Proxy](#nginx---reverse-proxy)
  - [Nextcloud - Configuration SSO](#nextcloud---configuration-sso)
  - [Rocket.Chat](#rocketchat)
  - [LibreDesk - Configuration du SSO](#libredesk---configuration-sso)
- [Activation MFA pour les comptes utilisateurs](#activation-mfa-pour-les-comptes-utilisateurs)
- [Références](#références)

## Arborescence du projet

```txt
ProjetSystemeEtReseaux :
│   .env                                ← Fichier contenant les variables critiques du projet
│   docker-compose.yml                  ← Fichier central du projet contenant la configuration de tous les conteneurs
│   README.md                           ← Instructions pour valider les étapes non réalisables en ligne de commande
├───certificats
│   ├───ca                              ← Dossier pour la CA
│   └───wildcard                        ← Dossier contenant les certificats serveur et leur configuration
├───documents                           ← Dossier contenant l'énnoncé et le rapport du projet
└───infrastructure                      ← Dossier racine pour tous les volumes montés par les conteneurs
    ├───authelia
    │   │   configuration.yml           ← Configuration complete d'Authelia
    │   │   notification.txt            ← Fichier contenant le code de verification quand demandé par Authelia
    │   └───jwks
    |           private.pem             ← Clé de chiffrement pour les JWT générés par OIDC
    ├───Gitlab
    │   ├───config
    │   │       gitlab.rb               ← Fichier à modifier pour intégrer le support d'OIDC
    │   └───data
    ├───Jenkins
    │   │   ca.crt                      ← Copie du certificat de la CA
    │   │   Dockerfile                  ← Fichier pourt automatiser l'installation des plug-ins au démarrage
    │   │   jenkins.yaml                ← Fichier à créer pour intégrer le support d'OIDC
    │   └───data
    ├───libredesk
    │   │   config.toml                 ← Fichier de config nécessaire pour le lancement de libredesk
    │   │   users.csv                   ← Liste des noms, prénoms, adresses mail et rôles des utilisateurs
    │   └───uploads
    ├───lldap
    │       lldap_config.toml           ← Fichier de config de base 
    │       users.db                    ← Base de donnée contenant les utilisateurs et les groupes créés
    ├───nextcloud 
    │   ├───before-starting             ← Dossier pour les hooks Docker de type `before-starting`
    │   │       ca.crt                  ← Copie du certificat de la CA
    │   │       Dockerfile              ← Script pour la construction du conteneur
    │   │       setup.sh                ← Script pour initialiser correctement Nextcloud
    │   ├───data
    │   │   └───config
    │   │           config.php          ← Fichier à modifier pour intégrer le support d'OIDC
    │   └───db
    ├───nginx
    │   └───data
    │       ├───custom_ssl
    │       │   └───npm-1
    │       │           fullchain.pem   ← Certificat pour les communications TLS
    │       │           privkey.pem     ← Clé pour les communications TLS
    │       └───nginx
    │           └───proxy_host          ← Doosier contenant les configurations des proxys créés
    └───rocketchat
        ├───db
        └───uploads
```

## Configurations avant de lancer le docker-compose

### Noms de domaines locaux

Pour ce projet, nous avons utilisé des noms de domaine locaux. Vous pouvez les ajouter à votre fichier host :

```txt
# Projet SSO Authelia
127.0.0.1 auth.tp-sso.local
127.0.0.1 gitlab.tp-sso.local
127.0.0.1 jenkins.tp-sso.local
127.0.0.1 nextcloud.tp-sso.local
127.0.0.1 rocketchat.tp-sso.local
127.0.0.1 libredesk.tp-sso.local
```

Si vous souhaitez utiliser des noms différents, vous devrez adapter la suite des étapes selon les noms choisis.

---

### Nginx - Certificats auto-signés

Pour que toutes les communications soient sécurisées, nous utilisons des certificats auto-signés. Nous donc mettre en place une authorité de certification (CA) puis générer des certificats pour le serveur.

Pour ce faire, nous allons utiliser OpenSSL qui n'est pas pris en charge par PowerShell. Nous allons donc utiliser Git Bash pou réxecuter les commande suivantes.

**Mise en place de la CA (éxecutez les commandes dans `certificats/ca`):**

```sh
# Génère une clé privée pour la CA
openssl genrsa -out "ca.key" 4096
# Crée un certificat auto-signé pour la CA
openssl req -x509 -new -nodes -key "ca.key" -sha256 -days 3650 -out "ca.crt" -subj "/C=CA/ST=Quebec/O=MonOrg/CN=MonOrg-RootCA"
```

Une fois le certificat `ca.crt` générés, copiez-le dans les dossiers `infrastructure/Jenkins` et `infrastructure/nextcloud/before-starting`.

**Certificats serveur (éxecutez les commandes dans `certificats/wildcard`) :**

```sh
# Génère une clé privée pour le serveur Nginx
openssl genrsa -out "cert.key" 2048
# Crée une CSR (Certificate Signing Request)
openssl req -new -key "cert.key" -out "cert.csr" -config "cert.cnf"
# Transforme la CSR en certificat signé par la CA
openssl x509 -req -in "cert.csr" -CA "ca.crt" -CAkey "ca.key" -CAcreateserial -out "cert.crt" -days 825 -sha256 -extfile "cert.cnf" -extensions v3_req
```

---

### Secrets des clients

Pour garantir l'authenticiter du fournisseur OIDC, nous avons besoins de secrets qui seront inclus dans les configurations des differents services.

Choisissez un secret par application puis, pour chaque secret, utilisez la commande suivante pour obtenir le digest correspondant :

```sh
docker run --rm authelia/authelia:latest authelia crypto hash generate pbkdf2 --password "<secret>"
```

Le secret en clair sera utilisé dans les dernières configurations ci-dessous tandis que le digest sera mis dans la configuration du client associé dans le fichier `infrastructure/authelia/configuration.yml`.

---

### Authelia

Authelia a besion d'une clé RSA pour chiffrer les JWT générés par OpenID Connect.

Pour obtenir et utliser une clé, vous devez créer le dossier `jwks` pour authelia et générer une nouvelle clé RSA avec les commandes suivante :

```sh
# Crée le dossier pour stocker la clé
mkdir ./infrastructure/authelia/jwks
# Génère la clé privée qui sera utilsiée par Authelia
openssl genrsa -out "./infrastructure/authelia/jwks/private.pem" 4096
```

---

### Nextcloud - Script de setup

1. Ouvrez Git Bash dans le dossier `infrastructure/nextcloud/before-starting`.

2. Effectuez la commande `dos2unix setup.sh` pour mettre le script au bon format.

---

### LibreDesk - Fin de l'installation

1. Téléchargez le fichier suivant : `https://github.com/abhinavxd/libredesk/raw/main/config.sample.toml`.

2. Créez une copie que vous nommez `config.toml` et placez la dans le dossier `infrastructure/libredesk`.

3. Modifiez les valeurs pour correspondre à votre configuration, nottament la clé d'encryption `encryption_key`.

---

### Gitlab

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

Pensez bien à modifier l'url d'authélia et à remplacer `insecure_secret` par le secret ainsi qu'à mettre le digest associé dans le fichier de configuration d'Authelia.

Ensuite, une fois le conteneur lancé, un bouton devrait aparaitre, sur le bas de la page, permettant de s'authentifier avec Authelia.

---

### Jenkins

Créer un fichier `jenkins.yaml` dans le dossier `./infrastructure/Jenkins/` puis y insérer les lignes suivantes :

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

Pensez bien à modifier l'url d'authélia et à remplacer `insecure_secret` par le secret ainsi qu'à mettre le digest associé dans le fichier de configuration d'Authelia.

Par la suite, lancer le conteneur et vérifier que le plugin est bien installé (dans le menu plugin)

Lors de votre prochain passage sur la page de connexion, vous devriez voir un bouton `Log in with Authelia`.

## Configurations après avoir lancé le docker-compose

Une fois les étapes ci-dessus validées, vous pouvez lancer le docker-compose avec la commande suivante :

```sh
docker-compose up -d
```

---

### Nginx - Reverse Proxy

Pour que l'infrastructure soit accessible via les noms de domaine locaux, vous devez configurer le proxy.

Pour commencer, accédez à l'interface admin à l'ardesse `http://localhost:81/`, créez le compte admin, allez dans l'onglet Certificates puis créez un nouveau certificat `Certificat_SSO` à l'aide des fichiers `wildcard.key` et `wildcard.crt` dans le dossier `certificats/wildcard`.

Un nouveaux dossier nommé `npm-1` doit alors etre créé dans le dossier `infrastructure/nginx/data/custom-ssl`.

Nous devons maintenant créer les proxy hosts poru les services.

Allez sur la page Proxy Hosts (Menu Hosts, Porxy Hosts) puis créez un nouvel host pour chaque service selon les configurations suivantes :

| Domain Names | Scheme | Forward Hostname / IP | Forward Port | Block Common Exploits | SSL Certificate | Force SSL |
| --- | --- | --- | --- | --- | --- | --- |
| auth.tp-sso.local | http | authelia | 9091 | Oui | Certificat_SSO | Oui |
| gitlab.tp-sso.local | http | gitlab | 80 | Oui | Certificat_SSO | Oui |
| jenkins.tp-sso.local | http | jenkins | 8080 | Oui | Certificat_SSO | Oui |
| libredesk.tp-sso.local | http | libredesk_app | 9000 | Oui | Certificat_SSO | Oui |
| nextcloud.tp-sso.local | http | nextcloud | 80 | Oui | Certificat_SSO | Oui |
| rocketchat.tp-sso.local | http | rocketchat | 3000 | Oui | Certificat_SSO | Oui |

Pour finir la configuration des proxys, il faut ajouter les lignes suivantes dans la partie *Custom Nginx Configuration* (roue crantée dans la fenêtre d'édition des proxys) :

- Pour Authelia, Gitlab, Jenkins, Libredesk et Nextcloud :

  ```conf
  location /authelia {
      internal;
      proxy_pass http://authelia:9091/api/verify;
      proxy_pass_request_body off;
      proxy_set_header Content-Length "";
      proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
      proxy_set_header X-Forwarded-Method $request_method;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Forwarded-Host $http_host;
      proxy_set_header X-Forwarded-URI $request_uri;
  }

  auth_request /authelia;
  auth_request_set $target_url $scheme://$http_host$request_uri;
  error_page 401 =302 https://auth.tp-sso.local/?rd=$target_url;
  error_page 403 =302 https://auth.tp-sso.local/error?code=403;
  ```

- Pour Rocket.Chat :

  ```conf
  location / {
      auth_request /authelia;
      auth_request_set $target_url $scheme://$http_host$request_uri;
      error_page 401 =302 https://auth.tp-sso.local/?rd=$target_url;
      error_page 403 =302 https://auth.tp-sso.local/error?code=403;

      proxy_pass http://rocketchat:3000;
      proxy_set_header Host $http_host;
      proxy_set_header X-Forwarded-Proto https;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Real-IP $remote_addr;
      }
  ```

Vous trouverez les fichiers de configuration pour chaque proxy dans le dossier `infrastructure/nginx/data/nginx/proxy_host`

---

### Nextcloud - Configuration SSO

Après avoir lancé le docker-compose, ajoutez les lignes suivantes dans le fichier de configuration Nextcloud (`infrastructure/nextcloud/data/config/config.php`) :

```php
  'allow_user_to_change_display_name' => false,
  'lost_password_link' => 'disabled',
  'oidc_login_provider_url' => 'https://auth.tp-sso.local',
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

Pensez bien à modifier l'url d'authélia et à remplacer `insecure_secret` par le secret ainsi qu'à mettre le digest associé dans le fichier de configuration d'Authelia.

Lors de votre prochain passage sur la page de connexion, vous devriez voir un bouton `Log in with Authelia`

---

### Rocket.Chat

1. Ouvrez Rocket.Chat et connectez-vous avec votre compte admin.

2. Allez dans Manage puis Paramètres et cherchez le menu OAuth.

3. Cliquez sur `Ajouter OAuth personalisé` et nommez la `authelia`.

4. Vous devriez avoir une section `Custom OAuth: Authelia` (si non rafraichissez la page).  
  Activez cette méthode de connexion et modifiez les paramètres suivants :

    - URL: `https://auth.tp-sso.local`
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

    Pensez bien à modifier l'url d'authélia et à remplacer `insecure_secret` par le secret ainsi qu'à mettre le digest associé dans le fichier de configuration d'Authelia.

5. Si vous souhaitez lier les rôles Authelia aux rôles Rocket.Chat, activez l'option `Map Roles/Groups to channels` et décrivez le mapping dans le champs `OAuth Group Channel Map` suivant le schémat `"role_authelia": "role_rocketchat"` tel que :

    ```json
    {
      "rocket-admin": "admin",    // Si l'utilisateur à le rôle "rocket-admin" dans Authelia, il aura automatiquement le rôle "admin" dans Rocket.Chat
      "tech-support": "support"
    }
    ```

6. Allez dans Manage puis Paramètres et cherchez le menu Comtpe. Alelz dans la section Authentification à deux facteurs puis désactivez l'option `Activer l'authentification à deux facteurs par e-mail`.

Lors de votre prochain passage sur la page de connexion, vous devriez voir un bouton `Log in with Authelia`

---

### LibreDesk - Configuration SSO

#### Ajout des utilisateurs

LibreDesk ne supportant pas l'auto-providing lors de la connexion via SSO, nous devons ajouter tous les utilisateurs avant de tenter toute connexion.

1. Allez dans les paramètres admin de Libredesk, Teammates puis Agents.

2. Cliquez sur le bouton `import` et séléctionnez le fichier `infrastructure/libredesk/users.csv`.

Vous aurez alors tous vos comptes utilisateur prêt à être utilisé.

#### Mise en place du SSO

1. Allez dans les paramètres admin de LibreDesk, Workplace puis General

2. Remplacez la root URL de LibreDesk par `https://libredesk.tp-sso.local`.

3. Allez dans les paramètres, Security, puis SSO.

4. Cliquez sur `New SSO`, choisissez `Custom` pour le fournisseur puis entrez les informations suivantes :
    - Name: `Autelia`
    - Provider URL: `https://auth.tp-sso.local`
    - Logo URL : `https://www.authelia.com/images/branding/logo-cropped.png`
    - Client ID: `libredesk`
    - Client secret: `insecure_secret`

    Pensez bien à modifier l'url d'authélia et à remplacer `insecure_secret` par le secret ainsi qu'à mettre le digest associé dans le fichier de configuration d'Authelia.

5. Validez en cliquant sur `Save`. LibreDesk va tester la connexion avec le fournisseur d'identité pour valider le SSO.

6. Verifiez que l'adresse de retrour donnée par LibreDesk correspond bien à celle dans la configuration Authelia

## Activation MFA pour les comptes utilisateurs

Lors de la première connexion sur nun compte, Authelia vosu demandera de mettre en place la MFA pour ce compte.  
Lorsque vous choisirerez une méthode, Authelia vous demandera un code qui sera disponible dans le fichier `infrastructure/authelia/notification.txt`.  
Suivez ensuite les étapes relatives à al méthode choisie puis vous pourrez utiliser le compte pour vos connexion aux services.

## Références

- [Documentation Authelia](https://www.authelia.com/configuration/prologue/introduction/)
- [Documentation GitLab](https://docs.gitlab.com/integration/saml/)
- [Documentation Jenkins](https://www.jenkins.io/doc/book/)
- [Documentation Plug-in Jenkins](https://plugins.jenkins.io/oic-auth/)
- [Documentation LibreDesk](https://docs.libredesk.io/introduction)
- [Documentation Nextcloud](https://docs.nextcloud.com/server/stable/admin_manual)
- [Documentation App OIDC Nextcloud](https://apps.nextcloud.com/apps/oidc_login)
- [Documentation Rocket.Chat](https://docs.rocket.chat/docs)
