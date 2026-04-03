#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Lista nera Nvidia #

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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_nvidia.log"

printf "${INFO} ${SKY_BLUE}lista nera nouveau${RESET}...\n"
# Lista nera nouveau
NOUVEAU="/etc/modprobe.d/nouveau.conf"
if [ -f "$NOUVEAU" ]; then
  printf "${OK} Sembra che ${YELLOW}nouveau${RESET} sia già nella lista nera..procedendo.\n"
else
  echo "blacklist nouveau" | sudo tee -a "$NOUVEAU" 2>&1 | tee -a "$LOG"

  # Per mettere completamente nella lista nera nouveau (Vedi wiki.archlinux.org/title/Kernel_module#Blacklisting 6.1)
  if [ -f "/etc/modprobe.d/blacklist.conf" ]; then
    echo "install nouveau /bin/true" | sudo tee -a "/etc/modprobe.d/blacklist.conf" 2>&1 | tee -a "$LOG"
  else
    echo "install nouveau /bin/true" | sudo tee "/etc/modprobe.d/blacklist.conf" 2>&1 | tee -a "$LOG"
  fi
fi

printf "\n%.0s" {1..2}
