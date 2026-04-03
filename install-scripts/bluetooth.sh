#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Cose Bluetooth #

blue=(
  bluez
  bluez-utils
  blueman
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_bluetooth.log"

# Bluetooth
printf "${NOTE} Installazione pacchetti ${SKY_BLUE}Bluetooth${RESET}...\n"
 for BLUE in "${blue[@]}"; do
   install_package "$BLUE" "$LOG"
  done

printf " Attivazione servizi ${YELLOW}Bluetooth${RESET}...\n"
sudo systemctl enable --now bluetooth.service 2>&1 | tee -a "$LOG"

printf "\n%.0s" {1..2}
