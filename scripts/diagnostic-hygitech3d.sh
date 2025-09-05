#!/bin/bash

# Script de diagnostic pour Hygitech-3D
# Identifie les problèmes d'autorisations et de configuration

set -e

echo "=========================================="
echo "DIAGNOSTIC HYGITECH-3D"
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
    echo -e "${GREEN}[OK]${NC} $1"
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

# Vérification de l'existence du répertoire
check_project_directory() {
    info "1. Vérification du répertoire du projet..."
    
    if [ -d "$PROJECT_DIR" ]; then
        log "Répertoire $PROJECT_DIR existe"
        info "Structure du répertoire:"
        ls -la "$PROJECT_DIR" | head -20
        
        # Vérifier la propriété
        info "Propriétaire actuel du répertoire principal:"
        ls -ld "$PROJECT_DIR"
    else
        error "Le répertoire $PROJECT_DIR n'existe pas!"
        error "Le projet n'est peut-être pas installé correctement"
        
        # Chercher d'autres répertoires possibles
        info "Recherche d'autres répertoires possibles:"
        find /var/www -name "*hygitech*" 2>/dev/null || echo "Aucun répertoire hygitech trouvé dans /var/www"
        find /home -name "*hygitech*" 2>/dev/null || echo "Aucun répertoire hygitech trouvé dans /home"
    fi
    echo ""
}

# Vérification de l'utilisateur et du groupe
check_user_group() {
    info "2. Vérification de l'utilisateur et du groupe..."
    
    if getent passwd "$USER_NAME" > /dev/null 2>&1; then
        log "Utilisateur $USER_NAME existe"
    else
        error "Utilisateur $USER_NAME n'existe pas"
    fi
    
    if getent group "$GROUP_NAME" > /dev/null 2>&1; then
        log "Groupe $GROUP_NAME existe"
    else
        error "Groupe $GROUP_NAME n'existe pas"
    fi
    echo ""
}

# Vérification des fichiers critiques
check_critical_files() {
    info "3. Vérification des fichiers critiques..."
    
    if [ ! -d "$PROJECT_DIR" ]; then
        error "Impossible de vérifier les fichiers - répertoire principal manquant"
        return
    fi
    
    # Vérifier le backend
    if [ -d "$PROJECT_DIR/backend" ]; then
        log "Répertoire backend existe"
        
        if [ -f "$PROJECT_DIR/backend/server.py" ]; then
            log "Fichier server.py existe"
            ls -la "$PROJECT_DIR/backend/server.py"
        else
            error "Fichier server.py manquant"
        fi
        
        if [ -f "$PROJECT_DIR/backend/.env" ]; then
            log "Fichier .env backend existe"
            ls -la "$PROJECT_DIR/backend/.env"
            info "Contenu du fichier .env (masqué):"
            sed 's/=.*/=***/' "$PROJECT_DIR/backend/.env" 2>/dev/null || error "Impossible de lire le fichier .env"
        else
            error "Fichier .env backend manquant"
        fi
        
        if [ -f "$PROJECT_DIR/backend/requirements.txt" ]; then
            log "Fichier requirements.txt existe"
        else
            error "Fichier requirements.txt manquant"
        fi
    else
        error "Répertoire backend manquant"
    fi
    
    # Vérifier le frontend
    if [ -d "$PROJECT_DIR/frontend" ]; then
        log "Répertoire frontend existe"
        
        if [ -f "$PROJECT_DIR/frontend/package.json" ]; then
            log "Fichier package.json existe"
        else
            error "Fichier package.json manquant"
        fi
    else
        error "Répertoire frontend manquant"
    fi
    
    # Vérifier ecosystem.config.js
    if [ -f "$PROJECT_DIR/ecosystem.config.js" ]; then
        log "Fichier ecosystem.config.js existe"
        ls -la "$PROJECT_DIR/ecosystem.config.js"
    else
        error "Fichier ecosystem.config.js manquant"
    fi
    echo ""
}

# Vérification des autorisations
check_permissions() {
    info "4. Vérification des autorisations..."
    
    if [ ! -d "$PROJECT_DIR" ]; then
        error "Impossible de vérifier les autorisations - répertoire principal manquant"
        return
    fi
    
    info "Autorisations du répertoire principal:"
    ls -ld "$PROJECT_DIR"
    
    info "Autorisations des sous-répertoires principaux:"
    find "$PROJECT_DIR" -maxdepth 2 -type d -exec ls -ld {} \; 2>/dev/null | head -10
    
    info "Fichiers avec des autorisations problématiques (non lisibles):"
    find "$PROJECT_DIR" -type f ! -readable 2>/dev/null | head -10 || log "Aucun fichier non lisible trouvé"
    
    echo ""
}

