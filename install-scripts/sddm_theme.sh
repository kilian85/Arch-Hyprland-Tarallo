#!/bin/bash
# SDDM themes — installa tutti i temi supportati dal selettore grafico #

theme_name="simple_sddm_2"
source_theme="https://github.com/JaKooLit/simple-sddm-2.git"

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Failed to change directory to $PARENT_DIR"; exit 1; }

if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

LOG="Install-Logs/install-$(date +%d-%H%M%S)_sddm_theme.log"

printf "${INFO} Installazione ${SKY_BLUE}temi SDDM aggiuntivi${RESET} (selettore grafico)\n"
sudo mkdir -p /usr/share/sddm/themes

# ─── 1. simple_sddm_2 (clone da GitHub) ──────────────────────────────────────

printf "${INFO} Installazione ${YELLOW}simple_sddm_2${RESET}...\n"

[ -d "/usr/share/sddm/themes/$theme_name" ] && sudo rm -rf "/usr/share/sddm/themes/$theme_name"
[ -d "$theme_name" ] && rm -rf "$theme_name"

if git clone --depth=1 "$source_theme" "$theme_name" 2>&1 | tee -a "$LOG"; then
  sudo mv "$theme_name" "/usr/share/sddm/themes/$theme_name" 2>&1 | tee -a "$LOG"

  # Imposta simple_sddm_2 come tema attivo in sddm.conf
  sddm_conf="/etc/sddm.conf"
  [ -f "$sddm_conf" ] && sudo cp "$sddm_conf" "$sddm_conf.bak" 2>&1 | tee -a "$LOG" || sudo touch "$sddm_conf"

  if grep -q '^\[Theme\]' "$sddm_conf"; then
    sudo sed -i "/^\[Theme\]/,/^\[/{s/^\s*Current=.*/Current=$theme_name/}" "$sddm_conf"
    grep -q '^\s*Current=' "$sddm_conf" || sudo sed -i "/^\[Theme\]/a Current=$theme_name" "$sddm_conf"
  else
    printf "\n[Theme]\nCurrent=%s" "$theme_name" | sudo tee -a "$sddm_conf" > /dev/null
  fi

  if ! grep -q '^\[General\]' "$sddm_conf"; then
    printf "\n[General]\nInputMethod=qtvirtualkeyboard" | sudo tee -a "$sddm_conf" > /dev/null
  else
    grep -q '^\s*InputMethod=' "$sddm_conf" \
      && sudo sed -i '/^\[General\]/,/^\[/{s/^\s*InputMethod=.*/InputMethod=qtvirtualkeyboard/}' "$sddm_conf" \
      || sudo sed -i '/^\[General\]/a InputMethod=qtvirtualkeyboard' "$sddm_conf"
  fi

  # Sfondo predefinito
  sudo cp -r assets/sddm.png "/usr/share/sddm/themes/$theme_name/Backgrounds/default" 2>&1 | tee -a "$LOG"
  sudo sed -i 's|^wallpaper=".*"|wallpaper="Backgrounds/default"|' "/usr/share/sddm/themes/$theme_name/theme.conf" 2>&1 | tee -a "$LOG"

  echo "${OK} - ${YELLOW}simple_sddm_2${RESET} installato." | tee -a "$LOG"
else
  echo "${ERROR} - Clonazione simple_sddm_2 fallita." | tee -a "$LOG"
fi

# ─── 2. sddm-astronaut-theme (AUR) ───────────────────────────────────────────

printf "${INFO} Installazione ${YELLOW}sddm-astronaut-theme${RESET} (AUR)...\n"
install_package "sddm-astronaut-theme" "$LOG"

# ─── 3. sugar-candy (AUR) ────────────────────────────────────────────────────

printf "${INFO} Installazione ${YELLOW}sugar-candy${RESET} (AUR)...\n"
install_package "sddm-sugar-candy-git" "$LOG"

# ─── Riepilogo ────────────────────────────────────────────────────────────────

printf "\n"
echo "============================================================" | tee -a "$LOG"
echo "${OK} Temi SDDM installati:" | tee -a "$LOG"
for t in simple_sddm_2 sddm-astronaut-theme sugar-candy elarun maldives maya; do
  if [ -d "/usr/share/sddm/themes/$t" ]; then
    echo "  [x] $t" | tee -a "$LOG"
  else
    echo "  [ ] $t (non trovato)" | tee -a "$LOG"
  fi
done
echo "============================================================" | tee -a "$LOG"

printf "\n%.0s" {1..2}
