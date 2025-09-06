#!/bin/bash

# Script d'installation et configuration serveur FTP pour HYGITECH-3D
# Serveur: vsftpd (Very Secure FTP Daemon)
# Accès: utilisateur ubuntu vers /var/www/

set -e

echo "=========================================="
echo "INSTALLATION SERVEUR FTP SÉCURISÉ"
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

# Configuration
FTP_USER="ubuntu"
FTP_ROOT="/var/www"
FTP_PORT="21"
PASSIVE_MIN_PORT="40000"
PASSIVE_MAX_PORT="40100"

# Vérification des privilèges root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Ce script doit être exécuté avec sudo"
        exit 1
    fi
    log "Privilèges root confirmés"
}

# Détection de la distribution
detect_system() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        log "Système détecté: $OS $VER"
    else
        error "Impossible de détecter le système"
        exit 1
    fi
    
    # Vérifier Ubuntu/Debian
    if [[ "$OS" != *"Ubuntu"* && "$OS" != *"Debian"* ]]; then
        warn "Ce script est optimisé pour Ubuntu/Debian"
        read -p "Continuer quand même ? (y/N): " CONTINUE
        if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Sauvegarde des configurations existantes
backup_configs() {
    log "Sauvegarde des configurations existantes..."
    
    BACKUP_DIR="/root/ftp-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Sauvegarder vsftpd.conf s'il existe
    if [[ -f /etc/vsftpd.conf ]]; then
        cp /etc/vsftpd.conf "$BACKUP_DIR/vsftpd.conf.bak"
        log "Configuration vsftpd sauvegardée"
    fi
    
    # Sauvegarder les règles UFW
    if command -v ufw >/dev/null 2>&1; then
        ufw status numbered > "$BACKUP_DIR/ufw-rules.bak" 2>/dev/null || true
    fi
    
    info "Sauvegardes créées dans: $BACKUP_DIR"
}

# Installation de vsftpd
install_vsftpd() {
    log "Installation du serveur FTP vsftpd..."
    
    # Mise à jour des paquets
    apt update
    
    # Installation de vsftpd et outils
    apt install -y vsftpd ufw
    
    # Vérification de l'installation
    if systemctl is-enabled vsftpd >/dev/null 2>&1; then
        log "vsftpd installé et activé"
    else
        error "Échec de l'installation de vsftpd"
        exit 1
    fi
}

# Configuration de l'utilisateur FTP
configure_ftp_user() {
    log "Configuration de l'utilisateur FTP: $FTP_USER"
    
    # Vérifier que l'utilisateur existe
    if ! id "$FTP_USER" >/dev/null 2>&1; then
        log "Création de l'utilisateur $FTP_USER..."
        useradd -m -s /bin/bash "$FTP_USER"
        
        # Définir un mot de passe
        info "Définition du mot de passe pour $FTP_USER"
        passwd "$FTP_USER"
    else
        log "Utilisateur $FTP_USER existe déjà"
    fi
    
    # Ajouter l'utilisateur au groupe www-data pour les permissions web
    usermod -a -G www-data "$FTP_USER"
    
    # Créer le répertoire home s'il n'existe pas
    FTP_HOME="/home/$FTP_USER"
    if [[ ! -d "$FTP_HOME" ]]; then
        mkdir -p "$FTP_HOME"
        chown "$FTP_USER:$FTP_USER" "$FTP_HOME"
    fi
    
    log "Utilisateur $FTP_USER configuré"
}

