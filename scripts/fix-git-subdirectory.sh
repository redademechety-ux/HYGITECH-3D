#!/bin/bash

# Script pour corriger les problèmes de git clone avec sous-répertoires
# Déplace les fichiers du sous-répertoire vers le répertoire principal

set -e

echo "=========================================="
echo "CORRECTION PROBLÈME GIT CLONE SOUS-RÉPERTOIRE"
echo "=========================================="

# Variables
PROJECT_DIR="/var/www/hygitech-3d"
BACKUP_DIR="/tmp/hygitech-3d-backup-$(date +%Y%m%d-%H%M%S)"

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

# Fonction pour analyser la structure du répertoire
analyze_structure() {
    log "Analyse de la structure du répertoire..."
    
    if [ ! -d "$PROJECT_DIR" ]; then
        error "Le répertoire $PROJECT_DIR n'existe pas!"
        exit 1
    fi
    
    info "Contenu de $PROJECT_DIR:"
    ls -la "$PROJECT_DIR"
    
    # Chercher des sous-répertoires qui pourraient contenir le vrai projet
    info "Recherche de sous-répertoires contenant des fichiers du projet..."
    
    # Chercher des répertoires contenant server.py ou package.json
    find "$PROJECT_DIR" -name "server.py" -o -name "package.json" -o -name "requirements.txt" 2>/dev/null | while read file; do
        info "Fichier trouvé: $file"
    done
    
    # Chercher des répertoires qui ressemblent au projet
    find "$PROJECT_DIR" -type d -name "*hygitech*" 2>/dev/null | while read dir; do
        warn "Sous-répertoire suspect trouvé: $dir"
    done
}

# Fonction pour identifier le sous-répertoire problématique
identify_subdirectory() {
    log "Identification du sous-répertoire contenant les fichiers du projet..."
    
    # Chercher le répertoire contenant à la fois backend et frontend
    SUBDIRS=$(find "$PROJECT_DIR" -maxdepth 2 -type d -name "backend" -o -name "frontend" | head -10)
    
    if [ -z "$SUBDIRS" ]; then
        warn "Aucun sous-répertoire backend ou frontend trouvé"
        info "Structure actuelle du répertoire:"
        find "$PROJECT_DIR" -maxdepth 3 -type d | head -20
        return 1
    fi
    
    # Analyser chaque répertoire trouvé
    for dir in $SUBDIRS; do
        parent_dir=$(dirname "$dir")
        info "Vérification de $parent_dir"
        
        # Vérifier si c'est un répertoire du projet complet
        if [ -d "$parent_dir/backend" ] && [ -d "$parent_dir/frontend" ]; then
            warn "Répertoire de projet trouvé: $parent_dir"
            
            # Si ce n'est pas le répertoire principal, c'est probablement le problème
            if [ "$parent_dir" != "$PROJECT_DIR" ]; then
                error "Le projet semble être dans un sous-répertoire: $parent_dir"
                PROJECT_SUBDIR="$parent_dir"
                return 0
            fi
        fi
    done
    
    return 1
}

# Fonction pour créer une sauvegarde
create_backup() {
    log "Création d'une sauvegarde..."
    
    mkdir -p "$BACKUP_DIR"
    cp -r "$PROJECT_DIR" "$BACKUP_DIR/"
    
    log "Sauvegarde créée dans: $BACKUP_DIR"
}

