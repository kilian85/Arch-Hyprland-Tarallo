#!/bin/bash
# Snapper - Snapshot btrfs automatici #

snapper_pkgs=(
  snapper
  snap-pac
  grub-btrfs
  inotify-tools
  btrfs-assistant
)

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "Failed to change directory to $PARENT_DIR"; exit 1; }

if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

LOG="Install-Logs/install-$(date +%d-%H%M%S)_snapper.log"

# Verifica filesystem btrfs
if ! findmnt -n -o FSTYPE / | grep -q btrfs; then
  printf "${ERROR} Il filesystem root non è btrfs. Snapper non verrà installato.\n"
  exit 1
fi

printf "${NOTE} Installazione pacchetti ${SKY_BLUE}Snapper${RESET}...\n"
for PKG in "${snapper_pkgs[@]}"; do
  install_package "$PKG" "$LOG"
done

# Crea configurazione snapper per root (rimuove eventuale config precedente)
printf "${NOTE} Creazione configurazione snapper per ${YELLOW}/${RESET}...\n"
if sudo snapper list-configs 2>/dev/null | grep -q "^root"; then
  printf "${INFO} Configurazione root già esistente, la riciclo.\n"
  sudo snapper -c root delete-config >> "$LOG" 2>&1
fi
sudo snapper -c root create-config / >> "$LOG" 2>&1
printf "${OK} Configurazione snapper ${SKY_BLUE}root${RESET} creata.\n"

# Permette agli utenti del gruppo wheel di usare snapper senza password
printf "${NOTE} Configurazione sudoers per ${SKY_BLUE}snapper${RESET}...\n"
echo "%wheel ALL=(ALL) NOPASSWD: /usr/bin/snapper" | sudo tee /etc/sudoers.d/snapper >> "$LOG" 2>&1
sudo chmod 440 /etc/sudoers.d/snapper >> "$LOG" 2>&1
printf "${OK} Snapper eseguibile con ${YELLOW}sudo snapper${RESET} senza password (gruppo wheel).\n"

# Abilita timer per snapshot automatici e pulizia
printf "${NOTE} Abilitazione timer ${SKY_BLUE}snapper${RESET}...\n"
sudo systemctl enable --now snapper-timeline.timer >> "$LOG" 2>&1
sudo systemctl enable --now snapper-cleanup.timer >> "$LOG" 2>&1
printf "${OK} Timer snapper abilitati.\n"

# Abilita grub-btrfs per mostrare snapshot nel menu GRUB
printf "${NOTE} Abilitazione ${SKY_BLUE}grub-btrfsd${RESET}...\n"
sudo systemctl enable --now grub-btrfsd >> "$LOG" 2>&1
printf "${OK} grub-btrfsd abilitato: gli snapshot appariranno nel menu GRUB.\n"

printf "\n%.0s" {1..2}
