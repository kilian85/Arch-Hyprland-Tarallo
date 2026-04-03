#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Font #

# Questi font sono il minimo richiesto per far funzionare i dot preconfigurati. Puoi aggiungere qui come richiesto
# AVVERTIMENTO! Se rimuovi pacchetti qui, i dotfiles potrebbero non funzionare correttamente.
# e anche, assicurati che i pacchetti siano presenti in AUR e nel repo ufficiale di Arch

fonts=(
  adobe-source-code-pro-fonts 
  noto-fonts-emoji
  otf-font-awesome 
  ttf-droid 
  ttf-fira-code
  ttf-fantasque-nerd
  ttf-jetbrains-mono 
  ttf-jetbrains-mono-nerd
  ttf-victor-mono
  noto-fonts
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_fonts.log"


# Installazione dei componenti principali
printf "\n%s - Installazione dei ${SKY_BLUE}font${RESET} necessari.... \n" "${NOTE}"

for PKG1 in "${fonts[@]}"; do
  install_package "$PKG1" "$LOG"
done

printf "\n%.0s" {1..2}