# Configuration des permissions /var/www
configure_www_permissions() {
    log "Configuration des permissions pour $FTP_ROOT..."
    
    # Créer /var/www s'il n'existe pas
    if [[ ! -d "$FTP_ROOT" ]]; then
        mkdir -p "$FTP_ROOT"
        log "Répertoire $FTP_ROOT créé"
    fi
    
    # Configuration des permissions
    # Le groupe www-data aura accès en lecture/écriture
    chgrp -R www-data "$FTP_ROOT"
    chmod -R 775 "$FTP_ROOT"
    
    # Assurer que les nouveaux fichiers héritent du groupe
    chmod g+s "$FTP_ROOT"
    
    # Créer un lien symbolique dans le home de l'utilisateur FTP
    FTP_LINK="$FTP_HOME/www"
    if [[ ! -L "$FTP_LINK" ]]; then
        ln -sf "$FTP_ROOT" "$FTP_LINK"
        chown -h "$FTP_USER:$FTP_USER" "$FTP_LINK"
        log "Lien symbolique créé: $FTP_LINK -> $FTP_ROOT"
    fi
    
    log "Permissions configurées pour $FTP_ROOT"
}

# Configuration de vsftpd
configure_vsftpd() {
    log "Configuration du serveur vsftpd..."
    
    # Arrêter le service pour la configuration
    systemctl stop vsftpd
    
    # Créer la configuration vsftpd
    cat > /etc/vsftpd.conf << 'EOF'
# Configuration vsftpd pour HYGITECH-3D
# Générée automatiquement

# Écoute sur IPv4
listen=YES
listen_ipv6=NO

# Accès anonyme désactivé
anonymous_enable=NO

# Accès utilisateurs locaux activé
local_enable=YES

# Permissions d'écriture
write_enable=YES
local_umask=002

# Messages et logs
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
xferlog_std_format=YES
xferlog_file=/var/log/vsftpd.log

# Connexions
connect_from_port_20=YES
ftpd_banner=Serveur FTP HYGITECH-3D

# Sécurité
chroot_local_user=YES
allow_writeable_chroot=YES
secure_chroot_dir=/var/run/vsftpd/empty

# Mode passif (important pour les connexions à travers firewall/NAT)
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100

# Limites de connexion
max_clients=10
max_per_ip=3

# Performance
local_max_rate=1000000

# SSL/TLS (optionnel, décommentez si certificat SSL disponible)
#ssl_enable=YES
#allow_anon_ssl=NO
#force_local_data_ssl=NO
#force_local_logins_ssl=NO
#ssl_tlsv1=YES
#ssl_sslv2=NO
#ssl_sslv3=NO
#rsa_cert_file=/etc/ssl/certs/vsftpd.pem

# Utilisateurs autorisés
userlist_enable=YES
userlist_file=/etc/vsftpd.userlist
userlist_deny=NO

# Options avancées
tcp_wrappers=YES
hide_ids=YES
EOF

    # Créer la liste des utilisateurs autorisés
    echo "$FTP_USER" > /etc/vsftpd.userlist
    
    # Créer le répertoire sécurisé pour chroot
    mkdir -p /var/run/vsftpd/empty
    
    # Ajuster les permissions
    chmod 644 /etc/vsftpd.conf
    chmod 644 /etc/vsftpd.userlist
    
    log "Configuration vsftpd créée"
}

# Configuration du firewall
configure_firewall() {
    log "Configuration du firewall pour FTP..."
    
    # Activer UFW s'il ne l'est pas déjà
    if ! ufw status | grep -q "Status: active"; then
        info "Activation du firewall UFW..."
        ufw --force enable
    fi
    
    # Règles FTP
    ufw allow $FTP_PORT/tcp comment "FTP Control"
    ufw allow $PASSIVE_MIN_PORT:$PASSIVE_MAX_PORT/tcp comment "FTP Passive Mode"
    
    # Règles SSH (important pour ne pas se bloquer)
    ufw allow 22/tcp comment "SSH"
    
    # Règles web (HTTP/HTTPS)
    ufw allow 80/tcp comment "HTTP"
    ufw allow 443/tcp comment "HTTPS"
    
    # Recharger le firewall
    ufw reload
    
    log "Firewall configuré pour FTP"
    
    # Afficher le statut
    info "État du firewall:"
    ufw status numbered
}

