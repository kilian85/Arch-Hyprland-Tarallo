#!/bin/bash
# pokemon-color-scripts#

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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_zsh_pokemon.log"

printf "${NOTE} Rimozione tracce di ${SKY_BLUE}Pokemon Color Scripts${RESET}\n"

# Install Pokemon Color Scripts
printf "${NOTE} Installazione ${SKY_BLUE}Pokemon Color Scripts${RESET}\n"
for pok in "pokemon-colorscripts-git"; do
  install_package_f "$pok" "$LOG"
done

printf "\n%.0s" {1..1}

# Chiedi quale config fastfetch usare
if whiptail --title "Fastfetch Config" --yesno "Vuoi usare il fastfetch con Pokemon?\n\nScegli NO per mantenere il fastfetch con Tarallo." 10 60; then
    USE_POKEMON=true
else
    USE_POKEMON=false
fi

# Check if ~/.zshrc exists
if [ -f "$HOME/.zshrc" ]; then
    if [ "$USE_POKEMON" = true ]; then
        # Attiva pokemon e commenta la riga fastfetch esistente
        sed -i 's|^#pokemon-colorscripts --no-title -s -r \| fastfetch -c \$HOME/.config/fastfetch/config-pokemon.jsonc --logo-type file-raw --logo-height 10 --logo-width 5 --logo -|pokemon-colorscripts --no-title -s -r \| fastfetch -c \$HOME/.config/fastfetch/config-pokemon.jsonc --logo-type file-raw --logo-height 10 --logo-width 5 --logo -|' "$HOME/.zshrc" >> "$LOG" 2>&1
        sed -i "s|^fastfetch -c .*\.jsonc|#fastfetch -c $HOME/.config/fastfetch/config.jsonc|" "$HOME/.zshrc" >> "$LOG" 2>&1
        echo "${OK} Fastfetch Pokemon attivato." | tee -a "$LOG"
    else
        # Mantieni config personalizzato, assicurati che la riga pokemon sia commentata
        sed -i 's|^pokemon-colorscripts|#pokemon-colorscripts|' "$HOME/.zshrc" >> "$LOG" 2>&1
        echo "${OK} Config fastfetch personalizzato mantenuto." | tee -a "$LOG"
    fi
else
    echo "$HOME/.zshrc non trovato. Impossibile configurare ${YELLOW}fastfetch${RESET}" >> "$LOG" 2>&1
fi
  
printf "\n%.0s" {1..2}
