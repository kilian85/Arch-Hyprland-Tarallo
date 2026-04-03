#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Pacchetto Principale Hyprland #

hypr_eco=(
  hypridle
  hyprlock
)

hypr=(
  hyprland
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_hyprland.log"

# Verifica se Hyprland è installato
if command -v Hyprland >/dev/null 2>&1; then
  printf "$NOTE - ${YELLOW} Hyprland è già installato.${RESET} Nessuna azione richiesta.\n"
else
  printf "$INFO - Hyprland non trovato. ${SKY_BLUE} Installazione di Hyprland...${RESET}\n"
  for HYPRLAND in "${hypr[@]}"; do
    install_package "$HYPRLAND" "$LOG"
  done
fi

# Pacchetti Hyprland -eco
printf "${NOTE} - Installazione di ${SKY_BLUE}altri pacchetti Hyprland-eco${RESET} .......\n"
for HYPR in "${hypr_eco[@]}"; do
  if ! command -v "$HYPR" >/dev/null 2>&1; then
    printf "$INFO - ${YELLOW}$HYPR${RESET} non trovato. Installazione di ${YELLOW}$HYPR...${RESET}\n"
    install_package "$HYPR" "$LOG"
  else
    printf "$NOTE - ${YELLOW} $HYPR è già installato.${RESET} Nessuna azione richiesta.\n"
  fi
done

printf "\n%.0s" {1..2}
