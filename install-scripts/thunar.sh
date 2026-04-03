#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Thunar #

thunar=(
  thunar 
  thunar-volman 
  tumbler
  ffmpegthumbnailer 
  thunar-archive-plugin
  xarchiver
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_thunar.log"

# Thunar
printf "${INFO} Installazione pacchetti ${SKY_BLUE}Thunar${RESET}...\n"  
  for THUNAR in "${thunar[@]}"; do
    install_package "$THUNAR" "$LOG"
  done

printf "\n%.0s" {1..1}

 # Controlla le configurazioni esistenti e le copia se non presenti
for DIR1 in gtk-3.0 Thunar xfce4; do
  DIRPATH=~/.config/$DIR1
  if [ -d "$DIRPATH" ]; then
    echo -e "${NOTE} Configurazione per ${MAGENTA}$DIR1${RESET} trovata, copia non necessaria." 2>&1 | tee -a "$LOG"
  else
    echo -e "${NOTE} Configurazione per ${YELLOW}$DIR1${RESET} non trovata, copia dai file asset in corso." 2>&1 | tee -a "$LOG"
    cp -r assets/$DIR1 ~/.config/ && echo "${OK} Copia di $DIR1 completata!" || echo "${ERROR} Errore durante la copia dei file di configurazione di $DIR1." 2>&1 | tee -a "$LOG"
  fi
done

printf "\n%.0s" {1..2}
