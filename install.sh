#!/bin/bash

clear

# Set some colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

# Create Directory for Install Logs
if [ ! -d Install-Logs ]; then
    mkdir Install-Logs
fi

# Set the name of the log file to include the current date and time
LOG="Install-Logs/01-Hyprland-Install-Scripts-$(date +%d-%H%M%S).log"

# Check if running as root. If root, script will exit
if [[ $EUID -eq 0 ]]; then
    echo "${ERROR}  This script should ${WARNING}NOT${RESET} be executed as root!! Exiting......." | tee -a "$LOG"
    printf "\n%.0s" {1..2} 
    exit 1
fi

# Check if PulseAudio package is installed
if pacman -Qq | grep -qw '^pulseaudio$'; then
    echo "$ERROR PulseAudio is detected as installed. Uninstall it first or edit install.sh on line 211 (execute_script 'pipewire.sh')." | tee -a "$LOG"
    printf "\n%.0s" {1..2} 
    exit 1
fi

# Check if base-devel is installed
if pacman -Q base-devel &> /dev/null; then
    echo "base-devel è già installato."
else
    echo "$NOTE Installazione base-devel.........."

    if sudo pacman -S --noconfirm base-devel; then
        echo "👌 ${OK} base-devel installato con successo." | tee -a "$LOG"
    else
        echo "❌ $ERROR base-devel non trovato o impossibile installarlo."  | tee -a "$LOG"
        echo "$ACTION Installa base-devel manualmente prima di eseguire questo script... Uscita" | tee -a "$LOG"
        exit 1
    fi
fi

# install whiptails if detected not installed. Necessary for this version
if ! command -v whiptail >/dev/null; then
    echo "${NOTE} - whiptail non è installato. Installazione..." | tee -a "$LOG"
    sudo pacman -S --noconfirm libnewt
    printf "\n%.0s" {1..1}
fi

clear

printf "\n%.0s" {1..2}  
echo -e "\e[35m
	╔╦╗╔═╗╔═╗╔═╗╦  ╦  ╔═╗   ╦ ╦╗ ╔╔═╗╔═╗╦  ╔═╗╔╗╔╔╦╗
	 ║ ╠═╣╠╦╝╠═╣║  ║  ║ ║   ╠═╣╚╦╝╠═╝╠╦╝║  ╠═╣║║║ ║║ 2026
	 ╩ ╝ ╚╩╚═╝ ╚╩═╝╩═╝╚═╝   ╩ ╩ ╩ ╩  ╩╚═╩═╝╝ ╚╝╚╝═╩╝ Arch Linux
