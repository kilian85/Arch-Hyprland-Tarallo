#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# XDG-Desktop-Portals hyprland #

xdg=(
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    umockdev
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_xdph.log"

# XDG-DESKTOP-PORTAL-HYPRLAND
printf "${NOTE} Installazione di ${SKY_BLUE}xdg-desktop-portal-hyprland${RESET}\n" 
for xdgs in "${xdg[@]}"; do
  install_package "$xdgs" "$LOG"
done
    
printf "\n%.0s" {1..2}
