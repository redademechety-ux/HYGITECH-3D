#!/bin/bash

# 🚀 Script d'Installation Automatisé HYGITECH-3D
# Usage: ./install-script.sh votre-domaine.com

set -e

# Couleurs pour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN=${1:-""}
APP_DIR="/var/www/hygitech-3d"
APP_USER="hygitech"
MONGO_DB="hygitech3d_production"

# Fonctions utilitaires
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Ce script doit être exécuté en tant que root (sudo)"
        exit 1
    fi
}

check_domain() {
    if [[ -z "$DOMAIN" ]]; then
        log_error "Usage: ./install-script.sh votre-domaine.com"
        exit 1
    fi
    log_info "Installation pour le domaine: $DOMAIN"
}

update_system() {
    log_info "Mise à jour du système..."
    apt update && apt upgrade -y
    apt install -y curl wget git nginx software-properties-common ufw
    log_success "Système mis à jour"
}

create_user() {
    log_info "Création de l'utilisateur $APP_USER..."
    if ! id "$APP_USER" &>/dev/null; then
        useradd -m -s /bin/bash $APP_USER
        usermod -aG sudo $APP_USER
        log_success "Utilisateur $APP_USER créé"
    else
        log_warning "Utilisateur $APP_USER existe déjà"
    fi
}

install_nodejs() {
    log_info "Installation de Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
    
    log_info "Installation de Yarn..."
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
    apt update && apt install -y yarn
    
    log_info "Installation de PM2..."
    npm install -g pm2
    
    log_success "Node.js, Yarn et PM2 installés"
}

install_python() {
    log_info "Installation de Python 3 et pip..."
    apt install -y python3 python3-pip python3-venv
    pip3 install --upgrade pip
    log_success "Python installé"
}

install_mongodb() {
    log_info "Installation de MongoDB..."
    wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-5.0.list
    apt update
    apt install -y mongodb-org
    
    systemctl start mongod
    systemctl enable mongod
    
    # Test MongoDB
    if systemctl is-active --quiet mongod; then
        log_success "MongoDB installé et démarré"
    else
        log_error "Échec du démarrage de MongoDB"
        exit 1
    fi
}

setup_application() {
    log_info "Configuration de l'application..."
    
    # Création du répertoire
    mkdir -p $APP_DIR
    chown $APP_USER:$APP_USER $APP_DIR
    
    # Note: Ici vous devrez adapter selon votre méthode de déploiement
    # Option 1: Clone depuis Git (remplacer par votre repo)
    # cd $APP_DIR
    # git clone https://github.com/votre-username/hygitech-3d .git .
    
    # Option 2: Copie depuis le répertoire actuel (pour test local)
    if [[ -f "/app/frontend/package.json" ]]; then
        log_info "Copie des fichiers depuis /app..."
        cp -r /app/frontend $APP_DIR/
        cp -r /app/backend $APP_DIR/
        chown -R $APP_USER:$APP_USER $APP_DIR
    else
        log_warning "Fichiers source non trouvés. Vous devrez copier manuellement votre code dans $APP_DIR"
    fi
    
    log_success "Répertoire d'application configuré"
}

setup_backend() {
    log_info "Configuration du backend..."
    
    cd $APP_DIR/backend
    
    # Création environnement virtuel Python
    sudo -u $APP_USER python3 -m venv venv
    sudo -u $APP_USER bash -c "source venv/bin/activate && pip install -r requirements.txt"
    
    # Configuration .env
    cat > .env << EOF
MONGO_URL=mongodb://localhost:27017
DB_NAME=$MONGO_DB
ENVIRONMENT=production
EOF
    
    chown $APP_USER:$APP_USER .env
    log_success "Backend configuré"
}

setup_frontend() {
    log_info "Configuration du frontend..."
    
    cd $APP_DIR/frontend
    
    # Configuration .env.production
    cat > .env.production << EOF
REACT_APP_BACKEND_URL=https://$DOMAIN
EOF
    
    # Installation et build
    sudo -u $APP_USER yarn install
    sudo -u $APP_USER yarn build
    
    chown -R $APP_USER:$APP_USER .
    log_success "Frontend configuré et compilé"
}

