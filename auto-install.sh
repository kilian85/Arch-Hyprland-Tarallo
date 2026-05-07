#!/bin/bash

# Set some colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

# Variables
Distro="Arch-Hyprland"
Distro_DIR="$HOME/$Distro"
Github_URL="https://github.com/kilian85/Arch-Hyprland-Tarallo.git"

printf "\n%.0s" {1..1}

if ! command -v git &> /dev/null
then
    echo "${INFO} Git non trovato! ${SKY_BLUE}Installazione Git...${RESET}"
    if ! sudo pacman -S git --noconfirm; then
        echo "${ERROR} Installazione Git fallita. Uscita."
        exit 1
    fi
fi

printf "\n%.0s" {1..1}

if [ -d "$Distro_DIR" ]; then
    echo "${YELLOW}$Distro_DIR esiste. Aggiornamento repository... ${RESET}"
    cd "$Distro_DIR"
    git stash && git pull
    chmod +x install.sh
    ./install.sh
else
    echo "${MAGENTA}$Distro_DIR non esiste. Clonazione repository...${RESET}"
    git clone --depth=1 "$Github_URL" "$Distro_DIR"
    cd "$Distro_DIR"
    chmod +x install.sh
    ./install.sh
fi
