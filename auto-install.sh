#!/bin/bash
# https://github.com/JaKooLit

# Imposta i colori per i messaggi di output
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERRORE]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTA]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[AVVISO]$(tput sgr0)"
CAT="$(tput setaf 6)[AZIONE]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

# Variabili
Distro="Arch-Hyprland"
Github_URL="https://github.com/JaKooLit/$Distro.git"
Distro_DIR="$HOME/$Distro"

printf "\n%.0s" {1..1}

# Verifica se git è installato
if ! command -v git &> /dev/null
then
    echo "${INFO} Git non trovato! ${SKY_BLUE}Installazione di Git in corso...${RESET}"
    if ! sudo pacman -S git --noconfirm; then
        echo "${ERROR} Installazione di Git fallita. Uscita in corso."
        exit 1
    fi
fi

printf "\n%.0s" {1..1}

# Verifica se la directory esiste già per aggiornarla o clonarla
if [ -d "$Distro_DIR" ]; then
    echo "${YELLOW}La directory $Distro_DIR esiste. Aggiornamento del repository... ${RESET}"
    cd "$Distro_DIR"
    git stash && git pull
    chmod +x install.sh
    ./install.sh
else
    echo "${MAGENTA}La directory $Distro_DIR non esiste. Clonazione del repository...${RESET}"
    git clone --depth=1 "$Github_URL" "$Distro_DIR"
    cd "$Distro_DIR"
    chmod +x install.sh
    ./install.sh
fi
