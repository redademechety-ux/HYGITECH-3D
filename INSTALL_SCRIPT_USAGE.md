# Script d'Installation HYGITECH-3D - Version Corrigée

## 🚀 Améliorations apportées

Le script `install-hygitech-3d.sh` a été entièrement corrigé pour résoudre les problèmes d'installation de Node.js et npm.

### ✅ Corrections principales

1. **Installation Node.js robuste** avec 3 méthodes de fallback :
   - **Méthode 1:** NodeSource (recommandée) - Node.js 18
   - **Méthode 2:** Snap (fallback automatique)
   - **Méthode 3:** NVM (dernière tentative)

2. **Correction du bug "nodistro"** :
   - Détection automatique de la distribution Ubuntu
   - Support pour Ubuntu 20.04 (focal), 22.04 (jammy), 24.04 (noble)
   - Fallback intelligent vers jammy pour les versions non supportées

3. **Installation Yarn améliorée** :
   - Méthode 1: Via npm (recommandée maintenant)
   - Méthode 2: Repository Yarn (fallback)

4. **Installation PM2 sécurisée** :
   - Vérification de l'installation
   - Gestion des erreurs

5. **Nettoyage automatique** :
   - Suppression des installations ratées précédentes
   - Nettoyage des repositories corrompus

6. **Validation complète** :
   - Vérification de tous les outils installés
   - Résumé des versions
   - Échec rapide si outils critiques manquants

## 📋 Utilisation

### Commande d'installation

```bash
# Avec repository GitHub (recommandé)
sudo ./install-hygitech-3d.sh https://github.com/VOTRE-USERNAME/hygitech-3d.git

# Sans repository GitHub (installation manuelle des fichiers)
sudo ./install-hygitech-3d.sh
```

### Prérequis

- Ubuntu 20.04, 22.04, ou 24.04
- Accès root (sudo)
- Connexion internet stable

## 🔧 Résolution des problèmes

### Si l'installation Node.js échoue encore

Le script essaie automatiquement 3 méthodes. Si toutes échouent :

1. **Vérifiez votre connexion internet**
2. **Exécutez le script de diagnostic** :
   ```bash
   sudo ./scripts/diagnostic-hygitech3d.sh
   ```
3. **Utilisez le script de correction Node.js** :
   ```bash
   sudo ./scripts/fix-nodejs-npm.sh
   ```

### Messages d'erreur courants

#### "command not found: npm"
✅ **Résolu** - Le script utilise maintenant plusieurs méthodes d'installation

#### "nodistro main" repository error
✅ **Résolu** - Détection automatique de la distribution Ubuntu

#### "GPG key error"
✅ **Résolu** - Nettoyage automatique des clés corrompues

#### "Package conflicts"
✅ **Résolu** - Nettoyage préventif des installations précédentes

## 📊 Processus d'installation

1. **Vérifications préliminaires**
   - Privilèges root
   - Port disponible
   - Repository GitHub (optionnel)

2. **Installation des dépendances système**
   - Mise à jour système
   - Outils de base (curl, wget, git, nginx, etc.)
   - Nettoyage préventif

3. **Installation Node.js robuste**
   - Tentative NodeSource
   - Fallback Snap si échec
   - Fallback NVM si échec
   - Validation des installations

4. **Installation des outils complémentaires**
   - Yarn (via npm ou repository)
   - PM2 (avec vérification)

5. **Installation MongoDB**
   - Repository MongoDB
   - Configuration de base

6. **Installation Python et FastAPI**
   - Python 3.x
   - pip et virtualenv
   - Dépendances Python

7. **Configuration des services**
   - Utilisateur système
   - Permissions
   - Nginx
   - PM2
   - SSL (Let's Encrypt)

8. **Déploiement de l'application**
   - Clone GitHub ou files locaux
   - Installation des dépendances
   - Configuration des variables d'environnement
   - Démarrage des services

9. **Tests finaux**
   - Backend (port 8002)
   - Frontend
   - Base de données
   - SSL

## ⚡ Avantages de la version corrigée

- **Plus fiable** : 3 méthodes d'installation Node.js
- **Plus rapide** : Nettoyage automatique des échecs
- **Plus smart** : Détection automatique Ubuntu
- **Plus robuste** : Gestion complète des erreurs
- **Plus transparent** : Validation et résumés complets

## 🚀 Temps d'installation estimé

- **Installation complète** : 10-15 minutes
- **Node.js seulement** : 2-3 minutes
- **Réinstallation après correction** : 5-8 minutes

## 📞 Support

Si vous rencontrez encore des problèmes après ces corrections :

1. Exécutez le diagnostic complet
2. Vérifiez les logs d'installation
3. Utilisez les scripts de correction dans `/scripts/`