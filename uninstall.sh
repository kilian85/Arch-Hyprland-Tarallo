#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Script di disinstallazione KooL Arch-Hyprland #

clear

# Imposta i colori per i messaggi di output
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERRORE]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTA]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[AVVISO]$(tput sgr0)"
CAT="$(tput setaf 6)[AZIONE]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

printf "\n%.0s" {1..2}
echo -e "\e[35m
	╦╔═┌─┐┌─┐╦    ╦ ╦┬ ┬┌─┐┬─┐┬  ┌─┐┌┐┌┌┬┐
	╠╩╗│ ││ │║    ╠═╣└┬┘├─┘├┬┘│  ├─┤│││ ││ DISINSTALLAZIONE
	╩ ╩└─┘└─┘╩═╝  ╩ ╩ ┴ ┴  ┴└─┴─┘┴ ┴┘└┘─┴┘ Arch Linux
\e[0m"
printf "\n%.0s" {1..1}

# Mostra il messaggio di benvenuto usando whiptail con opzioni Sì/No
whiptail --title "Script di Disinstallazione KooL Dots Arch-Hyprland" --yesno \
"Ciao! Questo script disinstallerà i pacchetti e le configurazioni di KooL Hyprland.

Puoi scegliere i pacchetti e le directory che desideri rimuovere.
NOTA: Questo rimuoverà le configurazioni da ~/.config

ATTENZIONE: Dopo la disinstallazione, il sistema potrebbe diventare instabile.

Vogliamo procedere?" 20 80

if [ $? -eq 1 ]; then
    echo "$INFO Processo di disinstallazione annullato."
    exit 0
fi

# Funzione per rimuovere i pacchetti selezionati
remove_packages() {
    local selected_packages_file=$1
    while read -r package; do
        if pacman -Qi "$package" &> /dev/null; then
            echo "Rimozione del pacchetto: $package"
            if ! sudo pacman -Rs --noconfirm "$package"; then
                echo "$ERROR Impossibile rimuovere il pacchetto: $package"
            else
                echo "$OK Pacchetto rimosso con successo: $package"
            fi
        else
            echo "$INFO Pacchetto ${YELLOW}$package${RESET} non trovato. Salto."
        fi
    done < "$selected_packages_file"
}

# Funzione per rimuovere le directory selezionate
remove_directories() {
    local selected_dirs_file=$1
    while read -r dir; do
        pattern="$HOME/.config/$dir*"        
        # Ciclo tra le directory che corrispondono al pattern
        for dir_to_remove in $pattern; do
            if [ -d "$dir_to_remove" ]; then
                echo "Rimozione della directory: $dir_to_remove"
                if ! rm -rf "$dir_to_remove"; then
                    echo "$ERROR Impossibile rimuovere la directory: $dir_to_remove"
                else
                    echo "$OK Directory rimossa con successo: $dir_to_remove"
                fi
            else
                echo "$INFO Directory ${YELLOW}$dir_to_remove${RESET} non trovata. Salto."
            fi
        done
    done < "$selected_dirs_file"
}

# Elenco dei pacchetti tra cui scegliere
packages=(
    "btop" "monitor delle risorse" "off"
    "brightnessctl" "controllo luminosità" "off"
    "cava" "visualizzatore audio cross-platform" "off"
    "cliphist" "gestore appunti (clipboard)" "off"
    "fastfetch" "info sistema fastfetch" "off"
    "ffmpegthumbnailer" "generatore miniature video" "off"
    "grim" "strumento screenshot" "off"
    "imagemagick" "manipolazione immagini" "off"
    "kitty" "terminale kitty" "off"
    "kvantum" "temi per app QT" "off"
    "mousepad" "editor di testo semplice" "off"
    "mpv" "lettore multimediale" "off"
    "mpv-mpris" "plugin mpv" "off"
    "network-manager-applet" "applet gestione rete" "off"
    "nvtop" "monitor risorse GPU" "off"
    "nwg-displays" "configurazione monitor" "off"
    "nwg-look" "configurazione temi GTK" "off"
    "pamixer" "controllo audio pamixer" "off"
    "pokemon-colorscripts-git" "script colori pokemon nel terminale" "off"
    "pavucontrol" "controllo volume pavucontrol" "off"
    "playerctl" "controllo riproduzione media" "off"
    "pyprland" "estensione pyprland" "off"
    "qalculate-gtk" "calcolatrice QT" "off"
    "qt5ct" "configurazione qt5" "off"
    "qt6ct" "configurazione qt6" "off"
    "quickshell" "quickshell" "off"
    "rofi-wayland" "menu di avvio rofi" "off"
    "slurp" "strumento selezione area screenshot" "off"
    "swappy" "strumento editing screenshot" "off"
    "swaync" "centro notifiche" "off"
    "swww" "gestore sfondi" "off"
    "thunar" "gestore file (file manager)" "off"
    "thunar-archive-plugin" "plugin archivi per thunar" "off"
    "thunar-volman" "gestione volumi per thunar" "off"
    "tumbler" "servizio miniature" "off"
    "wallust" "generatore tavolozza colori" "off"
    "waybar" "barra di sistema wayland" "off"
    "wl-clipboard" "gestore appunti wayland" "off"
    "wlogout" "menu di chiusura sessione" "off"
    "xdg-desktop-portal-hy
