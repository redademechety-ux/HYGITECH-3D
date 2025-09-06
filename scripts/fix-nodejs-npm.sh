#!/bin/bash

# Script de correction pour installer Node.js et npm sur Ubuntu
# Compatible avec Ubuntu 20.04, 22.04, et 24.04

set -e

echo "=========================================="
echo "INSTALLATION NODE.JS ET NPM"
echo "=========================================="

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

# Fonction pour détecter la version d'Ubuntu
detect_ubuntu_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        UBUNTU_VERSION=$VERSION_CODENAME
        UBUNTU_VERSION_ID=$VERSION_ID
        log "Détection: Ubuntu $VERSION_ID ($VERSION_CODENAME)"
    else
        error "Impossible de détecter la version d'Ubuntu"
        exit 1
    fi
}

# Fonction pour nettoyer les installations précédentes
cleanup_previous_installations() {
    log "Nettoyage des installations précédentes..."
    
    # Arrêter les processus qui pourraient utiliser les paquets
    pkill -f node || true
    pkill -f npm || true
    
    # Suppression des paquets Node.js existants
    apt remove -y nodejs npm node 2>/dev/null || true
    apt purge -y nodejs npm node 2>/dev/null || true
    apt autoremove -y 2>/dev/null || true
    
    # Nettoyage des repositories et clés
    rm -f /etc/apt/sources.list.d/nodesource.list* 2>/dev/null || true
    rm -f /etc/apt/keyrings/nodesource.gpg* 2>/dev/null || true
    rm -f /usr/share/keyrings/nodesource.gpg* 2>/dev/null || true
    
    # Nettoyage des caches
    apt update 2>/dev/null || true
    
    log "Nettoyage terminé"
}

# Fonction pour installer Node.js via NodeSource (méthode recommandée)
install_nodejs_nodesource() {
    log "Installation de Node.js 18 via NodeSource..."
    
    # Mise à jour du système
    apt update && apt upgrade -y
    
    # Installation des dépendances
    apt install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release
    
    # Création du répertoire pour les clés GPG
    mkdir -p /etc/apt/keyrings
    
    # Téléchargement et installation de la clé GPG NodeSource (méthode moderne)
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    
    # Ajout du repository NodeSource
    NODE_MAJOR=18
    
    # Détecter la version d'Ubuntu pour le repository
    case $UBUNTU_VERSION in
        "focal"|"jammy"|"noble")
            DISTRO=$UBUNTU_VERSION
            ;;
        "mantic"|"lunar")
            DISTRO="jammy"  # Fallback pour les versions récentes
            warn "Version Ubuntu $UBUNTU_VERSION non officiellement supportée, utilisation de jammy"
            ;;
        *)
            DISTRO="jammy"  # Fallback par défaut
            warn "Version Ubuntu $UBUNTU_VERSION inconnue, utilisation de jammy"
            ;;
    esac
    
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x $DISTRO main" > /etc/apt/sources.list.d/nodesource.list
    
    # Mise à jour et installation
    apt update
    apt install -y nodejs
    
    # Vérification
    if node --version && npm --version; then
        log "✅ Node.js $(node --version) et npm $(npm --version) installés avec succès"
        return 0
    else
        error "❌ Échec de l'installation via NodeSource"
        return 1
    fi
}

# Fonction pour installer Node.js via Snap (méthode alternative)
install_nodejs_snap() {
    log "Installation de Node.js via Snap (méthode alternative)..."
    
    # Installation de snapd si nécessaire
    if ! command -v snap &> /dev/null; then
        apt update
        apt install -y snapd
        systemctl enable --now snapd
        # Attendre que snapd soit prêt
        sleep 10
    fi
    
    # Installation de Node.js via snap
    snap install node --classic
    
    # Créer des liens symboliques pour compatibilité
    ln -sf /snap/bin/node /usr/local/bin/node
    ln -sf /snap/bin/npm /usr/local/bin/npm
    
    # Vérification
    if node --version && npm --version; then
        log "✅ Node.js $(node --version) et npm $(npm --version) installés via Snap"
        return 0
    else
        error "❌ Échec de l'installation via Snap"
        return 1
    fi
}

