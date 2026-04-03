#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# pokemon-color-scripts #

## ATTENZIONE: NON MODIFICARE OLTRE QUESTA LINEA SE NON SAI COSA STAI FACENDO! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Cambia la directory di lavoro nella directory padre dello script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Impossibile cambiare directory in $PARENT_DIR"; exit 1; }

# Carica lo script delle funzioni globali
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Impossibile caricare Global_functions.sh"
  exit 1
fi

# Imposta il nome del file di log includendo la data e l'ora corrente
LOG="Install-Logs/install-$(date +%d-%H%M%S)_zsh_pokemon.log"

printf "${NOTE} Rimozione di eventuali tracce di ${SKY_BLUE}Pokemon Color Scripts${RESET}\n"

# Installazione di Pokemon Color Scripts
printf "${NOTE} Installazione di ${SKY_BLUE}Pokemon Color Scripts${RESET}\n"
for pok in "pokemon-colorscripts-git"; do
  install_package_f "$pok" "$LOG"
done

printf "\n%.0s" {1..1}

# Controlla se il file ~/.zshrc esiste
if [ -f "$HOME/.zshrc" ]; then
    # Abilita il comando pokemon-colorscripts nel file .zshrc
	sed -i 's|^#pokemon-colorscripts --no-title -s -r \| fastfetch -c \$HOME/.config/fastfetch/config-pokemon.jsonc --logo-type file-raw --logo-height 10 --logo-width 5 --logo -|pokemon-colorscripts --no-title -s -r \| fastfetch -c \$HOME/.config/fastfetch/config-pokemon.jsonc --logo-type file-raw --logo-height 10 --logo-width 5 --logo -|' "$HOME/.zshrc" >> "$LOG" 2>&1
    # Disabilita la configurazione compatta di fastfetch
	sed -i "s|^fastfetch -c \$HOME/.config/fastfetch/config-compact.jsonc|#fastfetch -c \$HOME/.config/fastfetch/config-compact.jsonc|" "$HOME/.zshrc" >> "$LOG" 2>&1
else
    echo "$HOME/.zshrc non trovato. Impossibile abilitare ${YELLOW}Pokemon color scripts${RESET}" >> "$LOG" 2>&1
fi
  
printf "\n%.0s" {1..2}
