#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Gestore di accesso SDDM #

sddm=(
  qt6-declarative
  qt6-svg
  qt6-virtualkeyboard
  qt6-multimedia-ffmpeg
  qt5-quickcontrols2
  sddm
)

# gestori di accesso da disabilitare
login=(
  lightdm
  gdm3
  gdm
  lxdm
  lxdm-gtk3
)

## AVVERTIMENTO: NON MODIFICARE OLTRE QUESTA RIGA SE NON SAI COSA STAI FACENDO! ##
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cambia la directory di lavoro nella directory padre dello script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || {
  echo "${ERROR} Impossibile cambiare directory in $PARENT_DIR"
  exit 1
}

# Sorgente lo script delle funzioni globali
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Impossibile sorgentare Global_functions.sh"
  exit 1
fi

# Imposta il nome del file di log per includere la data e l'ora corrente
LOG="Install-Logs/install-$(date +%d-%H%M%S)_sddm.log"

# Installa SDDM e il tema SDDM
printf "${NOTE} Installazione di sddm e dipendenze........\n"
for package in "${sddm[@]}"; do
  install_package "$package" "$LOG"
done

printf "\n%.0s" {1..1}

# Verifica se altri gestori di accesso sono installati e disabilita il loro servizio prima di abilitare sddm
for login_manager in "${login[@]}"; do
  if pacman -Qs "$login_manager" >/dev/null 2>&1; then
    sudo systemctl disable "$login_manager.service" >>"$LOG" 2>&1
    echo "$login_manager disabilitato." >>"$LOG" 2>&1
  fi
done

# Verifica doppia con systemctl
for manager in "${login[@]}"; do
  if systemctl is-active --quiet "$manager" >/dev/null 2>&1; then
    echo "$manager è attivo, lo disabilito..." >>"$LOG" 2>&1
    sudo systemctl disable "$manager" --now >>"$LOG" 2>&1
  fi
done

printf "\n%.0s" {1..1}
printf "${INFO} Attivazione del servizio sddm........\n"
sudo systemctl enable sddm

wayland_sessions_dir=/usr/share/wayland-sessions
[ ! -d "$wayland_sessions_dir" ] && {
  printf "$CAT - $wayland_sessions_dir non trovato, creazione...\n"
  sudo mkdir "$wayland_sessions_dir" 2>&1 | tee -a "$LOG"
}

printf "\n%.0s" {1..2}

