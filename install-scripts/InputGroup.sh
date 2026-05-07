#!/bin/bash
# Adding users into input group #

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Failed to change directory to $PARENT_DIR"; exit 1; }

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi



# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_input.log"

# Check if the 'input' group exists
if grep -q '^input:' /etc/group; then
    echo "${OK} Il gruppo ${MAGENTA}input${RESET} esiste."
else
    echo "${NOTE} Il gruppo ${MAGENTA}input${RESET} non esiste. Creazione gruppo ${MAGENTA}input${RESET}..."
    sudo groupadd input
    echo "${MAGENTA}input${RESET} group created" >> "$LOG"
fi

# Add the user to the 'input' group
sudo usermod -aG input "$(whoami)"
echo "${OK} Utente ${YELLOW}$(whoami)${RESET} aggiunto al gruppo ${MAGENTA}input${RESET}. Le modifiche avranno effetto dopo il prossimo accesso." >> "$LOG"

printf "\n%.0s" {1..2}
