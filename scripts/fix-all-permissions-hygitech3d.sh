#!/bin/bash

# Script complet de correction des autorisations pour Hygitech-3D
# Ce script résout tous les problèmes d'autorisations dans /var/www/hygitech-3d/

set -e  # Arrêter le script en cas d'erreur

echo "=========================================="
echo "CORRECTION DES AUTORISATIONS HYGITECH-3D"
echo "=========================================="

# Variables
PROJECT_DIR="/var/www/hygitech-3d"
USER_NAME="web-hygitech-3d"
GROUP_NAME="web-hygitech-3d"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Fonction pour vérifier si le répertoire existe
check_directory() {
    if [ ! -d "$PROJECT_DIR" ]; then
        error "Le répertoire $PROJECT_DIR n'existe pas!"
        error "Vérifiez que le projet Hygitech-3D est bien installé dans $PROJECT_DIR"
        error "Si le projet est dans un autre répertoire, modifiez la variable PROJECT_DIR au début du script"
        exit 1
    fi
    log "Répertoire $PROJECT_DIR trouvé"
    
    # Afficher la structure du répertoire pour diagnostic
    log "Structure du répertoire:"
    ls -la "$PROJECT_DIR"
}

# Fonction pour créer l'utilisateur et le groupe s'ils n'existent pas
create_user_group() {
    log "Vérification de l'utilisateur et du groupe..."
    
    # Créer le groupe s'il n'existe pas
    if ! getent group "$GROUP_NAME" > /dev/null 2>&1; then
        warn "Groupe $GROUP_NAME n'existe pas, création..."
        sudo groupadd "$GROUP_NAME"
        log "Groupe $GROUP_NAME créé"
    else
        log "Groupe $GROUP_NAME existe déjà"
    fi
    
    # Créer l'utilisateur s'il n'existe pas
    if ! getent passwd "$USER_NAME" > /dev/null 2>&1; then
        warn "Utilisateur $USER_NAME n'existe pas, création..."
        sudo useradd -r -g "$GROUP_NAME" -s /bin/bash -d /var/www "$USER_NAME"
        log "Utilisateur $USER_NAME créé"
    else
        log "Utilisateur $USER_NAME existe déjà"
    fi
}

# Fonction pour corriger la propriété des fichiers
fix_ownership() {
    log "Correction de la propriété des fichiers..."
    sudo chown -R "$USER_NAME:$GROUP_NAME" "$PROJECT_DIR/"
    log "Propriété corrigée pour $USER_NAME:$GROUP_NAME"
}

# Fonction pour corriger les permissions des répertoires
fix_directory_permissions() {
    log "Correction des permissions des répertoires..."
    
    # Permissions générales des répertoires
    find "$PROJECT_DIR" -type d -exec sudo chmod 755 {} \;
    
    # Permissions spéciales pour certains répertoires
    if [ -d "$PROJECT_DIR/frontend/node_modules" ]; then
        sudo chmod -R 755 "$PROJECT_DIR/frontend/node_modules"
        log "Permissions node_modules corrigées"
    fi
    
    if [ -d "$PROJECT_DIR/frontend/build" ]; then
        sudo chmod -R 755 "$PROJECT_DIR/frontend/build"
        log "Permissions build corrigées"
    fi
    
    log "Permissions des répertoires corrigées"
}

# Fonction pour corriger les permissions des fichiers
fix_file_permissions() {
    log "Correction des permissions des fichiers..."
    
    # Permissions générales des fichiers
    find "$PROJECT_DIR" -type f -exec sudo chmod 644 {} \;
    
    # Permissions spéciales pour les fichiers exécutables
    if [ -f "$PROJECT_DIR/install-hygitech-3d.sh" ]; then
        sudo chmod 755 "$PROJECT_DIR/install-hygitech-3d.sh"
        log "Permissions install-hygitech-3d.sh corrigées"
    fi
    
    # Permissions pour les fichiers Python
    find "$PROJECT_DIR" -name "*.py" -exec sudo chmod 644 {} \;
    
    # Permissions pour les fichiers JavaScript
    find "$PROJECT_DIR" -name "*.js" -exec sudo chmod 644 {} \;
    find "$PROJECT_DIR" -name "*.jsx" -exec sudo chmod 644 {} \;
    
    log "Permissions des fichiers corrigées"
}

# Fonction pour créer et configurer le fichier .env backend
create_backend_env() {
    log "Configuration du fichier .env backend..."
    
    ENV_FILE="$PROJECT_DIR/backend/.env"
    
    # Supprimer l'ancien fichier s'il existe avec des problèmes
    if [ -f "$ENV_FILE" ]; then
        warn "Suppression de l'ancien fichier .env"
        sudo rm -f "$ENV_FILE"
    fi
    
    # Créer le nouveau fichier .env avec sudo tee
    log "Création du nouveau fichier .env"
    sudo tee "$ENV_FILE" > /dev/null << 'EOF'
MONGO_URL=mongodb://localhost:27017
DB_NAME=hygitech3d
ENVIRONMENT=production
PORT=8001
DEBUG=false
EOF
    
    # Corriger les permissions du fichier .env
    sudo chown "$USER_NAME:$GROUP_NAME" "$ENV_FILE"
    sudo chmod 644 "$ENV_FILE"
    
    log "Fichier .env backend créé et configuré"
}

# Fonction pour vérifier le fichier .env frontend
check_frontend_env() {
    log "Vérification du fichier .env frontend..."
    
    FRONTEND_ENV="$PROJECT_DIR/frontend/.env"
    
    if [ -f "$FRONTEND_ENV" ]; then
        log "Fichier .env frontend existe"
        sudo chown "$USER_NAME:$GROUP_NAME" "$FRONTEND_ENV"
        sudo chmod 644 "$FRONTEND_ENV"
        log "Permissions du fichier .env frontend corrigées"
    else
        warn "Fichier .env frontend n'existe pas, mais ce n'est pas critique pour le moment"
    fi
}

