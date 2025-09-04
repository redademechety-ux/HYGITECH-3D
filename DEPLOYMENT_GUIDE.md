# 🚀 Guide de Déploiement HYGITECH-3D

## 📋 Prérequis Serveur

### Configuration Minimale Recommandée
- **OS** : Ubuntu 20.04+ / CentOS 7+ / Debian 10+
- **RAM** : 2 GB minimum (4 GB recommandé)
- **CPU** : 2 vCore minimum
- **Stockage** : 20 GB minimum
- **Réseau** : IP publique avec ports 80/443 ouverts

### Logiciels Requis
- **Node.js** : Version 18+ 
- **Python** : Version 3.8+
- **MongoDB** : Version 5.0+
- **Nginx** : Version 1.18+
- **PM2** : Gestionnaire de processus
- **Certbot** : Pour SSL (Let's Encrypt)

## 🏗️ Architecture de Déploiement

```
Internet → Nginx (Port 80/443) → Frontend (Port 3000)
                               → Backend API (Port 8001)
                               → MongoDB (Port 27017)
```

## 📦 Structure de Fichiers sur le Serveur

```
/var/www/hygitech-3d/
├── frontend/           # Application React build
├── backend/           # API FastAPI
├── logs/             # Fichiers de logs
├── nginx/            # Configuration Nginx
├── ssl/              # Certificats SSL
└── scripts/          # Scripts de maintenance
```

## 🛠️ Installation Manuelle Étape par Étape

### 1. Préparation du Serveur
```bash
# Mise à jour système
sudo apt update && sudo apt upgrade -y

# Installation des dépendances système
sudo apt install -y curl wget git nginx software-properties-common

# Création utilisateur dédié
sudo useradd -m -s /bin/bash hygitech
sudo usermod -aG sudo hygitech
```

### 2. Installation Node.js
```bash
# Via NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Installation Yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update && sudo apt install -y yarn

# Installation PM2
sudo npm install -g pm2
```

### 3. Installation Python et FastAPI
```bash
# Python 3.8+
sudo apt install -y python3 python3-pip python3-venv

# Installation pip packages globaux
sudo pip3 install fastapi uvicorn python-multipart
```

### 4. Installation MongoDB
```bash
# Import GPG key
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -

# Add repository
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list

# Install MongoDB
sudo apt update
sudo apt install -y mongodb-org

# Start et enable MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod
```

### 5. Déploiement de l'Application
```bash
# Création du répertoire
sudo mkdir -p /var/www/hygitech-3d
sudo chown hygitech:hygitech /var/www/hygitech-3d

# Clone du code (remplacer par votre repo)
cd /var/www/hygitech-3d
git clone <votre-repo> .

# Configuration Backend
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Configuration Frontend
cd ../frontend
yarn install
yarn build
```

### 6. Configuration des Variables d'Environnement
```bash
# Backend .env
cat > /var/www/hygitech-3d/backend/.env << EOF
MONGO_URL=mongodb://localhost:27017
DB_NAME=hygitech3d_production
ENVIRONMENT=production
EOF

# Frontend .env.production
cat > /var/www/hygitech-3d/frontend/.env.production << EOF
REACT_APP_BACKEND_URL=https://votre-domaine.com
EOF
```

### 7. Configuration Nginx
```bash
# Configuration site
sudo tee /etc/nginx/sites-available/hygitech-3d << EOF
server {
    listen 80;
    server_name votre-domaine.com www.votre-domaine.com;
    
    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name votre-domaine.com www.votre-domaine.com;
    
    # SSL Configuration (sera ajouté par Certbot)
    
    # Frontend (React)
    location / {
        root /var/www/hygitech-3d/frontend/build;
        index index.html;
        try_files \$uri \$uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # Backend API
    location /api {
        proxy_pass http://localhost:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
}
EOF

# Activation du site
sudo ln -s /etc/nginx/sites-available/hygitech-3d /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 8. Configuration SSL avec Let's Encrypt
```bash
# Installation Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtention certificat SSL
sudo certbot --nginx -d votre-domaine.com -d www.votre-domaine.com

# Test renouvellement automatique
sudo certbot renew --dry-run
```

### 9. Configuration PM2 pour la Production
```bash
# Configuration PM2 backend
cat > /var/www/hygitech-3d/ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'hygitech-backend',
    script: 'venv/bin/uvicorn',
    args: 'server:app --host 0.0.0.0 --port 8001',
    cwd: '/var/www/hygitech-3d/backend',
    instances: 2,
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production'
    },
    error_file: '/var/www/hygitech-3d/logs/backend-error.log',
    out_file: '/var/www/hygitech-3d/logs/backend-out.log',
    log_file: '/var/www/hygitech-3d/logs/backend-combined.log'
  }]
}
EOF

