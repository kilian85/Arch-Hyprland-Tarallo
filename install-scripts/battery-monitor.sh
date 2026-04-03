#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Monitor Batteria e Notifica Batteria Scarica #

battery=(
  acpi
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_battery-monitor.log"

# Monitor Batteria
printf "${NOTE} Installazione pacchetti ${SKY_BLUE}Monitor Batteria${RESET}...\n"
for BAT in "${battery[@]}"; do
  install_package "$BAT" "$LOG"
done

# Crea script di monitoraggio batteria
printf "${NOTE} Creazione script ${YELLOW}monitor batteria${RESET}...\n"

BATTERY_SCRIPT="$HOME/.config/hypr/scripts/battery-monitor.sh"
mkdir -p "$HOME/.config/hypr/scripts"

cat > "$BATTERY_SCRIPT" << 'EOF'
#!/bin/bash
# Script Notifica Batteria Scarica
# Monitora il livello della batteria e invia notifiche

# Configurazione
LOW_BATTERY_THRESHOLD=20
CRITICAL_BATTERY_THRESHOLD=10
CHECK_INTERVAL=60  # Controlla ogni 60 secondi

# Traccia lo stato delle notifiche per evitare spam
NOTIFIED_LOW=false
NOTIFIED_CRITICAL=false

while true; do
    # Ottieni la percentuale della batteria
    BATTERY_LEVEL=$(acpi -b | grep -P -o '[0-9]+(?=%)')
    BATTERY_STATUS=$(acpi -b | grep -o 'Discharging\|Charging\|Full')
    
    # Invia notifiche solo durante la scarica
    if [ "$BATTERY_STATUS" = "Discharging" ]; then
        if [ "$BATTERY_LEVEL" -le "$CRITICAL_BATTERY_THRESHOLD" ] && [ "$NOTIFIED_CRITICAL" = false ]; then
            notify-send -u critical -i battery-caution "Batteria Critica" "Il livello della batteria è al ${BATTERY_LEVEL}%! Collega immediatamente il caricabatterie."
            NOTIFIED_CRITICAL=true
            NOTIFIED_LOW=true
        elif [ "$BATTERY_LEVEL" -le "$LOW_BATTERY_THRESHOLD" ] && [ "$NOTIFIED_LOW" = false ]; then
            notify-send -u normal -i battery-low "Batteria Scarica" "Il livello della batteria è al ${BATTERY_LEVEL}%. Considera di collegare il caricabatterie."
            NOTIFIED_LOW=true
        fi
    else
        # Resetta i flag delle notifiche durante la carica o piena
        NOTIFIED_LOW=false
        NOTIFIED_CRITICAL=false
    fi
    
    sleep "$CHECK_INTERVAL"
done
EOF

chmod +x "$BATTERY_SCRIPT"

printf "${OK} Script monitor batteria creato in ${YELLOW}$BATTERY_SCRIPT${RESET}\n"

# Crea servizio utente systemd
printf "${NOTE} Creazione ${YELLOW}servizio utente systemd${RESET} per monitor batteria...\n"

SYSTEMD_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_DIR"

cat > "$SYSTEMD_DIR/battery-monitor.service" << EOF
[Unit]
Description=Monitor Livello Batteria
After=graphical-session.target

[Service]
Type=simple
ExecStart=$BATTERY_SCRIPT
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

printf "${OK} Systemd service created\n"

# Enable and start the service
printf "${NOTE} Enabling and starting ${YELLOW}battery-monitor${RESET} service...\n"
systemctl --user daemon-reload
systemctl --user enable battery-monitor.service 2>&1 | tee -a "$LOG"
systemctl --user start battery-monitor.service 2>&1 | tee -a "$LOG"

printf "${OK} Battery monitor service is now running!\n"
printf "${INFO} You can check status with: ${YELLOW}systemctl --user status battery-monitor${RESET}\n"
printf "${INFO} To stop: ${YELLOW}systemctl --user stop battery-monitor${RESET}\n"
printf "${INFO} To disable: ${YELLOW}systemctl --user disable battery-monitor${RESET}\n"

printf "\n%.0s" {1..2}
