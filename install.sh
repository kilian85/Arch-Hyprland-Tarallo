#!/bin/bash
# https://github.com/JaKooLit

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

# Crea Directory per i Log di Installazione
if [ ! -d Install-Logs ]; then
    mkdir Install-Logs
fi

# Imposta il nome del file di log per includere la data e l'ora correnti
LOG="Install-Logs/01-Hyprland-Install-Scripts-$(date +%d-%H%M%S).log"

# Controlla se eseguito come root. Se root, lo script uscirà
if [[ $EUID -eq 0 ]]; then
    echo "${ERROR}  Questo script dovrebbe ${WARNING}NON${RESET} essere eseguito come root!! Uscendo......." | tee -a "$LOG"
    printf "\n%.0s" {1..2} 
    exit 1
fi

# Controlla se il pacchetto PulseAudio è installato
if pacman -Qq | grep -qw '^pulseaudio$'; then
    echo "$ERROR PulseAudio è rilevato come installato. Disinstallalo prima o modifica install.sh alla riga 211 (execute_script 'pipewire.sh')." | tee -a "$LOG"
    printf "\n%.0s" {1..2} 
    exit 1
fi

# Controlla se base-devel è installato
if pacman -Q base-devel &> /dev/null; then
    echo "base-devel è già installato."
else
    echo "$NOTE Installa base-devel.........."

    if sudo pacman -S --noconfirm base-devel; then
        echo "👌 ${OK} base-devel è stato installato con successo." | tee -a "$LOG"
    else
        echo "❌ $ERROR base-devel non trovato né può essere installato."  | tee -a "$LOG"
        echo "$ACTION Installa base-devel manualmente prima di eseguire questo script... Uscendo" | tee -a "$LOG"
        exit 1
    fi
fi

# installa whiptails se rilevato non installato. Necessario per questa versione
if ! command -v whiptail >/dev/null; then
    echo "${NOTE} - whiptail non è installato. Installando..." | tee -a "$LOG"
    sudo pacman -S --noconfirm libnewt
    printf "\n%.0s" {1..1}
fi

clear

printf "\n%.0s" {1..2}  
echo -e "\e[35m
   ╔╦╗╔═╗╦═╗╔═╗╦  ╦  ╔═╗  ╦ ╦╦ ╦╔═╗╦═╗╦  ╔═╗╔╗╔╔╦╗
	║ ╠═╣╠╦╝╠═╣║  ║  ║ ║  ╠═╣╚╦╝╠═╝╠╦╝║  ╠═╣║║║ ║║ 2026
	╩ ╩ ╩╩╚═╩ ╩╩═╝╩═╝╚═╝  ╩ ╩ ╩ ╩  ╩╚═╩═╝╩ ╩╝╚╝╚╩╝ Arch Linux
