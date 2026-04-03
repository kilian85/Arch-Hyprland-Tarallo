#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Funzioni Globali per gli Script #

set -e

# Imposta alcuni colori per i messaggi di output
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[AZIONE]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

# Crea Directory per i Log di Installazione
if [ ! -d Install-Logs ]; then
    mkdir Install-Logs
fi

# Funzione per mostrare il progresso
show_progress() {
    local pid=$1
    local package_name=$2
    local spin_chars=("●○○○○○○○○○" "○●○○○○○○○○" "○○●○○○○○○○" "○○○●○○○○○○" "○○○○●○○○○" \
                      "○○○○○●○○○○" "○○○○○○●○○○" "○○○○○○○●○○" "○○○○○○○○●○" "○○○○○○○○○●") 
    local i=0

    tput civis 
    printf "\r${NOTE} Installazione di ${YELLOW}%s${RESET} ..." "$package_name"

    while ps -p $pid &> /dev/null; do
        printf "\r${NOTE} Installazione di ${YELLOW}%s${RESET} %s" "$package_name" "${spin_chars[i]}"
        i=$(( (i + 1) % 10 ))  
        sleep 0.3  
    done

    printf "\r${NOTE} Installazione di ${YELLOW}%s${RESET} ... Fatto!%-20s \n" "$package_name" ""
    tput cnorm  
}



# Funzione per installare pacchetti con pacman
install_package_pacman() {
  # Controlla se il pacchetto è già installato
  if pacman -Q "$1" &>/dev/null ; then
    echo -e "${INFO} ${MAGENTA}$1${RESET} è già installato. Saltando..."
  else
    # Esegui pacman e reindirizza tutto l'output a un file di log
    (
      stdbuf -oL sudo pacman -S --noconfirm "$1" 2>&1
    ) >> "$LOG" 2>&1 &
    PID=$!
    show_progress $PID "$1" 

    # Controlla nuovamente se il pacchetto è installato
    if pacman -Q "$1" &>/dev/null ; then
      echo -e "${OK} Il pacchetto ${YELLOW}$1${RESET} è stato installato con successo!"
    else
      echo -e "\n${ERROR} ${YELLOW}$1${RESET} installazione fallita. Controlla il $LOG. Potrebbe essere necessario installarlo manualmente."
    fi
  fi
}

ISAUR=$(command -v yay || command -v paru)
# Funzione per installare pacchetti con yay o paru
install_package() {
  if $ISAUR -Q "$1" &>> /dev/null ; then
    echo -e "${INFO} ${MAGENTA}$1${RESET} è già installato. Saltando..."
  else
    (
      stdbuf -oL $ISAUR -S --noconfirm "$1" 2>&1
    ) >> "$LOG" 2>&1 &
    PID=$!
    show_progress $PID "$1"  
    
    # Controlla nuovamente se il pacchetto è installato
    if $ISAUR -Q "$1" &>> /dev/null ; then
      echo -e "${OK} Il pacchetto ${YELLOW}$1${RESET} è stato installato con successo!"
    else
      # Qualcosa manca, esci per rivedere il log
      echo -e "\n${ERROR} ${YELLOW}$1${RESET} installazione fallita :( , controlla il install.log. Potrebbe essere necessario installarlo manualmente! Mi dispiace, ho provato :("
    fi
  fi
}

# Funzione per installare pacchetti con yay o paru senza controllare se installati
install_package_f() {
  (
    stdbuf -oL $ISAUR -S --noconfirm "$1" 2>&1
  ) >> "$LOG" 2>&1 &
  PID=$!
  show_progress $PID "$1"  

  # Controlla nuovamente se il pacchetto è installato
  if $ISAUR -Q "$1" &>> /dev/null ; then
    echo -e "${OK} Il pacchetto ${YELLOW}$1${RESET} è stato installato con successo!"
  else
    # Qualcosa manca, esci per rivedere il log
    echo -e "\n${ERROR} ${YELLOW}$1${RESET} installazione fallita :( , controlla il install.log. Potrebbe essere necessario installarlo manualmente! Mi dispiace, ho provato :("
  fi
}


# Funzione per rimuovere pacchetti
uninstall_package() {
  local pkg="$1"

  # Controllo se il pacchetto è installato
  if pacman -Qi "$pkg" &>/dev/null; then
    echo -e "${NOTE} rimozione di $pkg ..."
    sudo pacman -R --noconfirm "$pkg" 2>&1 | tee -a "$LOG" | grep -v "error: target not found"
    
    if ! pacman -Qi "$pkg" &>/dev/null; then
      echo -e "\e[1A\e[K${OK} $pkg rimosso."
    else
      echo -e "\e[1A\e[K${ERROR} Rimozione di $pkg fallita. Nessuna azione richiesta."
      return 1
    fi
  else
    echo -e "${INFO} Pacchetto $pkg non installato, saltando."
  fi
  return 0
}
