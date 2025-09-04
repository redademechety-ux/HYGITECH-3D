#!/bin/bash

# 🚀 Script d'Installation Multi-Sites
# Usage: ./install-multi-sites.sh site-name domaine.com port-backend

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SITE_NAME=${1:-""}
DOMAIN=${2:-""}
BACKEND_PORT=${3:-""}
APP_DIR="/var/www/${SITE_NAME}"
APP_USER="web-${SITE_NAME}"
MONGO_DB="${SITE_NAME//-/_}_production"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_params() {
    if [[ -z "$SITE_NAME" || -z "$DOMAIN" || -z "$BACKEND_PORT" ]]; then
        log_error "Usage: ./install-multi-sites.sh site-name domaine.com port-backend"
        log_error "Exemple: ./install-multi-sites.sh hygitech-3d hygitech-3d.com 8001"
        log_error "         ./install-multi-sites.sh mon-site2 mon-site2.com 8002"
        exit 1
    fi
    
    # Vérifier que le port n'est pas déjà utilisé
    if netstat -tuln | grep -q ":${BACKEND_PORT} "; then
        log_error "Port $BACKEND_PORT déjà utilisé !"
        exit 1
    fi
    
    log_info "Installation du site: $SITE_NAME sur $DOMAIN (port $BACKEND_PORT)"
}

install_dependencies_once() {
    # Vérifier si déjà installé
    if command -v node &> /dev/null && command -v python3 &> /dev/null && systemctl is-active --quiet mongod; then
        log_info "Dépendances déjà installées, on passe..."
        return
    fi
    
    log_info "Installation des dépendances système (une seule fois)..."
    apt update && apt upgrade -y
    apt install -y curl wget git nginx software-properties-common ufw
    
    # Node.js
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
    apt update && apt install -y yarn
    npm install -g pm2
    
    # Python
    apt install -y python3 python3-pip python3-venv
    
    # MongoDB (une seule instance partagée)
    if ! systemctl is-active --quiet mongod; then
        wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | apt-key add -
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-5.0.list
        apt update && apt install -y mongodb-org
        systemctl start mongod
        systemctl enable mongod
    fi
    
    log_success "Dépendances installées"
}

setup_site() {
    log_info "Configuration du site $SITE_NAME..."
    
    # Utilisateur dédié par site
    if ! id "$APP_USER" &>/dev/null; then
        useradd -m -s /bin/bash $APP_USER
        usermod -aG sudo $APP_USER
    fi
    
    # Répertoire du site
    mkdir -p $APP_DIR
    chown $APP_USER:$APP_USER $APP_DIR
    
    log_success "Site $SITE_NAME configuré"
}

setup_backend() {
    log_info "Configuration backend pour $SITE_NAME (port $BACKEND_PORT)..."
    
    cd $APP_DIR/backend
    
    # Environnement virtuel Python
    sudo -u $APP_USER python3 -m venv venv
    sudo -u $APP_USER bash -c "source venv/bin/activate && pip install -r requirements.txt"
    
    # Configuration .env avec port personnalisé
    cat > .env << EOF
MONGO_URL=mongodb://localhost:27017
DB_NAME=$MONGO_DB
ENVIRONMENT=production
PORT=$BACKEND_PORT
EOF
    
    chown $APP_USER:$APP_USER .env
    log_success "Backend $SITE_NAME configuré sur port $BACKEND_PORT"
}

setup_frontend() {
    log_info "Configuration frontend pour $SITE_NAME..."
    
    cd $APP_DIR/frontend
    
    # Configuration avec bon backend URL
    cat > .env.production << EOF
REACT_APP_BACKEND_URL=https://$DOMAIN
EOF
    
    sudo -u $APP_USER yarn install
    sudo -u $APP_USER yarn build
    
    chown -R $APP_USER:$APP_USER .
    log_success "Frontend $SITE_NAME configuré"
}

setup_pm2() {
    log_info "Configuration PM2 pour $SITE_NAME..."
    
    mkdir -p $APP_DIR/logs
    
    cat > $APP_DIR/ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: '${SITE_NAME}-backend',
    script: 'venv/bin/uvicorn',
    args: 'server:app --host 0.0.0.0 --port $BACKEND_PORT',
    cwd: '$APP_DIR/backend',
    instances: 1,
    env: {
      NODE_ENV: 'production'
    },
    error_file: '$APP_DIR/logs/backend-error.log',
    out_file: '$APP_DIR/logs/backend-out.log',
    log_file: '$APP_DIR/logs/backend-combined.log'
  }]
}
EOF
    
    chown -R $APP_USER:$APP_USER $APP_DIR/logs
    chown $APP_USER:$APP_USER $APP_DIR/ecosystem.config.js
    
    # Démarrage PM2
    cd $APP_DIR
    sudo -u $APP_USER pm2 start ecosystem.config.js
    sudo -u $APP_USER pm2 save
    
    log_success "PM2 configuré pour $SITE_NAME"
}

update_nginx() {
    log_info "Mise à jour configuration Nginx pour $SITE_NAME..."
    
    # Configuration spécifique au site
    cat > /etc/nginx/sites-available/$SITE_NAME << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    # SSL sera configuré par Certbot
    
    # Frontend
    location / {
        root $APP_DIR/frontend/build;
        index index.html;
        try_files \$uri \$uri/ /index.html;
        
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # Backend API
    location /api {
        proxy_pass http://localhost:$BACKEND_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
}
EOF
    
    # Activation du site
    ln -sf /etc/nginx/sites-available/$SITE_NAME /etc/nginx/sites-enabled/
    
    # Test et reload
    nginx -t && systemctl reload nginx
    
    log_success "Nginx mis à jour pour $SITE_NAME"
}

setup_ssl() {
    log_info "Configuration SSL pour $DOMAIN..."
    
    # Installation Certbot si pas déjà fait
    if ! command -v certbot &> /dev/null; then
        apt install -y certbot python3-certbot-nginx
    fi
    
    # Certificat pour ce domaine
    certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN
    
    log_success "SSL configuré pour $DOMAIN"
}

# MAIN EXECUTION
echo "🚀 Installation Multi-Sites - $SITE_NAME"
echo "========================================"

check_params
install_dependencies_once
setup_site
setup_backend  
setup_frontend
setup_pm2
update_nginx
setup_ssl

log_success "🎉 Site $SITE_NAME installé avec succès !"
log_info "Accessible sur: https://$DOMAIN"
log_info "Backend sur port: $BACKEND_PORT"
log_info "Processus PM2: ${SITE_NAME}-backend"

echo ""
echo "Pour installer un autre site:"
echo "./install-multi-sites.sh mon-site2 mon-site2.com 8002"