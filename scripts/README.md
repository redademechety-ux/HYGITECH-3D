# Scripts de Maintenance Hygitech-3D

Ce répertoire contient les scripts de maintenance et de correction pour le déploiement de Hygitech-3D sur serveur de production.

## 📋 Scripts disponibles

### 1. `diagnostic-hygitech3d.sh` - Diagnostic complet
**Objectif :** Analyser l'état actuel du système et identifier les problèmes

**Fonctionnalités :**
- Vérification de l'existence du répertoire du projet
- Contrôle des utilisateurs et groupes
- Vérification des fichiers critiques (server.py, .env, package.json, etc.)
- Analyse des autorisations
- État des services (PM2, MongoDB)
- Vérification des ports (8001, 3000, 27017)
- Analyse des logs récents
- Recommandations automatiques

**Utilisation :**
```bash
sudo ./diagnostic-hygitech3d.sh
```

### 2. `fix-git-subdirectory.sh` - Correction des problèmes de git clone
**Objectif :** Corriger les problèmes causés par git clone qui place les fichiers dans un sous-répertoire

**Fonctionnalités :**
- Détection automatique des sous-répertoires problématiques
- Sauvegarde automatique avant modification
- Déplacement des fichiers vers l'emplacement correct
- Vérification de la structure finale

**Utilisation :**
```bash
sudo ./fix-git-subdirectory.sh
```

**Options :**
```bash
./fix-git-subdirectory.sh --help  # Afficher l'aide
```

### 3. `fix-all-permissions-hygitech3d.sh` - Correction complète des autorisations
**Objectif :** Résoudre tous les problèmes d'autorisations et de configuration

**Fonctionnalités :**
- Création/vérification de l'utilisateur `web-hygitech-3d`
- Correction de toutes les autorisations (755 pour répertoires, 644 pour fichiers)
- Création du fichier `.env` backend avec les variables nécessaires
- Configuration de `ecosystem.config.js` pour PM2
- Nettoyage et redémarrage de PM2
- Test automatique des services

**Utilisation :**
```bash
sudo ./fix-all-permissions-hygitech3d.sh
```

## 🚀 Procédure recommandée

### Étape 1 - Copier les scripts vers votre serveur de production

**Option A - Via GitHub (recommandée) :**
```bash
# Sur votre serveur de production
cd /tmp
git clone https://github.com/VOTRE-USERNAME/hygitech-3d.git
cp hygitech-3d/scripts/*.sh .
chmod +x *.sh
```

**Option B - Via SCP :**
```bash
# Depuis votre machine locale
scp scripts/*.sh your-server:/tmp/
ssh your-server "chmod +x /tmp/*.sh"
```

### Étape 2 - Exécuter le diagnostic
```bash
sudo /tmp/diagnostic-hygitech3d.sh
```

### Étape 3 - Corriger les problèmes de structure (si nécessaire)
```bash
sudo /tmp/fix-git-subdirectory.sh
```

### Étape 4 - Corriger toutes les autorisations
```bash
sudo /tmp/fix-all-permissions-hygitech3d.sh
```

### Étape 5 - Vérifier le résultat
```bash
# Vérifier que le backend répond
curl http://localhost:8001/api/status

# Vérifier le statut PM2
sudo -u web-hygitech-3d pm2 status

# Voir les logs si nécessaire
sudo -u web-hygitech-3d pm2 logs hygitech-3d-backend
```

## 🔧 Configuration automatique

Les scripts configurent automatiquement :
- **Utilisateur :** `web-hygitech-3d`
- **Groupe :** `web-hygitech-3d`
- **Répertoire projet :** `/var/www/hygitech-3d`
- **Variables d'environnement :**
  - `MONGO_URL=mongodb://localhost:27017`
  - `DB_NAME=hygitech3d`
  - `ENVIRONMENT=production`
  - `PORT=8001`
  - `DEBUG=false`

## 📝 Logs et dépannage

**Logs PM2 :**
```bash
sudo -u web-hygitech-3d pm2 logs hygitech-3d-backend
sudo -u web-hygitech-3d pm2 logs hygitech-3d-backend --lines 50
```

**Logs système :**
```bash
tail -f /var/log/supervisor/hygitech-3d-backend.err.log
tail -f /var/log/supervisor/hygitech-3d-backend.out.log
```

**Commandes PM2 utiles :**
```bash
sudo -u web-hygitech-3d pm2 status
sudo -u web-hygitech-3d pm2 restart hygitech-3d-backend
sudo -u web-hygitech-3d pm2 stop hygitech-3d-backend
sudo -u web-hygitech-3d pm2 delete hygitech-3d-backend
```

## ⚠️ Notes importantes

- Tous les scripts créent des sauvegardes automatiques
- Les scripts sont conçus pour Ubuntu/Debian
- Ils nécessitent les privilèges sudo
- MongoDB doit être installé et en fonctionnement
- PM2 doit être installé globalement

## 📞 Support

Si vous rencontrez des problèmes :
1. Exécutez d'abord le diagnostic
2. Vérifiez les logs
3. Consultez les recommandations du diagnostic
4. Les sauvegardes sont disponibles dans `/tmp/hygitech-3d-backup-*`