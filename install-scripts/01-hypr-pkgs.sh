#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Pacchetti Hyprland #

# modifica i pacchetti desiderati qui.
# AVVERTIMENTO! Se rimuovi pacchetti qui, i dotfiles potrebbero non funzionare correttamente.
# e assicurati anche che i pacchetti siano presenti in AUR e nel repository ufficiale di Arch

# aggiungi pacchetti desiderati qui
Extra=(
  steam
  bottles
  brave-bin
  visual-studio-code-bin
)

hypr_package=(
  #aylurs-gtk-shell
  bc
  cliphist
  curl
  grim
  gvfs
  gvfs-mtp
  hyprpolkitagent
  imagemagick
  inxi
  jq
  kitty
  kvantum
  libspng
  nano
  network-manager-applet
  pamixer
  pavucontrol
  playerctl
  python-requests
  python-pyquery
  qt5ct
  qt6ct
  qt6-svg
  rofi
  slurp
  swappy
  swaync
  swww
  unzip # necessario più tardi
  wallust
  waybar
  wget
  wl-clipboard
  wlogout
  xdg-user-dirs
  xdg-utils
  yad
  libayatana-appindicator
)

# i seguenti pacchetti possono essere eliminati. tuttavia, i dotfiles potrebbero non funzionare correttamente
hypr_package_2=(
  brightnessctl
  btop
  cava
  loupe
  fastfetch
  gnome-system-monitor
  mousepad
  mpv
  mpv-mpris
  nvtop
  nwg-look
  nwg-displays
  pacman-contrib
  qalculate-gtk
  yt-dlp
)

# Elenco dei pacchetti da disinstallare poiché confliggono con alcuni pacchetti
uninstall=(
  aylurs-gtk-shell
  dunst
  cachyos-hyprland-settings
  mako
  rofi
  wallust-git
  rofi-lbonn-wayland
  rofi-lbonn-wayland-git
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_hypr-pkgs.log"

# rimozione pacchetti in conflitto
overall_failed=0
printf "\n%s - ${SKY_BLUE}Rimozione di alcuni pacchetti${RESET} poiché confliggono con i dot di Hyprland di KooL \n" "${NOTE}"
for PKG in "${uninstall[@]}"; do
  uninstall_package "$PKG" 2>&1 | tee -a "$LOG"
  if [ $? -ne 0 ]; then
    overall_failed=1
  fi
done

if [ $overall_failed -ne 0 ]; then
  echo -e "${ERROR} Alcuni pacchetti non sono stati disinstallati. Controlla il log."
fi

printf "\n%.0s" {1..1}

# Installazione dei componenti principali
printf "\n%s - Installazione dei ${SKY_BLUE}pacchetti necessari per Hyprland di KooL${RESET} .... \n" "${NOTE}"

for PKG1 in "${hypr_package[@]}" "${hypr_package_2[@]}" "${Extra[@]}"; do
  install_package "$PKG1" "$LOG"
done

printf "\n%.0s" {1..2}