\e[0m"
printf "\n%.0s" {1..1} 

# Messaggio di benvenuto utilizzando whiptail (per visualizzare informazioni)
whiptail --title "Script di Installazione Tarallo Arch-Hyprland (2026)" \
    --msgbox "Benvenuto in Tarallo Arch-Hyprland (2026) Install Script!!!\n\n\
ATTENZIONE: Esegui un aggiornamento completo del sistema e riavvia prima !!! (Altamente raccomandato)\n\n\
NOTA: Se stai installando su una VM, assicurati di abilitare l'accelerazione 3D altrimenti Hyprland potrebbe NON avviarsi!" \
    15 80

# Chiedi se l'utente vuole procedere
if ! whiptail --title "Procedere con l'Installazione?" \
    --yesno "Vuoi procedere?" 7 50; then
    echo -e "\n"
    echo "❌ ${INFO} Hai 🫵 scelto ${YELLOW}NON${RESET} di procedere. ${YELLOW}Uscendo...${RESET}" | tee -a "$LOG"
    echo -e "\n" 
    exit 1
fi

echo "👌 ${OK} 🇵🇭 ${MAGENTA}KooL..${RESET} ${SKY_BLUE}continuiamo con l'installazione...${RESET}" | tee -a "$LOG"

sleep 1
printf "\n%.0s" {1..1}

# installa pciutils se rilevato non installato. Necessario per rilevare la GPU
if ! pacman -Qs pciutils > /dev/null; then
    echo "${NOTE} - pciutils non è installato. Installando..." | tee -a "$LOG"
    sudo pacman -S --noconfirm pciutils
    printf "\n%.0s" {1..1}
fi

# Path to the install-scripts directory
script_directory=install-scripts

# Funzione per eseguire uno script se esiste e renderlo eseguibile
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


## Valori predefiniti per le opzioni (verranno sovrascritti dal file preset se disponibile)
gtk_themes="OFF"
bluetooth="OFF"
thunar="OFF"
quickshell="OFF"
sddm="OFF"
sddm_theme="OFF"
xdph="OFF"
zsh="OFF"
pokemon="OFF"
#rog="OFF"
dots="OFF"
input_group="OFF"
nvidia="OFF"
wallpaper_engine="OFF"
nouveau="OFF"

# Funzione per caricare il file preset
load_preset() {
    if [ -f "$1" ]; then
        echo "✅ Caricando preset: $1"
        source "$1"
    else
        echo "⚠️ File preset non trovato: $1. Utilizzando valori predefiniti."
    fi
}

# Check if --preset argument is passed
if [[ "$1" == "--preset" && -n "$2" ]]; then
    load_preset "$2"
fi

# Controlla se yay o paru è installato
echo "${INFO} - Controllando se yay o paru è installato"
if ! command -v yay &>/dev/null && ! command -v paru &>/dev/null; then
    echo "${CAT} - Né yay né paru trovati. Chiedendo 🗣️ all'UTENTE di selezionare..."
    while true; do
        aur_helper=$(whiptail --title "Né Yay né Paru è installato" --checklist "Né Yay né Paru è installato. Scegli un AUR.\n\nNOTA: Seleziona solo 1 helper AUR!\nINFO: barra spaziatrice per selezionare" 12 60 2 \
            "yay" "AUR Helper yay" "OFF" \
            "paru" "AUR Helper paru" "OFF" \
            3>&1 1>&2 2>&3)

        if [ $? -ne 0 ]; then  
            echo "❌ ${INFO} Hai annullato la selezione. ${YELLOW}Arrivederci!${RESET}" | tee -a "$LOG"
            exit 0 
        fi

        if [ -z "$aur_helper" ]; then
            whiptail --title "Errore" --msgbox "Devi selezionare almeno un helper AUR per procedere." 10 60 2
            continue 
        fi

        echo "${INFO} - Hai selezionato: $aur_helper come tuo helper AUR"  | tee -a "$LOG"

        aur_helper=$(echo "$aur_helper" | tr -d '"')

        # Check if multiple helpers were selected
        if [[ $(echo "$aur_helper" | wc -w) -ne 1 ]]; then
            whiptail --title "Errore" --msgbox "Devi selezionare esattamente un helper AUR." 10 60 2
            continue  
        else
            break 
        fi
    done
else
    echo "${NOTE} - L'helper AUR è già installato. Saltando la selezione dell'helper AUR."
fi

# Lista dei servizi da controllare per gestori di login attivi
services=("gdm.service" "gdm3.service" "lightdm.service" "lxdm.service")

# Funzione per controllare se alcuni servizi di login sono attivi
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
    whiptail --title "Rilevati gestori di login non-SDDM attivi" \
        --msgbox "I seguenti gestori di login sono attivi:\n\n$active_list\n\nSe vuoi installare SDDM e il tema SDDM, ferma e disabilita i servizi attivi sopra, riavvia prima di eseguire questo script\n\nLa tua opzione per installare SDDM e il tema SDDM è ora stata rimossa\n\n- Ja " 23 80
fi

# Controlla se GPU NVIDIA è rilevata
nvidia_detected=false
if lspci | grep -i "nvidia" &> /dev/null; then
    nvidia_detected=true
    whiptail --title "GPU NVIDIA Rilevata" --msgbox "GPU NVIDIA rilevata nel tuo sistema.\n\nNOTA: Lo script installerà nvidia-dkms, nvidia-utils e nvidia-settings se scegli di configurare." 12 60
fi

# Initialize the options array for whiptail checklist
options_command=(
    whiptail --title "Seleziona Opzioni" --checklist "Scegli le opzioni da installare o configurare\nNOTA: 'BARRA SPAZIATRICE' per selezionare & 'TAB' per cambiare selezione" 28 100 15
)

# Aggiungi opzioni NVIDIA se rilevata
if [ "$nvidia_detected" == "true" ]; then
    options_command+=(
        "nvidia" "Vuoi che lo script configuri la GPU NVIDIA?" "OFF"
        "nouveau" "Vuoi che Nouveau sia nella blacklist?" "OFF"
    )
fi

# Aggiungi opzione 'input_group' se l'utente non è nel gruppo input
input_group_detected=false
if ! groups "$(whoami)" | grep -q '\binput\b'; then
    input_group_detected=true
    whiptail --title "Gruppo Input" --msgbox "Al momento non sei nel gruppo input.\n\nAggiungerti al gruppo input potrebbe essere necessario per la funzionalità keyboard-state di Waybar." 12 60
fi

# Aggiungi opzione 'input_group' se necessario
if [ "$input_group_detected" == "true" ]; then
    options_command+=(
        "input_group" "Aggiungere il tuo UTENTE al gruppo input per alcune funzionalità waybar?" "OFF"
    )
fi

# Aggiungi condizionatamente opzioni SDDM e tema SDDM se nessun gestore di login attivo è trovato
if ! check_services_running; then
    options_command+=(
        "sddm" "Installare e configurare il gestore di login SDDM?" "OFF"
        "sddm_theme" "Scaricare e Installare tema SDDM aggiuntivo?" "OFF"
    )
fi

# Add the remaining static options
options_command+=(
    "gtk_themes" "Installare temi GTK? (richiesto per la funzione Chiaro/Scuro)" "OFF"
    "bluetooth" "Vuoi che lo script configuri il Bluetooth?" "OFF"
    "thunar" "Vuoi che il file manager Thunar sia installato?" "OFF"
    "quickshell" "Installare quickshell per Panoramica Desktop-Like?" "OFF"
    "xdph" "Installare XDG-DESKTOP-PORTAL-HYPRLAND (per condivisione schermo)?" "OFF"
    "zsh" "Installare la shell zsh con Oh-My-Zsh?" "OFF"
    "pokemon" "Aggiungere script di colori Pokemon al tuo terminale?" "OFF"
    #"rog" "Stai installando su laptop Asus ROG?" "OFF"
    "dots" "Scaricare e installare i dotfiles KooL Hyprland preconfigurati?" "OFF"
	"wallpaper_engine" "Installa Linux Wallpaper Engine GUI (AUR)?" "OFF"
)

# Cattura le opzioni selezionate prima che il ciclo while inizi
while true; do
    selected_options=$("${options_command[@]}" 3>&1 1>&2 2>&3)

    # Check if the user pressed Cancel (exit status 1)
    if [ $? -ne 0 ]; then
        echo -e "\n"
        echo "❌ ${INFO} Hai 🫵 annullato la selezione. ${YELLOW}Arrivederci!${RESET}" | tee -a "$LOG"
        exit 0  # Exit the script if Cancel is pressed
    fi

    # If no option was selected, notify and restart the selection
    if [ -z "$selected_options" ]; then
        whiptail --title "Avviso" --msgbox "Nessuna opzione selezionata. Seleziona almeno un'opzione." 10 60
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
        if ! whiptail --title "File Dot KooL Hyprland" --yesno \
"Non hai selezionato di installare i dotfiles KooL Hyprland preconfigurati.\n\nNota gentilmente che se procedi senza Dots, Hyprland si avvierà con la configurazione Hyprland vanilla predefinita e non sarò in grado di darti supporto.\n\nVuoi continuare l'installazione senza i Dot KooL Hyprland o tornare alle scelte/opzioni?" \
        --yes-button "Continua" --no-button "Ritorna" 15 90; then
            echo "🔙 Ritornando alle opzioni..." | tee -a "$LOG"
            continue
        else
            # User chose to continue
            echo "${INFO} ⚠️ Continuando SENZA l'installazione dei dotfiles..." | tee -a "$LOG"
			printf "\n%.0s" {1..1}
        fi
    fi
    
	# Prepare the confirmation message
    confirm_message="Hai selezionato le seguenti opzioni:\n\n"
    for option in "${options[@]}"; do
        confirm_message+=" - $option\n"
    done
    confirm_message+="\nSei felice di queste scelte?"

    # Confirmation prompt
    if ! whiptail --title "Conferma le Tue Scelte" --yesno "$(printf "%s" "$confirm_message")" 25 80; then
        echo -e "\n"
        echo "❌ ${SKY_BLUE}Non sei 🫵 felice${RESET}. ${YELLOW}Ritornando alle opzioni...${RESET}" | tee -a "$LOG"
        continue 
    fi

    echo "👌 ${OK} Hai confermato le tue scelte. Procedendo con ${SKY_BLUE}KooL 🇵🇭 Hyprland Installation...${RESET}" | tee -a "$LOG"
    break  
done

printf "\n%.0s" {1..1}

# Assicurando che base-devel sia installato
execute_script "00-base.sh"
sleep 1
execute_script "pacman.sh"
sleep 1

# Esegui script helper AUR dopo altre installazioni se applicabile
if [ "$aur_helper" == "paru" ]; then
    execute_script "paru.sh"
elif [ "$aur_helper" == "yay" ]; then
    execute_script "yay.sh"
fi

sleep 1

# Run the Hyprland related scripts
echo "${INFO} Installando ${SKY_BLUE}pacchetti aggiuntivi KooL Hyprland...${RESET}" | tee -a "$LOG"
sleep 1
execute_script "01-hypr-pkgs.sh"

echo "${INFO} Installando ${SKY_BLUE}pipewire e pipewire-audio...${RESET}" | tee -a "$LOG"
sleep 1
execute_script "pipewire.sh"

echo "${INFO} Installando ${SKY_BLUE}font necessari...${RESET}" | tee -a "$LOG"
sleep 1
execute_script "fonts.sh"

echo "${INFO} Installando ${SKY_BLUE}Hyprland...${RESET}"
sleep 1
execute_script "hyprland.sh"

# Pulisci le opzioni selezionate (rimuovi virgolette e taglia spazi)
selected_options=$(echo "$selected_options" | tr -d '"' | tr -s ' ')

# Converti opzioni selezionate in un array (dividendo per spazi)
IFS=' ' read -r -a options <<< "$selected_options"

# Cicla attraverso le opzioni selezionate
for option in "${options[@]}"; do
    case "$option" in
        sddm)
            if check_services_running; then
                active_list=$(printf "%s\n" "${active_services[@]}")
                whiptail --title "Errore" --msgbox "Uno dei seguenti servizi di login è in esecuzione:\n$active_list\n\nFerma e disabilitalo o NON scegliere SDDM." 12 60
                exec "$0"  
            else
                echo "${INFO} Installando e configurando ${SKY_BLUE}SDDM...${RESET}" | tee -a "$LOG"
                execute_script "sddm.sh"
            fi
            ;;
        nvidia)
            echo "${INFO} Configurando ${SKY_BLUE}roba nvidia${RESET}" | tee -a "$LOG"
            execute_script "nvidia.sh"
            ;;
        nouveau)
            echo "${INFO} mettendo nella blacklist ${SKY_BLUE}nouveau${RESET}"
            execute_script "nvidia_nouveau.sh" | tee -a "$LOG"
            ;;
        gtk_themes)
            echo "${INFO} Installando ${SKY_BLUE}temi GTK...${RESET}" | tee -a "$LOG"
            execute_script "gtk_themes.sh"
            ;;
        input_group)
            echo "${INFO} Aggiungendo utente al ${SKY_BLUE}gruppo input...${RESET}" | tee -a "$LOG"
            execute_script "InputGroup.sh"
            ;;
        quickshell)
            echo "${INFO} Installando ${SKY_BLUE}quickshell per Panoramica Desktop...${RESET}" | tee -a "$LOG"
            execute_script "quickshell.sh"
            ;;
        xdph)
            echo "${INFO} Installando ${SKY_BLUE}xdg-desktop-portal-hyprland...${RESET}" | tee -a "$LOG"
            execute_script "xdph.sh"
            ;;
        bluetooth)
            echo "${INFO} Configurando ${SKY_BLUE}Bluetooth...${RESET}" | tee -a "$LOG"
            execute_script "bluetooth.sh"
            ;;
        thunar)
            echo "${INFO} Installando ${SKY_BLUE}file manager Thunar...${RESET}" | tee -a "$LOG"
            execute_script "thunar.sh"
            execute_script "thunar_default.sh"
            ;;
        sddm_theme)
            echo "${INFO} Scaricando e Installando ${SKY_BLUE}tema SDDM aggiuntivo...${RESET}" | tee -a "$LOG"
            execute_script "sddm_theme.sh"
            ;;
        zsh)
            echo "${INFO} Installando ${SKY_BLUE}zsh con Oh-My-Zsh...${RESET}" | tee -a "$LOG"
            execute_script "zsh.sh"
            ;;
        pokemon)
            echo "${INFO} Aggiungendo ${SKY_BLUE}script di colori Pokemon al terminale...${RESET}" | tee -a "$LOG"
            execute_script "zsh_pokemon.sh"
            ;;
        dots)
            echo "${INFO} Installando dotfiles ${SKY_BLUE}KooL Hyprland preconfigurati...${RESET}" | tee -a "$LOG"
            execute_script "dotfiles-main.sh"
            ;;
        wallpaper_engine)
            echo "${INFO} Installando ${SKY_BLUE}linux-wallpaperengine-gui...${RESET}" | tee -a "$LOG"
            # Utilizza l'helper AUR (yay o paru) che lo script ha rilevato all'inizio
            $aur_helper -S --noconfirm linux-wallpaperengine-gui-bin 2>&1 | tee -a "$LOG"
            ;;
        *)
            echo "Opzione sconosciuta: $option" | tee -a "$LOG"
            ;;
    esac
