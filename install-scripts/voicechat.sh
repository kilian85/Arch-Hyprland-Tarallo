#!/bin/bash
# Voice chat packages selection #

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "Failed to change directory to $PARENT_DIR"; exit 1; }

if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

LOG="Install-Logs/install-$(date +%d-%H%M%S)_voicechat.log"

VOICECHAT=$(whiptail --title "Chat Vocale" --checklist "Seleziona i pacchetti per la chat vocale:\n(Spazio per selezionare, Invio per confermare)" 14 60 2 \
  "discord"    "Discord"     OFF \
  "teamspeak3" "TeamSpeak 3" OFF \
  3>&1 1>&2 2>&3)

if [ -n "$VOICECHAT" ]; then
  printf "${NOTE} Installazione ${SKY_BLUE}pacchetti chat vocale${RESET}\n"
  for PKG_VOICE in $VOICECHAT; do
    PKG_VOICE=$(echo "$PKG_VOICE" | tr -d '"')
    install_package "$PKG_VOICE" "$LOG"
  done
  printf "${OK} Pacchetti chat vocale installati.\n"
else
  printf "${NOTE} Nessun pacchetto chat vocale selezionato.\n"
fi

printf "\n%.0s" {1..1}
