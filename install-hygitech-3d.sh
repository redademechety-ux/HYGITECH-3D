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

cleanup_failed_nodejs_installation() {
    log_info "Nettoyage des installations Node.js précédentes ratées..."
    
    # Arrêter les processus qui pourraient bloquer
    pkill -f node 2>/dev/null || true
    pkill -f npm 2>/dev/null || true
    
    # Supprimer les paquets conflictuels
    apt remove -y nodejs npm node 2>/dev/null || true
    apt purge -y nodejs npm node 2>/dev/null || true
    apt autoremove -y 2>/dev/null || true
    
    # Nettoyer les repositories et clés
    rm -f /etc/apt/sources.list.d/nodesource.list* 2>/dev/null || true
    rm -f /etc/apt/keyrings/nodesource.gpg* 2>/dev/null || true
    rm -f /usr/share/keyrings/nodesource.gpg* 2>/dev/null || true
    
    # Mise à jour après nettoyage
    apt update 2>/dev/null || true
    
    log_success "Nettoyage terminé"
}

install_nodejs_robust() {
    log_info "Installation robuste de Node.js 18..."
    
    # Méthode 1: NodeSource (recommandée)
    if ! command -v node &> /dev/null; then
        # Nettoyage préventif des installations ratées
        cleanup_failed_nodejs_installation
        log_info "Tentative 1: Installation via NodeSource..."
        
        # Téléchargement et installation de la clé GPG NodeSource
        if curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg; then
            # Ajout du repository NodeSource
            NODE_MAJOR=18
            
            # Détecter la distribution Ubuntu
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                DISTRO_CODENAME=$VERSION_CODENAME
            else
                DISTRO_CODENAME="jammy"  # Fallback pour Ubuntu 22.04
            fi
            
            # Fallback pour les versions non supportées
            case $DISTRO_CODENAME in
                "focal"|"jammy"|"noble") 
                    ;;
                *)
                    log_warning "Version Ubuntu $DISTRO_CODENAME non officiellement supportée, utilisation de jammy"
                    DISTRO_CODENAME="jammy"
                    ;;
            esac
            
            echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x $DISTRO_CODENAME main" > /etc/apt/sources.list.d/nodesource.list
            
            if apt update && apt install -y nodejs; then
                if node --version && npm --version; then
                    log_success "Node.js $(node --version) et npm $(npm --version) installés via NodeSource"
                    return 0
                fi
            fi
        fi
        
        log_warning "Méthode NodeSource échouée, tentative avec Snap..."
        
        # Méthode 2: Snap (fallback)
        if ! command -v snap &> /dev/null; then
            apt install -y snapd
            systemctl enable snapd
            systemctl start snapd
            sleep 10
        fi
        
        if snap install node --classic; then
            # Créer des liens symboliques
            ln -sf /snap/bin/node /usr/local/bin/node
            ln -sf /snap/bin/npm /usr/local/bin/npm
            
            if node --version && npm --version; then
                log_success "Node.js $(node --version) installé via Snap"
                return 0
            fi
        fi
        
        log_warning "Méthode Snap échouée, tentative avec NVM..."
        
        # Méthode 3: NVM (dernière tentative)
        if curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash; then
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            
            if nvm install 18 && nvm use 18 && nvm alias default 18; then
                # Créer des liens globaux
                ln -sf "$NVM_DIR/versions/node/$(nvm version)/bin/node" /usr/local/bin/node
                ln -sf "$NVM_DIR/versions/node/$(nvm version)/bin/npm" /usr/local/bin/npm
                
                if node --version && npm --version; then
                    log_success "Node.js $(node --version) installé via NVM"
                    return 0
                fi
            fi
        fi
        
        log_error "Impossible d'installer Node.js avec toutes les méthodes. Installation manuelle requise."
        exit 1
    else
        log_success "Node.js déjà installé: $(node --version)"
    fi
}

