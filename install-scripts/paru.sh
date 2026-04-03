#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Helper AUR Paru #
# NOTA: Se yay è già installato, paru non verrà installato #

pkg="paru-bin"

## AVVERTIMENTO: NON MODIFICARE OLTRE QUESTA RIGA SE NON SAI COSA STAI FACENDO! ##
# Imposta il nome del file di log per includere la data e l'ora corrente
LOG="install-$(date +%d-%H%M%S)_yay.log"

# Imposta alcuni colori per i messaggi di output
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

# Crea directory per i log di installazione
if [ ! -d Install-Logs ]; then
    mkdir Install-Logs
fi

# Verifica l'helper AUR e installalo se non trovato
ISAUR=$(command -v yay || command -v paru)
if [ -n "$ISAUR" ]; then
  printf "\n%s - ${SKY_BLUE}Helper AUR${RESET} già installato, procedo.\n" "${OK}"
else
  printf "\n%s - Installazione di ${SKY_BLUE}$pkg${RESET} da AUR\n" "${NOTE}"

# Verifica se la directory esiste e rimuovila
if [ -d "$pkg" ]; then
    rm -rf "$pkg"
fi
  git clone https://aur.archlinux.org/$pkg.git || { printf "%s - Impossibile clonare ${YELLOW}$pkg${RESET} da AUR\n" "${ERROR}"; exit 1; }
  cd $pkg || { printf "%s - Impossibile entrare nella directory $pkg\n" "${ERROR}"; exit 1; }
  makepkg -si --noconfirm 2>&1 | tee -a "$LOG" || { printf "%s - Impossibile installare ${YELLOW}$pkg${RESET} da AUR\n" "${ERROR}"; exit 1; }

  # spostamento dei log di installazione nella directory Install-Logs
  mv install*.log ../Install-Logs/ || true   
  cd ..
fi

# Aggiorna il sistema prima di procedere
printf "\n%s - Esecuzione di un aggiornamento completo del sistema per evitare problemi.... \n" "${NOTE}"
ISAUR=$(command -v yay || command -v paru)

$ISAUR -Syu --noconfirm 2>&1 | tee -a "$LOG" || { printf "%s - Impossibile aggiornare il sistema\n" "${ERROR}"; exit 1; }

printf "\n%.0s" {1..2}
