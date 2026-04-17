# Prosentinel
Surveillance de processus pour détecter les potentielles anomalie


Lancement du daemon :

# Recharger systemd
sudo systemctl daemon-reload

# Activer au démarrage
sudo systemctl enable prosentinel

# Démarrer maintenant
sudo systemctl start prosentinel

# Statut
sudo systemctl status prosentinel

# Voir les logs en live
sudo tail -f /var/log/prosentinel.log

# Pour l'arrêter 
sudo systemctl stop prosentinel