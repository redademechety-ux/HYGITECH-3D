# Changelog - Script d'Installation HYGITECH-3D

## Version 2.0 - Corrections Majeures (Septembre 2025)

### 🐛 Corrections critiques

#### Problème résolu : `npm: command not found`
- **Cause** : Erreur dans l'URL du repository NodeSource (`nodistro` au lieu de la vraie distribution)
- **Solution** : Détection automatique de la distribution Ubuntu avec fallbacks

#### Installation Node.js robuste
- ✅ **Méthode 1** : NodeSource (recommandée)
  - Détection automatique Ubuntu (focal/jammy/noble)
  - Fallback intelligent pour versions non supportées
- ✅ **Méthode 2** : Snap (fallback automatique)
  - Installation snapd si nécessaire
  - Liens symboliques automatiques
- ✅ **Méthode 3** : NVM (dernière tentative)
  - Installation Node.js 18 via NVM
  - Configuration globale automatique

### 🔧 Améliorations techniques

#### Nettoyage automatique
```bash
cleanup_failed_nodejs_installation()
```
- Suppression des installations ratées
- Nettoyage des repositories corrompus
- Suppression des conflits de paquets

#### Installation Yarn améliorée
- **Nouvelle méthode** : Via npm (recommandée)
- **Fallback** : Repository Yarn officiel
- **Tolérance** : Continue si Yarn échoue (npm suffisant)

#### Validation complète
- Vérification de tous les outils installés
- Résumé des versions après installation
- Échec rapide si outils critiques manquants

### 📋 Détails des corrections

#### Avant (❌ Problématique)
```bash
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main"
```

#### Après (✅ Corrigé)
```bash
# Détection automatique de la distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_CODENAME=$VERSION_CODENAME
else
    DISTRO_CODENAME="jammy"  # Fallback Ubuntu 22.04
fi

# Fallback pour versions non supportées
case $DISTRO_CODENAME in
    "focal"|"jammy"|"noble") ;;
    *)
        log_warning "Version Ubuntu $DISTRO_CODENAME non supportée, utilisation de jammy"
        DISTRO_CODENAME="jammy"
        ;;
esac

echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x $DISTRO_CODENAME main"
```

### 🚀 Nouvelles fonctionnalités

#### Installation avec retry automatique
```bash
# Tentative NodeSource
if install_method_1; then
    success
elif install_method_2; then  # Fallback Snap
    success  
elif install_method_3; then  # Fallback NVM
    success
else
    exit 1  # Échec de toutes les méthodes
fi
```

#### Gestion d'erreurs avancée
- Logs détaillés pour chaque étape
- Messages d'erreur explicites
- Suggestions de correction automatique

#### Support multi-versions Ubuntu
- ✅ Ubuntu 20.04 (Focal Fossa)
- ✅ Ubuntu 22.04 (Jammy Jellyfish)  
- ✅ Ubuntu 24.04 (Noble Numbat)
- ✅ Versions futures (fallback automatique)

### 📊 Tests de compatibilité

| Ubuntu Version | Status | NodeSource | Snap | NVM |
|----------------|--------|------------|------|-----|
| 20.04 (focal)  | ✅ Testé | ✅ | ✅ | ✅ |
| 22.04 (jammy)  | ✅ Testé | ✅ | ✅ | ✅ |
| 24.04 (noble)  | ✅ Testé | ✅ | ✅ | ✅ |
| Future         | ✅ Auto  | ✅ | ✅ | ✅ |

### 🔄 Migration depuis ancienne version

#### Si ancien script avait échoué
```bash
# Le nouveau script nettoie automatiquement
sudo ./install-hygitech-3d.sh
```

#### Si Node.js mal installé
```bash
# Correction spécifique
sudo ./scripts/fix-nodejs-npm.sh
```

### 📈 Améliorations de performance

- **Temps d'installation réduit** : Nettoyage préventif
- **Taux de réussite amélioré** : 3 méthodes de fallback
- **Récupération automatique** : Plus besoin d'intervention manuelle

### 🔮 Prochaines améliorations prévues

- [ ] Support Debian
- [ ] Installation Docker optionnelle
- [ ] Configuration SSL automatique wildcard
- [ ] Monitoring automatique avec alertes
- [ ] Backup automatique avant installation

### 📞 Migration et support

Pour migrer depuis l'ancienne version :
1. Téléchargez la nouvelle version du script
2. Exécutez le diagnostic : `sudo ./scripts/diagnostic-hygitech3d.sh`
3. Lancez l'installation : `sudo ./install-hygitech-3d.sh`

Le script détecte et corrige automatiquement les problèmes d'installation précédente.