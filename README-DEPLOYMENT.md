# 🚀 Déploiement HYGITECH-3D - Guide Rapide

## ⚡ Installation Rapide (Recommandée)

### Prérequis
- Serveur Ubuntu 20.04+ avec accès root
- Domaine pointant vers votre serveur
- Ports 80 et 443 ouverts

### Installation en 1 commande
```bash
# Télécharger et exécuter le script
wget https://raw.githubusercontent.com/votre-repo/install-script.sh
chmod +x install-script.sh
sudo ./install-script.sh votre-domaine.com
```

## 🐳 Option Docker (Alternative)

### Installation avec Docker Compose
```bash
# Cloner le projet
git clone <votre-repo>
cd hygitech-3d

# Configuration
cp .env.example .env
# Éditer .env avec vos valeurs

# Démarrage
docker-compose -f docker-compose.production.yml up -d
```

## 📁 Fichiers de Déploiement Fournis

- **`install-script.sh`** : Script d'installation automatisé complet
- **`DEPLOYMENT_GUIDE.md`** : Guide détaillé étape par étape  
- **`docker-compose.production.yml`** : Configuration Docker pour production

## 🔧 Après Installation

### Vérification
```bash
# Status des services
sudo systemctl status mongod nginx
sudo -u hygitech pm2 status

# Test du site
curl https://votre-domaine.com
curl https://votre-domaine.com/api/
```

### Maintenance
```bash
# Sauvegarde
/var/www/hygitech-3d/scripts/backup-mongo.sh

# Mise à jour
/var/www/hygitech-3d/scripts/deploy.sh

# Logs
sudo -u hygitech pm2 logs
sudo tail -f /var/log/nginx/error.log
```

## 🆘 Support

En cas de problème, vérifiez :
1. DNS pointant vers votre serveur
2. Firewall (ports 80/443 ouverts)  
3. Certificats SSL générés
4. Services MongoDB, PM2, Nginx actifs

## 📊 Architecture Finale

```
Internet → Nginx (SSL) → React Frontend
                      → FastAPI Backend → MongoDB
```

Votre site sera accessible sur `https://votre-domaine.com` avec :
- ✅ HTTPS automatique (Let's Encrypt)
- ✅ Formulaire de contact fonctionnel
- ✅ Optimisation SEO complète
- ✅ Sauvegardes automatiques
- ✅ Monitoring PM2
- ✅ Sécurité renforcée