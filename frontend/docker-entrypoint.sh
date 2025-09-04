#!/bin/sh

# Script d'entrée pour le container Frontend Nginx

set -e

# Génération de certificats SSL auto-signés pour développement/test
if [ ! -f /etc/nginx/ssl/cert.pem ]; then
    echo "Génération de certificats SSL auto-signés..."
    mkdir -p /etc/nginx/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/key.pem \
        -out /etc/nginx/ssl/cert.pem \
        -subj "/C=FR/ST=IDF/L=Malakoff/O=HYGITECH-3D/CN=localhost"
    echo "Certificats SSL générés"
fi

# Création des répertoires de logs si nécessaire
mkdir -p /var/log/nginx
touch /var/log/nginx/access.log
touch /var/log/nginx/error.log

# Test de la configuration Nginx
echo "Test de la configuration Nginx..."
nginx -t

# Démarrage de Nginx
echo "Démarrage de Nginx..."
exec "$@"