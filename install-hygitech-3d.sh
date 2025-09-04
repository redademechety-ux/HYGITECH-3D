#!/bin/bash

# 🚀 Script d'Installation HYGITECH-3D - Version Corrigée Ubuntu 22.04+
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
    if [[ -n "$GITHUB_REPO" ]]; then
        log_info "Test de connectivité au repository GitHub..."
        if curl -s --head --max-time 10 "$GITHUB_REPO" | grep -q "200 OK"; then
            log_success "Repository GitHub accessible"
        else
            log_warning "Repository GitHub non accessible, passage en mode manuel"
            GITHUB_REPO=""
        fi
    fi
    
    if [[ -z "$GITHUB_REPO" ]]; then
        log_warning "Mode installation manuelle activé"
        log_info "Les fichiers doivent être placés dans $APP_DIR"
    fi
}

check_port_available() {
    if ss -tuln 2>/dev/null | grep -q ":${BACKEND_PORT} " || netstat -tuln 2>/dev/null | grep -q ":${BACKEND_PORT} "; then
        log_error "Port $BACKEND_PORT déjà utilisé !"
        exit 1
    fi
    log_success "Port $BACKEND_PORT disponible"
}

install_system_dependencies() {
    log_info "Installation des dépendances système (méthode moderne)..."
    
    # Mise à jour système
    apt update && apt upgrade -y
    apt install -y curl wget git nginx software-properties-common ufw ca-certificates gnupg lsb-release apt-transport-https
    
    # Créer le répertoire pour les clés GPG
    mkdir -p /etc/apt/keyrings
    
    # Installation Node.js 18 (méthode moderne)
    if ! command -v node &> /dev/null; then
        log_info "Installation de Node.js 18..."
        
        # Téléchargement et installation de la clé GPG NodeSource
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
        
        # Ajout du repository NodeSource
        NODE_MAJOR=18
        echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
        
        apt update && apt install -y nodejs
        
        # Vérification
        node --version && npm --version
        log_success "Node.js $(node --version) installé"
    else
        log_success "Node.js déjà installé: $(node --version)"
    fi
    
    # Installation Yarn (méthode moderne)
    if ! command -v yarn &> /dev/null; then
        log_info "Installation de Yarn..."
        
        # Nettoyage des anciennes installations
        apt remove -y yarn 2>/dev/null || true
        
        # Méthode moderne pour Yarn
        curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /etc/apt/keyrings/yarn.gpg
        echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
        
        apt update && apt install -y yarn
        
        # Vérification
        yarn --version
        log_success "Yarn $(yarn --version) installé"
    else
        log_success "Yarn déjà installé: $(yarn --version)"
    fi
    
    # Installation PM2
    if ! command -v pm2 &> /dev/null; then
        log_info "Installation de PM2..."
        npm install -g pm2
        log_success "PM2 installé"
    else
        log_success "PM2 déjà installé"
    fi
    
    # Installation Python
    if ! command -v python3 &> /dev/null; then
        log_info "Installation de Python 3..."
        apt install -y python3 python3-pip python3-venv python3-dev
        log_success "Python installé"
    else
        log_success "Python déjà installé: $(python3 --version)"
    fi
    
    # Installation MongoDB (méthode moderne)
    if ! systemctl is-active --quiet mongod 2>/dev/null; then
        log_info "Installation de MongoDB 6.0..."
        
        # Nettoyage des anciennes clés
        rm -f /etc/apt/keyrings/mongodb-server-*.gpg
        
        # Installation de la clé GPG MongoDB
        curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | gpg --dearmor -o /etc/apt/keyrings/mongodb-server-6.0.gpg
        
        # Ajout du repository MongoDB
        echo "deb [ arch=amd64,arm64 signed-by=/etc/apt/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/6.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-6.0.list
        
        apt update && apt install -y mongodb-org
        
        # Configuration et démarrage
        systemctl start mongod
        systemctl enable mongod
        
        # Attendre que MongoDB soit prêt
        sleep 10
        
        # Test de MongoDB
        if systemctl is-active --quiet mongod; then
            log_success "MongoDB installé et démarré"
        else
            log_error "Problème avec MongoDB"
            systemctl status mongod
            exit 1
        fi
    else
        log_success "MongoDB déjà installé et actif"
    fi
    
    log_success "Toutes les dépendances système sont installées"
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
            sudo -u $APP_USER git pull origin main || sudo -u $APP_USER git pull origin master
        else
            log_info "Clone du repository depuis GitHub..."
            # Clone directement dans le répertoire cible
            sudo -u $APP_USER git clone $GITHUB_REPO $APP_DIR/temp
            if [[ $? -eq 0 ]]; then
                sudo -u $APP_USER cp -r $APP_DIR/temp/* $APP_DIR/
                sudo -u $APP_USER cp -r $APP_DIR/temp/.* $APP_DIR/ 2>/dev/null || true
                rm -rf $APP_DIR/temp
                log_success "Code cloné depuis GitHub"
            else
                log_error "Échec du clone GitHub"
                GITHUB_REPO=""
            fi
        fi
    fi
    
    if [[ -z "$GITHUB_REPO" ]]; then
        log_warning "Mode manuel activé - Copie de fichiers requise"
        log_info "Veuillez copier vos fichiers dans $APP_DIR avec cette structure :"
        log_info "  $APP_DIR/frontend/ (code React avec package.json)"
        log_info "  $APP_DIR/backend/ (code FastAPI avec requirements.txt)"
        echo ""
        echo "Commandes pour copier depuis votre machine locale :"
        echo "  scp -r ./frontend root@$(hostname -I | awk '{print $1}'):$APP_DIR/"
        echo "  scp -r ./backend root@$(hostname -I | awk '{print $1}'):$APP_DIR/"
        echo ""
        echo "Ou utilisez MobaXterm/FileZilla pour glisser-déposer les dossiers"
        echo ""
        read -p "Appuyez sur Entrée une fois les fichiers copiés dans $APP_DIR..."
    fi
    
    # Vérification des fichiers essentiels
    if [[ ! -d "$APP_DIR/frontend" ]]; then
        log_error "Répertoire frontend/ manquant dans $APP_DIR"
        ls -la $APP_DIR
        exit 1
    fi
    
    if [[ ! -d "$APP_DIR/backend" ]]; then
        log_error "Répertoire backend/ manquant dans $APP_DIR"
        ls -la $APP_DIR
        exit 1
    fi
    
    if [[ ! -f "$APP_DIR/frontend/package.json" ]]; then
        log_error "Fichier package.json manquant dans $APP_DIR/frontend/"
        ls -la $APP_DIR/frontend/
        exit 1
    fi
    
    if [[ ! -f "$APP_DIR/backend/requirements.txt" ]]; then
        log_error "Fichier requirements.txt manquant dans $APP_DIR/backend/"
        ls -la $APP_DIR/backend/
        exit 1
    fi
    
    chown -R $APP_USER:$APP_USER $APP_DIR
    log_success "Code source vérifié et prêt"
}

setup_backend() {
    log_info "Configuration du backend HYGITECH-3D (port $BACKEND_PORT)..."
    
    cd $APP_DIR/backend
    
    # Environnement virtuel Python
    if [[ ! -d "venv" ]]; then
        sudo -u $APP_USER python3 -m venv venv
        log_success "Environnement virtuel Python créé"
    fi
    
    # Installation des dépendances Python
    log_info "Installation des dépendances Python..."
    sudo -u $APP_USER bash -c "source venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"
    
    # Configuration .env pour production
    cat > .env << EOF
MONGO_URL=mongodb://localhost:27017
DB_NAME=$MONGO_DB
ENVIRONMENT=production
PORT=$BACKEND_PORT
EOF
    
    chown $APP_USER:$APP_USER .env
    
    log_success "Backend HYGITECH-3D configuré sur port $BACKEND_PORT"
}

setup_frontend() {
    log_info "Configuration du frontend HYGITECH-3D..."
    
    cd $APP_DIR/frontend
    
    # Configuration environnement de production
    cat > .env.production << EOF
REACT_APP_BACKEND_URL=https://$DOMAIN
EOF
    
    # Installation des dépendances avec timeout étendu
    log_info "Installation des dépendances frontend (peut prendre 5-10 minutes)..."
    sudo -u $APP_USER yarn install --frozen-lockfile --network-timeout 600000
    
    # Build de production avec plus de mémoire
    log_info "Build de production du frontend..."
    sudo -u $APP_USER NODE_OPTIONS="--max-old-space-size=4096" yarn build
    
    # Vérification que le build existe
    if [[ ! -d "build" ]]; then
        log_error "Le build du frontend a échoué"
        exit 1
    fi
    
    chown -R $APP_USER:$APP_USER .
    log_success "Frontend HYGITECH-3D compilé avec succès"
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
    instances: 1,
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
    
    # Configuration du démarrage automatique
    env PATH=$PATH:/usr/bin pm2 startup systemd -u $APP_USER --hp /home/$APP_USER
    sudo -u $APP_USER pm2 save
    
    log_success "PM2 configuré - processus 'hygitech-3d-backend' démarré"
}

setup_nginx() {
    log_info "Configuration Nginx pour HYGITECH-3D..."
    
    # Suppression du site par défaut
    rm -f /etc/nginx/sites-enabled/default
    
    # Configuration du site
    cat > /etc/nginx/sites-available/$SITE_NAME << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
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
        nginx -t
        exit 1
    fi
}

setup_ssl() {
    log_info "Configuration SSL pour $DOMAIN..."
    
    # Installation Certbot via snap (méthode recommandée)
    if ! command -v certbot &> /dev/null; then
        log_info "Installation de Certbot via snap..."
        apt install -y snapd
        snap install core; snap refresh core
        snap install --classic certbot
        ln -sf /snap/bin/certbot /usr/bin/certbot
    fi
    
    # Obtention certificat SSL
    certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email contact@$DOMAIN --redirect
    
    log_success "SSL configuré pour $DOMAIN et www.$DOMAIN"
}

setup_firewall() {
    log_info "Configuration du firewall..."
    
    ufw allow ssh
    ufw allow 'Nginx Full'
    ufw --force enable
    
    log_success "Firewall configuré"
}

create_maintenance_scripts() {
    log_info "Création des scripts de maintenance..."
    
    # Script de statut
    cat > $APP_DIR/scripts/status.sh << 'EOF'
#!/bin/bash
echo "📊 STATUS HYGITECH-3D"
echo "===================="

echo "🔧 Services système:"
echo "  - MongoDB: $(systemctl is-active mongod)"
echo "  - Nginx: $(systemctl is-active nginx)"

echo "🚀 Processus PM2:"
sudo -u web-hygitech-3d pm2 list | grep -E "(hygitech|online|stopped|errored)" || echo "  - Aucun processus PM2 trouvé"

echo "🌐 Test connectivité:"
curl -s -o /dev/null -w "  - Frontend: %{http_code}\n" http://localhost/ 2>/dev/null
curl -s -o /dev/null -w "  - Backend API: %{http_code}\n" http://localhost:8002/api/ 2>/dev/null

echo "💾 Espace disque:"
df -h / | tail -1 | awk '{print "  - Utilisé: " $3 "/" $2 " (" $5 ")"}'

echo "🧠 Mémoire:"
free -h | grep Mem | awk '{print "  - Utilisée: " $3 "/" $2}'

echo "🌐 SSL Status:"
if [[ -f "/etc/letsencrypt/live/hygitech-3d.com/fullchain.pem" ]]; then
    echo "  - SSL: ✅ Actif"
    openssl x509 -in /etc/letsencrypt/live/hygitech-3d.com/fullchain.pem -noout -dates | grep notAfter | sed 's/^/  - Expire: /'
else
    echo "  - SSL: ❌ Non configuré"
fi
EOF
    
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
    
    # Script de mise à jour
    cat > $APP_DIR/scripts/update.sh << 'EOF'
#!/bin/bash
cd /var/www/hygitech-3d

echo "🔄 Mise à jour HYGITECH-3D..."

# Sauvegarde avant mise à jour
./scripts/backup-mongo.sh

# Pull des changements si Git
if [[ -d ".git" ]]; then
    sudo -u web-hygitech-3d git pull origin main
fi

# Mise à jour backend
cd backend
sudo -u web-hygitech-3d bash -c "source venv/bin/activate && pip install -r requirements.txt"

# Mise à jour frontend
cd ../frontend
sudo -u web-hygitech-3d yarn install
sudo -u web-hygitech-3d NODE_OPTIONS="--max-old-space-size=4096" yarn build

# Redémarrage
sudo -u web-hygitech-3d pm2 restart hygitech-3d-backend
sudo systemctl reload nginx

echo "✅ Mise à jour terminée !"
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
    if systemctl is-active --quiet mongod; then
        log_success "✅ MongoDB opérationnel"
    else
        log_error "❌ MongoDB non accessible"
    fi
    
    # Test Backend (attendre démarrage)
    log_info "Attente du démarrage du backend (15 secondes)..."
    sleep 15
    
    if curl -f http://localhost:$BACKEND_PORT/api/ >/dev/null 2>&1; then
        log_success "✅ Backend HYGITECH-3D (port $BACKEND_PORT)"
    else
        log_warning "⚠️  Backend en cours de démarrage"
        log_info "Vérifiez les logs avec: sudo -u $APP_USER pm2 logs hygitech-3d-backend"
    fi
    
    # Test Frontend
    if curl -f http://localhost/ >/dev/null 2>&1; then
        log_success "✅ Frontend HYGITECH-3D accessible"
    else
        log_warning "⚠️  Frontend nécessite la configuration DNS"
    fi
    
    # Test PM2
    if sudo -u $APP_USER pm2 list | grep -q "hygitech-3d-backend"; then
        log_success "✅ Processus PM2 actif"
    else
        log_error "❌ Problème avec PM2"
    fi
}

# MAIN EXECUTION
echo "🚀 Installation HYGITECH-3D (Version Corrigée - Ubuntu 22.04+)"
echo "=============================================================="
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
echo "# Status complet du site:"
echo "$APP_DIR/scripts/status.sh"
echo ""
echo "# Logs en temps réel:"
echo "sudo -u $APP_USER pm2 logs hygitech-3d-backend"
echo ""
echo "# Redémarrage:"
echo "sudo -u $APP_USER pm2 restart hygitech-3d-backend"
echo "sudo systemctl reload nginx"
echo ""
echo "# Test des URLs:"
echo "curl -I http://localhost/"
echo "curl -I http://localhost:$BACKEND_PORT/api/"

run_tests

log_success "✅ HYGITECH-3D est maintenant en ligne !"
log_info "N'oubliez pas de configurer votre DNS pour pointer vers ce serveur"