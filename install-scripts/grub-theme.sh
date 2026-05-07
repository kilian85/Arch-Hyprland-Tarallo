#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"
cd ..
source "install-scripts/Global_functions.sh"

LOG_FILE="Install-Logs/$(date +%d-%H%M%S)-grub-theme.log"
mkdir -p "Install-Logs"

THEME_DIR="/boot/grub/themes"
THEME_NAME="kawaii-grub-theme"
THEME_SRC="${SCRIPT_DIR}/../kawaii-grub-theme/${THEME_NAME}"
THEME_PATH="$THEME_DIR/$THEME_NAME/theme.txt"
GRUB_CONFIG="/etc/default/grub"

echo -e "${NOTE} Starting KawaiiGRUB theme installation..." 2>&1 | tee -a "$LOG_FILE"

# Verify theme source folder exists in the repo
if [ ! -d "$THEME_SRC" ]; then
  echo -e "${ERROR} Theme folder '$THEME_NAME' not found at $THEME_SRC" 2>&1 | tee -a "$LOG_FILE"
  exit 1
fi

# Remove previous installation if present
if [ -d "$THEME_DIR/$THEME_NAME" ]; then
  echo -e "${NOTE} Removing existing theme installation..." 2>&1 | tee -a "$LOG_FILE"
  sudo rm -rf "$THEME_DIR/$THEME_NAME" 2>&1 | tee -a "$LOG_FILE"
fi

# Copy theme to /boot/grub/themes
echo -e "${NOTE} Copying theme to $THEME_DIR..." 2>&1 | tee -a "$LOG_FILE"
sudo mkdir -p "$THEME_DIR" 2>&1 | tee -a "$LOG_FILE"
sudo cp -r "$THEME_SRC" "$THEME_DIR/" 2>&1 | tee -a "$LOG_FILE"

if [ $? -ne 0 ]; then
  echo -e "${ERROR} Failed to copy theme files." 2>&1 | tee -a "$LOG_FILE"
  exit 1
fi
echo -e "${OK} Theme files copied successfully." 2>&1 | tee -a "$LOG_FILE"

# Set GRUB_THEME in /etc/default/grub
echo -e "${NOTE} Setting GRUB theme path..." 2>&1 | tee -a "$LOG_FILE"
sudo sed -i "/^GRUB_THEME=/d" "$GRUB_CONFIG" 2>&1 | tee -a "$LOG_FILE"
echo "GRUB_THEME=\"$THEME_PATH\"" | sudo tee -a "$GRUB_CONFIG" >> "$LOG_FILE"
echo -e "${OK} GRUB_THEME set to $THEME_PATH" 2>&1 | tee -a "$LOG_FILE"

# Add quiet and splash to kernel parameters if not already present
echo -e "${NOTE} Adding quiet and splash to kernel parameters..." 2>&1 | tee -a "$LOG_FILE"
if ! sudo grep -q "^GRUB_CMDLINE_LINUX_DEFAULT" "$GRUB_CONFIG"; then
  echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"' | sudo tee -a "$GRUB_CONFIG" >> "$LOG_FILE"
else
  sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ {
    /quiet/! s/=\(['"'"'"]\)\(.*\)\1/=\1\2 quiet\1/
    /splash/! s/=\(['"'"'"]\)\(.*\)\1/=\1\2 splash\1/
  }' "$GRUB_CONFIG" 2>&1 | tee -a "$LOG_FILE"
fi
echo -e "${OK} Kernel parameters updated." 2>&1 | tee -a "$LOG_FILE"

# Regenerate GRUB config
echo -e "${NOTE} Regenerating GRUB configuration..." 2>&1 | tee -a "$LOG_FILE"
if command -v update-grub &> /dev/null; then
  sudo update-grub 2>&1 | tee -a "$LOG_FILE"
elif command -v grub-mkconfig &> /dev/null; then
  sudo grub-mkconfig -o /boot/grub/grub.cfg 2>&1 | tee -a "$LOG_FILE"
else
  echo -e "${ERROR} Could not find update-grub or grub-mkconfig." 2>&1 | tee -a "$LOG_FILE"
  exit 1
fi

echo -e "${OK} KawaiiGRUB theme installed successfully!" 2>&1 | tee -a "$LOG_FILE"
echo -e "${NOTE} Log saved to $LOG_FILE"
