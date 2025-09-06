#!/bin/bash

# Script de test pour valider le clone GitHub automatique

set -e

echo "=========================================="
echo "TEST DU CLONE GITHUB AUTOMATIQUE"
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

# Configuration de test
TEST_DIR="/tmp/hygitech-test-$(date +%s)"
GITHUB_REPO=${1:-"https://github.com/VOTRE-USERNAME/hygitech-3d.git"}

# Fonction de test du clone
test_github_clone() {
    log "Test du clone GitHub : $GITHUB_REPO"
    
    # Créer le répertoire de test
    mkdir -p "$TEST_DIR"
    
    # Test 1: Vérification de l'accessibilité
    info "Test 1: Vérification de l'accessibilité du repository..."
    if curl -s --connect-timeout 10 --head "$GITHUB_REPO" | head -1 | grep -q "200\|301\|302"; then
        log "✅ Repository accessible"
    else
        error "❌ Repository non accessible"
        return 1
    fi
    
    # Test 2: Clone direct
    info "Test 2: Clone direct du repository..."
    if git clone "$GITHUB_REPO" "$TEST_DIR/direct-clone"; then
        log "✅ Clone direct réussi"
        
        # Vérifier la structure
        if [[ -d "$TEST_DIR/direct-clone/frontend" && -d "$TEST_DIR/direct-clone/backend" ]]; then
            log "✅ Structure frontend/backend détectée au niveau racine"
        else
            # Chercher dans les sous-répertoires
            FOUND_FRONTEND=$(find "$TEST_DIR/direct-clone" -name "frontend" -type d | head -1)
            FOUND_BACKEND=$(find "$TEST_DIR/direct-clone" -name "backend" -type d | head -1)
            
            if [[ -n "$FOUND_FRONTEND" && -n "$FOUND_BACKEND" ]]; then
                warn "⚠️  Structure imbriquée détectée"
                info "Frontend trouvé dans: $FOUND_FRONTEND"
                info "Backend trouvé dans: $FOUND_BACKEND"
                PARENT_DIR=$(dirname "$FOUND_FRONTEND")
                info "Répertoire parent: $PARENT_DIR"
            else
                error "❌ Structure frontend/backend non trouvée"
                info "Contenu du repository:"
                ls -la "$TEST_DIR/direct-clone"
                return 1
            fi
        fi
    else
        error "❌ Échec du clone direct"
        return 1
    fi
    
    # Test 3: Simulation de la correction automatique
    info "Test 3: Simulation de la correction automatique..."
    if [[ -n "$PARENT_DIR" && "$PARENT_DIR" != "$TEST_DIR/direct-clone" ]]; then
        # Créer un répertoire de simulation
        mkdir -p "$TEST_DIR/auto-fix"
        
        # Copier le contenu du répertoire parent
        cp -r "$PARENT_DIR"/* "$TEST_DIR/auto-fix/" 2>/dev/null || true
        cp -r "$PARENT_DIR"/.* "$TEST_DIR/auto-fix/" 2>/dev/null || true
        
        if [[ -d "$TEST_DIR/auto-fix/frontend" && -d "$TEST_DIR/auto-fix/backend" ]]; then
            log "✅ Correction automatique simulée avec succès"
        else
            error "❌ Échec de la correction automatique simulée"
            return 1
        fi
    fi
    
    # Test 4: Vérification des fichiers critiques
    info "Test 4: Vérification des fichiers critiques..."
    
    FRONTEND_DIR=""
    BACKEND_DIR=""
    
    if [[ -d "$TEST_DIR/auto-fix/frontend" ]]; then
        FRONTEND_DIR="$TEST_DIR/auto-fix/frontend"
        BACKEND_DIR="$TEST_DIR/auto-fix/backend"
    elif [[ -d "$TEST_DIR/direct-clone/frontend" ]]; then
        FRONTEND_DIR="$TEST_DIR/direct-clone/frontend"
        BACKEND_DIR="$TEST_DIR/direct-clone/backend"
    fi
    
    if [[ -n "$FRONTEND_DIR" ]]; then
        if [[ -f "$FRONTEND_DIR/package.json" ]]; then
            log "✅ package.json trouvé dans frontend"
        else
            error "❌ package.json manquant dans frontend"
        fi
        
        if [[ -f "$BACKEND_DIR/requirements.txt" ]]; then
            log "✅ requirements.txt trouvé dans backend"
        else
            error "❌ requirements.txt manquant dans backend"
        fi
        
        if [[ -f "$BACKEND_DIR/server.py" ]]; then
            log "✅ server.py trouvé dans backend"
        else
            error "❌ server.py manquant dans backend"
        fi
    fi
    
    # Nettoyage
    rm -rf "$TEST_DIR"
    
    log "✅ Test terminé avec succès"
    return 0
}

# Test avec différents formats d'URL
test_url_formats() {
    log "Test des différents formats d'URL..."
    
    # Format original fourni
    info "Format original: $1"
    
    # Générer des variantes
    VARIANTS=(
        "$1"
        "${1%.git}.git"
        "${1%.git}"
    )
    
    for variant in "${VARIANTS[@]}"; do
        info "Test de: $variant"
        if curl -s --connect-timeout 5 --head "$variant" | head -1 | grep -q "200\|301\|302"; then
            log "✅ $variant accessible"
        else
            warn "❌ $variant non accessible"
        fi
    done
}

# Fonction principale
main() {
    log "Début du test du clone GitHub automatique..."
    
    if [[ -z "$1" ]]; then
        error "Usage: $0 <URL_GITHUB>"
        error "Exemple: $0 https://github.com/username/hygitech-3d.git"
        error "Ou: $0 username/hygitech-3d"
        exit 1
    fi
    
    # Test des formats d'URL
    test_url_formats "$1"
    
    echo ""
    
    # Test du clone principal
    if test_github_clone; then
        log "🎉 Tous les tests sont passés avec succès!"
        info "Le script d'installation devrait fonctionner correctement avec ce repository."
    else
        error "❌ Des tests ont échoué."
        error "Le repository pourrait ne pas être compatible ou accessible."
        exit 1
    fi
}

# Afficher l'aide si demandé
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 <URL_GITHUB>"
    echo ""
    echo "Ce script teste la capacité du script d'installation à cloner"
    echo "automatiquement un repository GitHub et à en extraire les"
    echo "répertoires frontend et backend."
    echo ""
    echo "Exemples:"
    echo "  $0 https://github.com/username/hygitech-3d.git"
    echo "  $0 username/hygitech-3d"
    echo ""
    echo "Le script teste:"
    echo "1. L'accessibilité du repository"
    echo "2. Le clone direct"
    echo "3. La détection de structure frontend/backend"
    echo "4. La correction automatique si structure imbriquée"
    echo "5. La présence des fichiers critiques"
    exit 0
fi

# Exécuter le script principal
main "$@"

exit 0