done

sleep 1
# copia config fastfetch se arch.png non è presente
if [ ! -f "$HOME/.config/fastfetch/arch.png" ]; then
    cp -r assets/fastfetch "$HOME/.config/"
fi

clear

# controllo finale pacchetti essenziali se è installato
execute_script "02-Final-Check.sh"

printf "\n%.0s" {1..1}

# Controlla se hyprland o hyprland-git è installato
if pacman -Q hyprland &> /dev/null || pacman -Q hyprland-git &> /dev/null; then
printf "\n ${OK} 👌 Hyprland è installato. Tuttavia, alcuni pacchetti essenziali potrebbero non essere installati. Vedi sopra!"
printf "\n${CAT} Ignora questo messaggio se indica ${YELLOW}Tutti i pacchetti essenziali${RESET} sono installati come sopra\n"
    sleep 2
    printf "\n%.0s" {1..2}

    printf "${SKY_BLUE}Grazie${RESET} 🫰 for using 🇵🇭 ${MAGENTA}KooL's Hyprland Dots${RESET}. ${YELLOW}Divertiti e buona giornata!${RESET}"
    printf "\n%.0s" {1..2}

printf "\n${NOTE} Puoi avviare Hyprland digitando ${SKY_BLUE}Hyprland${RESET} (SE SDDM non è installato) (nota la H maiuscola!).\n"
printf "\n${NOTE} Tuttavia, è ${YELLOW}altamente raccomandato riavviare${RESET} il tuo sistema.\n\n"

    while true; do
        echo -n "${CAT} Vuoi riavviare ora? (y/n): "
        read HYP
        HYP=$(echo "$HYP" | tr '[:upper:]' '[:lower:]')

        if [[ "$HYP" == "y" || "$HYP" == "yes" ]]; then
            echo "${INFO} Riavviando ora..."
            systemctl reboot 
            break
        elif [[ "$HYP" == "n" || "$HYP" == "no" ]]; then
            echo "👌 ${OK} Hai scelto NON di riavviare"
            printf "\n%.0s" {1..1}
            # Check if NVIDIA GPU is present
            if lspci | grep -i "nvidia" &> /dev/null; then
                echo "${INFO} COMUNQUE ${YELLOW}GPU NVIDIA${RESET} rilevata. Promemoria che devi RIAVVIARE il tuo SISTEMA..."
                printf "\n%.0s" {1..1}
            fi
            break
        else
            echo "${WARN} Risposta non valida. Rispondi con 'y' o 'n'."
        fi
    done
else
    # Stampa messaggio di errore se nessuno dei pacchetti è installato
    printf "\n${WARN} Hyprland NON è installato. Controlla 00_CHECK-time_installed.log e altri file nella directory Install-Logs/..."
    printf "\n%.0s" {1..3}
    exit 1
fi


printf "\n%.0s" {1..2}