# Fonction pour installer Node.js via les repositories Ubuntu (dernière option)
install_nodejs_ubuntu() {
    log "Installation de Node.js via les repositories Ubuntu (version système)..."
    
    apt update
    apt install -y nodejs npm
    
    # Vérification
    if node --version && npm --version; then
        log "✅ Node.js $(node --version) et npm $(npm --version) installés via Ubuntu"
        warn "⚠️  Note: Cette version peut être plus ancienne que la version 18"
        return 0
    else
        error "❌ Échec de l'installation via Ubuntu repositories"
        return 1
    fi
}

# Fonction pour installer Yarn
install_yarn() {
    log "Installation de Yarn..."
    
    if ! command -v yarn &> /dev/null; then
        # Installation via npm (méthode recommandée maintenant)
        npm install -g yarn
        
        if yarn --version; then
            log "✅ Yarn $(yarn --version) installé"
        else
            warn "❌ Échec de l'installation de Yarn"
        fi
    else
        log "✅ Yarn déjà installé: $(yarn --version)"
    fi
}

# Fonction pour installer PM2
install_pm2() {
    log "Installation de PM2..."
    
    if ! command -v pm2 &> /dev/null; then
        npm install -g pm2
        
        if pm2 --version; then
            log "✅ PM2 $(pm2 --version) installé"
        else
            warn "❌ Échec de l'installation de PM2"
        fi
    else
        log "✅ PM2 déjà installé: $(pm2 --version)"
    fi
}

# Fonction pour tester l'installation
test_installation() {
    log "Test de l'installation..."
    
    echo ""
    info "Versions installées:"
    echo "Node.js: $(node --version 2>/dev/null || echo 'Non installé')"
    echo "npm: $(npm --version 2>/dev/null || echo 'Non installé')"
    echo "Yarn: $(yarn --version 2>/dev/null || echo 'Non installé')"
    echo "PM2: $(pm2 --version 2>/dev/null || echo 'Non installé')"
    
    # Test simple de npm
    info "Test de npm..."
    if npm --version > /dev/null 2>&1; then
        log "✅ npm fonctionne correctement"
    else
        error "❌ npm ne fonctionne pas"
        return 1
    fi
    
    # Test du PATH
    info "Vérification du PATH..."
    echo "Node.js PATH: $(which node 2>/dev/null || echo 'Non trouvé')"
    echo "npm PATH: $(which npm 2>/dev/null || echo 'Non trouvé')"
}

# Fonction principale
main() {
    log "Début de l'installation Node.js et npm..."
    
    # Vérification des privilèges root
    if [ "$EUID" -ne 0 ]; then 
        error "Ce script doit être exécuté avec sudo"
        exit 1
    fi
    
    # Détection de la version Ubuntu
    detect_ubuntu_version
    
    # Nettoyage des installations précédentes
    cleanup_previous_installations
    
    # Tentative d'installation avec plusieurs méthodes
    log "Tentatives d'installation Node.js..."
    
    if install_nodejs_nodesource; then
        log "✅ Installation réussie via NodeSource"
    elif install_nodejs_snap; then
        log "✅ Installation réussie via Snap"
    elif install_nodejs_ubuntu; then
        log "✅ Installation réussie via Ubuntu repositories"
    else
        error "❌ Toutes les méthodes d'installation ont échoué"
        exit 1
    fi
    
    # Installation des outils complémentaires
    install_yarn
    install_pm2
    
    # Test final
    test_installation
    
    echo ""
    log "✅ Installation Node.js et npm terminée avec succès!"
    info "Vous pouvez maintenant relancer le script install-hygitech-3d.sh"
}

# Afficher l'aide si demandé
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: sudo $0"
    echo ""
    echo "Ce script installe Node.js, npm, Yarn et PM2 sur Ubuntu."
    echo ""
    echo "Le script essaie plusieurs méthodes d'installation:"
    echo "1. NodeSource (recommandé) - Node.js 18"
    echo "2. Snap (alternatif) - Version stable"
    echo "3. Ubuntu repositories (dernier recours) - Version système"
    echo ""
    echo "Options:"
    echo "  --help, -h    Afficher cette aide"
    exit 0
fi

# Exécuter le script principal
main

exit 0