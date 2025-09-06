# Guide du Serveur FTP HYGITECH-3D

## 🚀 Installation rapide

```bash
# Sur votre serveur de production
cd /tmp
wget https://raw.githubusercontent.com/VOTRE-USERNAME/hygitech-3d/main/scripts/install-ftp-server.sh
chmod +x install-ftp-server.sh
sudo ./install-ftp-server.sh
```

## 📋 Ce que fait le script d'installation

### ✅ Installation et configuration
- **vsftpd** : Serveur FTP sécurisé et performant
- **Utilisateur ubuntu** : Accès FTP avec son mot de passe
- **Permissions /var/www** : Accès lecture/écriture au répertoire web
- **Firewall** : Configuration automatique des ports FTP
- **SSL/TLS** : Option de chiffrement (certificat auto-signé)

### 🔧 Configuration automatique
- Port FTP : **21** (standard)
- Mode passif : Ports **40000-40100** 
- Utilisateurs autorisés : **ubuntu** (extensible)
- Répertoire racine : **/var/www** (via lien symbolique)
- Logs : **/var/log/vsftpd.log**

## 🌐 Connexion FTP

### Informations de connexion
```
Serveur : [IP de votre serveur]
Port : 21
Utilisateur : ubuntu
Mot de passe : [mot de passe ubuntu]
Mode : Passif (recommandé)
```

### Clients FTP recommandés

#### FileZilla (Gratuit - Windows/Mac/Linux)
1. **Hôte** : IP de votre serveur
2. **Port** : 21
3. **Protocole** : FTP
4. **Utilisateur** : ubuntu
5. **Mot de passe** : votre mot de passe ubuntu
6. **Mode de transfert** : Passif

#### WinSCP (Windows)
- Protocole : FTP
- Serveur : IP de votre serveur
- Utilisateur : ubuntu
- Mode passif : Activé

#### Ligne de commande
```bash
# Connexion FTP en ligne de commande
ftp [IP-SERVEUR]
# Saisir : ubuntu
# Saisir : mot-de-passe
# Commandes FTP disponibles
```

## 📁 Structure des répertoires

Une fois connecté en FTP, vous verrez :

```
/home/ubuntu/
├── www/  → Lien symbolique vers /var/www/
└── [autres fichiers utilisateur]
```

Le répertoire `www` est un lien direct vers `/var/www/` où se trouvent vos sites web.

### Exemple pour HYGITECH-3D
```
/home/ubuntu/www/
├── hygitech-3d/
│   ├── frontend/
│   │   ├── src/
│   │   ├── public/
│   │   └── package.json
│   ├── backend/
│   │   ├── server.py
│   │   └── requirements.txt
│   └── ecosystem.config.js
└── [autres sites web]
```

## 🔐 Sécurité

### Points importants
- ⚠️  **FTP standard** : Les mots de passe transitent en clair
- 🔒 **SSL/TLS** : Option disponible pour chiffrer les connexions
- 🔥 **Firewall** : Ports automatiquement configurés
- 👥 **Utilisateurs** : Seul ubuntu a accès par défaut

### Améliorer la sécurité

#### 1. Activer SSL/TLS
Le script propose l'activation SSL pendant l'installation, ou manuellement :

```bash
sudo nano /etc/vsftpd.conf
# Décommenter ou ajouter :
ssl_enable=YES
rsa_cert_file=/etc/ssl/private/vsftpd.pem
```

#### 2. Changer le mot de passe régulièrement
```bash
sudo passwd ubuntu
```

#### 3. Ajouter d'autres utilisateurs FTP
```bash
# Créer un nouvel utilisateur
sudo useradd -m ftpuser2
sudo passwd ftpuser2
sudo usermod -a -G www-data ftpuser2

# L'ajouter à la liste FTP
echo 'ftpuser2' | sudo tee -a /etc/vsftpd.userlist

# Redémarrer le service
sudo systemctl restart vsftpd
```

## 🔧 Gestion du serveur

### Commandes essentielles

