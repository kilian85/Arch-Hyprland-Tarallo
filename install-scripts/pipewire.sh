#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Pipewire e componenti audio Pipewire #

pipewire=(
    pipewire
    wireplumber
    pipewire-audio
    pipewire-alsa
    pipewire-pulse
    sof-firmware
)

# aggiunto questo poiché alcuni report indicano che lo script non lo installava.
# fondamentalmente forza reinstallazione
pipewire_2=(
    pipewire-pulse
)

############## AVVERTIMENTO: NON MODIFICARE OLTRE QUESTA RIGA SE NON SAI COSA STAI FACENDO! ##############
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Cambia la directory di lavoro nella directory padre dello script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Impossibile cambiare directory in $PARENT_DIR"; exit 1; }

# Sorgente lo script delle funzioni globali
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"

# Imposta il nome del file di log per includere la data e l'ora corrente
LOG="Install-Logs/install-$(date +%d-%H%M%S)_pipewire.log"

# Disabilitazione di pulseaudio per evitare conflitti e registrazione dell'output
echo -e "${NOTE} Disabilitazione di pulseaudio per evitare conflitti..."
systemctl --user disable --now pulseaudio.socket pulseaudio.service >> "$LOG" 2>&1 || true

# Pipewire
echo -e "${NOTE} Installazione dei pacchetti ${SKY_BLUE}Pipewire${RESET}..."
for PIPEWIRE in "${pipewire[@]}"; do
    install_package "$PIPEWIRE" "$LOG"
done

for PIPEWIRE2 in "${pipewire_2[@]}"; do
    install_package_pacman "$PIPEWIRE" "$LOG"
done

echo -e "${NOTE} Attivazione dei servizi Pipewire..."
# Reindirizza l'output di systemctl al file di log
systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service 2>&1 | tee -a "$LOG"
systemctl --user enable --now pipewire.service 2>&1 | tee -a "$LOG"

echo -e "\n${OK} Installazione Pipewire e configurazione servizi completata!" 2>&1 | tee -a "$LOG"

printf "\n%.0s" {1..2}
