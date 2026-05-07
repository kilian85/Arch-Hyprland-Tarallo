#!/bin/bash
# Gaming packages selection #

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "Failed to change directory to $PARENT_DIR"; exit 1; }

if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

LOG="Install-Logs/install-$(date +%d-%H%M%S)_gaming.log"

GAMING=$(whiptail --title "Pacchetti Gaming" --checklist "Seleziona i pacchetti gaming da installare:\n(Spazio per selezionare, Invio per confermare)" 18 75 6 \
  "bottles"                   "Bottles (gestore prefissi Wine)"  OFF \
  "heroic-games-launcher-bin" "Heroic Games Launcher (Epic/GOG)" OFF \
  "lutris"                    "Lutris (launcher giochi)"         OFF \
  "steam"                     "Steam"                            OFF \
  "wine-staging"              "Wine Staging"                     OFF \
  "winetricks"                "Winetricks"                       OFF \
  3>&1 1>&2 2>&3)

if [ -n "$GAMING" ]; then
  printf "${NOTE} Installazione ${SKY_BLUE}pacchetti gaming${RESET}\n"
  for PKG_GAME in $GAMING; do
    PKG_GAME=$(echo "$PKG_GAME" | tr -d '"')
    install_package "$PKG_GAME" "$LOG"
  done
  printf "${OK} Pacchetti gaming installati.\n"
else
  printf "${NOTE} Nessun pacchetto gaming selezionato.\n"
fi

printf "\n%.0s" {1..1}