# Vérification de PM2
check_pm2() {
    info "5. Vérification de PM2..."
    
    if command -v pm2 &> /dev/null; then
        log "PM2 est installé"
        
        info "Processus PM2 actuels:"
        pm2 status 2>/dev/null || warn "Impossible d'obtenir le statut PM2"
        
        info "Processus hygitech-3d:"
        pm2 describe hygitech-3d-backend 2>/dev/null || warn "Processus hygitech-3d-backend non trouvé"
        
    else
        error "PM2 n'est pas installé"
    fi
    echo ""
}

# Vérification de MongoDB
check_mongodb() {
    info "6. Vérification de MongoDB..."
    
    if systemctl is-active --quiet mongod; then
        log "MongoDB est actif"
    else
        error "MongoDB n'est pas actif"
        info "Statut de MongoDB:"
        systemctl status mongod --no-pager -l || error "Impossible d'obtenir le statut MongoDB"
    fi
    echo ""
}

# Vérification des ports
check_ports() {
    info "7. Vérification des ports..."
    
    info "Port 8001 (backend):"
    if netstat -tuln | grep -q ":8001 "; then
        log "Port 8001 est en écoute"
        netstat -tuln | grep ":8001 "
    else
        warn "Port 8001 n'est pas en écoute"
    fi
    
    info "Port 3000 (frontend):"
    if netstat -tuln | grep -q ":3000 "; then
        log "Port 3000 est en écoute"
        netstat -tuln | grep ":3000 "
    else
        warn "Port 3000 n'est pas en écoute"
    fi
    
    info "Port 27017 (MongoDB):"
    if netstat -tuln | grep -q ":27017 "; then
        log "Port 27017 (MongoDB) est en écoute"
    else
        error "Port 27017 (MongoDB) n'est pas en écoute"
    fi
    echo ""
}

# Vérification des logs
check_logs() {
    info "8. Vérification des logs récents..."
    
    info "Logs PM2 (dernières lignes):"
    if [ -f "/var/log/supervisor/hygitech-3d-backend.err.log" ]; then
        tail -10 "/var/log/supervisor/hygitech-3d-backend.err.log" 2>/dev/null || warn "Impossible de lire les logs d'erreur"
    else
        warn "Fichier de logs d'erreur non trouvé"
    fi
    
    info "Logs système récents (hygitech):"
    journalctl --no-pager -u hygitech* --since "1 hour ago" -n 10 2>/dev/null || warn "Aucun log système trouvé"
    echo ""
}

# Recommandations
show_recommendations() {
    echo "=========================================="
    echo "RECOMMANDATIONS"
    echo "=========================================="
    
    info "Basé sur ce diagnostic, voici les actions recommandées:"
    
    if [ ! -d "$PROJECT_DIR" ]; then
        warn "1. Le répertoire principal n'existe pas - vérifiez l'installation"
    fi
    
    if ! getent passwd "$USER_NAME" > /dev/null 2>&1; then
        warn "2. Créer l'utilisateur $USER_NAME"
    fi
    
    if ! getent group "$GROUP_NAME" > /dev/null 2>&1; then
        warn "3. Créer le groupe $GROUP_NAME"
    fi
    
    if [ -d "$PROJECT_DIR" ] && [ ! -f "$PROJECT_DIR/backend/.env" ]; then
        warn "4. Créer le fichier .env backend"
    fi
    
    if [ -d "$PROJECT_DIR" ] && [ ! -f "$PROJECT_DIR/ecosystem.config.js" ]; then
        warn "5. Créer le fichier ecosystem.config.js"
    fi
    
    info "Pour corriger automatiquement ces problèmes, exécutez le script fix-all-permissions-hygitech3d.sh"
    echo ""
}

# Exécution principale
main() {
    log "Début du diagnostic Hygitech-3D..."
    echo ""
    
    check_project_directory
    check_user_group
    check_critical_files
    check_permissions
    check_pm2
    check_mongodb
    check_ports
    check_logs
    show_recommendations
    
    log "Diagnostic terminé!"
}

# Exécuter le script principal
main

exit 0