setup_nginx() {
    log_info "Configuration de Nginx..."
    
    cat > /etc/nginx/sites-available/hygitech-3d << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Frontend (React)
    location / {
        root $APP_DIR/frontend/build;
        index index.html;
        try_files \$uri \$uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # Backend API
    location /api {
        proxy_pass http://localhost:8001;
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
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
}
EOF
    
    # Activation du site
    ln -sf /etc/nginx/sites-available/hygitech-3d /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test configuration
    if nginx -t; then
        systemctl reload nginx
        log_success "Nginx configuré"
    else
        log_error "Erreur de configuration Nginx"
        exit 1
    fi
}

setup_pm2() {
    log_info "Configuration de PM2..."
    
    mkdir -p $APP_DIR/logs
    
    cat > $APP_DIR/ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'hygitech-backend',
    script: 'venv/bin/uvicorn',
    args: 'server:app --host 0.0.0.0 --port 8001',
    cwd: '$APP_DIR/backend',
    instances: 2,
    exec_mode: 'cluster',
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
    
    # Démarrage PM2 en tant qu'utilisateur app
    cd $APP_DIR
    sudo -u $APP_USER pm2 start ecosystem.config.js
    sudo -u $APP_USER pm2 startup systemd -u $APP_USER
    sudo -u $APP_USER pm2 save
    
    log_success "PM2 configuré et services démarrés"
}

setup_ssl() {
    log_info "Installation de Certbot pour SSL..."
    apt install -y certbot python3-certbot-nginx
    
    log_info "Obtention du certificat SSL pour $DOMAIN..."
    certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN
    
    # Test renouvellement
    certbot renew --dry-run
    
    log_success "SSL configuré avec Let's Encrypt"
}

setup_firewall() {
    log_info "Configuration du firewall..."
    ufw --force reset
    ufw allow ssh
    ufw allow 'Nginx Full' 
    ufw --force enable
    log_success "Firewall configuré"
}

create_scripts() {
    log_info "Création des scripts de maintenance..."
    
    mkdir -p $APP_DIR/scripts
    
    # Script de sauvegarde
    cat > $APP_DIR/scripts/backup-mongo.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p /var/backups/mongodb
mongodump --db hygitech3d_production --out /var/backups/mongodb/$DATE
find /var/backups/mongodb/ -mtime +7 -delete
echo "Sauvegarde MongoDB créée: $DATE"
EOF
    
    # Script de déploiement
    cat > $APP_DIR/scripts/deploy.sh << EOF
#!/bin/bash
cd $APP_DIR

echo "🔄 Démarrage du déploiement..."

# Sauvegarde avant mise à jour
./scripts/backup-mongo.sh

# Pull des changements (si Git)
# git pull origin main

# Mise à jour backend
cd backend
source venv/bin/activate
pip install -r requirements.txt

# Mise à jour frontend
cd ../frontend
yarn install
yarn build

# Redémarrage services
sudo -u $APP_USER pm2 restart all
sudo systemctl reload nginx

echo "✅ Déploiement terminé avec succès !"
EOF
    
    chmod +x $APP_DIR/scripts/*.sh
    chown -R $APP_USER:$APP_USER $APP_DIR/scripts
    
    # Cron pour sauvegarde quotidienne
    (sudo -u $APP_USER crontab -l 2>/dev/null; echo "0 2 * * * $APP_DIR/scripts/backup-mongo.sh") | sudo -u $APP_USER crontab -
    
    log_success "Scripts de maintenance créés"
}

run_tests() {
    log_info "Tests de vérification..."
    
    # Test MongoDB
    if mongo --eval "db.adminCommand('ismaster')" > /dev/null 2>&1; then
        log_success "✅ MongoDB fonctionne"
    else
        log_error "❌ MongoDB ne répond pas"
    fi
    
    # Test Backend
    sleep 5  # Attendre démarrage PM2
    if curl -f http://localhost:8001/api/ > /dev/null 2>&1; then
        log_success "✅ Backend fonctionne"
    else
        log_warning "⚠️  Backend pourrait avoir besoin de quelques secondes pour démarrer"
    fi
    
    # Test Nginx
    if curl -f http://localhost/ > /dev/null 2>&1; then
        log_success "✅ Nginx sert le frontend"
    else
        log_error "❌ Problème avec Nginx"
    fi
    
    # Test SSL (si domaine public)
    if curl -f https://$DOMAIN/ > /dev/null 2>&1; then
        log_success "✅ SSL fonctionne"
    else
        log_warning "⚠️  SSL pourrait ne pas être accessible (DNS/domaine)"
    fi
}

# MAIN EXECUTION

echo "🚀 Installation HYGITECH-3D - Script Automatisé"
echo "================================================"

check_root
check_domain

log_info "Début de l'installation pour $DOMAIN..."

update_system
create_user
install_nodejs
install_python
install_mongodb
setup_application
setup_backend
setup_frontend
setup_nginx
setup_pm2
setup_ssl
setup_firewall
create_scripts

log_success "🎉 Installation terminée avec succès !"

echo ""
echo "📋 RÉSUMÉ DE L'INSTALLATION"
echo "=========================="
echo "🌐 Site web: https://$DOMAIN"
echo "📁 Répertoire app: $APP_DIR"
echo "👤 Utilisateur app: $APP_USER"
echo "🗄️ Base de données: $MONGO_DB"
echo ""
echo "🔧 COMMANDES UTILES"
echo "==================="
echo "# Status des services:"
echo "sudo systemctl status mongod nginx"
echo "sudo -u $APP_USER pm2 status"
echo ""
echo "# Logs:"
echo "sudo -u $APP_USER pm2 logs"
echo "sudo tail -f /var/log/nginx/error.log"
echo ""
echo "# Redémarrage:"
echo "$APP_DIR/scripts/deploy.sh"
echo ""
echo "# Sauvegarde:"
echo "$APP_DIR/scripts/backup-mongo.sh"

run_tests

log_success "✅ Votre site HYGITECH-3D est maintenant en ligne !"
log_info "N'oubliez pas de configurer vos DNS pour pointer vers ce serveur"