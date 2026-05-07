#!/bin/bash
# 💫 https://github.com/kilian85 💫 #
# ThinkPad T470 packages              #

thinkpad=(
    tlp
    tlp-rdw
    thinkfan
    acpi_call-dkms
    throttled
)

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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_thinkpad.log"

### Install software for ThinkPad T470 ###

printf " Installazione ${SKY_BLUE}pacchetti ThinkPad T470${RESET}...\n"
for PKG in "${thinkpad[@]}"; do
    install_package "$PKG" "$LOG"
done

printf " Abilitazione servizi ThinkPad...\n"
sudo systemctl enable tlp.service 2>&1 | tee -a "$LOG"
sudo systemctl enable thinkfan.service 2>&1 | tee -a "$LOG"

printf "\n%.0s" {1..2}
