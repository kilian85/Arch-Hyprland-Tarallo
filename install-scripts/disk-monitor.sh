#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Monitor Spazio Disco #

disk=(
  libnotify
)


## AVVERTIMENTO: NON MODIFICARE OLTRE QUESTA RIGA SE NON SAI COSA STAI FACENDO! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Cambia la directory di lavoro nella directory padre dello script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Impossibile cambiare directory in $PARENT_DIR"; exit 1; }

# Sorgente lo script delle funzioni globali
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Impossibile sorgentare Global_functions.sh"
  exit 1
fi

# Imposta il nome del file di log per includere la data e l'ora corrente
LOG="Install-Logs/install-$(date +%d-%H%M%S)_disk-monitor.log"

# Monitor Disco
printf "${NOTE} Installazione pacchetti per ${SKY_BLUE}Monitor Disco${RESET}...\n"
for DISK in "${disk[@]}"; do
  install_package "$DISK" "$LOG"
done

# Crea script di monitoraggio disco
printf "${NOTE} Creazione script di ${YELLOW}monitoraggio spazio disco${RESET}...\n"

DISK_SCRIPT="$HOME/.config/hypr/scripts/disk-monitor.sh"
mkdir -p "$HOME/.config/hypr/scripts"

cat > "$DISK_SCRIPT" << 'EOF'
#!/bin/bash
# Script di Monitoraggio Spazio Disco
# Monitora l'utilizzo del disco e invia notifiche

# Configurazione
DISK_WARNING_THRESHOLD=80
DISK_CRITICAL_THRESHOLD=90
CHECK_INTERVAL=300  # Controlla ogni 5 minuti

# Traccia lo stato delle notifiche
declare -A NOTIFIED_WARNING
declare -A NOTIFIED_CRITICAL

while true; do
    # Ottieni l'utilizzo del disco per tutti i filesystem montati
    df -h | grep '^/dev/' | while read -r line; do
        DEVICE=$(echo "$line" | awk '{print $1}')
        MOUNT=$(echo "$line" | awk '{print $6}')
        USAGE=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        
        # Salta se l'utilizzo non è un numero
        if ! [[ "$USAGE" =~ ^[0-9]+$ ]]; then
            continue
        fi
        
        # Controlla l'utilizzo del disco
        if [ "$USAGE" -ge "$DISK_CRITICAL_THRESHOLD" ]; then
            if [ "${NOTIFIED_CRITICAL[$MOUNT]}" != "true" ]; then
                notify-send -u critical -i drive-harddisk "Spazio Disco Critico" "Il punto di mount $MOUNT è al ${USAGE}% di riempimento!\nDispositivo: $DEVICE"
                NOTIFIED_CRITICAL[$MOUNT]="true"
                NOTIFIED_WARNING[$MOUNT]="true"
            fi
        elif [ "$USAGE" -ge "$DISK_WARNING_THRESHOLD" ]; then
            if [ "${NOTIFIED_WARNING[$MOUNT]}" != "true" ]; then
                notify-send -u normal -i drive-harddisk "Spazio Disco Basso" "Il punto di mount $MOUNT è al ${USAGE}% di riempimento\nDispositivo: $DEVICE"
                NOTIFIED_WARNING[$MOUNT]="true"
            fi
        else
            # Resetta le notifiche quando l'utilizzo scende
            if [ "$USAGE" -lt $((DISK_WARNING_THRESHOLD - 5)) ]; then
                NOTIFIED_WARNING[$MOUNT]="false"
                NOTIFIED_CRITICAL[$MOUNT]="false"
            fi
        fi
    done
    
    sleep "$CHECK_INTERVAL"
done
EOF

chmod +x "$DISK_SCRIPT"

printf "${OK} Script di monitoraggio disco creato in ${YELLOW}$DISK_SCRIPT${RESET}\n"

# Crea servizio systemd utente
printf "${NOTE} Creazione ${YELLOW}servizio systemd utente${RESET} per monitoraggio disco...\n"

SYSTEMD_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_DIR"

cat > "$SYSTEMD_DIR/disk-monitor.service" << EOF
[Unit]
Description=Monitor Spazio Disco
After=graphical-session.target

[Service]
Type=simple
ExecStart=$DISK_SCRIPT
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

printf "${OK} Servizio systemd creato\n"

# Abilita e avvia il servizio
printf "${NOTE} Abilitazione e avvio servizio ${YELLOW}disk-monitor${RESET}...\n"
systemctl --user daemon-reload
systemctl --user enable disk-monitor.service 2>&1 | tee -a "$LOG"
systemctl --user start disk-monitor.service 2>&1 | tee -a "$LOG"

printf "${OK} Il servizio monitor disco è ora in esecuzione!\n"
printf "${INFO} Puoi controllare lo stato con: ${YELLOW}systemctl --user status disk-monitor${RESET}\n"
printf "${INFO} Visualizza utilizzo disco: ${YELLOW}df -h${RESET}\n"

printf "\n%.0s" {1..2}
