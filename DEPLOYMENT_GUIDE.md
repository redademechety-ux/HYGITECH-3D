# 🚀 Guide de Déploiement HYGITECH-3D

## 📋 Prérequis Serveur

### Configuration Minimale Recommandée
- **OS** : Ubuntu 20.04+ / Ubuntu 22.04+ (recommandé)
- **RAM** : 2 GB minimum (4 GB recommandé)
- **CPU** : 2 vCore minimum
- **Stockage** : 20 GB minimum
- **Réseau** : IP publique avec ports 80/443 ouverts

### Logiciels Installés Automatiquement
- **Node.js** : Version 18+
- **Python** : Version 3.8+
- **MongoDB** : Version 6.0+
- **Nginx** : Version 1.18+
- **PM2** : Gestionnaire de processus
- **Certbot** : Pour SSL (Let's Encrypt)
- **Yarn** : Gestionnaire de paquets Node.js

## 🏗️ Architecture de Déploiement

```
Internet → Nginx (Port 80/443) → Frontend React (build/)
                               → Backend API (Port 8002)
                               → MongoDB (Port 27017)
```

## 📦 Structure sur le Serveur

```
/var/www/hygitech-3d/
├── frontend/           # Application React compilée
│   ├── build/         # Fichiers statiques servis par Nginx
│   ├── src/           # Code source React
│   └── package.json   # Dépendances Node.js
├── backend/           # API FastAPI
│   ├── venv/         # Environnement virtuel Python
│   ├── server.py     # Serveur principal
│   └── .env          # Configuration production
├── logs/             # Logs applicatifs
├── scripts/          # Scripts de maintenance
├── backups/          # Sauvegardes MongoDB
└── ecosystem.config.js # Configuration PM2
```

## ⚡ Installation Automatique (Recommandée)

### 1. Connexion au serveur
```bash
ssh root@votre-ip-serveur
```

### 2. Téléchargement et exécution
```bash
# Télécharger le script d'installation
wget https://raw.githubusercontent.com/redademechety-ux/hygitech-3d/main/install-hygitech-3d.sh
chmod +x install-hygitech-3d.sh

# Lancer l'installation avec GitHub
sudo ./install-hygitech-3d.sh https://github.com/redademechety-ux/hygitech-3d.git

# Ou installation manuelle (copie de fichiers)
sudo ./install-hygitech-3d.sh
```

### 3. Configuration DNS
Pointez votre domaine vers votre serveur :
```
Type A : hygitech-3d.com → IP-DE-VOTRE-SERVEUR
Type A : www.hygitech-3d.com → IP-DE-VOTRE-SERVEUR
```

## 🔧 Installation Manuelle (Étape par Étape)

### 1. Préparation du système
```bash
# Mise à jour
sudo apt update && sudo apt upgrade -y

# Dépendances de base
sudo apt install -y curl wget git nginx software-properties-common ufw ca-certificates gnupg lsb-release
```

### 2. Installation Node.js 18
```bash
# Clé GPG NodeSource
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

# Repository
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" > /etc/apt/sources.list.d/nodesource.list

# Installation
sudo apt update && sudo apt install -y nodejs
```

### 3. Installation Yarn
```bash
# Clé GPG Yarn
curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /etc/apt/keyrings/yarn.gpg

# Repository
echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list

# Installation
sudo apt update && sudo apt install -y yarn
```

### 4. Installation MongoDB 6.0
```bash
# Clé GPG MongoDB
curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | gpg --dearmor -o /etc/apt/keyrings/mongodb-server-6.0.gpg

# Repository
echo "deb [ arch=amd64,arm64 signed-by=/etc/apt/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/6.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-6.0.list

# Installation
sudo apt update && sudo apt install -y mongodb-org

# Démarrage
sudo systemctl start mongod
sudo systemctl enable mongod
```

### 5. Installation Python et PM2
```bash
# Python
sudo apt install -y python3 python3-pip python3-venv python3-dev

# PM2
sudo npm install -g pm2
```

### 6. Configuration de l'application
```bash
# Utilisateur dédié
sudo useradd -m -s /bin/bash web-hygitech-3d

# Répertoires
sudo mkdir -p /var/www/hygitech-3d/{logs,scripts,backups}
sudo chown -R web-hygitech-3d:web-hygitech-3d /var/www/hygitech-3d

# Clone du code
cd /var/www/hygitech-3d
sudo -u web-hygitech-3d git clone https://github.com/redademechety-ux/hygitech-3d.git .
```

### 7. Configuration Backend
```bash
cd /var/www/hygitech-3d/backend

# Environnement virtuel
sudo -u web-hygitech-3d python3 -m venv venv
sudo -u web-hygitech-3d bash -c "source venv/bin/activate && pip install -r requirements.txt"

# Configuration .env
sudo tee .env << EOF
MONGO_URL=mongodb://localhost:27017
DB_NAME=hygitech3d_production
ENVIRONMENT=production
PORT=8002
EOF

sudo chown web-hygitech-3d:web-hygitech-3d .env
```

### 8. Configuration Frontend
```bash
cd /var/www/hygitech-3d/frontend

# Configuration environnement
sudo tee .env.production << EOF
REACT_APP_BACKEND_URL=https://hygitech-3d.com
EOF

# Build
sudo -u web-hygitech-3d yarn install --frozen-lockfile
sudo -u web-hygitech-3d NODE_OPTIONS="--max-old-space-size=4096" yarn build
```

### 9. Configuration PM2
```bash
# Configuration ecosystem
sudo tee /var/www/hygitech-3d/ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'hygitech-3d-backend',
    script: 'venv/bin/uvicorn',
    args: 'server:app --host 0.0.0.0 --port 8002',
    cwd: '/var/www/hygitech-3d/backend',
    instances: 1,
    env: {
      NODE_ENV: 'production',
      PORT: '8002'
    },
    error_file: '/var/www/hygitech-3d/logs/backend-error.log',
    out_file: '/var/www/hygitech-3d/logs/backend-out.log',
    log_file: '/var/www/hygitech-3d/logs/backend-combined.log',
    time: true,
    max_memory_restart: '1G'
  }]
}
EOF

# Démarrage
cd /var/www/hygitech-3d
sudo -u web-hygitech-3d pm2 start ecosystem.config.js
sudo -u web-hygitech-3d pm2 save
```

### 10. Configuration Nginx
```bash
# Configuration site
sudo tee /etc/nginx/sites-available/hygitech-3d << EOF
server {
    listen 80;
    server_name hygitech-3d.com www.hygitech-3d.com;
    
    # Frontend React
    location / {
        root /var/www/hygitech-3d/frontend/build;
        index index.html;
        try_files \$uri \$uri/ /index.html;
        
        # Cache assets statiques
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        # Pas de cache pour index.html
        location = /index.html {
            expires -1;
            add_header Cache-Control "no-cache, no-store, must-revalidate";
        }
    }
    
    # Backend API
    location /api {
        proxy_pass http://localhost:8002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
}
EOF

# Activation
sudo ln -sf /etc/nginx/sites-available/hygitech-3d /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
```

### 11. Configuration SSL
```bash
# Installation Certbot
sudo apt install -y snapd
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -sf /snap/bin/certbot /usr/bin/certbot

# Certificat SSL
sudo certbot --nginx -d hygitech-3d.com -d www.hygitech-3d.com --non-interactive --agree-tos --email contact@hygitech-3d.com --redirect
```

### 12. Configuration Firewall
```bash
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw --force enable
```

## 🔄 Scripts de Maintenance

Le script d'installation crée automatiquement des scripts de maintenance :

### Status du site
```bash
/var/www/hygitech-3d/scripts/status.sh
```

### Sauvegarde MongoDB
```bash
/var/www/hygitech-3d/scripts/backup-mongo.sh
```

### Mise à jour
```bash
/var/www/hygitech-3d/scripts/update.sh
```

## 📊 Monitoring et Logs

### Logs applicatifs
```bash
# Logs backend
sudo -u web-hygitech-3d pm2 logs hygitech-3d-backend

# Logs Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Logs MongoDB
sudo tail -f /var/log/mongodb/mongod.log
```

### Monitoring PM2
```bash
sudo -u web-hygitech-3d pm2 monit
sudo -u web-hygitech-3d pm2 status
```

## 🛠️ Commandes de Maintenance

### Redémarrage des services
```bash
# Backend uniquement
sudo -u web-hygitech-3d pm2 restart hygitech-3d-backend

# Nginx
sudo systemctl reload nginx

# MongoDB
sudo systemctl restart mongod

# Tous les services
sudo systemctl restart mongod nginx
sudo -u web-hygitech-3d pm2 restart all
```

### Vérification de l'état
```bash
# Services système
sudo systemctl status mongod nginx

# PM2
sudo -u web-hygitech-3d pm2 status

# Test connectivité
curl -I http://localhost/
curl -I http://localhost:8002/api/
curl -I https://hygitech-3d.com
```

## 🚨 Dépannage

### Problèmes courants

#### 1. Site non accessible
```bash
# Vérifier les services
sudo systemctl status nginx mongod
sudo -u web-hygitech-3d pm2 status

# Tester localement
curl -I http://localhost/
```

#### 2. Backend API ne répond pas
```bash
# Logs backend
sudo -u web-hygitech-3d pm2 logs hygitech-3d-backend --lines 50

# Test direct
curl -I http://localhost:8002/api/

# Redémarrage
sudo -u web-hygitech-3d pm2 restart hygitech-3d-backend
```

#### 3. Erreur SSL/HTTPS
```bash
# Renouveler certificat
sudo certbot renew --force-renewal -d hygitech-3d.com

# Vérifier expiration
sudo certbot certificates
```

#### 4. MongoDB déconnecté
```bash
# Status MongoDB
sudo systemctl status mongod

# Logs MongoDB
sudo tail -f /var/log/mongodb/mongod.log

# Redémarrage
sudo systemctl restart mongod
```

#### 5. Formulaire de contact ne fonctionne pas
```bash
# Test API contact
curl -X POST http://localhost:8002/api/contact \
     -H "Content-Type: application/json" \
     -d '{"name":"Test","email":"test@email.com","phone":"0123456789","subject":"test","message":"Test message"}'

# Vérifier base de données
mongo hygitech3d_production --eval "db.contact_requests.find().limit(5)"
```

## 🔒 Sécurité

### Fonctionnalités de sécurité implémentées
- ✅ Utilisateur dédié non-root (`web-hygitech-3d`)
- ✅ Firewall UFW configuré
- ✅ SSL/TLS avec Let's Encrypt
- ✅ Headers de sécurité Nginx
- ✅ Rate limiting sur API
- ✅ Isolation des processus PM2
- ✅ Environnement virtuel Python isolé

### Recommandations supplémentaires
```bash
# Désactiver login root SSH
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config

# Changer port SSH par défaut
sudo sed -i 's/#Port 22/Port 2222/g' /etc/ssh/sshd_config

# Redémarrer SSH
sudo systemctl restart sshd

# Mettre à jour UFW
sudo ufw allow 2222/tcp
sudo ufw delete allow 22/tcp
```

## 📈 Performance

### Optimisations automatiques
- Gzip compression activée
- Cache des assets statiques (1 an)
- Pas de cache pour index.html
- PM2 avec restart automatique
- Node.js avec plus de mémoire pour le build

### Monitoring des performances
```bash
# CPU et mémoire
htop

# Espace disque
df -h

# Status des processus
sudo -u web-hygitech-3d pm2 monit
```

## 🔄 Mise à Jour du Site

### Mise à jour automatique
```bash
/var/www/hygitech-3d/scripts/update.sh
```

### Mise à jour manuelle
```bash
cd /var/www/hygitech-3d

# Sauvegarde
./scripts/backup-mongo.sh

# Pull des changements
sudo -u web-hygitech-3d git pull origin main

# Mise à jour backend
cd backend
sudo -u web-hygitech-3d bash -c "source venv/bin/activate && pip install -r requirements.txt"

# Mise à jour frontend
cd ../frontend
sudo -u web-hygitech-3d yarn install
sudo -u web-hygitech-3d NODE_OPTIONS="--max-old-space-size=4096" yarn build

# Redémarrage
sudo -u web-hygitech-3d pm2 restart hygitech-3d-backend
sudo systemctl reload nginx
```

## ✅ Vérification Post-Installation

Une fois l'installation terminée, vérifiez :

### 1. Services actifs
```bash
sudo systemctl is-active mongod nginx
sudo -u web-hygitech-3d pm2 list
```

### 2. Connectivité
```bash
curl -I https://hygitech-3d.com
curl -I https://hygitech-3d.com/api/
```

### 3. SSL fonctionnel
```bash
openssl s_client -connect hygitech-3d.com:443 -servername hygitech-3d.com
```

### 4. Formulaire de contact
- Tester sur https://hygitech-3d.com
- Remplir et soumettre le formulaire
- Vérifier en base : `mongo hygitech3d_production --eval "db.contact_requests.find()"`

## 🎉 Résultat Final

Après installation réussie, vous aurez :
- ✅ Site accessible sur https://hygitech-3d.com
- ✅ Redirection automatique www.hygitech-3d.com
- ✅ Formulaire de contact opérationnel
- ✅ WhatsApp flottant avec vrais numéros
- ✅ SSL automatique et sécurisé
- ✅ Sauvegardes MongoDB quotidiennes
- ✅ Monitoring PM2 complet
- ✅ Logs structurés et accessibles

**Votre site HYGITECH-3D est maintenant en ligne et prêt à recevoir des clients ! 🚀**