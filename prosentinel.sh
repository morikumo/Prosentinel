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
    '$3 > threshold && $11 !~ /ps|awk|bash/ \
    {printf "%-8s %-10s %-5s %-5s %s\n", $2, $1, $3, $4, $11}')

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
    [[ "$ppid" == "2" || "$ppid" == "1" || "$pid" == "2" ]] && continue


    GHOST_WHITELIST="systemd|ssh-agent|fusermount|sd-pam|gdm|systemd-userwor"
    if echo "$cmd" | grep -qE "$GHOST_WHITELIST"; then
        continue
    fi

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

# ─── 5. Détection : processus root suspects ───────────────────
echo -e "${CYAN}[ Détection — processus root suspects ]${RESET}"

# Processus légitimes connus qui tournent en root
WHITELIST="systemd|kthreadd|kworker|ksoftirqd|migration|rcu_|init|sshd|cron|rsyslog|NetworkManager|dockerd|containerd|udevd|journald|logind|dbus|polkit|gdm|wpa_supplicant|haveged|smartd|ModemManager|upowerd|udisksd|fwupd|accounts|power-profiles|fusermount|pcscd"
ROOT_SUSPECTS=""

while IFS= read -r line; do
    pid=$(echo "$line"  | awk '{print $2}')
    cmd=$(echo "$line"  | awk '{print $11}')
    name=$(cat /proc/$pid/comm 2>/dev/null)

    # Ignorer si dans la whitelist
    if echo "$name" | grep -qE "$WHITELIST"; then
        continue
    fi

    # Ignorer les threads kernel
    ppid=$(awk '/PPid/{print $2}' /proc/$pid/status 2>/dev/null)
    [[ "$ppid" == "2" || "$ppid" == "1" || "$pid" == "2" ]] && continue
    [[ "$pid"  == "1" ]] && continue

    ROOT_SUSPECTS+="$(printf '%-8s %-10s %s\n' "$pid" "root" "$name")\n"

done < <(ps aux --no-headers | awk '$1 == "root"')

if [[ -z "$ROOT_SUSPECTS" ]]; then
    echo -e "${GREEN}Aucun processus root suspect détecté.${RESET}"
else
    echo -e "${ORANGE}AVERTISSEMENT — Processus root hors whitelist :${RESET}"
    echo -e "${DIM}PID      USER       COMMAND${RESET}"
    echo -e "${DIM}-------- ---------- -------------------------${RESET}"
    echo -e "${ORANGE}${ROOT_SUSPECTS}${RESET}"
fi

echo ""

# ─── 6. Détection : ports suspects + connexions externes ──────
echo -e "${CYAN}[ Détection — réseau ]${RESET}"

# Ports légitimes connus
PORT_WHITELIST="22|80|443|53|631|25|587|993|3306|5432|8080|8443"

# ── 6a. Processus écoutant sur des ports inhabituels ──────────
echo -e "${DIM}Ports en écoute hors whitelist :${RESET}"

SUSPECT_PORTS=""

while IFS= read -r line; do
    port=$(echo "$line" | awk '{print $4}' | rev | cut -d: -f1 | rev)
    pid=$(echo  "$line" | awk '{print $7}' | cut -d/ -f1 | tr -d ' ')
    name=$(echo "$line" | awk '{print $7}' | cut -d/ -f2)

    [[ -z "$port" || -z "$pid" ]] && continue

    if ! echo "$port" | grep -qE "^($PORT_WHITELIST)$"; then
        SUSPECT_PORTS+="$(printf '%-8s %-20s %s\n' "$pid" "$name" "$port")\n"
    fi
done < <(ss -tlnp 2>/dev/null | tail -n +2)

if [[ -z "$SUSPECT_PORTS" ]]; then
    echo -e "${GREEN}Aucun port suspect en écoute.${RESET}"
else
    echo -e "${ORANGE}AVERTISSEMENT — Ports hors whitelist :${RESET}"
    echo -e "${DIM}PID      PROCESS              PORT${RESET}"
    echo -e "${DIM}-------- -------------------- -----${RESET}"
    echo -e "${ORANGE}${SUSPECT_PORTS}${RESET}"
fi

echo ""

# ── 6b. Connexions actives vers IPs externes ──────────────────
echo -e "${DIM}Connexions actives vers IPs externes :${RESET}"

EXTERNAL_CONNS=""

while IFS= read -r line; do
    # Extraire IP:PORT distante (5ème colonne)
    remote=$(echo "$line" | awk '{print $5}')
    ip=$(echo "$remote" | sed 's/:\([0-9]*\)$//' | tr -d '[]')
    port=$(echo "$remote" | grep -oE ':[0-9]+$' | tr -d ':')
    # Extraire nom du processus
    proc=$(echo "$line" | grep -oP '"\K[^"]+(?=")' | head -1)

    [[ -z "$ip" || -z "$port" ]] && continue

    # Ignorer IPs privées et locales
    if echo "$ip" | grep -qE \
        '^(127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.|::1|fe80|0\.0\.0\.0|\*|-)'; then
        continue
    fi

    EXTERNAL_CONNS+="$(printf '%-25s %-6s %s\n' "$ip" "$port" "${proc:-inconnu}")\n"

done < <(ss -tnp state established 2>/dev/null | tail -n +2)

if [[ -z "$EXTERNAL_CONNS" ]]; then
    echo -e "${GREEN}Aucune connexion externe active.${RESET}"
else
    echo -e "${RED}ALERTE — Connexions vers IPs externes :${RESET}"
    echo -e "${DIM}IP DISTANTE               PORT   PROCESS${RESET}"
    echo -e "${DIM}------------------------- ------ ----------${RESET}"
    echo -e "${RED}${EXTERNAL_CONNS}${RESET}"
fi

echo ""