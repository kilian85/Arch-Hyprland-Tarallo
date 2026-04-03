#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Thunar-default #


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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_thunar-default.log"

printf "${INFO} Impostazione di ${SKY_BLUE}Thunar${RESET} come gestore file predefinito...\n"  
 
xdg-mime default thunar.desktop inode/directory
xdg-mime default thunar.desktop application/x-wayland-gnome-saved-search
echo "${OK} ${MAGENTA}Thunar${RESET} è ora impostato come gestore file predefinito." | tee -a "$LOG"

printf "\n%.0s" {1..2}
