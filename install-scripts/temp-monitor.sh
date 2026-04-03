#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Monitor Temperature - Avvisi Temperatura CPU/GPU #

temp=(
  lm_sensors
  libnotify
)

## ATTENZIONE: NON MODIFICARE OLTRE QUESTA LINEA SE NON SAI COSA STAI FACENDO! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Cambia la directory di lavoro alla cartella superiore dello script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Impossibile cambiare directory in $PARENT_DIR"; exit 1; }

# Carica il file delle funzioni globali
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Impossibile caricare Global_functions.sh"
  exit 1
fi

# Imposta il nome del file di log includendo data e ora corrente
LOG="Install-Logs/install-$(date +%d-%H%M%S)_temp-monitor.log"

# Monitor di Temperatura
printf "${NOTE} Installazione pacchetti ${SKY_BLUE}Monitor di Temperatura${RESET}...\n"
for TEMP in "${temp[@]}"; do
  install_package "$TEMP" "$LOG"
done

# Rilevamento sensori
printf "${NOTE} Rilevamento ${YELLOW}sensori hardware${RESET}...\n"
sudo sensors-detect --auto 2>&1 | tee -a "$LOG"

# Creazione dello script di monitoraggio temperatura
printf "${NOTE} Creazione dello script di ${YELLOW}monitoraggio temperatura${RESET}...\n"

TEMP_SCRIPT="$HOME/.config/hypr/scripts/temp-monitor.sh"
mkdir -p "$HOME/.config/hypr/scripts"

cat > "$TEMP_SCRIPT" << 'EOF'
#!/bin/bash
# Script di Monitoraggio Temperatura
# Monitora le temperature di CPU e GPU e invia avvisi

# Configurazione
CPU_TEMP_WARNING=75
CPU_TEMP_CRITICAL=85
GPU_TEMP_WARNING=75
GPU_TEMP_CRITICAL=85
CHECK_INTERVAL=30  # Controlla ogni 30 secondi

# Tracciamento stato notifiche
NOTIFIED_CPU_WARN=false
NOTIFIED_CPU_CRIT=false
NOTIFIED_GPU_WARN=false
NOTIFIED_GPU_CRIT=false

while true; do
    # Ottieni temperatura CPU (media di tutti i core)
    CPU_TEMP=$(sensors | grep -i 'Package id 0:\|Tdie:' | awk '{print $4}' | sed 's/+//;s/°C//' | head -1)
    
    # Se Package id non trovato, prova altri metodi
    if [ -z "$CPU_TEMP" ]; then
        CPU_TEMP=$(sensors | grep -i 'Core 0:' | awk '{print $3}' | sed 's/+//;s/°C//' | head -1)
    fi
    
    # Ottieni temperatura GPU (se disponibile)
    GPU_TEMP=$(sensors | grep -i 'edge:\|temp1:' | awk '{print $2}' | sed 's/+//;s/°C//' | head -1)
    
    # Controllo temperatura CPU
    if [ -n "$CPU_TEMP" ]; then
        CPU_TEMP_INT=${CPU_TEMP%.*}
        
        if [ "$CPU_TEMP_INT" -ge "$CPU_TEMP_CRITICAL" ]; then
            if [ "$NOTIFIED_CPU_CRIT" = false ]; then
                notify-send -u critical -i temperature-high "Temperatura CPU Critica" "La temperatura della CPU è di ${CPU_TEMP}°C! Il sistema potrebbe rallentare o spegnersi."
                NOTIFIED_CPU_CRIT=true
                NOTIFIED_CPU_WARN=true
            fi
        elif [ "$CPU_TEMP_INT" -ge "$CPU_TEMP_WARNING" ]; then
            if [ "$NOTIFIED_CPU_WARN" = false ]; then
                notify-send -u normal -i temperature-normal "Temperatura CPU Elevata" "La temperatura della CPU è di ${CPU_TEMP}°C"
                NOTIFIED_CPU_WARN=true
            fi
        else
            NOTIFIED_CPU_WARN=false
            NOTIFIED_CPU_CRIT=false
        fi
    fi
    
    # Controllo temperatura GPU
    if [ -n "$GPU_TEMP" ]; then
        GPU_TEMP_INT=${GPU_TEMP%.*}
        
        if [ "$GPU_TEMP_INT" -ge "$GPU_TEMP_CRITICAL" ]; then
            if [ "$NOTIFIED_GPU_CRIT" = false ]; then
                notify-send -u critical -i temperature-high "Temperatura GPU Critica" "La temperatura della GPU è di ${GPU_TEMP}°C!"
                NOTIFIED_GPU_CRIT=true
                NOTIFIED_GPU_WARN=true
            fi
        elif [ "$GPU_TEMP_INT" -ge "$GPU_TEMP_WARNING" ]; then
            if [ "$NOTIFIED_GPU_WARN" = false ]; then
                notify-send -u normal -i temperature-normal "Temperatura GPU Elevata" "La temperatura della GPU è di ${GPU_TEMP}°C"
                NOTIFIED_GPU_WARN=true
            fi
        else
            NOTIFIED_GPU_WARN=false
            NOTIFIED_GPU_CRIT=false
        fi
    fi
    
    sleep "$CHECK_INTERVAL"
done
EOF

chmod +x "$TEMP_SCRIPT"

printf "${OK} Script di monitoraggio creato in ${YELLOW}$TEMP_SCRIPT${RESET}\n"

# Creazione del servizio utente systemd
printf "${NOTE} Creazione del ${YELLOW}servizio utente systemd${RESET} per il monitoraggio temperatura...\n"

SYSTEMD_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_DIR"

cat > "$SYSTEMD_DIR/temp-monitor.service" << EOF
[Unit]
Description=Monitor di Temperatura
After=graphical-session.target

[Service]
Type=simple
ExecStart=$TEMP_SCRIPT
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

printf "${OK} Servizio Systemd creato\n"

# Abilitazione e avvio del servizio
printf "${NOTE} Abilitazione e avvio del servizio ${YELLOW}temp-monitor${RESET}...\n"
systemctl --user daemon-reload
systemctl --user enable temp-monitor.service 2>&1 | tee -a "$LOG"
systemctl --user start temp-monitor.service 2>&1 | tee -a "$LOG"

printf "${OK} Il servizio di monitoraggio temperatura è ora attivo!\n"
printf "${INFO} Puoi controllare lo stato con: ${YELLOW}systemctl --user status temp-monitor${RESET}\n"
printf "${INFO} Visualizza temperature attuali: ${YELLOW}sensors${RESET}\n"

printf "\n%.0s" {1..2}
