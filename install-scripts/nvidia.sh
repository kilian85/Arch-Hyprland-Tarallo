#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Cose Nvidia #

nvidia_pkg=(
  nvidia-dkms
  nvidia-settings
  nvidia-utils
  libva
  libva-nvidia-driver
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_nvidia.log"


# cose nvidia
printf "${YELLOW} Controllo di altri pacchetti hyprland e rimozione se presenti..${RESET}\n"
if pacman -Qs hyprland > /dev/null; then
  printf "${YELLOW} Hyprland rilevato. rimozione per installare Hyprland dal repo ufficiale...${RESET}\n"
    for hyprnvi in hyprland-git hyprland-nvidia hyprland-nvidia-git hyprland-nvidia-hidpi-git; do
    sudo pacman -R --noconfirm "$hyprnvi" 2>/dev/null | tee -a "$LOG" || true
    done
fi

# Installa pacchetti Nvidia aggiuntivi
printf "${YELLOW} Installazione di ${SKY_BLUE}Pacchetti Nvidia e header Linux${RESET}...\n"
for krnl in $(cat /usr/lib/modules/*/pkgbase); do
  for NVIDIA in "${krnl}-headers" "${nvidia_pkg[@]}"; do
    install_package "$NVIDIA" "$LOG"
  done
done

# Verifica se i moduli Nvidia sono già aggiunti in mkinitcpio.conf e aggiungili se non lo sono
if grep -qE '^MODULES=.*nvidia. *nvidia_modeset.*nvidia_uvm.*nvidia_drm' /etc/mkinitcpio.conf; then
  echo "Moduli Nvidia già inclusi in /etc/mkinitcpio.conf" 2>&1 | tee -a "$LOG"
else
  sudo sed -Ei 's/^(MODULES=\([^\)]*)\)/\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf 2>&1 | tee -a "$LOG"
  echo "${OK} Moduli Nvidia aggiunti in /etc/mkinitcpio.conf"
fi

printf "\n%.0s" {1..1}
printf "${INFO} Ricostruzione di ${YELLOW}Initramfs${RESET}...\n" 2>&1 | tee -a "$LOG"
sudo mkinitcpio -P 2>&1 | tee -a "$LOG"

printf "\n%.0s" {1..1}

# Passi aggiuntivi per Nvidia
NVEA="/etc/modprobe.d/nvidia.conf"
if [ -f "$NVEA" ]; then
  printf "${INFO} Sembra che ${YELLOW}nvidia_drm modeset=1 fbdev=1${RESET} sia già aggiunto nel tuo sistema..procedo."
  printf "\n"
else
  printf "\n"
  printf "${YELLOW} Aggiunta di opzioni a $NVEA..."
  sudo echo -e "options nvidia_drm modeset=1 fbdev=1" | sudo tee -a /etc/modprobe.d/nvidia.conf 2>&1 | tee -a "$LOG"
  printf "\n"
fi

# Aggiuntivo per utenti GRUB
if [ -f /etc/default/grub ]; then
    printf "${INFO} ${YELLOW}GRUB${RESET} bootloader rilevato\n" 2>&1 | tee -a "$LOG"
    
    # Verifica se nvidia-drm.modeset=1 è presente
    if ! sudo grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
        sudo sed -i -e 's/\(GRUB_CMDLINE_LINUX_DEFAULT=".*\)"/\1 nvidia-drm.modeset=1"/' /etc/default/grub
        printf "${OK} nvidia-drm.modeset=1 aggiunto a /etc/default/grub\n" 2>&1 | tee -a "$LOG"
    fi

    # Verifica se nvidia_drm.fbdev=1 è presente
    if ! sudo grep -q "nvidia_drm.fbdev=1" /etc/default/grub; then
        sudo sed -i -e 's/\(GRUB_CMDLINE_LINUX_DEFAULT=".*\)"/\1 nvidia_drm.fbdev=1"/' /etc/default/grub
        printf "${OK} nvidia_drm.fbdev=1 aggiunto a /etc/default/grub\n" 2>&1 | tee -a "$LOG"
    fi

    # Rigenera configurazione GRUB 
    if sudo grep -q "nvidia-drm.modeset=1" /etc/default/grub || sudo grep -q "nvidia_drm.fbdev=1" /etc/default/grub; then
       sudo grub-mkconfig -o /boot/grub/grub.cfg
       printf "${INFO} ${YELLOW}GRUB${RESET} configurazione rigenerata\n" 2>&1 | tee -a "$LOG"
    fi
  
    printf "${OK} Passi aggiuntivi per ${YELLOW}GRUB${RESET} completati\n" 2>&1 | tee -a "$LOG"
fi

# Additional for systemd-boot users
if [ -f /boot/loader/loader.conf ]; then
    printf "${INFO} ${YELLOW}systemd-boot${RESET} bootloader detected\n" 2>&1 | tee -a "$LOG"
  
    backup_count=$(find /boot/loader/entries/ -type f -name "*.conf.bak" | wc -l)
    conf_count=$(find /boot/loader/entries/ -type f -name "*.conf" | wc -l)
  
    if [ "$backup_count" -ne "$conf_count" ]; then
        find /boot/loader/entries/ -type f -name "*.conf" | while read imgconf; do
            # Backup conf
            sudo cp "$imgconf" "$imgconf.bak"
            printf "${INFO} Backup created for systemd-boot loader: %s\n" "$imgconf" 2>&1 | tee -a "$LOG"
            
            # Clean up options and update with NVIDIA settings
            sdopt=$(grep -w "^options" "$imgconf" | sed 's/\b nvidia-drm.modeset=[^ ]*\b//g' | sed 's/\b nvidia_drm.fbdev=[^ ]*\b//g')
            sudo sed -i "/^options/c${sdopt} nvidia-drm.modeset=1 nvidia_drm.fbdev=1" "$imgconf" 2>&1 | tee -a "$LOG"
        done

        printf "${OK} Additional steps for ${YELLOW}systemd-boot${RESET} completed\n" 2>&1 | tee -a "$LOG"
    else
        printf "${NOTE} ${YELLOW}systemd-boot${RESET} is already configured...\n" 2>&1 | tee -a "$LOG"
    fi
fi

printf "\n%.0s" {1..2} 