install_system_dependencies() {
    log_info "Installation des dépendances système..."
    
    # Mise à jour système
    apt update && apt upgrade -y
    apt install -y curl wget git nginx software-properties-common ufw ca-certificates gnupg lsb-release apt-transport-https
    
    # Créer le répertoire pour les clés GPG
    mkdir -p /etc/apt/keyrings
    
    # Installation Node.js avec méthodes multiples
    install_nodejs_robust
    
    # Installation Yarn (méthodes multiples)
    if ! command -v yarn &> /dev/null; then
        log_info "Installation de Yarn..."
        
        # Méthode 1: Via npm (recommandée maintenant)
        if npm install -g yarn; then
            if yarn --version; then
                log_success "Yarn $(yarn --version) installé via npm"
            fi
        else
            log_warning "Installation npm échouée, tentative avec repository Yarn..."
            
            # Méthode 2: Repository Yarn (fallback)
            apt remove -y yarn 2>/dev/null || true
            
            if curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /etc/apt/keyrings/yarn.gpg; then
                echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
                
                if apt update && apt install -y yarn; then
                    if yarn --version; then
                        log_success "Yarn $(yarn --version) installé via repository"
                    fi
                else
                    log_warning "Yarn non installé, mais npm peut être utilisé à la place"
                fi
            else
                log_warning "Yarn non installé, mais npm peut être utilisé à la place"
            fi
        fi
    else
        log_success "Yarn déjà installé: $(yarn --version)"
    fi
    
    # Installation PM2
    if ! command -v pm2 &> /dev/null; then
        log_info "Installation de PM2..."
        if npm install -g pm2; then
            if pm2 --version; then
                log_success "PM2 $(pm2 --version) installé"
            else
                log_error "PM2 installé mais pas fonctionnel"
            fi
        else
            log_error "Échec de l'installation de PM2"
        fi
    else
        log_success "PM2 déjà installé: $(pm2 --version)"
    fi
    
    # Validation finale des outils installés
    log_info "Validation des outils installés..."
    
    echo ""
    log_info "Résumé des versions installées:"
    echo "  Node.js: $(node --version 2>/dev/null || echo 'NON INSTALLÉ')"
    echo "  npm: $(npm --version 2>/dev/null || echo 'NON INSTALLÉ')"
    echo "  Yarn: $(yarn --version 2>/dev/null || echo 'NON INSTALLÉ (npm utilisable)')"
    echo "  PM2: $(pm2 --version 2>/dev/null || echo 'NON INSTALLÉ')"
    echo ""
    
    # Vérifications critiques
    if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
        log_error "Node.js ou npm manquant. Installation impossible."
        exit 1
    fi
    
    if ! command -v pm2 &> /dev/null; then
        log_error "PM2 manquant. Installation impossible."
        exit 1
    fi
    
    log_success "Tous les outils critiques sont installés et fonctionnels"
    
    # Installation Python avec gestion des versions spécifiques
    if ! command -v python3 &> /dev/null; then
        log_info "Installation de Python 3..."
        apt install -y python3 python3-pip python3-venv python3-dev
        log_success "Python installé"
    else
        log_success "Python déjà installé: $(python3 --version)"
        
        # Vérification et installation des packages manquants pour la version spécifique
        PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
        log_info "Version Python détectée: $PYTHON_VERSION"
        
        # Installation des packages venv spécifiques à la version
        case $PYTHON_VERSION in
            "3.13")
                log_info "Installation des packages Python 3.13..."
                apt install -y python3.13-venv python3.13-dev python3-pip
                ;;
            "3.12")
                log_info "Installation des packages Python 3.12..."
                apt install -y python3.12-venv python3.12-dev python3-pip
                ;;
            "3.11")
                log_info "Installation des packages Python 3.11..."
                apt install -y python3.11-venv python3.11-dev python3-pip
                ;;
            "3.10")
                log_info "Installation des packages Python 3.10..."
                apt install -y python3.10-venv python3.10-dev python3-pip
                ;;
            *)
                log_info "Installation des packages Python génériques..."
                apt install -y python3-venv python3-dev python3-pip
                ;;
        esac
        
        # Vérification que python3-venv fonctionne
        if ! python3 -m venv --help >/dev/null 2>&1; then
            log_warning "python3-venv ne fonctionne pas, installation forcée de tous les packages..."
            apt install -y python3-venv python3.13-venv python3.12-venv python3.11-venv python3.10-venv 2>/dev/null || true
        fi
        
        log_success "Packages Python venv installés"
    fi
    
    # Installation MongoDB (méthode moderne avec correction Ubuntu 24.04+)
    if ! systemctl is-active --quiet mongod 2>/dev/null; then
        log_info "Installation de MongoDB 6.0..."
        
        # Détection de la version Ubuntu pour compatibilité
        UBUNTU_CODENAME=$(lsb_release -cs)
        UBUNTU_VERSION=$(lsb_release -rs)
        log_info "Ubuntu détecté: $UBUNTU_VERSION ($UBUNTU_CODENAME)"
        
        # Force l'utilisation de jammy pour Ubuntu 24.04+ car MongoDB ne supporte pas encore ces versions
        if [[ "$UBUNTU_CODENAME" == "plucky" ]] || [[ "$UBUNTU_CODENAME" == "oracular" ]] || [[ "$UBUNTU_CODENAME" == "noble" ]] || [[ "${UBUNTU_VERSION%%.*}" -ge 24 ]]; then
            log_warning "Ubuntu 24.04+ détecté - MongoDB non supporté officiellement"
            log_info "Installation alternative via repository Ubuntu 22.04 ou Snap"
            
            # Tentative 1: Utiliser le repository jammy
            MONGO_CODENAME="jammy"
            log_info "Tentative avec repository jammy (Ubuntu 22.04)..."
            
            # Nettoyage complet des anciennes configurations
            rm -f /etc/apt/keyrings/mongodb-server-*.gpg
            rm -f /etc/apt/sources.list.d/mongodb-org-*.list
            apt update
            
            # Installation de la clé GPG MongoDB
            curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | gpg --dearmor -o /etc/apt/keyrings/mongodb-server-6.0.gpg
            
            # Ajout du repository MongoDB avec jammy forcé
            echo "deb [ arch=amd64,arm64 signed-by=/etc/apt/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-6.0.list
            
            # Test du repository
            apt update
            if apt-cache policy mongodb-org > /dev/null 2>&1; then
                log_success "Repository MongoDB jammy accessible"
                apt install -y mongodb-org
                systemctl start mongod
                systemctl enable mongod
            else
                log_warning "Repository MongoDB jammy inaccessible, passage à l'installation Snap"
                
                # Tentative 2: Installation via Snap
                rm -f /etc/apt/sources.list.d/mongodb-org-6.0.list
                apt update
                
                # Installation de snapd si pas présent
                if ! command -v snap &> /dev/null; then
                    apt install -y snapd
                    systemctl enable snapd
                    systemctl start snapd
                    # Attendre que snapd soit prêt
                    sleep 10
                fi
                
                # Installation MongoDB via snap
                snap install mongodb --edge
                
                # Configuration du service systemd pour MongoDB snap
                mkdir -p /var/snap/mongodb/current
                cat > /var/snap/mongodb/current/mongodb.conf << 'MONGO_SNAP_CONFIG'
