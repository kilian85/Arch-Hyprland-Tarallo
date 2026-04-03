#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Hyprland-Dots da scaricare dal main #


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

# Verifica se Hyprland-Dots esiste
printf "${NOTE} Clonazione e installazione di ${SKY_BLUE}KooL's Hyprland Dots${RESET}....\n"

if [ -d Hyprland-Dots ]; then
  cd Hyprland-Dots
  git stash && git pull
  chmod +x copy.sh
  ./copy.sh 
else
  if git clone --depth=1 https://github.com/JaKooLit/Hyprland-Dots; then
    cd Hyprland-Dots || exit 1
    chmod +x copy.sh
    ./copy.sh 
  else
    echo -e "$ERROR Impossibile scaricare ${YELLOW}KooL's Hyprland-Dots${RESET} . Verifica la tua connessione internet"
  fi
fi

printf "\n%.0s" {1..2}
