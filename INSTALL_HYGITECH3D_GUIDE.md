# 🚀 Installation HYGITECH-3D sur Serveur Multi-Sites

## 📋 **Informations de Configuration**

- **Domaine** : `hygitech-3d.com` et `www.hygitech-3d.com`
- **Port Backend** : `8002`
- **Utilisateur système** : `web-hygitech-3d`
- **Répertoire** : `/var/www/hygitech-3d/`
- **Base MongoDB** : `hygitech3d_production`
- **Processus PM2** : `hygitech-3d-backend`

## ⚡ **Installation Rapide**

### 1. Préparation des fichiers sur votre serveur

#### Option A: Depuis GitHub (Recommandée)
```bash
# Connexion SSH à votre serveur
ssh root@votre-ip-serveur

# Téléchargement du script
wget https://raw.githubusercontent.com/votre-username/hygitech-3d/main/install-hygitech-3d.sh
chmod +x install-hygitech-3d.sh

# Installation avec repository GitHub
sudo ./install-hygitech-3d.sh https://github.com/votre-username/hygitech-3d.git
```

#### Option B: Upload manuel des fichiers
```bash
# Sur votre serveur
mkdir -p /var/www/hygitech-3d

# Transférer vos fichiers via SCP/SFTP vers /var/www/hygitech-3d/
# Structure attendue :
# /var/www/hygitech-3d/frontend/
# /var/www/hygitech-3d/backend/
# /var/www/hygitech-3d/install-hygitech-3d.sh

# Puis lancer l'installation
cd /var/www/hygitech-3d
chmod +x install-hygitech-3d.sh
sudo ./install-hygitech-3d.sh
```

### 2. Configuration DNS
Pointez votre domaine vers votre serveur :
```
Type A : hygitech-3d.com → IP-DE-VOTRE-SERVEUR
Type A : www.hygitech-3d.com → IP-DE-VOTRE-SERVEUR
```

### 3. Vérification Post-Installation

Après installation, testez :
```bash
# Status des services
/var/www/hygitech-3d/scripts/status.sh

# Test des URLs
curl -I https://hygitech-3d.com
curl -I https://hygitech-3d.com/api/

# Logs en temps réel
sudo -u web-hygitech-3d pm2 logs hygitech-3d-backend
```

## 🔧 **Gestion du Site**

### Commandes de maintenance
```bash
# Redémarrage du site
sudo -u web-hygitech-3d pm2 restart hygitech-3d-backend
sudo systemctl reload nginx

# Mise à jour du site (si connecté à Git)
/var/www/hygitech-3d/scripts/deploy.sh

# Sauvegarde de la base de données
/var/www/hygitech-3d/scripts/backup-mongo.sh

# Monitoring
sudo -u web-hygitech-3d pm2 monit
```

### Logs et debugging
```bash
# Logs du backend
sudo -u web-hygitech-3d pm2 logs hygitech-3d-backend

# Logs Nginx
sudo tail -f /var/log/nginx/hygitech-3d-access.log
sudo tail -f /var/log/nginx/hygitech-3d-error.log

# Logs MongoDB
sudo tail -f /var/log/mongodb/mongod.log
```

## 🌐 **Coexistence Multi-Sites**

Votre serveur peut héberger d'autres sites :

```bash
# Installation d'un 2ème site (exemple)
./install-multi-sites.sh mon-site2 mon-site2.com 8003

# Installation d'un 3ème site
./install-multi-sites.sh boutique boutique-en-ligne.com 8004
```

### Architecture finale
```
Serveur Ubuntu
├── Nginx (ports 80/443)
│   ├── hygitech-3d.com → Backend port 8002
│   ├── mon-site2.com → Backend port 8003
│   └── boutique-en-ligne.com → Backend port 8004
├── MongoDB (bases séparées)
├── PM2 avec processus multiples
└── SSL automatique par domaine
```

## 📊 **Monitoring Multi-Sites**

```bash
# Voir tous les sites actifs
sudo pm2 status

# Redémarrer tous les sites
sudo pm2 restart all

# Status Nginx global
sudo nginx -t
sudo systemctl status nginx

# Certificats SSL de tous les domaines
sudo certbot certificates
```

## 🔒 **Sécurité**

Le script configure automatiquement :
- ✅ Utilisateurs séparés par site
- ✅ Firewall UFW avec ports essentiels
- ✅ SSL automatique (Let's Encrypt)
- ✅ Headers de sécurité Nginx
- ✅ Rate limiting sur formulaire de contact
- ✅ Isolation des processus PM2

## 🆘 **Dépannage**

### Problèmes courants

1. **Site non accessible**
   ```bash
   # Vérifier les services
   systemctl status nginx mongod
   sudo -u web-hygitech-3d pm2 status
   ```

2. **Erreur SSL**
   ```bash
   # Renouveler certificat
   sudo certbot renew --force-renewal -d hygitech-3d.com
   ```

3. **Port 8002 non accessible**
   ```bash
   # Vérifier si le port est utilisé
   netstat -tuln | grep 8002
   sudo -u web-hygitech-3d pm2 restart hygitech-3d-backend
   ```

4. **Formulaire de contact ne fonctionne pas**
   ```bash
   # Test direct de l'API
   curl -X POST http://localhost:8002/api/contact \
        -H "Content-Type: application/json" \
        -d '{"name":"Test","email":"test@test.com","phone":"0123456789","subject":"Test","message":"Test"}'
   ```

## 📞 **Support**

En cas de problème :
1. Vérifiez les logs avec les commandes ci-dessus
2. Assurez-vous que DNS pointe vers votre serveur
3. Vérifiez que les ports 80/443 sont ouverts
4. Testez la connectivité MongoDB

## 🎉 **Résultat Final**

Une fois installé, vous aurez :
- ✅ **https://hygitech-3d.com** : Site vitrine complet
- ✅ **Formulaire de contact** : Fonctionnel avec sauvegarde MongoDB
- ✅ **WhatsApp flottant** : Avec vos vrais numéros
- ✅ **SEO optimisé** : Pour "désinfection, désinsectisation, dératisation"
- ✅ **SSL automatique** : Certificats Let's Encrypt
- ✅ **Sauvegardes automatiques** : MongoDB quotidiennes
- ✅ **Monitoring** : PM2 avec logs détaillés
- ✅ **Multi-sites ready** : Prêt pour d'autres sites

**Votre site HYGITECH-3D sera opérationnel sur le port 8002 avec toutes les fonctionnalités ! 🚀**