# Fonction pour déplacer les fichiers
move_files() {
    if [ -z "$PROJECT_SUBDIR" ]; then
        error "Aucun sous-répertoire problématique identifié"
        return 1
    fi
    
    log "Déplacement des fichiers de $PROJECT_SUBDIR vers $PROJECT_DIR..."
    
    # Créer un répertoire temporaire
    TEMP_DIR="/tmp/hygitech-move-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$TEMP_DIR"
    
    # Déplacer tous les fichiers du sous-répertoire vers le répertoire temporaire
    mv "$PROJECT_SUBDIR"/* "$TEMP_DIR/" 2>/dev/null || warn "Certains fichiers n'ont pas pu être déplacés (fichiers cachés?)"
    
    # Déplacer les fichiers cachés aussi
    if ls "$PROJECT_SUBDIR"/.[!.]* 1> /dev/null 2>&1; then
        mv "$PROJECT_SUBDIR"/.[!.]* "$TEMP_DIR/" 2>/dev/null || warn "Certains fichiers cachés n'ont pas pu être déplacés"
    fi
    
    # Supprimer l'ancien contenu du répertoire principal (sauf le sous-répertoire)
    find "$PROJECT_DIR" -mindepth 1 -maxdepth 1 ! -path "$PROJECT_SUBDIR" -exec rm -rf {} \; 2>/dev/null || warn "Nettoyage partiel du répertoire principal"
    
    # Déplacer tous les fichiers du répertoire temporaire vers le répertoire principal
    mv "$TEMP_DIR"/* "$PROJECT_DIR/" 2>/dev/null
    if ls "$TEMP_DIR"/.[!.]* 1> /dev/null 2>&1; then
        mv "$TEMP_DIR"/.[!.]* "$PROJECT_DIR/" 2>/dev/null
    fi
    
    # Supprimer le sous-répertoire maintenant vide
    rmdir "$PROJECT_SUBDIR" 2>/dev/null || warn "Le sous-répertoire n'était pas complètement vide"
    
    # Nettoyer le répertoire temporaire
    rm -rf "$TEMP_DIR"
    
    log "Fichiers déplacés avec succès!"
}

# Fonction pour vérifier le résultat
verify_structure() {
    log "Vérification de la nouvelle structure..."
    
    info "Nouvelle structure du répertoire $PROJECT_DIR:"
    ls -la "$PROJECT_DIR"
    
    # Vérifier que les répertoires principaux sont présents
    if [ -d "$PROJECT_DIR/backend" ] && [ -d "$PROJECT_DIR/frontend" ]; then
        log "✅ Structure correcte: backend et frontend sont dans le répertoire principal"
    else
        error "❌ Problème: backend ou frontend manquant dans le répertoire principal"
    fi
    
    # Vérifier les fichiers critiques
    if [ -f "$PROJECT_DIR/backend/server.py" ]; then
        log "✅ server.py trouvé"
    else
        error "❌ server.py manquant"
    fi
    
    if [ -f "$PROJECT_DIR/frontend/package.json" ]; then
        log "✅ package.json trouvé"
    else
        error "❌ package.json manquant"
    fi
}

# Fonction principale
main() {
    log "Début de la correction du problème de sous-répertoire git..."
    
    # Étape 1: Analyser la structure
    analyze_structure
    
    # Étape 2: Identifier le problème
    if identify_subdirectory; then
        warn "Problème de sous-répertoire détecté!"
        
        # Étape 3: Créer une sauvegarde
        create_backup
        
        # Étape 4: Déplacer les fichiers
        if move_files; then
            # Étape 5: Vérifier le résultat
            verify_structure
            
            log "✅ Correction terminée avec succès!"
            info "Sauvegarde disponible dans: $BACKUP_DIR"
            info "Vous pouvez maintenant exécuter le script fix-all-permissions-hygitech3d.sh"
        else
            error "❌ Échec du déplacement des fichiers"
            error "La sauvegarde est disponible dans: $BACKUP_DIR"
            exit 1
        fi
    else
        log "Aucun problème de sous-répertoire détecté ou structure correcte"
        info "Si vous pensez qu'il y a encore un problème, vérifiez manuellement la structure"
    fi
}

# Afficher l'aide si demandé
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0"
    echo ""
    echo "Ce script corrige les problèmes causés par git clone qui copie les fichiers"
    echo "dans un sous-répertoire au lieu du répertoire principal."
    echo ""
    echo "Le script va:"
    echo "1. Analyser la structure du répertoire $PROJECT_DIR"
    echo "2. Identifier si les fichiers sont dans un sous-répertoire"
    echo "3. Créer une sauvegarde"
    echo "4. Déplacer les fichiers vers le répertoire principal"
    echo "5. Vérifier que la structure est correcte"
    echo ""
    echo "Une sauvegarde sera automatiquement créée avant toute modification."
    exit 0
fi

# Exécuter le script principal
main

exit 0