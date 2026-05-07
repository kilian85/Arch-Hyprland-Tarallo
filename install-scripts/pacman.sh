#!/bin/bash
# pacman adding up extra-spices #

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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_pacman.log"

echo -e "${NOTE} Aggiunta ${MAGENTA}opzioni extra${RESET} in pacman.conf ... ${RESET}" 2>&1 | tee -a "$LOG"
pacman_conf="/etc/pacman.conf"

# Remove comments '#' from specific lines
lines_to_edit=(
    "Color"
    "CheckSpace"
    "VerbosePkgLists"
    "ParallelDownloads"
)

# Uncomment specified lines if they are commented out
for line in "${lines_to_edit[@]}"; do
    if grep -q "^#$line" "$pacman_conf"; then
        sudo sed -i "s/^#$line/$line/" "$pacman_conf"
        echo -e "${CAT} Decommentato: $line ${RESET}" 2>&1 | tee -a "$LOG"
    else
        echo -e "${CAT} $line è già decommentato. ${RESET}" 2>&1 | tee -a "$LOG"
    fi
done

# Add "ILoveCandy" below ParallelDownloads if it doesn't exist
if grep -q "^ParallelDownloads" "$pacman_conf" && ! grep -q "^ILoveCandy" "$pacman_conf"; then
    sudo sed -i "/^ParallelDownloads/a ILoveCandy" "$pacman_conf"
    echo -e "${CAT} Aggiunto ${MAGENTA}ILoveCandy${RESET} dopo ${MAGENTA}ParallelDownloads${RESET}. ${RESET}" 2>&1 | tee -a "$LOG"
else
    echo -e "${CAT} ${YELLOW}ILoveCandy${RESET} è già presente, continuo.. ${RESET}" 2>&1 | tee -a "$LOG"
fi

echo -e "${CAT} ${MAGENTA}Pacman.conf${RESET} configurato con successo ${RESET}" 2>&1 | tee -a "$LOG"


# updating pacman.conf
printf "\n%s - ${SKY_BLUE}Sincronizzazione repository Pacman${RESET}\n" "${INFO}"
sudo pacman -Sy

printf "\n%.0s" {1..2}
