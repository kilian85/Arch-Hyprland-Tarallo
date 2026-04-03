#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# quickshell - per panoramica desktop sostituendo AGS

if [[ $USE_PRESET = [Yy] ]]; then
  source ./preset.sh
fi

quick=(
    qt6-5compat
    quickshell
)

## AVVERTIMENTO: NON MODIFICARE OLTRE QUESTA RIGA SE NON SAI COSA STAI FACENDO! ##
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cambia la directory di lavoro nella directory padre dello script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || {
  echo "${ERROR} Impossibile cambiare directory in $PARENT_DIR"
  exit 1
}

# Sorgente lo script delle funzioni globali
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Impossibile sorgentare Global_functions.sh"
  exit 1
fi

# Imposta il nome del file di log per includere la data e l'ora corrente
LOG="Install-Logs/install-$(date +%d-%H%M%S)_quick.log"

# Installazione dei componenti principali
printf "\n%s - Installazione di ${SKY_BLUE}Quick Shell ${RESET} per Panoramica Desktop \n" "${NOTE}"

for PKG1 in "${quick[@]}"; do
  install_package "$PKG1" "$LOG"
done

printf "\n%.0s" {1..1}

