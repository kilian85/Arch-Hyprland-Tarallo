#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# zsh e oh my zsh #

zsh_pkg=(
  lsd
  mercurial
  zsh
  zsh-completions
)

zsh_pkg2=(
  fzf
)

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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_zsh.log"

# Installazione dei pacchetti core di zsh
printf "\n%s - Installazione dei ${SKY_BLUE}pacchetti zsh${RESET} .... \n" "${NOTE}"
for ZSH in "${zsh_pkg[@]}"; do
  install_package "$ZSH" "$LOG"
done 

# Controlla se la directory zsh-completions esiste
if [ -d "zsh-completions" ]; then
    rm -rf zsh-completions
fi

# Installa Oh My Zsh, i plugin e imposta zsh come shell predefinita
if command -v zsh >/dev/null; then
  printf "${NOTE} Installazione di ${SKY_BLUE}Oh My Zsh e dei plugin${RESET} ...\n"
  if [ ! -d "$HOME/.oh-my-zsh" ]; then  
    sh -c "$(curl -fsSL https://install.ohmyz.sh)" "" --unattended  	       
  else
    echo "${INFO} La directory .oh-my-zsh esiste già. Salto la re-installazione." 2>&1 | tee -a "$LOG"
  fi
  
  # Controlla se le directory esistono prima di clonare i repository
  if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
      git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 
  else
      echo "${INFO} La directory zsh-autosuggestions esiste già. Clonazione saltata." 2>&1 | tee -a "$LOG"
  fi

  if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
      git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 
  else
      echo "${INFO} La directory zsh-syntax-highlighting esiste già. Clonazione saltata." 2>&1 | tee -a "$LOG"
  fi
  
  # Controlla se ~/.zshrc e .zprofile esistono, crea un backup e copia la nuova configurazione
  if [ -f "$HOME/.zshrc" ]; then
      cp -b "$HOME/.zshrc" "$HOME/.zshrc-backup" || true
  fi

  if [ -f "$HOME/.zprofile" ]; then
      cp -b "$HOME/.zprofile" "$HOME/.zprofile-backup" || true
  fi
  
  # Copia dei temi zsh preconfigurati e del profilo
  cp -r 'assets/.zshrc' ~/
  cp -r 'assets/.zprofile' ~/

  # Controlla se la shell corrente è zsh
  current_shell=$(basename "$SHELL")
  if [ "$current_shell" != "zsh" ]; then
    printf "${NOTE} Cambio della shell predefinita in ${MAGENTA}zsh${RESET}..."
    printf "\n%.0s" {1..2}

    # Ciclo per assicurarsi che il comando chsh vada a buon fine
    while ! chsh -s "$(command -v zsh)"; do
      echo "${ERROR} Autenticazione fallita. Per favore inserisci la password corretta." 2>&1 | tee -a "$LOG"
      sleep 1
    done

    printf "${INFO} Shell cambiata con successo in ${MAGENTA}zsh${RESET}" 2>&1 | tee -a "$LOG"
  else
    echo "${NOTE} La tua shell è già impostata su ${MAGENTA}zsh${RESET}."
  fi
  
fi

# Installazione dei pacchetti core aggiuntivi
printf "\n%s - Installazione di ${SKY_BLUE}fzf${RESET} .... \n" "${NOTE}"
for ZSH2 in "${zsh_pkg2[@]}"; do
  install_package "$ZSH2" "$LOG"
done

# Copia i temi oh-my-zsh addizionali dagli assets
if [ -d "$HOME/.oh-my-zsh/themes" ]; then
    cp -r assets/add_zsh_theme/* ~/.oh-my-zsh/themes >> "$LOG" 2>&1
fi

printf "\n%.0s" {1..2}