# Démarrage et activation des services
start_services() {
    log "Démarrage des services FTP..."
    
    # Activer et démarrer vsftpd
    systemctl enable vsftpd
    systemctl start vsftpd
    
    # Vérifier le statut
    if systemctl is-active --quiet vsftpd; then
        log "✅ Service vsftpd démarré et actif"
    else
        error "❌ Échec du démarrage de vsftpd"
        info "Logs d'erreur:"
        journalctl -u vsftpd --no-pager -l -n 10
        exit 1
    fi
}

# Tests de connectivité
test_ftp_server() {
    log "Tests du serveur FTP..."
    
    # Test 1: Port d'écoute
    info "Test 1: Vérification du port d'écoute..."
    if netstat -tuln | grep -q ":$FTP_PORT "; then
        log "✅ Port $FTP_PORT en écoute"
    else
        error "❌ Port $FTP_PORT non accessible"
    fi
    
    # Test 2: Connexion locale
    info "Test 2: Test de connexion FTP locale..."
    if command -v ftp >/dev/null 2>&1; then
        # Installer client FTP si pas présent
        apt install -y ftp >/dev/null 2>&1
    fi
    
    # Test simple de connexion (sans authentification)
    if timeout 5 bash -c "</dev/tcp/localhost/$FTP_PORT" 2>/dev/null; then
        log "✅ Connexion FTP locale possible"
    else
        warn "⚠️  Test de connexion locale échoué (peut être normal selon la configuration)"
    fi
    
    # Test 3: Vérification des logs
    info "Test 3: Vérification des logs..."
    if [[ -f /var/log/vsftpd.log ]]; then
        log "✅ Fichier de logs créé"
    else
        warn "⚠️  Fichier de logs non encore créé"
    fi
}

# Affichage des informations de connexion
show_connection_info() {
    echo ""
    echo "=========================================="
    echo "INFORMATIONS DE CONNEXION FTP"
    echo "=========================================="
    
    # Obtenir l'IP du serveur
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    info "Serveur FTP configuré avec succès !"
    echo ""
    echo "📋 Informations de connexion :"
    echo "  🌐 Adresse : $SERVER_IP"
    echo "  🔌 Port : $FTP_PORT"
    echo "  👤 Utilisateur : $FTP_USER"
    echo "  📁 Répertoire web : $FTP_ROOT"
    echo "  🔗 Lien symbolique : /home/$FTP_USER/www -> $FTP_ROOT"
    echo ""
    echo "🔧 Ports du firewall ouverts :"
    echo "  • Port $FTP_PORT (contrôle FTP)"
    echo "  • Ports $PASSIVE_MIN_PORT-$PASSIVE_MAX_PORT (mode passif)"
    echo ""
    echo "📱 Clients FTP recommandés :"
    echo "  • FileZilla (Windows/Mac/Linux)"
    echo "  • WinSCP (Windows)"
    echo "  • Cyberduck (Mac)"
    echo "  • Total Commander (Windows)"
    echo ""
    echo "⚙️  Configuration FileZilla :"
    echo "  Hôte : $SERVER_IP"
    echo "  Port : $FTP_PORT"
    echo "  Protocole : FTP"
    echo "  Utilisateur : $FTP_USER"
    echo "  Mot de passe : [celui défini lors de l'installation]"
    echo "  Mode de transfert : Passif (recommandé)"
    echo ""
    
    warn "🔐 SÉCURITÉ IMPORTANTE :"
    echo "  • Le mot de passe FTP transite en clair"
    echo "  • Utilisez uniquement sur des réseaux de confiance"
    echo "  • Considérez l'activation SSL/TLS pour la production"
    echo "  • Changez régulièrement le mot de passe"
    echo ""
    
    info "🧪 Test rapide :"
    echo "  ftp $SERVER_IP"
    echo "  (utilisateur: $FTP_USER, mot de passe: celui défini)"
    echo ""
}

