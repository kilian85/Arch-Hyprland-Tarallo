#!/bin/bash

# Colori e icone (presi dallo script principale)
OK="$(tput setaf 2)[OK]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"

echo "${NOTE} Installazione di Linux Wallpaper Engine GUI..."

# Tenta l'installazione usando l'helper AUR disponibile
if command -v yay &>/dev/null; then
    yay -S --noconfirm linux-wallpaperengine-gui-git
else
    echo "${ERROR} Nessun helper AUR (yay/paru) trovato!"
    exit 1
fi

if [ $? -eq 0 ]; then
    echo "${OK} Wallpaper Engine installato con successo."
else
    echo "${ERROR} Errore durante l'installazione di Wallpaper Engine."
    exit 1
fi
