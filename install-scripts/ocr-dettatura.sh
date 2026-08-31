#!/bin/bash
# OCR dallo schermo (SUPER ALT T) e dettatura vocale in italiano (F9)

if [[ $USE_PRESET = [Yy] ]]; then
  source ./preset.sh
fi

# Riconoscimento del testo a schermo. hyprpicker congela l'immagine durante la
# selezione, imagemagick ingrandisce prima dell'OCR: senza, il testo piccolo
# delle interfacce non viene letto.
ocr=(
    tesseract
    tesseract-data-ita
    tesseract-data-eng
    imagemagick
    hyprpicker
    grim
    slurp
    wl-clipboard
)

# Dettatura vocale: voxtype tiene il modello Whisper in memoria e scrive nella
# finestra attiva con wtype.
dettatura=(
    voxtype-bin
    wtype
)

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || {
  echo "${ERROR} Failed to change directory to $PARENT_DIR"
  exit 1
}

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_ocr-dettatura.log"

printf "\n%s - Installazione ${SKY_BLUE}OCR dallo schermo${RESET} \n" "${NOTE}"
for PKG1 in "${ocr[@]}"; do
  install_package "$PKG1" "$LOG"
done

printf "\n%s - Installazione ${SKY_BLUE}dettatura vocale${RESET} (voxtype) \n" "${NOTE}"
for PKG2 in "${dettatura[@]}"; do
  install_package "$PKG2" "$LOG"
done

printf "\n%.0s" {1..1}

# --- Configurazione di voxtype ------------------------------------------------
if command -v voxtype >/dev/null 2>&1; then
  printf "\n%s - Configurazione ${SKY_BLUE}voxtype${RESET} in italiano \n" "${NOTE}"

  # large-v3-turbo e' il miglior compromesso per l'italiano: qualita' vicina a
  # large-v3 ma diverse volte piu' veloce.
  printf "%s - Scarico il modello Whisper large-v3-turbo (circa 1,5 GB)...\n" "${NOTE}"
  voxtype setup --download --model large-v3-turbo >> "$LOG" 2>&1
  voxtype setup vad >> "$LOG" 2>&1

  voxtype config set whisper.model large-v3-turbo >> "$LOG" 2>&1
  voxtype config set whisper.language it >> "$LOG" 2>&1
  voxtype config set hotkey.key F9 >> "$LOG" 2>&1

  # Ripulitura del testo dettato, se lo script dei dotfiles e' presente.
  POSTPROCESS="$HOME/.config/hypr/UserScripts/dettatura_postprocess.sh"
  if [ -x "$POSTPROCESS" ]; then
    voxtype config set output.post_process.command "$POSTPROCESS" >> "$LOG" 2>&1
    printf "%s - Ripulitura del dettato attiva\n" "${OK}"
  fi

  # Su GPU AMD/Intel il Vulkan fa una differenza enorme: misurate 6 s contro 21 s
  # per la stessa frase su una iGPU Vega.
  if command -v vulkaninfo >/dev/null 2>&1 || pacman -Q vulkan-icd-loader >/dev/null 2>&1; then
    printf "%s - Attivo l'accelerazione Vulkan di voxtype (richiede la password)\n" "${NOTE}"
    sudo voxtype setup gpu --enable >> "$LOG" 2>&1
  fi

  voxtype setup systemd >> "$LOG" 2>&1
  systemctl --user enable --now voxtype >> "$LOG" 2>&1

  if systemctl --user is-active --quiet voxtype; then
    echo -e "${OK} voxtype attivo: tieni premuto ${YELLOW}F9${RESET}, parla, rilascia."
  else
    echo -e "${NOTE} voxtype installato ma non ancora avviato. Dopo il riavvio: ${YELLOW}systemctl --user status voxtype${RESET}"
  fi

  # Il tasto viene letto da /dev/input, non da Hyprland: serve il gruppo input.
  if ! id -nG "$USER" | grep -qw input; then
    echo -e "${NOTE} Aggiungo ${YELLOW}$USER${RESET} al gruppo ${YELLOW}input${RESET} (serve a F9; effettivo al prossimo accesso)"
    sudo usermod -aG input "$USER" >> "$LOG" 2>&1
  fi
fi

# --- Ollama, facoltativo ------------------------------------------------------
# Serve alla voce "chiedi all'IA" dell'OCR e come riserva per la ripulitura del
# dettato quando non c'e' la chiave di Gemini.
if ! command -v ollama >/dev/null 2>&1; then
  printf "\n%s - Installare anche ${SKY_BLUE}Ollama${RESET} con qwen2.5:3b? Serve per riassumere e tradurre\n" "${NOTE}"
  printf "%s   il testo catturato con l'OCR, senza mandare nulla fuori casa (circa 2 GB). [s/N]: " "${CAT}"
  read -r RISPOSTA
  if [[ "$RISPOSTA" =~ ^[SsYy]$ ]]; then
    install_package "ollama" "$LOG"
    if command -v ollama >/dev/null 2>&1; then
      sudo systemctl enable --now ollama >> "$LOG" 2>&1
      sleep 3
      printf "%s - Scarico qwen2.5:3b...\n" "${NOTE}"
      ollama pull qwen2.5:3b >> "$LOG" 2>&1
    fi
  else
    echo -e "${NOTE} Salto Ollama. L'OCR normale funziona lo stesso; la voce con l'IA no."
  fi
fi

# --- Come migliorare la ripulitura del dettato --------------------------------
# Detto qui a voce alta perche' e' l'unico passaggio che resta da fare a mano.
if [ ! -f "$HOME/.config/dettatura-gemini.env" ]; then
  printf "\n%.0s" {1..1}
  printf "%s ${SKY_BLUE}Dettatura: come farla correggere meglio${RESET}\n" "${NOTE}"
  printf "   Il testo che detti con F9 viene ripulito prima di essere scritto.\n"
  printf "   In locale ci pensa qwen; ma l'italiano lo scrive molto meglio Gemini,\n"
  printf "   che si attiva con una chiave gratuita.\n\n"
  printf "   Aprila dalla ${YELLOW}schermata di benvenuto${RESET}, pulsante ${YELLOW}Dettatura vocale${RESET}:\n"
  printf "   il wizard ti guida, verifica la chiave e la salva al posto giusto.\n\n"
  printf "   Senza chiave funziona tutto lo stesso, in locale.\n"
  printf "   Con la chiave, invece, le frasi dettate vengono inviate a Google.\n"
fi

printf "\n%.0s" {1..2}
