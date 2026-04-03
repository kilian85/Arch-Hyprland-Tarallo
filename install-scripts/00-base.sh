#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# base-devel + archlinux-keyring #

base=( 
  base-devel
  archlinux-keyring
  findutils
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_base.log"

# Installazione dei componenti principali con pacman
echo -e "\nInstallazione di ${SKY_BLUE}base-devel${RESET} e ${SKY_BLUE}archlinux-keyring${RESET}..."

for PKG1 in "${base[@]}"; do
  echo "Installazione di $PKG1 con pacman..."
  install_package_pacman "$PKG1" "$LOG"
done

printf "\n%.0s" {1..1}
