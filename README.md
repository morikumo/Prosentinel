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
```sh
└─$ sudo systemctl status prosentinel
● prosentinel.service - ProSentinel — Process Security Monitor
     Loaded: loaded (/etc/systemd/system/prosentinel.service; enabled; preset: disabled)
     Active: active (running) since Sun 2026-04-19 16:28:05 CEST; 2min 33s ago
 Invocation: 714973ccc8784c998a30815a66d36c11
   Main PID: 111791 (bash)
      Tasks: 2 (limit: 37814)
     Memory: 2.8M (peak: 13.3M)
        CPU: 24.924s
     CGroup: /system.slice/prosentinel.service
             ├─111791 /bin/bash /home/[user]/Documents/project/Prosentinel/prosentinel.sh --daemon
             └─126122 sleep 60
``` 

# Voir les logs en live
sudo tail -f /var/log/prosentinel.log

# Pour l'arrêter 
sudo systemctl stop prosentinel

# POur desinstaller complètement 
sudo systemctl stop prosentinel
sudo systemctl disable prosentinel
sudo rm /etc/systemd/system/prosentinel.service
sudo systemctl daemon-reload

# Désactiver le démarrage automatique au boot
sudo systemctl disable prosentinel