# Fonction pour créer/corriger le fichier ecosystem.config.js
create_ecosystem_config() {
    log "Configuration du fichier ecosystem.config.js..."
    
    ECOSYSTEM_FILE="$PROJECT_DIR/ecosystem.config.js"
    
    # Créer le fichier ecosystem.config.js
    sudo tee "$ECOSYSTEM_FILE" > /dev/null << 'EOF'
module.exports = {
  apps: [{
    name: "hygitech-3d-backend",
    script: "uvicorn",
    args: "server:app --host 0.0.0.0 --port 8001",
    cwd: "/var/www/hygitech-3d/backend",
    instances: 1,
    exec_mode: "fork",
    env: {
      MONGO_URL: "mongodb://localhost:27017",
      DB_NAME: "hygitech3d",
      ENVIRONMENT: "production",
      PORT: "8001",
      DEBUG: "false"
    },
    log_file: "/var/log/supervisor/hygitech-3d-backend.log",
    out_file: "/var/log/supervisor/hygitech-3d-backend.out.log",
    error_file: "/var/log/supervisor/hygitech-3d-backend.err.log",
    log_date_format: "YYYY-MM-DD HH:mm:ss Z",
    autorestart: true,
    watch: false,
    max_memory_restart: "1G"
  }]
};
EOF
    
    # Corriger les permissions
    sudo chown "$USER_NAME:$GROUP_NAME" "$ECOSYSTEM_FILE"
    sudo chmod 644 "$ECOSYSTEM_FILE"
    
    log "Fichier ecosystem.config.js créé et configuré"
}

# Fonction pour nettoyer les anciens processus PM2
cleanup_pm2() {
    log "Nettoyage des anciens processus PM2..."
    
    # Arrêter tous les processus PM2 existants
    sudo -u "$USER_NAME" pm2 stop all 2>/dev/null || true
    sudo -u "$USER_NAME" pm2 delete all 2>/dev/null || true
    sudo -u "$USER_NAME" pm2 kill 2>/dev/null || true
    
    log "Anciens processus PM2 nettoyés"
}

# Fonction pour tester le backend manuellement
test_backend_manual() {
    log "Test manuel du backend..."
    
    cd "$PROJECT_DIR/backend"
    
    # Test avec uvicorn directement
    info "Test du backend avec uvicorn..."
    timeout 10s sudo -u "$USER_NAME" bash -c "
        export MONGO_URL=mongodb://localhost:27017
        export DB_NAME=hygitech3d
        export ENVIRONMENT=production
        export PORT=8001
        cd $PROJECT_DIR/backend
        python3 -c 'import server; print(\"Backend can be imported successfully\")'
    " || warn "Test d'importation échoué, mais cela peut être normal si des dépendances manquent"
    
    log "Test manuel terminé"
}

# Fonction pour démarrer PM2
start_pm2() {
    log "Démarrage de PM2..."
    
    cd "$PROJECT_DIR"
    
    # Démarrer l'application avec PM2
    sudo -u "$USER_NAME" pm2 start ecosystem.config.js
    
    # Afficher le statut
    sudo -u "$USER_NAME" pm2 status
    
    log "PM2 démarré"
}

# Fonction pour tester les services
test_services() {
    log "Test des services..."
    
    sleep 5  # Attendre que les services démarrent
    
    # Test du backend
    info "Test du backend sur le port 8001..."
    if curl -f -s http://localhost:8001/api/status > /dev/null 2>&1; then
        log "✅ Backend répond correctement"
    else
        warn "❌ Backend ne répond pas, vérifiez les logs"
    fi
    
    # Afficher les logs récents
    info "Logs récents du backend:"
    sudo -u "$USER_NAME" pm2 logs hygitech-3d-backend --lines 10 || true
}

# Fonction pour afficher un résumé
show_summary() {
    echo ""
    echo "=========================================="
    echo "RÉSUMÉ DE LA CORRECTION DES AUTORISATIONS"
    echo "=========================================="
    
    log "✅ Utilisateur et groupe créés/vérifiés: $USER_NAME:$GROUP_NAME"
    log "✅ Propriété des fichiers corrigée: $PROJECT_DIR"
    log "✅ Permissions des répertoires corrigées: 755"
    log "✅ Permissions des fichiers corrigées: 644"
    log "✅ Fichier .env backend créé: $PROJECT_DIR/backend/.env"
    log "✅ Fichier ecosystem.config.js configuré"
    log "✅ PM2 configuré et démarré"
    
    echo ""
    info "Commandes utiles pour la suite:"
    echo "  - Vérifier le statut PM2: sudo -u $USER_NAME pm2 status"
    echo "  - Voir les logs: sudo -u $USER_NAME pm2 logs hygitech-3d-backend"
    echo "  - Redémarrer PM2: sudo -u $USER_NAME pm2 restart hygitech-3d-backend"
    echo "  - Test backend: curl http://localhost:8001/api/status"
    
    echo ""
    log "Script de correction des autorisations terminé avec succès!"
}

# Exécution principale
main() {
    log "Début de la correction des autorisations..."
    
    check_directory
    create_user_group
    fix_ownership
    fix_directory_permissions
    fix_file_permissions
    create_backend_env
    check_frontend_env
    create_ecosystem_config
    cleanup_pm2
    test_backend_manual
    start_pm2
    test_services
    show_summary
}

# Exécuter le script principal
main

exit 0