\e[0m"
printf "\n%.0s" {1..1} 

# Welcome message using whiptail (for displaying information)
whiptail --title "Script di installazione di Arch-Hyprland-Tarallo (2026)" \
    --msgbox "Benvenuto nello script di installazione di Arch-Hyprland-Tarallo (2026)!!!\n\n\
ATTENZIONE: Esegui prima un aggiornamento completo del sistema e riavvia!!! (Fortemente raccomandato)\n\n\
NOTA: Se stai installando su una VM, assicurati di abilitare l'accelerazione 3D altrimenti Hyprland potrebbe NON avviarsi!" \
    15 80

# Ask if the user wants to proceed
if ! whiptail --title "Procedere con l'installazione?" \
    --yesno "Vuoi continuare?" 7 50; then
    echo -e "\n"
    echo "❌ ${INFO} Hai scelto di ${YELLOW}NON${RESET} continuare. ${YELLOW}Uscita...${RESET}" | tee -a "$LOG"
    echo -e "\n" 
    exit 1
fi

echo "👌 ${OK} ${MAGENTA}Perfetto..${RESET} ${SKY_BLUE}continuiamo con l'installazione...${RESET}" | tee -a "$LOG"

sleep 1
printf "\n%.0s" {1..1}

# install pciutils if detected not installed. Necessary for detecting GPU
if ! pacman -Qs pciutils > /dev/null; then
    echo "${NOTE} - pciutils non è installato. Installazione..." | tee -a "$LOG"
    sudo pacman -S --noconfirm pciutils
    printf "\n%.0s" {1..1}
fi

# Path to the install-scripts directory
script_directory=install-scripts

# Function to execute a script if it exists and make it executable
execute_script() {
    local script="$1"
    local script_path="$script_directory/$script"
    if [ -f "$script_path" ]; then
        chmod +x "$script_path"
        if [ -x "$script_path" ]; then
            env "$script_path"
        else
            echo "Failed to make script '$script' executable."
        fi
    else
        echo "Script '$script' not found in '$script_directory'."
    fi
}


## Default values for the options (will be overwritten by preset file if available)
gtk_themes="OFF"
bluetooth="OFF"
thunar="OFF"
quickshell="OFF"
sddm="OFF"
sddm_theme="OFF"
xdph="OFF"
zsh="OFF"
pokemon="OFF"
thinkpad="OFF"
fingerprint="OFF"
howdy="OFF"
snapper="OFF"
dots="OFF"
input_group="OFF"
ocr_dettatura="OFF"
nvidia="OFF"
nouveau="OFF"

# Function to load preset file
load_preset() {
    if [ -f "$1" ]; then
        echo "✅ Loading preset: $1"
        source "$1"
    else
        echo "⚠️ Preset file not found: $1. Using default values."
    fi
}

# Check if --preset argument is passed
if [[ "$1" == "--preset" && -n "$2" ]]; then
    load_preset "$2"
fi

# Check if yay or paru is installed
echo "${INFO} - Checking if yay or paru is installed"
if ! command -v yay &>/dev/null && ! command -v paru &>/dev/null; then
    echo "${CAT} - Né yay né paru trovati. Chiedo 🗣️ all'UTENTE di scegliere..."
    while true; do
        aur_helper=$(whiptail --title "Né Yay né Paru sono installati" --checklist "Né Yay né Paru sono installati. Scegli un AUR helper.\n\nNOTA: Seleziona solo 1 AUR helper!\nINFO: barra spaziatrice per selezionare" 12 60 2 \
            "yay" "AUR Helper yay" "OFF" \
            "paru" "AUR Helper paru" "OFF" \
            3>&1 1>&2 2>&3)

        if [ $? -ne 0 ]; then  
            echo "❌ ${INFO} Hai annullato la selezione. ${YELLOW}Arrivederci!${RESET}" | tee -a "$LOG"
            exit 0 
        fi

        if [ -z "$aur_helper" ]; then
            whiptail --title "Errore" --msgbox "Devi selezionare almeno un AUR helper per continuare." 10 60 2
            continue
        fi

        echo "${INFO} - Hai selezionato: $aur_helper come AUR helper"  | tee -a "$LOG"

        aur_helper=$(echo "$aur_helper" | tr -d '"')

        # Check if multiple helpers were selected
        if [[ $(echo "$aur_helper" | wc -w) -ne 1 ]]; then
            whiptail --title "Errore" --msgbox "Devi selezionare esattamente un AUR helper." 10 60 2
            continue  
        else
            break 
        fi
    done
else
    echo "${NOTE} - AUR helper già installato. Salto la selezione."
fi

# List of services to check for active login managers
services=("gdm.service" "gdm3.service" "lightdm.service" "lxdm.service")

# Function to check if any login services are active
check_services_running() {
    active_services=()  # Array to store active services
    for svc in "${services[@]}"; do
        if systemctl is-active --quiet "$svc"; then
            active_services+=("$svc")  
        fi
    done

    if [ ${#active_services[@]} -gt 0 ]; then
        return 0  
    else
        return 1  
    fi
}

if check_services_running; then
    active_list=$(printf "%s\n" "${active_services[@]}")

    # Display the active login manager(s) in the whiptail message box
    whiptail --title "Login manager attivo rilevato" \
        --msgbox "I seguenti login manager sono attivi:\n\n$active_list\n\nSe vuoi installare SDDM e il suo tema, ferma e disabilita i servizi sopra elencati, poi riavvia prima di eseguire questo script.\n\nL'opzione per installare SDDM e il suo tema è stata rimossa." 23 80
fi

# Check if NVIDIA GPU is detected
nvidia_detected=false
if lspci | grep -i "nvidia" &> /dev/null; then
    nvidia_detected=true
    whiptail --title "GPU NVIDIA rilevata" --msgbox "GPU NVIDIA rilevata nel sistema.\n\nNOTA: Lo script installerà nvidia-dkms, nvidia-utils e nvidia-settings se scegli di configurarla." 12 60
fi

# Initialize the options array for whiptail checklist
options_command=(
    whiptail --title "Seleziona le opzioni" --checklist "Scegli le opzioni da installare o configurare\nNOTA: 'BARRA SPAZIO' per selezionare & 'TAB' per cambiare selezione" 28 90 20
)

# Add NVIDIA options if detected
if [ "$nvidia_detected" == "true" ]; then
    options_command+=(
        "nvidia" "Vuoi configurare la GPU NVIDIA?" "OFF"
        "nouveau" "Vuoi mettere Nouveau in blacklist?" "OFF"
    )
fi

# Add 'input_group' option if user is not in input group
input_group_detected=false
if ! groups "$(whoami)" | grep -q '\binput\b'; then
    input_group_detected=true
    whiptail --title "Gruppo input" --msgbox "Non sei attualmente nel gruppo input.\n\nAggiungerti al gruppo input potrebbe essere necessario per la funzionalità keyboard-state di Waybar." 12 60
fi

# Add 'input_group' option if necessary
if [ "$input_group_detected" == "true" ]; then
    options_command+=(
        "input_group" "Aggiungere l'utente al gruppo input (funzionalità Waybar)?" "OFF"
    )
fi

# Conditionally add SDDM and SDDM theme options if no active login manager is found
if ! check_services_running; then
    options_command+=(
        "sddm" "Installare e configurare il login manager SDDM?" "OFF"
        "sddm_theme" "Temi SDDM extra (simple_sddm_2, astronaut, sugar-candy)" "OFF"
    )
fi

# Add the remaining static options
options_command+=(
    "browser"    "Installare un browser? (Brave, Firefox, Chromium...)" "OFF"
    "gaming"     "Installare pacchetti gaming? (Steam, Lutris, Bottles...)" "OFF"
    "gtk_themes" "Installare temi GTK? (richiesto per funzione Chiaro/Scuro)" "OFF"
    "bluetooth" "Configurare il Bluetooth?" "OFF"
    "thunar" "Installare il file manager Thunar?" "OFF"
    "quickshell" "Installare quickshell per la panoramica Desktop?" "OFF"
    "xdph" "Installare XDG-DESKTOP-PORTAL-HYPRLAND?" "OFF"
    "zsh" "Installare la shell zsh con Oh-My-Zsh?" "OFF"
    "pokemon" "Aggiungere Pokemon color scripts al terminale?" "OFF"
    "thinkpad" "Stai installando su un ThinkPad T470?" "OFF"
    "fingerprint" "Installare supporto lettore impronte (Validity 138a:0097)?" "OFF"
    "howdy" "Installare Howdy (facciale) + auto-login SDDM?" "OFF"
    "snapper" "Abilitare snapshot btrfs? (richiede filesystem btrfs)" "OFF"
    "ocr_dettatura" "Installare OCR dallo schermo e dettatura vocale italiana?" "OFF"
    "dots" "Scaricare e installare i dotfile Hyprland preconfigurati?" "OFF"
)

# Capture the selected options before the while loop starts
while true; do
    selected_options=$("${options_command[@]}" 3>&1 1>&2 2>&3)

    # Check if the user pressed Cancel (exit status 1)
    if [ $? -ne 0 ]; then
        echo -e "\n"
        echo "❌ ${INFO} Hai annullato la selezione. ${YELLOW}Arrivederci!${RESET}" | tee -a "$LOG"
        exit 0  # Exit the script if Cancel is pressed
    fi

    # If no option was selected, notify and restart the selection
    if [ -z "$selected_options" ]; then
        whiptail --title "Attenzione" --msgbox "Nessuna opzione selezionata. Seleziona almeno un'opzione." 10 60
        continue  # Return to selection if no options selected
    fi

    # Strip the quotes and trim spaces if necessary (sanitize the input)
    selected_options=$(echo "$selected_options" | tr -d '"' | tr -s ' ')

    # Convert selected options into an array (preserving spaces in values)
    IFS=' ' read -r -a options <<< "$selected_options"

    # Check if the "dots" option was selected
    dots_selected="OFF"
    for option in "${options[@]}"; do
        if [[ "$option" == "dots" ]]; then
            dots_selected="ON"
            break
        fi
    done

    # If "dots" is not selected, show a note and ask the user to proceed or return to choices
    if [[ "$dots_selected" == "OFF" ]]; then
        # Show a note about not selecting the "dots" option
        if ! whiptail --title "Dotfile Hyprland" --yesno \
        "Non hai selezionato l'installazione dei dotfile Hyprland preconfigurati.\n\nNOTA: Se procedi senza i Dotfile, Hyprland si avvierà con la configurazione vanilla predefinita e non sarà possibile offrire supporto.\n\nVuoi continuare senza i Dotfile o tornare alle opzioni?" \
        --yes-button "Continua" --no-button "Torna" 15 90; then
            echo "🔙 Ritorno alle opzioni..." | tee -a "$LOG"
            continue
        else
            # User chose to continue
            echo "${INFO} ⚠️ Continuo SENZA l'installazione dei dotfile..." | tee -a "$LOG"
			printf "\n%.0s" {1..1}
        fi
    fi

    # Prepare the confirmation message
    confirm_message="Hai selezionato le seguenti opzioni:\n\n"
    for option in "${options[@]}"; do
        confirm_message+=" - $option\n"
    done
    confirm_message+="\nSei soddisfatto di queste scelte?"

    # Confirmation prompt
    if ! whiptail --title "Conferma le tue scelte" --yesno "$(printf "%s" "$confirm_message")" 25 80; then
        echo -e "\n"
        echo "❌ ${SKY_BLUE}Non sei soddisfatto${RESET}. ${YELLOW}Ritorno alle opzioni...${RESET}" | tee -a "$LOG"
        continue 
    fi

    echo "👌 ${OK} Scelte confermate. Avvio installazione ${SKY_BLUE}Hyprland...${RESET}" | tee -a "$LOG"
    break  
done

printf "\n%.0s" {1..1}

# Ensuring base-devel is installed
execute_script "00-base.sh"
sleep 1
execute_script "pacman.sh"
sleep 1

# Execute AUR helper script after other installations if applicable
if [ "$aur_helper" == "paru" ]; then
    execute_script "paru.sh"
elif [ "$aur_helper" == "yay" ]; then
    execute_script "yay.sh"
fi

sleep 1

# Run the Hyprland related scripts
echo "${INFO} Installazione ${SKY_BLUE}pacchetti aggiuntivi Hyprland...${RESET}" | tee -a "$LOG"
sleep 1
execute_script "01-hypr-pkgs.sh"

echo "${INFO} Configurazione ${SKY_BLUE}SwayOSD${RESET} (OSD notifiche tastiera/luminosità)..." | tee -a "$LOG"
sleep 1
execute_script "swayosd.sh"

echo "${INFO} Installazione ${SKY_BLUE}pipewire e pipewire-audio...${RESET}" | tee -a "$LOG"
sleep 1
execute_script "pipewire.sh"

echo "${INFO} Installazione ${SKY_BLUE}font necessari...${RESET}" | tee -a "$LOG"
sleep 1
execute_script "fonts.sh"

echo "${INFO} Installazione ${SKY_BLUE}Hyprland...${RESET}"
sleep 1
execute_script "hyprland.sh"

echo "${INFO} Installazione ${SKY_BLUE}tema KawaiiGRUB...${RESET}" | tee -a "$LOG"
sleep 1
execute_script "grub-theme.sh"

# Clean up the selected options (remove quotes and trim spaces)
selected_options=$(echo "$selected_options" | tr -d '"' | tr -s ' ')

# Convert selected options into an array (splitting by spaces)
IFS=' ' read -r -a options <<< "$selected_options"

# Loop through selected options
for option in "${options[@]}"; do
    case "$option" in
        sddm)
            if check_services_running; then
                active_list=$(printf "%s\n" "${active_services[@]}")
                whiptail --title "Errore" --msgbox "Uno dei seguenti servizi di login è attivo:\n$active_list\n\nFerma e disabilita il servizio o NON scegliere SDDM." 12 60
                exec "$0"
            else
                echo "${INFO} Installazione e configurazione ${SKY_BLUE}SDDM...${RESET}" | tee -a "$LOG"
                execute_script "sddm.sh"
            fi
            ;;
        nvidia)
            echo "${INFO} Configurazione ${SKY_BLUE}NVIDIA${RESET}" | tee -a "$LOG"
            execute_script "nvidia.sh"
            ;;
        nouveau)
            echo "${INFO} Blacklist ${SKY_BLUE}nouveau${RESET}"
            execute_script "nvidia_nouveau.sh" | tee -a "$LOG"
            ;;
        browser)
            echo "${INFO} Selezione ${SKY_BLUE}browser...${RESET}" | tee -a "$LOG"
            execute_script "browser.sh"
            ;;
        gaming)
            echo "${INFO} Selezione ${SKY_BLUE}pacchetti gaming...${RESET}" | tee -a "$LOG"
            execute_script "gaming.sh"
            ;;
        voicechat)
            echo "${INFO} Selezione ${SKY_BLUE}chat vocale...${RESET}" | tee -a "$LOG"
            execute_script "voicechat.sh"
            ;;
        gtk_themes)
            echo "${INFO} Installazione ${SKY_BLUE}temi GTK...${RESET}" | tee -a "$LOG"
            execute_script "gtk_themes.sh"
            ;;
        ocr_dettatura)
            echo "${INFO} Installazione ${SKY_BLUE}OCR e dettatura vocale...${RESET}" | tee -a "$LOG"
            execute_script "ocr-dettatura.sh"
            ;;
        input_group)
            echo "${INFO} Aggiunta utente al gruppo ${SKY_BLUE}input...${RESET}" | tee -a "$LOG"
            execute_script "InputGroup.sh"
            ;;
        quickshell)
            echo "${INFO} Installazione ${SKY_BLUE}quickshell per panoramica Desktop...${RESET}" | tee -a "$LOG"
            execute_script "quickshell.sh"
            ;;
        xdph)
            echo "${INFO} Installazione ${SKY_BLUE}xdg-desktop-portal-hyprland...${RESET}" | tee -a "$LOG"
            execute_script "xdph.sh"
            ;;
        bluetooth)
            echo "${INFO} Configurazione ${SKY_BLUE}Bluetooth...${RESET}" | tee -a "$LOG"
            execute_script "bluetooth.sh"
            ;;
        thunar)
            echo "${INFO} Installazione ${SKY_BLUE}file manager Thunar...${RESET}" | tee -a "$LOG"
            execute_script "thunar.sh"
            execute_script "thunar_default.sh"
            ;;
        sddm_theme)
            echo "${INFO} Download e installazione ${SKY_BLUE}tema SDDM aggiuntivo...${RESET}" | tee -a "$LOG"
            execute_script "sddm_theme.sh"
            ;;
        zsh)
            echo "${INFO} Installazione ${SKY_BLUE}zsh con Oh-My-Zsh...${RESET}" | tee -a "$LOG"
            execute_script "zsh.sh"
            ;;
        pokemon)
            echo "${INFO} Aggiunta ${SKY_BLUE}Pokemon color scripts al terminale...${RESET}" | tee -a "$LOG"
            execute_script "zsh_pokemon.sh"
            ;;
        thinkpad)
            echo "${INFO} Installazione ${SKY_BLUE}pacchetti ThinkPad T470...${RESET}" | tee -a "$LOG"
            execute_script "thinkpad.sh"
            ;;
        fingerprint)
            echo "${INFO} Installazione ${SKY_BLUE}lettore impronte (Validity 138a:0097)...${RESET}" | tee -a "$LOG"
            execute_script "fingerprint.sh"
            ;;
        howdy)
            echo "${INFO} Installazione ${SKY_BLUE}Howdy riconoscimento facciale...${RESET}" | tee -a "$LOG"
            execute_script "howdy.sh"
            ;;
        snapper)
            echo "${INFO} Configurazione ${SKY_BLUE}snapshot btrfs con snapper...${RESET}" | tee -a "$LOG"
            execute_script "snapper.sh"
            ;;
        dots)
            echo "${INFO} Installazione ${SKY_BLUE}dotfile Hyprland preconfigurati...${RESET}" | tee -a "$LOG"
            execute_script "dotfiles-main.sh"
            ;;
        *)
            echo "Unknown option: $option" | tee -a "$LOG"
            ;;
    esac
