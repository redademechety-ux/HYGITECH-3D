# 🚀 HYGITECH-3D - Site Vitrine Professionnel

Site vitrine moderne pour HYGITECH-3D, spécialiste en désinfection, désinsectisation et dératisation en Île-de-France.

## 🌟 Fonctionnalités

- **Site vitrine complet** : Hero section, services, zones d'intervention, tarifs, contact
- **Formulaire de contact fonctionnel** : Sauvegarde en base MongoDB
- **WhatsApp flottant** : Bouton de contact direct
- **SEO optimisé** : Pour les mots-clés "désinfection, désinsectisation, dératisation"
- **Design responsive** : Compatible mobile, tablette, desktop
- **SSL automatique** : Certificats Let's Encrypt
- **Architecture moderne** : React + FastAPI + MongoDB

## 🏗️ Architecture Technique

### Frontend
- **React 19** avec hooks modernes
- **Tailwind CSS** + **Shadcn/UI**
- **Axios** pour les appels API
- **React Router** pour la navigation

### Backend
- **FastAPI** (Python)
- **MongoDB** avec Motor (async)
- **Pydantic** pour la validation
- **CORS** configuré pour production

### Infrastructure
- **Nginx** comme reverse proxy
- **PM2** pour la gestion des processus
- **Ubuntu 22.04+** compatible
- **Let's Encrypt** pour SSL

## 📋 Informations Entreprise

- **Domaine** : hygitech-3d.com
- **Port Backend** : 8002
- **Téléphone** : 06 68 06 29 70 / 01 81 89 28 86
- **Email** : contact@hygitech-3d.com
- **Adresse** : 122 Boulevard Gabriel Péri, 92240 MALAKOFF
- **Zone** : Île-de-France

## 🚀 Installation Rapide

### Prérequis
- Serveur Ubuntu 20.04+ avec accès root
- Domaine pointant vers le serveur
- Ports 80/443 ouverts

### Installation en 1 commande
```bash
# Télécharger et exécuter le script
wget https://raw.githubusercontent.com/redademechety-ux/hygitech-3d/main/install-hygitech-3d.sh
chmod +x install-hygitech-3d.sh
sudo ./install-hygitech-3d.sh https://github.com/redademechety-ux/hygitech-3d.git
```

### Configuration DNS
Pointez votre domaine vers votre serveur :
```
Type A : hygitech-3d.com → IP-DE-VOTRE-SERVEUR
Type A : www.hygitech-3d.com → IP-DE-VOTRE-SERVEUR
```

## 🔧 Développement Local

### Backend
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn server:app --host 0.0.0.0 --port 8001 --reload
```

### Frontend
```bash
cd frontend
yarn install
yarn start
```

### Variables d'environnement
```bash
# Frontend (.env)
REACT_APP_BACKEND_URL=http://localhost:8001

# Backend (.env)
MONGO_URL=mongodb://localhost:27017
DB_NAME=hygitech3d_development
```

## 📊 Services Proposés

### Tarifs (À partir de)
- **Rongeurs** : 250€ HT
- **Blattes** : 180€ HT  
- **Fourmis** : 130€ TTC
- **Punaises de lit** : 200€ HT
- **Nettoyage fin de chantier** : Sur devis

### Zones d'intervention
- Paris (75)
- Hauts-de-Seine (92)
- Seine-Saint-Denis (93)
- Val-de-Marne (94)
- Seine-et-Marne (77)
- Yvelines (78)
- Essonne (91)
- Val-d'Oise (95)

## 🛠️ Gestion Post-Installation

### Commandes utiles
```bash
# Status du site
/var/www/hygitech-3d/scripts/status.sh

# Logs en temps réel
sudo -u web-hygitech-3d pm2 logs hygitech-3d-backend

# Mise à jour
/var/www/hygitech-3d/scripts/update.sh

# Sauvegarde manuelle
/var/www/hygitech-3d/scripts/backup-mongo.sh

# Redémarrage
sudo -u web-hygitech-3d pm2 restart hygitech-3d-backend
sudo systemctl reload nginx
```

### Monitoring
- **PM2** : `sudo -u web-hygitech-3d pm2 monit`
- **Logs Nginx** : `sudo tail -f /var/log/nginx/hygitech-3d-access.log`
- **MongoDB** : `sudo systemctl status mongod`

## 🔒 Sécurité

- Utilisateur dédié `web-hygitech-3d`
- Firewall UFW configuré
- Headers de sécurité Nginx
- Rate limiting sur formulaire
- SSL/TLS automatique
- Isolation des processus

## 📁 Structure du Projet

```
hygitech-3d/
├── frontend/                 # Application React
│   ├── public/
│   ├── src/
│   │   ├── components/       # Composants React
│   │   ├── data/            # Données mockées
│   │   └── hooks/           # Hooks personnalisés
│   ├── package.json
│   └── tailwind.config.js
├── backend/                 # API FastAPI
│   ├── server.py           # Serveur principal
│   ├── requirements.txt    # Dépendances Python
│   └── .env               # Variables d'environnement
├── install-hygitech-3d.sh # Script d'installation
├── DEPLOYMENT_GUIDE.md    # Guide de déploiement
└── README.md              # Ce fichier
```

## 🆘 Dépannage

### Problèmes courants

1. **Site non accessible**
   ```bash
   sudo systemctl status nginx mongod
   sudo -u web-hygitech-3d pm2 status
   ```

2. **Erreur SSL**
   ```bash
   sudo certbot renew --force-renewal -d hygitech-3d.com
   ```

3. **Backend non fonctionnel**
   ```bash
   sudo -u web-hygitech-3d pm2 logs hygitech-3d-backend --lines 50
   ```

4. **Formulaire ne fonctionne pas**
   ```bash
   curl -X POST http://localhost:8002/api/contact \
        -H "Content-Type: application/json" \
        -d '{"name":"Test","email":"test@test.com","phone":"0123456789","subject":"Test","message":"Test"}'
   ```

## 📞 Support

En cas de problème :
1. Vérifiez les logs avec les commandes ci-dessus
2. Assurez-vous que DNS pointe vers votre serveur
3. Vérifiez que les ports 80/443 sont ouverts
4. Testez la connectivité MongoDB

## 🏆 Résultat Final

Une fois installé, vous aurez :
- ✅ Site web moderne sur https://hygitech-3d.com
- ✅ Formulaire de contact opérationnel
- ✅ WhatsApp flottant avec vrais numéros
- ✅ SEO optimisé pour le référencement
- ✅ SSL automatique et sécurisé
- ✅ Sauvegardes automatiques
- ✅ Monitoring complet

## 📄 Licence

Ce projet est développé spécifiquement pour HYGITECH-3D.

---

**HYGITECH-3D** - Solutions d'hygiène professionnelles en Île-de-France  
📞 06 68 06 29 70 | ✉️ contact@hygitech-3d.com | 📍 92240 MALAKOFF