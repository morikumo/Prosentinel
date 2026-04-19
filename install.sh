#!/usr/bin/env bash

# ProSentinel — Install script
SCRIPT_PATH="$(realpath prosentinel.sh)"
SERVICE_FILE="/etc/systemd/system/prosentinel.service"

echo "Installation de ProSentinel..."
echo "Chemin détecté : $SCRIPT_PATH"

# Créer le fichier de log
sudo touch /var/log/prosentinel.log
sudo chmod 644 /var/log/prosentinel.log

# Générer le .service avec le bon chemin
sudo tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=ProSentinel — Process Security Monitor
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash $SCRIPT_PATH --daemon
Restart=on-failure
RestartSec=10
StandardOutput=append:/var/log/prosentinel.log
StandardError=append:/var/log/prosentinel.log

[Install]
WantedBy=multi-user.target
EOF

# Recharger et activer
sudo systemctl daemon-reload
sudo systemctl enable prosentinel
sudo systemctl start prosentinel

echo -e "ProSentinel installé et démarré."
echo -e "Statut : sudo systemctl status prosentinel"
echo -e "Logs   : sudo tail -f /var/log/prosentinel.log"