done

sleep 1
# copy fastfetch config if arch.png is not present
if [ ! -f "$HOME/.config/fastfetch/arch.png" ]; then
    cp -r assets/fastfetch "$HOME/.config/"
fi

clear

# final check essential packages if it is installed
execute_script "02-Final-Check.sh"

printf "\n%.0s" {1..1}

# Check if hyprland or hyprland-git is installed
if pacman -Q hyprland &> /dev/null || pacman -Q hyprland-git &> /dev/null; then
    printf "\n ${OK} 👌 Hyprland è installato. Alcuni pacchetti essenziali potrebbero mancare. Controlla sopra!"
    printf "\n${CAT} Ignora questo messaggio se sopra indica che ${YELLOW}tutti i pacchetti essenziali${RESET} sono installati\n"
    sleep 2
    printf "\n%.0s" {1..2}

    printf "${SKY_BLUE}Grazie${RESET} 🫰 per aver usato ${MAGENTA}Hyprland Tarallo${RESET}. ${YELLOW}Buon divertimento!${RESET}"
    printf "\n%.0s" {1..2}

    printf "\n${NOTE} Puoi avviare Hyprland digitando ${SKY_BLUE}Hyprland${RESET} (se SDDM non è installato) (attenzione alla H maiuscola!).\n"
    printf "\n${NOTE} È però ${YELLOW}fortemente raccomandato riavviare${RESET} il sistema.\n\n"

    while true; do
        echo -n "${CAT} Vuoi riavviare ora? (s/n): "
        read HYP
        HYP=$(echo "$HYP" | tr '[:upper:]' '[:lower:]')

        if [[ "$HYP" == "s" || "$HYP" == "si" || "$HYP" == "y" || "$HYP" == "yes" ]]; then
            echo "${INFO} Riavvio in corso..."
            systemctl reboot
            break
        elif [[ "$HYP" == "n" || "$HYP" == "no" ]]; then
            echo "👌 ${OK} Hai scelto di NON riavviare"
            printf "\n%.0s" {1..1}
            # Check if NVIDIA GPU is present
            if lspci | grep -i "nvidia" &> /dev/null; then
                echo "${INFO} NOTA: ${YELLOW}GPU NVIDIA${RESET} rilevata. Ricorda che devi RIAVVIARE il sistema..."
                printf "\n%.0s" {1..1}
            fi
            break
        else
            echo "${WARN} Risposta non valida. Rispondi con 's' o 'n'."
        fi
    done
else
    # Print error message if neither package is installed
    printf "\n${WARN} Hyprland NON è installato. Controlla 00_CHECK-time_installed.log e gli altri file in Install-Logs/..."
    printf "\n%.0s" {1..3}
    exit 1
fi


printf "\n%.0s" {1..2}