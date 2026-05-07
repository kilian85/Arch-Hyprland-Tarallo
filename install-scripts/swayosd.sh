#!/bin/bash
# SwayOSD system service setup #

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "Failed to change directory to $PARENT_DIR"; exit 1; }

if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

LOG="Install-Logs/install-$(date +%d-%H%M%S)_swayosd.log"

printf "${NOTE} Abilitazione servizio ${SKY_BLUE}SwayOSD${RESET} (libinput backend)...\n"

if sudo systemctl enable --now swayosd-libinput-backend.service >> "$LOG" 2>&1; then
  printf "${OK} Servizio ${SKY_BLUE}swayosd-libinput-backend${RESET} abilitato e avviato.\n"
else
  printf "${ERROR} Impossibile abilitare il servizio swayosd-libinput-backend. Controlla il log: $LOG\n"
fi

printf "\n%.0s" {1..1}
