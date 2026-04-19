# ProSentinel

Process security monitor for Linux — détecte les comportements suspects en temps réel. (La liste de test va etre ajoutés au fur et a mesure)

## Fonctionnalités

- Détection de processus lancés depuis `/tmp` ou `/dev/shm`
- Détection de consommation CPU/RAM anormale
- Détection de processus fantômes (exécutable supprimé après lancement)
- Détection de processus root hors whitelist
- Détection de ports en écoute inhabituels
- Détection de connexions actives vers des IPs externes
- Mode daemon via systemd (surveillance continue)

## Prérequis

- Linux (Debian / Ubuntu / Kali)
- Bash 5+
- systemd
- Droits sudo pour le mode daemon

## Installation

```bash
git clone https://github.com/ton-user/prosentinel.git
cd prosentinel
chmod +x prosentinel.sh install.sh
```

## Usage

```bash
# Afficher l'aide
./prosentinel.sh

# Scan unique
./prosentinel.sh --scan

# Installer et démarrer le daemon
./prosentinel.sh --daemon

# Vérifier l'état du daemon
./prosentinel.sh --status

# Arrêter le daemon
./prosentinel.sh --stop
```

## Structure

```
prosentinel/
├── prosentinel.sh    ← script principal
├── install.sh        ← installation du service systemd
└── README.md
```

## Logs

Les logs du daemon sont écrits dans `/var/log/prosentinel.log` :

```bash
sudo tail -f /var/log/prosentinel.log
```

## Détections

| Détection | Sévérité | Description |
|---|---|---|
| Exécutable depuis /tmp | CRITIQUE | Binaire lancé depuis un dossier temporaire |
| Processus fantôme | HAUTE | Exécutable supprimé après lancement |
| CPU/RAM anormale | HAUTE | Consommation > seuil configuré |
| Processus root suspect | MOYENNE | Process root hors whitelist |
| Port inhabituel | MOYENNE | Port en écoute hors whitelist |
| Connexion externe | INFO | Connexion active vers IP publique |

## Configuration

Les seuils sont configurables directement dans `prosentinel.sh` :

```bash
DAEMON_INTERVAL=60   # secondes entre chaque scan
CPU_THRESHOLD=50     # % CPU avant alerte
RAM_THRESHOLD=20     # % RAM avant alerte
```

## Avertissement

Cet outil est conçu pour surveiller **votre propre système**. Ne l'utilisez pas sur des systèmes dont vous n'êtes pas propriétaire.

## Licence

MIT