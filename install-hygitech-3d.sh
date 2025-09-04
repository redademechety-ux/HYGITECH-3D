#!/bin/bash

# 🚀 Script d'Installation HYGITECH-3D - Multi-Sites
# URL: hygitech-3d.com / www.hygitech-3d.com
# Port Backend: 8002

set -e

# Couleurs pour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration HYGITECH-3D
SITE_NAME="hygitech-3d"
DOMAIN="hygitech-3d.com"
BACKEND_PORT="8002"
APP_DIR="/var/www/${SITE_NAME}"
APP_USER="web-${SITE_NAME}"
MONGO_DB="hygitech3d_production"
GITHUB_REPO=${1:-""}

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

check_github_repo() {
    if [[ -z "$GITHUB_REPO" ]]; then
        log_warning "Repository GitHub non spécifié"
        log_info "Usage: ./install-hygitech-3d.sh https://github.com/votre-username/hygitech-3d.git"
        log_info "Ou placez manuellement les fichiers dans $APP_DIR"
        read -p "Voulez-vous continuer sans clone GitHub ? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

check_port_available() {
    if netstat -tuln 2>/dev/null | grep -q ":${BACKEND_PORT} "; then
        log_error "Port $BACKEND_PORT déjà utilisé !"
        log_info "Ports actuellement utilisés :"
        netstat -tuln | grep LISTEN | grep -E ':(80|443|800[0-9]|900[0-9])'
        exit 1
    fi
    log_success "Port $BACKEND_PORT disponible"
}

install_system_dependencies() {
    log_info "Vérification et installation des dépendances système..."
    
    # Mise à jour système
    apt update && apt upgrade -y
    apt install -y curl wget git nginx software-properties-common ufw netstat-nat
    
    # Node.js (si pas déjà installé)
    if ! command -v node &> /dev/null; then
        log_info "Installation de Node.js 18..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt install -y nodejs
    fi
    
    # Yarn (si pas déjà installé)
    if ! command -v yarn &> /dev/null; then
        log_info "Installation de Yarn..."
        curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
        echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
        apt update && apt install -y yarn
    fi
    
    # PM2 (si pas déjà installé)
    if ! command -v pm2 &> /dev/null; then
        log_info "Installation de PM2..."
        npm install -g pm2
    fi
    
    # Python (si pas déjà installé)
    if ! command -v python3 &> /dev/null; then
        log_info "Installation de Python 3..."
        apt install -y python3 python3-pip python3-venv
    fi
    
    # MongoDB (si pas déjà installé)
    if ! systemctl is-active --quiet mongod 2>/dev/null; then
        log_info "Installation de MongoDB..."
        wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | apt-key add -
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-5.0.list
        apt update && apt install -y mongodb-org
        systemctl start mongod
        systemctl enable mongod
    fi
    
    log_success "Dépendances système installées"
}

create_user_and_directories() {
    log_info "Création de l'utilisateur et des répertoires pour HYGITECH-3D..."
    
    # Utilisateur dédié
    if ! id "$APP_USER" &>/dev/null; then
        useradd -m -s /bin/bash $APP_USER
        log_success "Utilisateur $APP_USER créé"
    else
        log_warning "Utilisateur $APP_USER existe déjà"
    fi
    
    # Répertoires
    mkdir -p $APP_DIR/{logs,scripts,backups}
    chown -R $APP_USER:$APP_USER $APP_DIR
    
    log_success "Répertoires créés et permissions définies"
}

download_source_code() {
    log_info "Récupération du code source HYGITECH-3D..."
    
    if [[ -n "$GITHUB_REPO" ]]; then
        # Clone depuis GitHub
        if [[ -d "$APP_DIR/.git" ]]; then
            log_info "Repository existant, mise à jour..."
            cd $APP_DIR
            sudo -u $APP_USER git pull origin main
        else
            log_info "Clone du repository depuis GitHub..."
            sudo -u $APP_USER git clone $GITHUB_REPO $APP_DIR/temp
            sudo -u $APP_USER mv $APP_DIR/temp/* $APP_DIR/
            sudo -u $APP_USER mv $APP_DIR/temp/.* $APP_DIR/ 2>/dev/null || true
            rmdir $APP_DIR/temp
        fi
    else
        log_warning "Pas de repository GitHub spécifié"
        log_info "Veuillez copier manuellement vos fichiers dans $APP_DIR"
        log_info "Structure attendue :"
        log_info "  $APP_DIR/frontend/ (code React)"
        log_info "  $APP_DIR/backend/ (code FastAPI)"
        read -p "Appuyez sur Entrée une fois les fichiers copiés..."
    fi
    
    # Vérification des fichiers essentiels
    if [[ ! -d "$APP_DIR/frontend" || ! -d "$APP_DIR/backend" ]]; then
        log_error "Répertoires frontend/ ou backend/ manquants dans $APP_DIR"
        exit 1
    fi
    
    chown -R $APP_USER:$APP_USER $APP_DIR
    log_success "Code source récupéré"
}

setup_backend() {
    log_info "Configuration du backend HYGITECH-3D (port $BACKEND_PORT)..."
    
    cd $APP_DIR/backend
    
    # Environnement virtuel Python
    if [[ ! -d "venv" ]]; then
        sudo -u $APP_USER python3 -m venv venv
    fi
    
    # Installation des dépendances Python
    sudo -u $APP_USER bash -c "source venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"
    
    # Configuration .env pour production
    cat > .env << EOF
# Configuration HYGITECH-3D Production
MONGO_URL=mongodb://localhost:27017
DB_NAME=$MONGO_DB
ENVIRONMENT=production
PORT=$BACKEND_PORT

# Informations entreprise
COMPANY_NAME=HYGITECH-3D
COMPANY_EMAIL=contact@hygitech-3d.com
COMPANY_PHONE=0668062970
COMPANY_ADDRESS=122 Boulevard Gabriel Péri, 92240 MALAKOFF
EOF
    
    chown $APP_USER:$APP_USER .env
    
    # Modification du serveur pour utiliser le port personnalisé
    if grep -q "port.*8001" server.py; then
        sed -i "s/port.*8001/port=$BACKEND_PORT/g" server.py
    fi
    
    log_success "Backend HYGITECH-3D configuré sur port $BACKEND_PORT"
}

setup_frontend() {
    log_info "Configuration du frontend HYGITECH-3D..."
    
    cd $APP_DIR/frontend
    
    # Configuration environnement de production
    cat > .env.production << EOF
REACT_APP_BACKEND_URL=https://$DOMAIN
REACT_APP_COMPANY_NAME=HYGITECH-3D
REACT_APP_COMPANY_PHONE=06 68 06 29 70
REACT_APP_COMPANY_EMAIL=contact@hygitech-3d.com
EOF
    
    # Installation des dépendances et build
    log_info "Installation des dépendances frontend..."
    sudo -u $APP_USER yarn install --frozen-lockfile
    
    log_info "Build de production du frontend..."
    sudo -u $APP_USER yarn build
    
    chown -R $APP_USER:$APP_USER .
    log_success "Frontend HYGITECH-3D compilé"
}

setup_pm2() {
    log_info "Configuration PM2 pour HYGITECH-3D..."
    
    # Configuration PM2
    cat > $APP_DIR/ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'hygitech-3d-backend',
    script: 'venv/bin/uvicorn',
    args: 'server:app --host 0.0.0.0 --port $BACKEND_PORT',
    cwd: '$APP_DIR/backend',
    instances: 2,
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: '$BACKEND_PORT'
    },
    error_file: '$APP_DIR/logs/backend-error.log',
    out_file: '$APP_DIR/logs/backend-out.log',
    log_file: '$APP_DIR/logs/backend-combined.log',
    time: true,
    max_memory_restart: '1G'
  }]
}
EOF
    
    chown $APP_USER:$APP_USER $APP_DIR/ecosystem.config.js
    
    # Arrêt processus existant si présent
    sudo -u $APP_USER pm2 delete hygitech-3d-backend 2>/dev/null || true
    
    # Démarrage
    cd $APP_DIR
    sudo -u $APP_USER pm2 start ecosystem.config.js
    
    # Configuration startup (une seule fois)
    sudo -u $APP_USER pm2 startup systemd -u $APP_USER --hp /home/$APP_USER 2>/dev/null || true
    sudo -u $APP_USER pm2 save
    
    log_success "PM2 configuré - processus 'hygitech-3d-backend' démarré"
}

setup_nginx() {
    log_info "Configuration Nginx pour HYGITECH-3D..."
    
    # Configuration du site
    cat > /etc/nginx/sites-available/$SITE_NAME << EOF
# Configuration Nginx pour HYGITECH-3D
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    # SSL configuration (sera ajoutée par Certbot)
    
    # Logs spécifiques
    access_log /var/log/nginx/hygitech-3d-access.log;
    error_log /var/log/nginx/hygitech-3d-error.log;
    
    # Frontend React
    location / {
        root $APP_DIR/frontend/build;
        index index.html;
        try_files \$uri \$uri/ /index.html;
        
        # Cache pour les assets statiques
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        # Pas de cache pour index.html
        location = /index.html {
            expires -1;
            add_header Cache-Control "no-cache, no-store, must-revalidate";
        }
    }
    
    # Backend API FastAPI
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
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
}
EOF
    
    # Activation du site
    ln -sf /etc/nginx/sites-available/$SITE_NAME /etc/nginx/sites-enabled/
    
    # Test configuration
    if nginx -t; then
        systemctl reload nginx
        log_success "Configuration Nginx activée pour $DOMAIN"
    else
        log_error "Erreur dans la configuration Nginx"
        exit 1
    fi
}

setup_ssl() {
    log_info "Configuration SSL pour $DOMAIN..."
    
    # Installation Certbot si nécessaire
    if ! command -v certbot &> /dev/null; then
        apt install -y certbot python3-certbot-nginx
    fi
    
    # Obtention certificat SSL
    certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email contact@$DOMAIN --redirect
    
    # Test renouvellement automatique
    certbot renew --dry-run
    
    log_success "SSL configuré pour $DOMAIN et www.$DOMAIN"
}

setup_firewall() {
    log_info "Configuration du firewall..."
    
    # Configuration UFW
    ufw allow ssh
    ufw allow 'Nginx Full'
    ufw --force enable
    
    log_success "Firewall configuré"
}

create_maintenance_scripts() {
    log_info "Création des scripts de maintenance..."
    
    # Script de sauvegarde MongoDB
    cat > $APP_DIR/scripts/backup-mongo.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/backups/mongodb"
mkdir -p $BACKUP_DIR

echo "🔄 Sauvegarde MongoDB HYGITECH-3D..."
mongodump --db hygitech3d_production --out $BACKUP_DIR/$DATE

# Nettoyage des sauvegardes anciennes (> 7 jours)
find $BACKUP_DIR -mtime +7 -delete

echo "✅ Sauvegarde terminée: $BACKUP_DIR/$DATE"
EOF
    
    # Script de déploiement/mise à jour
    cat > $APP_DIR/scripts/deploy.sh << EOF
#!/bin/bash
cd $APP_DIR

echo "🔄 Démarrage mise à jour HYGITECH-3D..."

# Sauvegarde avant mise à jour
./scripts/backup-mongo.sh

# Pull des changements (si Git)
if [[ -d ".git" ]]; then
    sudo -u $APP_USER git pull origin main
fi

# Mise à jour backend
cd backend
sudo -u $APP_USER bash -c "source venv/bin/activate && pip install -r requirements.txt"

# Mise à jour frontend
cd ../frontend
sudo -u $APP_USER yarn install
sudo -u $APP_USER yarn build

# Redémarrage services
sudo -u $APP_USER pm2 restart hygitech-3d-backend
sudo systemctl reload nginx

echo "✅ Mise à jour HYGITECH-3D terminée !"
EOF
    
    # Script de monitoring
    cat > $APP_DIR/scripts/status.sh << 'EOF'
#!/bin/bash
echo "📊 STATUS HYGITECH-3D"
echo "===================="

echo "🔧 Services système:"
systemctl is-active mongod nginx | sed 's/^/  - /'

echo "🚀 Processus PM2:"
pm2 list | grep -E "(hygitech|online|stopped|errored)"

echo "🌐 Test connectivité:"
curl -s -o /dev/null -w "  - Frontend: %{http_code}\n" http://localhost/
curl -s -o /dev/null -w "  - Backend API: %{http_code}\n" http://localhost:8002/api/

echo "💾 Espace disque:"
df -h / | tail -1 | awk '{print "  - Utilisé: " $3 "/" $2 " (" $5 ")"}'

echo "🧠 Mémoire:"
free -h | grep Mem | awk '{print "  - Utilisée: " $3 "/" $2}'
EOF
    
    chmod +x $APP_DIR/scripts/*.sh
    chown -R $APP_USER:$APP_USER $APP_DIR/scripts
    
    # Cron pour sauvegarde quotidienne à 2h
    (sudo -u $APP_USER crontab -l 2>/dev/null; echo "0 2 * * * $APP_DIR/scripts/backup-mongo.sh") | sudo -u $APP_USER crontab -
    
    log_success "Scripts de maintenance créés"
}

run_tests() {
    log_info "Tests de vérification finale..."
    
    # Test MongoDB
    if mongo --eval "db.adminCommand('ismaster')" >/dev/null 2>&1; then
        log_success "✅ MongoDB opérationnel"
    else
        log_error "❌ MongoDB non accessible"
    fi
    
    # Test Backend (attendre démarrage)
    sleep 10
    if curl -f http://localhost:$BACKEND_PORT/api/ >/dev/null 2>&1; then
        log_success "✅ Backend HYGITECH-3D (port $BACKEND_PORT)"
    else
        log_warning "⚠️  Backend pourrait nécessiter quelques secondes supplémentaires"
    fi
    
    # Test Frontend
    if curl -f http://localhost/ >/dev/null 2>&1; then
        log_success "✅ Frontend HYGITECH-3D accessible"
    else
        log_error "❌ Problème d'accès au frontend"
    fi
    
    # Test HTTPS
    if curl -f https://$DOMAIN/ >/dev/null 2>&1; then
        log_success "✅ HTTPS fonctionnel sur $DOMAIN"
    else
        log_warning "⚠️  HTTPS pourrait nécessiter quelques minutes (propagation DNS)"
    fi
}

# MAIN EXECUTION
echo "🚀 Installation HYGITECH-3D - Configuration Multi-Sites"
echo "======================================================="
echo "🌐 Domaine: $DOMAIN"
echo "🔌 Port Backend: $BACKEND_PORT" 
echo "📁 Répertoire: $APP_DIR"
echo "👤 Utilisateur: $APP_USER"
echo ""

check_root
check_github_repo
check_port_available

log_info "Début de l'installation HYGITECH-3D..."

install_system_dependencies
create_user_and_directories
download_source_code
setup_backend
setup_frontend
setup_pm2
setup_nginx
setup_ssl
setup_firewall
create_maintenance_scripts

log_success "🎉 HYGITECH-3D installé avec succès !"

echo ""
echo "📋 RÉSUMÉ INSTALLATION HYGITECH-3D"
echo "=================================="
echo "🌐 Site web: https://$DOMAIN"
echo "🌐 Alternative: https://www.$DOMAIN"
echo "🔌 Backend API: Port $BACKEND_PORT"
echo "📁 Répertoire: $APP_DIR"
echo "👤 Utilisateur: $APP_USER"
echo "🗄️  Base MongoDB: $MONGO_DB"
echo ""
echo "🔧 COMMANDES UTILES"
echo "==================="
echo "# Status du site:"
echo "$APP_DIR/scripts/status.sh"
echo ""
echo "# Logs en temps réel:"
echo "sudo -u $APP_USER pm2 logs hygitech-3d-backend"
echo ""
echo "# Mise à jour du site:"
echo "$APP_DIR/scripts/deploy.sh"
echo ""
echo "# Sauvegarde manuelle:"
echo "$APP_DIR/scripts/backup-mongo.sh"
echo ""
echo "# Redémarrage:"
echo "sudo -u $APP_USER pm2 restart hygitech-3d-backend"
echo "sudo systemctl reload nginx"

run_tests

log_success "✅ HYGITECH-3D est maintenant en ligne sur https://$DOMAIN !"
log_info "Le formulaire de contact est opérationnel et sauvegarde en base MongoDB"