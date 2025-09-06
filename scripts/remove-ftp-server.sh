#!/bin/bash

# Script de désinstallation du serveur FTP
# Supprime vsftpd et nettoie la configuration

set -e

echo "=========================================="
echo "DÉSINSTALLATION SERVEUR FTP"
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

# Vérification des privilèges root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Ce script doit être exécuté avec sudo"
        exit 1
    fi
    log "Privilèges root confirmés"
}

# Arrêt et désactivation du service
stop_service() {
    log "Arrêt du service vsftpd..."
    
    if systemctl is-active --quiet vsftpd; then
        systemctl stop vsftpd
        log "Service vsftpd arrêté"
    fi
    
    if systemctl is-enabled --quiet vsftpd; then
        systemctl disable vsftpd
        log "Service vsftpd désactivé"
    fi
}

# Suppression des paquets
remove_packages() {
    log "Suppression des paquets FTP..."
    
    apt remove --purge -y vsftpd
    apt autoremove -y
    
    log "Paquets supprimés"
}

# Nettoyage des configurations
cleanup_configs() {
    log "Nettoyage des fichiers de configuration..."
    
    # Supprimer les fichiers de configuration
    rm -f /etc/vsftpd.conf
    rm -f /etc/vsftpd.userlist
    rm -f /etc/ssl/private/vsftpd.pem
    
    # Supprimer les répertoires
    rm -rf /var/run/vsftpd
    
    log "Configurations supprimées"
}

# Nettoyage des règles firewall
cleanup_firewall() {
    log "Nettoyage des règles firewall..."
    
    if command -v ufw >/dev/null 2>&1; then
        # Supprimer les règles FTP
        ufw delete allow 21/tcp 2>/dev/null || true
        ufw delete allow 40000:40100/tcp 2>/dev/null || true
        
        ufw reload
        log "Règles firewall FTP supprimées"
    fi
}

# Nettoyage des liens symboliques
cleanup_links() {
    log "Nettoyage des liens symboliques..."
    
    # Supprimer le lien www dans le home ubuntu
    if [[ -L /home/ubuntu/www ]]; then
        rm /home/ubuntu/www
        log "Lien symbolique /home/ubuntu/www supprimé"
    fi
}

# Fonction principale
main() {
    log "Début de la désinstallation du serveur FTP..."
    
    warn "Cette opération va supprimer complètement le serveur FTP"
    read -p "Êtes-vous sûr de vouloir continuer ? (y/N): " CONFIRM
    
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        info "Désinstallation annulée"
        exit 0
    fi
    
    check_root
    stop_service
    remove_packages
    cleanup_configs
    cleanup_firewall
    cleanup_links
    
    log "🎉 Serveur FTP désinstallé avec succès !"
    info "Les permissions sur /var/www sont conservées"
}

# Exécuter le script principal
main

exit 0