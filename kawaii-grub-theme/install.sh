#!/bin/bash

# KawaiiGRUB Installer made by Gabbar-v7
# Visit https://GitHub.com/Gabbar-v7

# Cool designed header
echo "#####################################################"
echo "#                                                   #"
echo "#         KawaiiGRUB Theme Installer                #"
echo "#              Made by Gabbar-v7                    #"
echo "#                   Visit                           #"
echo "#      https://github.com/Gabbar-v7/KawaiiGRUB      #"
echo "#                                                   #"
echo "#####################################################"
echo ""

# Ask for sudo password
echo "Please enter your sudo password to install the theme:"
sudo -v

# Variables
THEME_DIR="/boot/grub/themes"
THEME_NAME="kawaii-grub-theme"
THEME_PATH="$THEME_DIR/$THEME_NAME/theme.txt"
GRUB_CONFIG="/etc/default/grub"

# Check if the theme folder exists locally
if [ ! -d "$THEME_NAME" ]; then
  echo "Error: Theme folder '$THEME_NAME' not found locally. Make sure the folder is in the current directory."
  exit 1
fi

# Check if the theme directory exists in /boot/grub/themes
if [ -d "$THEME_DIR/$THEME_NAME" ]; then
  echo "Theme folder '$THEME_NAME' already exists in $THEME_DIR."
  echo "Deleting the existing theme folder..."
  sudo rm -rf "$THEME_DIR/$THEME_NAME"
  echo "Existing theme folder deleted."
fi

# Copy the theme folder to /boot/grub/themes
echo "Copying theme to $THEME_DIR..."
sudo mkdir -p "$THEME_DIR"
sudo cp -r "$THEME_NAME" "$THEME_DIR/"
echo "Theme copied successfully."

# Update the GRUB configuration
echo "Updating GRUB configuration to use the new theme..."
sudo sed -i "/^GRUB_THEME=/d" "$GRUB_CONFIG" # Remove any existing GRUB_THEME entry
echo "GRUB_THEME=\"$THEME_PATH\"" | sudo tee -a "$GRUB_CONFIG"

# Add quiet and splash to kernel parameters if not already present
echo "Adding quiet and splash to kernel parameters..."
if ! sudo grep -q "GRUB_CMDLINE_LINUX_DEFAULT" "$GRUB_CONFIG"; then
  echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"' | sudo tee -a "$GRUB_CONFIG"
else
  sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ {
    /quiet/! s/=\(['"'"'"]\)\(.*\)\1/=\1\2 quiet\1/
    /splash/! s/=\(['"'"'"]\)\(.*\)\1/=\1\2 splash\1/
  }' "$GRUB_CONFIG"
fi
echo "Kernel parameters updated."

# Update GRUB
echo "Updating GRUB..."
if command -v update-grub &> /dev/null; then
  # Debian-based systems
  sudo update-grub
elif command -v grub-mkconfig &> /dev/null; then
  # Arch-based systems
  sudo grub-mkconfig -o /boot/grub/grub.cfg
else
  echo "Error: Could not find a GRUB update command (update-grub or grub-mkconfig)."
  exit 1
fi

# Confirmation message
echo ""
echo "KawaiiGRUB theme installed successfully!"

# Pause to let the user see the output
echo "Press any key to exit..."
read -n 1 -s

# Exit
exit 1
