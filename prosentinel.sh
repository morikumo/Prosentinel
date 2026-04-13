#!/usr/bin/env bash

# ProSentinel v0.1 — Process Monitor
# Usage: ./prosentinel.sh

# Couleurs
RED='\033[1;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

echo -e "${CYAN}ProSentinel v0.1${RESET} — ${DIM}$(date '+%Y-%m-%d %H:%M:%S')${RESET}\n"

# ─── 1. Liste des processus ───────────────────────────────────
echo -e "${DIM}PID      USER       CPU%  MEM%  COMMAND${RESET}"
echo -e "${DIM}-------- ---------- ----- ----- -------------------------${RESET}"

ps aux --no-headers | awk '{printf "%-8s %-10s %-5s %-5s %s\n", $2, $1, $3, $4, $11}' | sort -k3 -rn

# ─── 2. Détection : processus lancés depuis /tmp ou /dev/shm ──
echo -e "${CYAN}[ Détection — exécutables suspects ]${RESET}"

SUSPECTS=$(ps aux --no-headers | awk '$11 ~ /^\/tmp|^\/dev\/shm/ {print $2, $1, $11}')

if [[ -z "$SUSPECTS" ]]; then
    echo -e "${GREEN}Aucun processus suspect détecté.${RESET}"
else
    echo -e "${RED}ALERTE — Processus lancés depuis un dossier suspect :${RESET}"
    echo -e "${DIM}PID      USER       CHEMIN${RESET}"
    echo -e "${DIM}-------- ---------- -------------------------${RESET}"
    while IFS= read -r line; do
        echo -e "${RED}$line${RESET}"
    done <<< "$SUSPECTS"
fi

echo ""