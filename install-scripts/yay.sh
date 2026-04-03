#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# AUR Helper Yay #
# NOTA: Se paru è già installato, yay non verrà installato #

pkg="yay-bin"

## ATTENZIONE: NON MODIFICARE OLTRE QUESTA LINEA SE NON SAI COSA STAI FACENDO! ##
# Imposta il nome del file di log includendo data e ora corrente
LOG="install-$(date +%d-%H%M%S)_yay.log"

# Impostazione dei colori per i messaggi di output
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

# Crea la directory per i Log di Installazione
if [ ! -d Install-Logs ]; then
    mkdir Install-Logs
fi

# Controlla la presenza di un AUR helper e lo installa se non trovato
ISAUR=$(command -v yay || command -v paru)
if [ -n "$ISAUR" ]; then
  printf "\n%s - ${SKY_BLUE}AUR helper${RESET} già installato, procedo oltre.\n" "${OK}"
else
  printf "\n%s - Installazione di ${SKY_BLUE}$pkg${RESET} da AUR\n" "${NOTE}"

# Controlla se la directory esiste e la rimuove
if [ -d "$pkg" ]; then
    rm -rf "$pkg"
fi
  git clone https://aur.archlinux.org/$pkg.git || { printf "%s - Errore durante la clonazione di ${YELLOW}$pkg${RESET} da AUR\n" "${ERROR}"; exit 1; }
  cd $pkg || { printf "%s - Impossibile entrare nella directory $pkg\n" "${ERROR}"; exit 1; }
  makepkg -si --noconfirm 2>&1 | tee -a "$LOG" || { printf "%s - Errore durante l'installazione di ${YELLOW}$pkg${RESET} da AUR\n" "${ERROR}"; exit 1; }

  # Sposta i log di installazione nella directory Install-Logs
  mv install*.log ../Install-Logs/ || true   
  cd ..
fi

# Aggiorna il sistema prima di procedere
printf "\n%s - Esecuzione di un aggiornamento completo del sistema per evitare problemi.... \n" "${NOTE}"
ISAUR=$(command -v yay || command -v paru)

$ISAUR -Syu --noconfirm 2>&1 | tee -a "$LOG" || { printf "%s -