```bash
# Statut du service
sudo systemctl status vsftpd

# Redémarrer le service
sudo systemctl restart vsftpd

# Arrêter le service
sudo systemctl stop vsftpd

# Démarrer le service
sudo systemctl start vsftpd

# Voir les logs en temps réel
sudo tail -f /var/log/vsftpd.log

# Voir les connexions actives
sudo netstat -tuln | grep :21
```

### Fichiers de configuration

#### `/etc/vsftpd.conf` - Configuration principale
```bash
sudo nano /etc/vsftpd.conf
# Redémarrer après modification :
sudo systemctl restart vsftpd
```

#### `/etc/vsftpd.userlist` - Utilisateurs autorisés
```bash
sudo nano /etc/vsftpd.userlist
# Ajouter un utilisateur par ligne
```

### Logs et débogage

```bash
# Logs du service vsftpd
sudo journalctl -u vsftpd

# Logs des transferts FTP
sudo tail -f /var/log/vsftpd.log

# Tester la connectivité locale
telnet localhost 21
```

## 🛠️ Résolution des problèmes

### Problème : "Connexion refusée" 

**Solution :**
```bash
# Vérifier que le service fonctionne
sudo systemctl status vsftpd

# Vérifier les ports ouverts
sudo netstat -tuln | grep :21

# Vérifier le firewall
sudo ufw status
```

### Problème : "Login incorrect"

**Solution :**
```bash
# Vérifier que l'utilisateur est dans la liste
cat /etc/vsftpd.userlist

# Tester le mot de passe
su - ubuntu

# Réinitialiser le mot de passe
sudo passwd ubuntu
```

### Problème : "Mode passif ne fonctionne pas"

**Solution :**
```bash
# Vérifier les ports passifs dans le firewall
sudo ufw status | grep 40000

# Si manquants, les ajouter :
sudo ufw allow 40000:40100/tcp
```

### Problème : "Permissions denied sur /var/www"

**Solution :**
```bash
# Corriger les permissions
sudo chown -R ubuntu:www-data /var/www
sudo chmod -R 775 /var/www

# Vérifier le lien symbolique
ls -la /home/ubuntu/www
```

## 📊 Surveillance et maintenance

### Surveillance des connexions
```bash
# Script de surveillance des connexions FTP
#!/bin/bash
while true; do
    echo "=== $(date) ==="
    sudo netstat -tn | grep :21
    sleep 60
done
```

### Sauvegarde de la configuration
```bash
# Sauvegarder la configuration
sudo cp /etc/vsftpd.conf /root/vsftpd.conf.backup
sudo cp /etc/vsftpd.userlist /root/vsftpd.userlist.backup
```

### Nettoyage des logs
```bash
# Nettoyer les anciens logs (à faire régulièrement)
sudo logrotate /etc/logrotate.d/vsftpd
```

## 🚮 Désinstallation

Si vous souhaitez supprimer complètement le serveur FTP :

```bash
# Utiliser le script de désinstallation
sudo /tmp/remove-ftp-server.sh

# Ou désinstallation manuelle :
sudo systemctl stop vsftpd
sudo systemctl disable vsftpd
sudo apt remove --purge vsftpd
sudo rm -f /etc/vsftpd.conf
sudo ufw delete allow 21/tcp
sudo ufw delete allow 40000:40100/tcp
```

## 💡 Conseils d'utilisation

### Pour développement
- ✅ FTP standard suffisant
- ✅ Connexion rapide et simple
- ✅ Compatible avec tous les éditeurs

### Pour production
- 🔒 Activez SSL/TLS obligatoirement
- 🔑 Utilisez des mots de passe forts
- 📝 Surveillez les logs régulièrement
- 🔄 Sauvegardez la configuration

### Alternatives plus sécurisées
- **SFTP** : Via SSH (port 22)
- **FTPS** : FTP avec SSL/TLS
- **rsync** : Synchronisation sécurisée
- **Git** : Pour le code source

## 📞 Support

En cas de problème :
1. Vérifiez les logs : `sudo tail -f /var/log/vsftpd.log`
2. Testez la connectivité : `telnet [IP] 21`
3. Vérifiez les permissions : `ls -la /var/www`
4. Consultez la configuration : `cat /etc/vsftpd.conf`

**Le serveur FTP est maintenant prêt pour faciliter vos déploiements HYGITECH-3D !** 🚀