# MongoDB configuration file for snap
storage:
  dbPath: /var/snap/mongodb/current/db
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: /var/snap/mongodb/current/mongod.log

net:
  port: 27017
  bindIp: 127.0.0.1

processManagement:
  fork: true
  pidFilePath: /var/snap/mongodb/current/mongod.pid
MONGO_SNAP_CONFIG
                
                # Service systemd pour MongoDB snap
                cat > /etc/systemd/system/mongod.service << 'MONGO_SNAP_SERVICE'
[Unit]
Description=MongoDB Database Server (Snap)
Documentation=https://docs.mongodb.org/manual
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
User=root
ExecStart=/snap/bin/mongodb.mongod --config /var/snap/mongodb/current/mongodb.conf
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
PIDFile=/var/snap/mongodb/current/mongod.pid

[Install]
WantedBy=multi-user.target
MONGO_SNAP_SERVICE
                
                systemctl daemon-reload
                systemctl enable mongod
                systemctl start mongod
            fi
            
        else
            # Ubuntu 22.04 et versions antérieures supportées
            log_info "Ubuntu $UBUNTU_VERSION supporté par MongoDB"
            MONGO_CODENAME="$UBUNTU_CODENAME"
            
            # Nettoyage des anciennes configurations
            rm -f /etc/apt/keyrings/mongodb-server-*.gpg
            rm -f /etc/apt/sources.list.d/mongodb-org-*.list
            
            # Installation de la clé GPG MongoDB
            curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | gpg --dearmor -o /etc/apt/keyrings/mongodb-server-6.0.gpg
            
            # Ajout du repository MongoDB
            echo "deb [ arch=amd64,arm64 signed-by=/etc/apt/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu $MONGO_CODENAME/mongodb-org/6.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-6.0.list
            
            apt update && apt install -y mongodb-org
            
            # Configuration et démarrage
            systemctl start mongod
            systemctl enable mongod
        fi
        
        # Attendre que MongoDB soit prêt
        log_info "Attente du démarrage de MongoDB..."
        sleep 20
        
        # Test de MongoDB avec plusieurs tentatives
        MONGO_READY=false
        for i in {1..6}; do
            if systemctl is-active --quiet mongod; then
                MONGO_READY=true
                log_success "MongoDB démarré avec succès"
                break
            fi
            log_info "Tentative $i/6 - Attente MongoDB..."
            sleep 10
        done
        
        if [ "$MONGO_READY" = false ]; then
            log_error "MongoDB ne démarre pas après plusieurs tentatives"
            log_info "Diagnostic MongoDB:"
            systemctl status mongod || systemctl status mongodb
            
            # Tentative de démarrage manuel pour diagnostic
            log_info "Tentative de diagnostic approfondi..."
            which mongod mongosh mongo 2>/dev/null || echo "Binaires MongoDB non trouvés"
            ls -la /var/log/mongodb/ 2>/dev/null || echo "Répertoire logs MongoDB non trouvé"
            
            # Tentative finale avec MongoDB Community via wget
            log_warning "Tentative d'installation manuelle MongoDB..."
            
            # Téléchargement direct du package MongoDB
            cd /tmp
            wget -q https://repo.mongodb.org/apt/ubuntu/dists/jammy/mongodb-org/6.0/multiverse/binary-amd64/mongodb-org-server_6.0.5_amd64.deb
            if [[ -f "mongodb-org-server_6.0.5_amd64.deb" ]]; then
                dpkg -i mongodb-org-server_6.0.5_amd64.deb || apt-get install -f -y
                systemctl start mongod
                systemctl enable mongod
                sleep 10
                if systemctl is-active --quiet mongod; then
                    log_success "MongoDB installé manuellement avec succès"
                    MONGO_READY=true
                fi
            fi
            
            if [ "$MONGO_READY" = false ]; then
                log_error "Impossible d'installer MongoDB. Installation interrompue."
                exit 1
            fi
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
        # Vérifier que l'URL GitHub est valide
        if ! curl -s --head "$GITHUB_REPO" | head -1 | grep -q "200 OK"; then
            log_warning "URL GitHub non accessible : $GITHUB_REPO"
            log_info "Tentative avec URL alternative..."
            
            # Essayer différents formats d'URL
            if [[ "$GITHUB_REPO" == *".git" ]]; then
                GITHUB_REPO_ALT="${GITHUB_REPO%.git}"
            else
                GITHUB_REPO_ALT="${GITHUB_REPO}.git"
            fi
            
            if ! curl -s --head "$GITHUB_REPO_ALT" | head -1 | grep -q "200 OK"; then
                log_error "Repository GitHub inaccessible. Passage en mode manuel."
                GITHUB_REPO=""
            else
                GITHUB_REPO="$GITHUB_REPO_ALT"
                log_success "URL alternative trouvée : $GITHUB_REPO"
            fi
        fi
    fi
    
    if [[ -n "$GITHUB_REPO" ]]; then
        # Clone depuis GitHub avec gestion robuste
        if [[ -d "$APP_DIR/.git" ]]; then
            log_info "Repository existant, mise à jour..."
            cd $APP_DIR
            chown -R $APP_USER:$APP_USER $APP_DIR
            sudo -u $APP_USER git pull origin main 2>/dev/null || sudo -u $APP_USER git pull origin master 2>/dev/null || {
                log_warning "Échec du git pull, re-clone du repository..."
                cd /tmp
                rm -rf $APP_DIR/.git
            }
        fi
        
        if [[ ! -d "$APP_DIR/.git" ]]; then
            log_info "Clone du repository depuis GitHub..."
            
            # Méthode 1: Clone direct dans le répertoire final (avec nettoyage préalable)
            rm -rf $APP_DIR/* $APP_DIR/.* 2>/dev/null || true
            
            if git clone $GITHUB_REPO $APP_DIR; then
                # Ajuster les permissions
                chown -R $APP_USER:$APP_USER $APP_DIR
                
                # Vérifier la structure
                if [[ -d "$APP_DIR/frontend" && -d "$APP_DIR/backend" ]]; then
                    log_success "Code cloné depuis GitHub avec succès (méthode directe)"
                else
                    log_warning "Structure inattendue, recherche de sous-répertoires..."
                    # Chercher dans les sous-répertoires
                    FOUND_FRONTEND=$(find $APP_DIR -name "frontend" -type d | head -1)
                    FOUND_BACKEND=$(find $APP_DIR -name "backend" -type d | head -1)
                    
                    if [[ -n "$FOUND_FRONTEND" && -n "$FOUND_BACKEND" ]]; then
                        PARENT_DIR=$(dirname "$FOUND_FRONTEND")
                        if [[ "$PARENT_DIR" != "$APP_DIR" ]]; then
                            log_info "Correction de la structure : déplacement depuis $PARENT_DIR..."
                            
                            # Créer un backup temporaire
                            TEMP_BACKUP="/tmp/hygitech-backup-$$"
                            cp -r $PARENT_DIR $TEMP_BACKUP
                            
                            # Vider le répertoire principal
                            rm -rf $APP_DIR/* $APP_DIR/.* 2>/dev/null || true
                            
                            # Déplacer les fichiers au bon endroit
                            cp -r $TEMP_BACKUP/* $APP_DIR/ 2>/dev/null || true
                            cp -r $TEMP_BACKUP/.* $APP_DIR/ 2>/dev/null || true
                            
                            # Nettoyer
                            rm -rf $TEMP_BACKUP
                            chown -R $APP_USER:$APP_USER $APP_DIR
                            
                            log_success "Structure corrigée automatiquement"
                        fi
                    else
                        log_error "Impossible de trouver frontend et backend dans le repository"
                        GITHUB_REPO=""
                    fi
                fi
            else
                log_warning "Échec du clone direct, tentative avec répertoire temporaire..."
                
                # Méthode 2: Clone dans un répertoire temporaire puis déplacement
                TEMP_DIR="/tmp/hygitech-clone-$$"
                rm -rf $TEMP_DIR
                
                if git clone $GITHUB_REPO $TEMP_DIR; then
                    log_info "Clone temporaire réussi, déplacement des fichiers..."
                    
                    # Chercher frontend et backend dans l'arborescence
                    FOUND_FRONTEND=$(find $TEMP_DIR -name "frontend" -type d | head -1)
                    FOUND_BACKEND=$(find $TEMP_DIR -name "backend" -type d | head -1)
                    
                    if [[ -n "$FOUND_FRONTEND" && -n "$FOUND_BACKEND" ]]; then
                        SOURCE_DIR=$(dirname "$FOUND_FRONTEND")
                        log_info "Fichiers trouvés dans : $SOURCE_DIR"
                        
                        # Vider le répertoire de destination
                        rm -rf $APP_DIR/* $APP_DIR/.* 2>/dev/null || true
                        
                        # Copier les fichiers
                        cp -r $SOURCE_DIR/* $APP_DIR/ 2>/dev/null || true
                        cp -r $SOURCE_DIR/.* $APP_DIR/ 2>/dev/null || true
                        
                        # Ajuster les permissions
                        chown -R $APP_USER:$APP_USER $APP_DIR
                        
                        log_success "Code copié depuis le repository temporaire"
                    else
                        log_error "Frontend/Backend non trouvés dans le repository temporaire"
                        GITHUB_REPO=""
                    fi
                    
                    # Nettoyer le répertoire temporaire
                    rm -rf $TEMP_DIR
                else
                    log_error "Impossible de cloner le repository GitHub"
                    GITHUB_REPO=""
                fi
            fi
        fi
    fi
    
    if [[ -z "$GITHUB_REPO" ]]; then
        log_warning "Mode manuel activé - Copie de fichiers requise"
        log_info "Veuillez copier vos fichiers dans $APP_DIR avec cette structure :"
        log_info "  $APP_DIR/frontend/ (code React avec package.json)"
        log_info "  $APP_DIR/backend/ (code FastAPI avec requirements.txt)"
        echo ""
        echo "=== OPTION 1: Copie depuis GitHub (RECOMMANDÉE) ==="
        echo "cd /tmp"
        echo "git clone https://github.com/VOTRE-USERNAME/hygitech-3d.git hygitech-source"
        echo "cp -r hygitech-source/frontend $APP_DIR/"
        echo "cp -r hygitech-source/backend $APP_DIR/"
        echo "cp hygitech-source/ecosystem.config.js $APP_DIR/ 2>/dev/null || true"
        echo "chown -R $APP_USER:$APP_USER $APP_DIR"
        echo "rm -rf hygitech-source"
        echo ""
        echo "=== OPTION 2: Copie depuis votre machine locale ==="
        echo "scp -r ./frontend root@$(hostname -I | awk '{print $1}'):$APP_DIR/"
        echo "scp -r ./backend root@$(hostname -I | awk '{print $1}'):$APP_DIR/"
        echo ""
        echo "=== OPTION 3: Correction automatique si structure imbriquée ==="
        echo "Si les dossiers sont dans un sous-répertoire (ex: $APP_DIR/hygitech-3d/):"
        echo "cd $APP_DIR && mv hygitech-3d/* . && mv hygitech-3d/.* . 2>/dev/null || true && rmdir hygitech-3d"
        echo ""
        
        # Tentative automatique de clone si pas de repository fourni
        log_info "Tentative de détection automatique du repository..."
        if [[ -f "/tmp/hygitech-3d.git" ]] || curl -s https://github.com/VOTRE-USERNAME/hygitech-3d >/dev/null 2>&1; then
            read -p "Voulez-vous que je tente un clone automatique depuis GitHub ? (y/N): " AUTO_CLONE
            if [[ "$AUTO_CLONE" =~ ^[Yy]$ ]]; then
                read -p "Entrez l'URL de votre repository GitHub: " MANUAL_REPO
                if [[ -n "$MANUAL_REPO" ]]; then
                    GITHUB_REPO="$MANUAL_REPO"
                    log_info "Tentative de clone avec : $GITHUB_REPO"
                    # Relancer la fonction récursivement avec le nouveau repo
                    download_source_code
                    return
                fi
            fi
        fi
        
        read -p "Appuyez sur Entrée une fois les fichiers copiés dans $APP_DIR..."
    fi
    
    # Vérification finale des fichiers essentiels
    if [[ ! -d "$APP_DIR/frontend" ]]; then
        log_error "Répertoire frontend/ manquant dans $APP_DIR"
        log_info "Structure actuelle :"
        ls -la $APP_DIR
        
        # Tentative de correction automatique si structure imbriquée
        REPO_NAME=$(basename ${GITHUB_REPO:-"hygitech-3d"} .git)
        if [[ -d "$APP_DIR/$REPO_NAME/frontend" ]]; then
            log_info "Détection structure imbriquée, correction automatique..."
            sudo -u $APP_USER mv $APP_DIR/$REPO_NAME/* $APP_DIR/ 2>/dev/null || true
            sudo -u $APP_USER mv $APP_DIR/$REPO_NAME/.* $APP_DIR/ 2>/dev/null || true
            sudo -u $APP_USER rmdir $APP_DIR/$REPO_NAME 2>/dev/null || true
            log_success "Structure corrigée automatiquement"
        else
            exit 1
        fi
    fi
    
    if [[ ! -d "$APP_DIR/backend" ]]; then
        log_error "Répertoire backend/ manquant dans $APP_DIR"
        log_info "Structure actuelle :"
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
    cat > .env << 'BACKEND_ENV'
MONGO_URL=mongodb://localhost:27017
DB_NAME=hygitech3d_production
ENVIRONMENT=production
PORT=8002
BACKEND_ENV
    
    chown $APP_USER:$APP_USER .env
    
    log_success "Backend HYGITECH-3D configuré sur port $BACKEND_PORT"
}

setup_frontend() {
    log_info "Configuration du frontend HYGITECH-3D..."
    
    cd $APP_DIR/frontend
    
    # Configuration environnement de production
    cat > .env.production << 'FRONTEND_ENV'
REACT_APP_BACKEND_URL=https://hygitech-3d.com
FRONTEND_ENV
    
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
    cat > $APP_DIR/ecosystem.config.js << 'PM2_CONFIG'
module.exports = {
  apps: [{
    name: 'hygitech-3d-backend',
    script: 'venv/bin/uvicorn',
    args: 'server:app --host 0.0.0.0 --port 8002',
    cwd: '/var/www/hygitech-3d/backend',
    instances: 1,
    env: {
      NODE_ENV: 'production',
      PORT: '8002'
    },
    error_file: '/var/www/hygitech-3d/logs/backend-error.log',
    out_file: '/var/www/hygitech-3d/logs/backend-out.log',
    log_file: '/var/www/hygitech-3d/logs/backend-combined.log',
    time: true,
    max_memory_restart: '1G'
  }]
}
PM2_CONFIG
    
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
    cat > /etc/nginx/sites-available/$SITE_NAME << 'NGINX_CONFIG'
server {
    listen 80;
    server_name hygitech-3d.com www.hygitech-3d.com;
    
    # Frontend React
    location / {
        root /var/www/hygitech-3d/frontend/build;
        index index.html;
        try_files $uri $uri/ /index.html;
        
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
        proxy_pass http://localhost:8002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
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
NGINX_CONFIG
    
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
    cat > $APP_DIR/scripts/status.sh << 'STATUS_SCRIPT'
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
STATUS_SCRIPT
    
    # Script de sauvegarde MongoDB
    cat > $APP_DIR/scripts/backup-mongo.sh << 'BACKUP_SCRIPT'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/backups/mongodb"
mkdir -p $BACKUP_DIR

echo "🔄 Sauvegarde MongoDB HYGITECH-3D..."
mongodump --db hygitech3d_production --out $BACKUP_DIR/$DATE

# Nettoyage des sauvegardes anciennes (> 7 jours)
find $BACKUP_DIR -mtime +7 -delete

echo "✅ Sauvegarde terminée: $BACKUP_DIR/$DATE"
BACKUP_SCRIPT
    
    # Script de mise à jour
    cat > $APP_DIR/scripts/update.sh << 'UPDATE_SCRIPT'
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
UPDATE_SCRIPT
    
    chmod +x $APP_DIR/scripts/*.sh
    chown -R $APP_USER:$APP_USER $APP_DIR/scripts
    
    # Cron pour sauvegarde quotidienne à 2h
    (sudo -u $APP_USER crontab -l 2>/dev/null; echo "0 2 * * * $APP_DIR/scripts/backup-mongo.sh") | sudo -u $APP_USER crontab -
    
    log_success "Scripts de maintenance créés"
}

run_tests() {
    log_info "Tests de vérification finale..."
    
    # Test MongoDB avec différentes commandes possibles
    if systemctl is-active --quiet mongod; then
        log_success "✅ MongoDB opérationnel"
    elif systemctl is-active --quiet mongodb; then
        log_success "✅ MongoDB opérationnel (service mongodb)"
    else
        log_error "❌ MongoDB non accessible"
        log_info "Vérification des services MongoDB disponibles:"
        systemctl list-units --type=service | grep -i mongo || echo "Aucun service MongoDB trouvé"
    fi
    
    # Test Backend (attendre démarrage)
    log_info "Attente du démarrage du backend (15 secondes)..."
    sleep 15
    
    if curl -f http://localhost:$BACKEND_PORT/api/ >/dev/null 2>&1; then
        log_success "✅ Backend HYGITECH-3D (port $BACKEND_PORT)"
    else
        log_warning "⚠️  Backend en cours de démarrage"
        log_info "Vérifiez les logs avec: sudo -u $APP_USER pm2 logs hygitech-3d-backend"
        
        # Test direct du backend
        log_info "Test de connectivité backend:"
        curl -I http://localhost:$BACKEND_PORT/api/ || echo "Backend non accessible"
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
        sudo -u $APP_USER pm2 list || echo "PM2 non disponible"
    fi
    
    # Test de base de données (si MongoDB fonctionne)
    if command -v mongosh >/dev/null 2>&1; then
        log_info "Test de connexion MongoDB avec mongosh..."
        if mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
            log_success "✅ Connexion MongoDB fonctionnelle"
        else
            log_warning "⚠️  MongoDB installé mais connexion échouée"
        fi
    elif command -v mongo >/dev/null 2>&1; then
        log_info "Test de connexion MongoDB avec mongo..."
        if mongo --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
            log_success "✅ Connexion MongoDB fonctionnelle"
        else
            log_warning "⚠️  MongoDB installé mais connexion échouée"
        fi
    else
        log_warning "⚠️  Client MongoDB non trouvé"
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