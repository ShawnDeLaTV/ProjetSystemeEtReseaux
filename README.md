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