# Démarrage des services
mkdir -p /var/www/hygitech-3d/logs
pm2 start ecosystem.config.js
pm2 startup
pm2 save
```

## 🔒 Sécurité et Optimisations

### Configuration Firewall
```bash
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw --force enable
```

### Sauvegarde MongoDB
```bash
# Script de sauvegarde quotidienne
cat > /var/www/hygitech-3d/scripts/backup-mongo.sh << EOF
#!/bin/bash
DATE=\$(date +%Y%m%d_%H%M%S)
mongodump --db hygitech3d_production --out /var/backups/mongodb/\$DATE
find /var/backups/mongodb/ -mtime +7 -delete
EOF

chmod +x /var/www/hygitech-3d/scripts/backup-mongo.sh

# Cron job pour sauvegarde quotidienne à 2h
(crontab -l 2>/dev/null; echo "0 2 * * * /var/www/hygitech-3d/scripts/backup-mongo.sh") | crontab -
```

## 🔄 Mise à Jour de l'Application

### Script de déploiement
```bash
cat > /var/www/hygitech-3d/scripts/deploy.sh << EOF
#!/bin/bash
cd /var/www/hygitech-3d

# Sauvegarde avant mise à jour
./scripts/backup-mongo.sh

# Pull des changements
git pull origin main

# Mise à jour backend
cd backend
source venv/bin/activate
pip install -r requirements.txt

# Mise à jour frontend
cd ../frontend
yarn install
yarn build

# Redémarrage services
pm2 restart all
sudo systemctl reload nginx

echo "Déploiement terminé avec succès !"
EOF

chmod +x /var/www/hygitech-3d/scripts/deploy.sh
```

## 📊 Monitoring et Logs

### Visualisation des logs
```bash
# Logs backend
pm2 logs hygitech-backend

# Logs Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Logs MongoDB
sudo tail -f /var/log/mongodb/mongod.log
```

### Monitoring PM2
```bash
pm2 monit  # Interface de monitoring en temps réel
```

## 🛠️ Maintenance

### Commands utiles
```bash
# Redémarrer tous les services
sudo systemctl restart mongod
pm2 restart all
sudo systemctl reload nginx

# Vérifier l'état des services
sudo systemctl status mongod
pm2 status
sudo nginx -t

# Nettoyer les logs
pm2 flush
sudo logrotate -f /etc/logrotate.d/nginx
```

## 🚨 Dépannage

### Problèmes courants
1. **Port 8001 non accessible** : Vérifier firewall et PM2
2. **SSL non fonctionnel** : Vérifier Certbot et configuration Nginx
3. **MongoDB connexion échouée** : Vérifier service et configuration
4. **Build frontend échoué** : Vérifier Node.js version et dépendances

### Tests de connectivité
```bash
# Test backend API
curl http://localhost:8001/api/

# Test frontend
curl http://localhost/

# Test MongoDB
mongo --eval "db.adminCommand('ismaster')"
```

---

**⚠️ Notes importantes :**
- Remplacer `votre-domaine.com` par votre vrai domaine
- Configurer les DNS pour pointer vers votre serveur
- Sauvegarder régulièrement la base de données
- Monitorer les performances et les logs