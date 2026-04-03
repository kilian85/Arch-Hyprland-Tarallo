#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# pacman aggiungendo spezie extra #

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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_pacman.log"

echo -e "${NOTE} Aggiunta di ${MAGENTA}Spezie Extra${RESET} in pacman.conf ... ${RESET}" 2>&1 | tee -a "$LOG"
pacman_conf="/etc/pacman.conf"

# Rimuovi commenti '#' da linee specifiche
lines_to_edit=(
    "Color"
    "CheckSpace"
    "VerbosePkgLists"
    "ParallelDownloads"
)

# Decommenta le linee specificate se sono commentate
for line in "${lines_to_edit[@]}"; do
    if grep -q "^#$line" "$pacman_conf"; then
        sudo sed -i "s/^#$line/$line/" "$pacman_conf"
        echo -e "${CAT} Decommentato: $line ${RESET}" 2>&1 | tee -a "$LOG"
    else
        echo -e "${CAT} $line è già decommentato. ${RESET}" 2>&1 | tee -a "$LOG"
    fi
done

# Aggiungi "ILoveCandy" sotto ParallelDownloads se non esiste
if grep -q "^ParallelDownloads" "$pacman_conf" && ! grep -q "^ILoveCandy" "$pacman_conf"; then
    sudo sed -i "/^ParallelDownloads/a ILoveCandy" "$pacman_conf"
    echo -e "${CAT} Aggiunto ${MAGENTA}ILoveCandy${RESET} dopo ${MAGENTA}ParallelDownloads${RESET}. ${RESET}" 2>&1 | tee -a "$LOG"
else
    echo -e "${CAT} Sembra che ${YELLOW}ILoveCandy${RESET} esista già ${RESET} procedendo.." 2>&1 | tee -a "$LOG"
fi

echo -e "${CAT} ${MAGENTA}Pacman.conf${RESET} condimento completato ${RESET}" 2>&1 | tee -a "$LOG"


# aggiornamento di pacman.conf
printf "\n%s - ${SKY_BLUE}Sincronizzazione Repository Pacman${RESET}\n" "${INFO}"
sudo pacman -Sy

printf "\n%.0s" {1..2}
