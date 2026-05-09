#!/bin/bash

echo " --- Script de configuration de l'infrastructure ---"

# --- CA ---
echo "--> Création de la CA"
# Crée le dossier pour la CA
mkdir ./certificats/ca
# Génère une clé privée pour la CA
openssl genrsa -out "./certificats/ca/ca.key" 4096
# Crée un certificat auto-signé pour la CA
openssl req -x509 -new -nodes -key "./certificats/ca/ca.key" -sha256 -days 3650 -out "./certificats/ca/ca.crt" -subj "//C=CA/ST=Quebec/O=MonOrg/CN=MonOrg-RootCA"
# Copie le certificat dans les dossier de Jenkins et Nextcloud
cp ./certificats/ca/ca.crt ./infrastructure/Jenkins
cp ./certificats/ca/ca.crt ./infrastructure/nextcloud/before-starting
echo "--> CA OK"

# --- Certificat serveur ---
echo "--> Création du certificat serveur"
# Génère une clé privée pour le serveur Nginx
openssl genrsa -out "./certificats/wildcard/wildcard.key" 2048
# Crée une CSR (Certificate Signing Request)
openssl req -new -key "./certificats/wildcard/wildcard.key" -out "./certificats/wildcard/wildcard.csr" -config "./certificats/wildcard/wildcard.cnf"
# Transforme la CSR en certificat signé par la CA
openssl x509 -req -in "./certificats/wildcard/wildcard.csr" -CA "./certificats/ca/ca.crt" -CAkey "./certificats/ca/ca.key" -CAcreateserial -out "./certificats/wildcard/wildcard.crt" -days 825 -sha256 -extfile "./certificats/wildcard/wildcard.cnf" -extensions v3_req
echo "--> Certificat serveur OK"

# --- Clé pour Authelia --- 
echo "--> Création de la clé pour Authelia"
# Crée le dossier pour stocker la clé
mkdir ./infrastructure/authelia/jwks
# Génère la clé privée qui sera utilsiée par Authelia
openssl genrsa -out "./infrastructure/authelia/jwks/private.pem" 4096
echo "--> Clé pour Authelia OK"

# --- Scruipt Nextcloud ---
echo "--> Formatage du script Nextcloud"
dos2unix ./infrastructure/nextcloud/before-starting/setup.sh
echo "--> Script Nextcloud OK"

