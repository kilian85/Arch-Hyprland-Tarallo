#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Aggiunta di utenti al gruppo input #

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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_input.log"

# Verifica se il gruppo 'input' esiste
if grep -q '^input:' /etc/group; then
    echo "${OK} Il gruppo ${MAGENTA}input${RESET} esiste."
else
    echo "${NOTE} Il gruppo ${MAGENTA}input${RESET} non esiste. Creazione del gruppo ${MAGENTA}input${RESET}..."
    sudo groupadd input
    echo "Gruppo ${MAGENTA}input${RESET} creato" >> "$LOG"
fi

# Aggiungi l'utente al gruppo 'input'
sudo usermod -aG input "$(whoami)"
echo "${OK} ${YELLOW}Utente${RESET} aggiunto al gruppo ${MAGENTA}input${RESET}. Le modifiche avranno effetto dopo il logout e il login." >> "$LOG"

printf "\n%.0s" {1..2}
