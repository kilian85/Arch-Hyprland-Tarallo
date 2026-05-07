#!/bin/bash
# Browser selection #

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "Failed to change directory to $PARENT_DIR"; exit 1; }

if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

LOG="Install-Logs/install-$(date +%d-%H%M%S)_browser.log"

BROWSER=$(whiptail --title "Scelta Browser" --menu "Quale browser vuoi installare?" 16 60 8 \
  "brave-bin"       "Brave" \
  "chromium"        "Chromium" \
  "firefox"         "Firefox" \
  "librewolf-bin"   "LibreWolf" \
  "opera-gx"        "Opera GX" \
  "vivaldi"         "Vivaldi" \
  "zen-browser-bin" "Zen Browser" \
  "none"            "Nessun browser" \
  3>&1 1>&2 2>&3)

if [ -n "$BROWSER" ] && [ "$BROWSER" != "none" ]; then
  printf "${NOTE} Installazione browser: ${SKY_BLUE}$BROWSER${RESET}\n"
  install_package "$BROWSER" "$LOG"
  printf "${OK} Browser ${SKY_BLUE}$BROWSER${RESET} installato.\n"
else
  printf "${NOTE} Nessun browser selezionato.\n"
fi

printf "\n%.0s" {1..1}
