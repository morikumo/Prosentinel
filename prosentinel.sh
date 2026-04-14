#!/usr/bin/env bash

# ProSentinel v0.1 — Process Monitor
# Usage: ./prosentinel.sh

# Couleurs
RED='\033[1;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'
ORANGE='\033[0;33m'

echo -e "${CYAN}ProSentinel v0.1${RESET} — ${DIM}$(date '+%Y-%m-%d %H:%M:%S')${RESET}\n"

# ─── 1. Liste des processus ───────────────────────────────────
echo -e "${DIM}PID      USER       CPU%  MEM%  COMMAND${RESET}"
echo -e "${DIM}-------- ---------- ----- ----- -------------------------${RESET}"

#ps aux --no-headers | awk '{printf "%-8s %-10s %-5s %-5s %s\n", $2, $1, $3, $4, $11}' | sort -k3 -rn

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

# ─── 3. Détection : consommation CPU / RAM anormale ───────────
echo -e "${CYAN}[ Détection — consommation anormale ]${RESET}"

CPU_THRESHOLD=50
RAM_THRESHOLD=20

HIGH_CPU=$(ps aux --no-headers | awk -v threshold="$CPU_THRESHOLD" \
    '$3 > threshold {printf "%-8s %-10s %-5s %-5s %s\n", $2, $1, $3, $4, $11}')

HIGH_RAM=$(ps aux --no-headers | awk -v threshold="$RAM_THRESHOLD" \
    '$4 > threshold {printf "%-8s %-10s %-5s %-5s %s\n", $2, $1, $3, $4, $11}')

if [[ -z "$HIGH_CPU" && -z "$HIGH_RAM" ]]; then
    echo -e "${GREEN}Aucune consommation anormale détectée.${RESET}"
else
    if [[ -n "$HIGH_CPU" ]]; then
        echo -e "${RED}ALERTE — CPU > ${CPU_THRESHOLD}% :${RESET}"
        echo -e "${DIM}PID      USER       CPU%  MEM%  COMMAND${RESET}"
        echo -e "${DIM}-------- ---------- ----- ----- -------------------------${RESET}"
        while IFS= read -r line; do
            echo -e "${RED}$line${RESET}"
        done <<< "$HIGH_CPU"
        echo ""
    fi

    if [[ -n "$HIGH_RAM" ]]; then
        echo -e "${ORANGE}ALERTE — RAM > ${RAM_THRESHOLD}% :${RESET}"
        echo -e "${DIM}PID      USER       CPU%  MEM%  COMMAND${RESET}"
        echo -e "${DIM}-------- ---------- ----- ----- -------------------------${RESET}"
        while IFS= read -r line; do
            echo -e "${ORANGE}$line${RESET}"
        done <<< "$HIGH_RAM"
        echo ""
    fi
fi

# ─── 4. Détection : processus fantômes ───────────────────────
echo -e "${CYAN}[ Détection — processus fantômes ]${RESET}"

GHOSTS=""

while IFS= read -r pid; do
    # Ignorer les threads kernel (pas de /proc/PID/exe ET ppid=2)
    ppid=$(awk '/PPid/{print $2}' /proc/$pid/status 2>/dev/null)
    [[ "$ppid" == "2" || "$pid" == "2" ]] && continue

    exe=$(readlink -f /proc/$pid/exe 2>/dev/null)
    if [[ -z "$exe" || "$exe" == *"(deleted)"* ]]; then
        cmd=$(cat /proc/$pid/comm 2>/dev/null)
        user=$(stat -c '%U' /proc/$pid 2>/dev/null)
        GHOSTS+="$(printf '%-8s %-10s %s\n' "$pid" "$user" "$cmd")\n"
    fi
done < <(ps aux --no-headers | awk '{print $2}')

if [[ -z "$GHOSTS" ]]; then
    echo -e "${GREEN}Aucun processus fantôme détecté.${RESET}"
else
    echo -e "${RED}ALERTE — Processus sans exécutable lisible :${RESET}"
    echo -e "${DIM}PID      USER       COMMAND${RESET}"
    echo -e "${DIM}-------- ---------- -------------------------${RESET}"
    echo -e "${RED}${GHOSTS}${RESET}"
fi

echo ""