# Affichage des commandes de gestion
show_management_commands() {
    echo "🔧 Commandes de gestion :"
    echo ""
    echo "  # Statut du service"
    echo "  sudo systemctl status vsftpd"
    echo ""
    echo "  # Redémarrer le service"
    echo "  sudo systemctl restart vsftpd"
    echo ""
    echo "  # Voir les logs"
    echo "  sudo tail -f /var/log/vsftpd.log"
    echo ""
    echo "  # Voir les connexions actives"
    echo "  sudo netstat -tuln | grep :$FTP_PORT"
    echo ""
    echo "  # Ajouter un utilisateur FTP"
    echo "  echo 'nouvel_utilisateur' | sudo tee -a /etc/vsftpd.userlist"
    echo ""
    echo "  # Modifier les permissions /var/www"
    echo "  sudo chown -R $FTP_USER:www-data /var/www"
    echo "  sudo chmod -R 775 /var/www"
    echo ""
    
    info "📁 Fichiers de configuration :"
    echo "  • /etc/vsftpd.conf (configuration principale)"
    echo "  • /etc/vsftpd.userlist (utilisateurs autorisés)"
    echo "  • /var/log/vsftpd.log (logs du serveur)"
    echo ""
}

# Installation SSL/TLS optionnelle
setup_ssl_option() {
    read -p "Voulez-vous configurer SSL/TLS pour sécuriser les connexions FTP ? (y/N): " SETUP_SSL
    
    if [[ "$SETUP_SSL" =~ ^[Yy]$ ]]; then
        log "Configuration SSL/TLS pour vsftpd..."
        
        # Générer un certificat auto-signé
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /etc/ssl/private/vsftpd.pem \
            -out /etc/ssl/private/vsftpd.pem \
            -subj "/C=FR/ST=IDF/L=Paris/O=HYGITECH-3D/CN=$SERVER_IP" 2>/dev/null
        
        chmod 600 /etc/ssl/private/vsftpd.pem
        
        # Activer SSL dans la configuration
        sed -i 's/#ssl_enable=YES/ssl_enable=YES/' /etc/vsftpd.conf
        sed -i 's/#rsa_cert_file=\/etc\/ssl\/certs\/vsftpd.pem/rsa_cert_file=\/etc\/ssl\/private\/vsftpd.pem/' /etc/vsftpd.conf
        
        # Redémarrer le service
        systemctl restart vsftpd
        
        log "✅ SSL/TLS configuré (certificat auto-signé)"
        warn "Pour la production, remplacez par un certificat valide"
    fi
}

# Fonction principale
main() {
    log "Début de l'installation du serveur FTP..."
    
    check_root
    detect_system
    backup_configs
    install_vsftpd
    configure_ftp_user
    configure_www_permissions
    configure_vsftpd
    configure_firewall
    start_services
    test_ftp_server
    
    # Option SSL
    setup_ssl_option
    
    show_connection_info
    show_management_commands
    
    log "🎉 Installation du serveur FTP terminée avec succès !"
}

# Afficher l'aide si demandé
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: sudo $0"
    echo ""
    echo "Ce script installe et configure un serveur FTP sécurisé (vsftpd)"
    echo "avec accès au répertoire /var/www pour l'utilisateur ubuntu."
    echo ""
    echo "Fonctionnalités:"
    echo "  • Installation de vsftpd"
    echo "  • Configuration utilisateur ubuntu"
    echo "  • Permissions sur /var/www"
    echo "  • Configuration firewall"
    echo "  • SSL/TLS optionnel"
    echo "  • Tests automatiques"
    echo ""
    echo "Après installation:"
    echo "  • Connexion FTP possible avec l'utilisateur ubuntu"
    echo "  • Accès direct au répertoire /var/www"
    echo "  • Lien symbolique /home/ubuntu/www -> /var/www"
    echo ""
    exit 0
fi

# Exécuter le script principal
main

exit 0