#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Controllo finale se i pacchetti sono installati
# NOTA: Questi controlli dei pacchetti sono solo per gli essenziali

packages=(
  cliphist
  kvantum
  rofi-wayland
  imagemagick
  swaync
  swww
  wallust
  waybar
  wl-clipboard
  wlogout
  kitty
  hypridle
  hyprlock
  hyprland
)

# Pacchetti locali che dovrebbero essere in /usr/local/bin/
local_pkgs_installed=(

)

## AVVERTIMENTO: NON MODIFICARE OLTRE QUESTA RIGA SE NON SAI COSA STAI FACENDO! ##
# Determina la directory dove si trova lo script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Cambia la directory di lavoro nella directory padre dello script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Impossibile cambiare directory in $PARENT_DIR"; exit 1; }

# Sorgente lo script delle funzioni globali
source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"

# Imposta il nome del file di log per includere la data e l'ora corrente
LOG="Install-Logs/00_CHECK-$(date +%d-%H%M%S)_installed.log"

printf "\n%s - Controllo finale se tutti i ${SKY_BLUE}pacchetti essenziali${RESET} sono stati installati \n" "${NOTE}"
# Inizializza un array vuoto per contenere i pacchetti mancanti
missing=()
local_missing=()

# Funzione per controllare se i pacchetti sono installati usando pacman
is_installed_pacman() {
    pacman -Qi "$1" &>/dev/null
}

# Cicla attraverso ogni pacchetto
for pkg in "${packages[@]}"; do
    # Controlla se i pacchetti sono installati
    if ! is_installed_pacman "$pkg"; then
        missing+=("$pkg")
    fi
done

# Controlla i pacchetti locali
for pkg1 in "${local_pkgs_installed[@]}"; do
    if ! [ -f "/usr/local/bin/$pkg1" ]; then
        local_missing+=("$pkg1")
    fi
done

# Registra i pacchetti mancanti
if [ ${#missing[@]} -eq 0 ] && [ ${#local_missing[@]} -eq 0 ]; then
    echo "${OK} OTTIMO! Tutti i ${YELLOW}pacchetti essenziali${RESET} sono stati installati con successo." | tee -a "$LOG"
else
    if [ ${#missing[@]} -ne 0 ]; then
        echo "${WARN} I seguenti pacchetti non sono installati e verranno registrati:"
        for pkg in "${missing[@]}"; do
            echo "${WARNING}$pkg${RESET}"
            echo "$pkg" >> "$LOG" 
        done
    fi

    if [ ${#local_missing[@]} -ne 0 ]; then
        echo "${WARN} I seguenti pacchetti locali mancano da /usr/local/bin/ e verranno registrati:"
        for pkg1 in "${local_missing[@]}"; do
            echo "${WARNING}$pkg1${REST} non è installato. Non riesco a trovarlo in /usr/local/bin/"
            echo "$pkg1" >> "$LOG" 
        done
    fi

    echo "${NOTE} Pacchetti mancanti registrati il $(date)" >> "$LOG"
fi

