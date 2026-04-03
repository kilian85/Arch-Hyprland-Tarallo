#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Temi GTK e ICONE e Sourcing da un Repo diverso #

engine=(
    unzip
    gtk-engine-murrine
)

## AVVERTIMENTO: NON MODIFICARE OLTRE QUESTA RIGA SE NON SAI COSA STAI FACENDO! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Cambia la directory di lavoro nella directory padre dello script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Impossibile cambiare directory in $PARENT_DIR"; exit 1; }

# Sorgente lo script delle funzioni globali
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Impossibile sorgentare Global_functions.sh"
  exit 1
fi


# Imposta il nome del file di log per includere la data e l'ora corrente
LOG="Install-Logs/install-$(date +%d-%H%M%S)_themes.log"


# installazione del motore necessario per i temi gtk
for PKG1 in "${engine[@]}"; do
    install_package "$PKG1" "$LOG"
done

# Verifica se la directory esiste e cancellala se presente
if [ -d "GTK-themes-icons" ]; then
    echo "$NOTE La directory dei temi GTK e delle icone esiste..eliminazione..." 2>&1 | tee -a "$LOG"
    rm -rf "GTK-themes-icons" 2>&1 | tee -a "$LOG"
fi

echo "$NOTE Clonazione del repository ${SKY_BLUE}temi GTK e icone${RESET}..." 2>&1 | tee -a "$LOG"
if git clone --depth=1 https://github.com/JaKooLit/GTK-themes-icons.git ; then
    cd GTK-themes-icons
    chmod +x auto-extract.sh
    ./auto-extract.sh
    cd ..
    echo "$OK Estratti temi GTK e icone nelle directory ~/.icons e ~/.themes" 2>&1 | tee -a "$LOG"
else
    echo "$ERROR Download fallito per temi GTK e icone.." 2>&1 | tee -a "$LOG"
fi

printf "\n%.0s" {1..2}
