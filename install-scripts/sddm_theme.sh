#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Temi SDDM #

source_theme="https://github.com/JaKooLit/simple-sddm-2.git"
theme_name="simple_sddm_2"

## ATTENZIONE: NON MODIFICARE OLTRE QUESTA LINEA SE NON SAI COSA STAI FACENDO! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Cambia la directory di lavoro alla cartella superiore dello script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Impossibile cambiare directory in $PARENT_DIR"; exit 1; }

# Carica il file delle funzioni globali
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Impossibile caricare Global_functions.sh"
  exit 1
fi


# Imposta il nome del file di log includendo data e ora corrente
LOG="Install-Logs/install-$(date +%d-%H%M%S)_sddm_theme.log"
    
# Temi SDDM
printf "${INFO} Installazione ${SKY_BLUE}Tema SDDM Addizionale${RESET}\n"

# Controlla se /usr/share/sddm/themes/$theme_name esiste e lo rimuove se presente
if [ -d "/usr/share/sddm/themes/$theme_name" ]; then
  sudo rm -rf "/usr/share/sddm/themes/$theme_name"
  echo -e "\e[1A\e[K${OK} - Rimossa la directory esistente $theme_name." 2>&1 | tee -a "$LOG"
fi

# Controlla se la directory $theme_name esiste nella cartella corrente e la rimuove
if [ -d "$theme_name" ]; then
  rm -rf "$theme_name"
  echo -e "\e[1A\e[K${OK} - Rimossa la directory esistente $theme_name dalla posizione corrente." 2>&1 | tee -a "$LOG"
fi

# Clona il repository
if git clone --depth=1 "$source_theme" "$theme_name"; then
  if [ ! -d "$theme_name" ]; then
    echo "${ERROR} Errore durante la clonazione del repository." | tee -a "$LOG"
  fi

  # Crea la directory dei temi se non esiste
  if [ ! -d "/usr/share/sddm/themes" ]; then
    sudo mkdir -p /usr/share/sddm/themes
    echo "${OK} - Directory '/usr/share/sddm/themes' creata." | tee -a "$LOG"
  fi

  # Sposta il tema clonato nella directory dei temi di sistema
  sudo mv "$theme_name" "/usr/share/sddm/themes/$theme_name" 2>&1 | tee -a "$LOG"

  # Configurazione del tema SDDM
  sddm_conf="/etc/sddm.conf"
  BACKUP_SUFFIX=".bak"

  echo -e "${NOTE} Configurazione della schermata di accesso (login)." | tee -a "$LOG"

  # Esegue il backup del file sddm.conf se esiste
  if [ -f "$sddm_conf" ]; then
    echo "Esecuzione backup di $sddm_conf" | tee -a "$LOG"
    sudo cp "$sddm_conf" "$sddm_conf$BACKUP_SUFFIX" 2>&1 | tee -a "$LOG"
  else
    echo "$sddm_conf non esiste, creazione di un nuovo file." | tee -a "$LOG"
    sudo touch "$sddm_conf" 2>&1 | tee -a "$LOG"
  fi

  # Controlla se esiste la sezione [Theme]
  if grep -q '^\[Theme\]' "$sddm_conf"; then
    # Aggiorna la riga Current= sotto la sezione [Theme]
    sudo sed -i "/^\[Theme\]/,/^\[/{s/^\s*Current=.*/Current=$theme_name/}" "$sddm_conf" 2>&1 | tee -a "$LOG"
    
    # Se la riga Current= non è stata trovata, la aggiunge dopo [Theme]
    if ! grep -q '^\s*Current=' "$sddm_conf"; then
      sudo sed -i "/^\[Theme\]/a Current=$theme_name" "$sddm_conf" 2>&1 | tee -a "$LOG"
      echo "Aggiunto Current=$theme_name sotto [Theme] in $sddm_conf" | tee -a "$LOG"
    else
      echo "Aggiornato Current=$theme_name in $sddm_conf" | tee -a "$LOG"
    fi
  else
    # Aggiunge la sezione [Theme] alla fine se non esiste
    echo -e "\n[Theme]\nCurrent=$theme_name" | sudo tee -a "$sddm_conf" > /dev/null
    echo "Aggiunta sezione [Theme] con Current=$theme_name in $sddm_conf" | tee -a "$LOG"
  fi

  # Aggiunge la sezione [General] con tastiera virtuale se non esiste
  if ! grep -q '^\[General\]' "$sddm_conf"; then
    echo -e "\n[General]\nInputMethod=qtvirtualkeyboard" | sudo tee -a "$sddm_conf" > /dev/null
    echo "Aggiunta sezione [General] con InputMethod=qtvirtualkeyboard in $sddm_conf" | tee -a "$LOG"
  else
    # Aggiorna InputMethod se la sezione esiste già
    if grep -q '^\s*InputMethod=' "$sddm_conf"; then
      sudo sed -i '/^\[General\]/,/^\[/{s/^\s*InputMethod=.*/InputMethod=qtvirtualkeyboard/}' "$sddm_conf" 2>&1 | tee -a "$LOG"
      echo "Aggiornato InputMethod a qtvirtualkeyboard in $sddm_conf" | tee -a "$LOG"
    else
      sudo sed -i '/^\[General\]/a InputMethod=qtvirtualkeyboard' "$sddm_conf" 2>&1 | tee -a "$LOG"
      echo "Aggiunto InputMethod=qtvirtualkeyboard sotto [General] in $sddm_conf" | tee -a "$LOG"
    fi
  fi

  # Sostituisce lo sfondo attuale con quello degli asset
  sudo cp -r assets/sddm.png "/usr/share/sddm/themes/$theme_name/Backgrounds/default" 2>&1 | tee -a "$LOG"
  sudo sed -i 's|^wallpaper=".*"|wallpaper="Backgrounds/default"|' "/usr/share/sddm/themes/$theme_name/theme.conf" 2>&1 | tee -a "$LOG"

  echo "${OK} - ${MAGENTA}Additional ${YELLOW}$theme_name SDDM Theme${RESET} successfully installed." | tee -a "$LOG"

else

  echo "${ERROR} - Fallito la clonazione di sddm theme repository. Perfavore controlla la tua connessione internet." | tee -a "$LOG" >&2
fi

printf "\n%.0s" {1..2}
