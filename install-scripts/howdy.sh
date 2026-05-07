#!/bin/bash
# 💫 https://github.com/kilian85 💫 #
# Howdy face recognition — ThinkPad T470 #
# Webcam IR /dev/video0 (YUYV 340x340)   #

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "Failed to change directory to $PARENT_DIR"; exit 1; }

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_howdy.log"

# =============================================================================
# Colors (standalone — coexistono con quelle di Global_functions.sh)
# =============================================================================
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[+]${NC} $1" | tee -a "$LOG"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1" | tee -a "$LOG"; }

[ "$EUID" -eq 0 ] && { echo -e "${RED}[ERROR]${NC} Non eseguire come root."; exit 1; }
CURRENT_USER="$USER"

echo "" | tee -a "$LOG"
echo "============================================================" | tee -a "$LOG"
echo "  Howdy face recognition — ThinkPad T470" | tee -a "$LOG"
echo "  Utente: $CURRENT_USER" | tee -a "$LOG"
echo "============================================================" | tee -a "$LOG"
echo "" | tee -a "$LOG"

# =============================================================================
# STEP 1 — Installazione howdy-git
# =============================================================================
info "Step 1/4: Installazione howdy-git..."

command -v yay &>/dev/null || { echo -e "${RED}[ERROR]${NC} yay non trovato."; exit 1; }

yay -S --needed --noconfirm howdy-git 2>&1 | tee -a "$LOG"
ok "howdy-git installato"

# =============================================================================
# STEP 2 — Config Howdy
# =============================================================================
info "Step 2/4: Scrittura config Howdy..."

HOWDY_CONF=/etc/howdy/config.ini
[ -f "$HOWDY_CONF" ] && sudo cp "$HOWDY_CONF" "${HOWDY_CONF}.bak"

sudo tee "$HOWDY_CONF" > /dev/null << 'EOF'
# Howdy config file

[core]
detection_notice = true
timeout_notice = true
no_confirmation = true
suppress_unknown = false
abort_if_ssh = true
abort_if_lid_closed = true
disabled = false
use_cnn = false
workaround = off

[video]
certainty = 3.5
timeout = 3
device_path = /dev/video0
warn_no_device = true
max_height = 320
frame_width = 340
frame_height = 340
dark_threshold = 100
recording_plugin = opencv
device_format = v4l2
force_mjpeg = false
exposure = -1
device_fps = 30
rotate = 0

[snapshots]
save_failed = false
save_successful = false

[rubberstamps]
enabled = false
stamp_rules =
	nod		5s		failsafe     min_distance=12

[debug]
end_report = false
verbose_stamps = false
gtk_stdout = false
EOF
ok "Config Howdy scritto (/dev/video0, YUYV, fps=30, timeout=3)"

# =============================================================================
# STEP 3 — PAM SDDM
# =============================================================================
info "Step 3/4: Configurazione PAM SDDM..."

sudo tee /etc/pam.d/sddm > /dev/null << 'EOF'
#%PAM-1.0

auth [success=done new_authtok_reqd=done default=ignore] pam_howdy.so
auth        include     system-login
-auth       optional    pam_gnome_keyring.so
-auth       optional    pam_kwallet5.so

account     include     system-login

password    include     system-login
-password   optional    pam_gnome_keyring.so    use_authtok

session     optional    pam_keyinit.so          force revoke
session     include     system-login
-session    optional    pam_gnome_keyring.so    auto_start
-session    optional    pam_kwallet5.so         auto_start
EOF
ok "PAM sddm configurato (pam_howdy.so primo)"

# =============================================================================
# STEP 4 — SDDM Input.qml Timer auto-login
# =============================================================================
info "Step 4/4: SDDM Input.qml — Timer auto-login..."

INPUT_QML="/usr/share/sddm/themes/simple_sddm_2/Components/Input.qml"

if [ ! -f "$INPUT_QML" ]; then
    warn "Tema simple_sddm_2 non trovato in $INPUT_QML"
    warn "Installa il tema SDDM e ri-esegui questo step"
else
    if grep -q "autoFaceLogin" "$INPUT_QML"; then
        warn "Timer autoFaceLogin già presente — skip"
    else
        sudo cp "$INPUT_QML" "${INPUT_QML}.bak"
        sudo python3 - "$INPUT_QML" << 'PYEOF'
import sys

path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

TIMER_BLOCK = '''
    Timer {
        id: autoFaceLogin
        interval: 50
        running: true
        repeat: false
        onTriggered: {
            var user = config.AllowUppercaseLettersInUsernames == "false" ? username.text.toLowerCase() : username.text
            sddm.login(user, "", sessionSelect.selectedSession)
        }
    }
'''

last_brace = content.rfind('}')
new_content = content[:last_brace] + TIMER_BLOCK + content[last_brace:]

with open(path, 'w') as f:
    f.write(new_content)

print("Timer autoFaceLogin aggiunto a Input.qml")
PYEOF
        ok "SDDM Input.qml modificato (Timer 50ms)"
    fi
fi

# =============================================================================
# Riepilogo finale
# =============================================================================
echo "" | tee -a "$LOG"
echo "============================================================" | tee -a "$LOG"
echo -e "${GREEN}  HOWDY COMPLETATO${NC}" | tee -a "$LOG"
echo "============================================================" | tee -a "$LOG"
echo "" | tee -a "$LOG"
echo "  [x] howdy-git installato" | tee -a "$LOG"
echo "  [x] Config Howdy (/dev/video0, YUYV, fps=30, timeout=3)" | tee -a "$LOG"
echo "  [x] PAM sddm (pam_howdy.so come primo metodo auth)" | tee -a "$LOG"
echo "  [x] SDDM Input.qml Timer 50ms (auto-login al boot)" | tee -a "$LOG"
echo "" | tee -a "$LOG"
echo "  Da fare manualmente:" | tee -a "$LOG"
echo "  [ ] sudo howdy add  (enrollment viso — guarda la webcam)" | tee -a "$LOG"
echo "  [ ] Riavvia e verifica auto-login SDDM" | tee -a "$LOG"
echo "" | tee -a "$LOG"
echo -e "${YELLOW}  NOTA: Il Timer da 50ms funziona bene. Se Howdy inizia${NC}" | tee -a "$LOG"
echo -e "${YELLOW}  a dare falsi negativi, aumentarlo a 250-500ms in Input.qml.${NC}" | tee -a "$LOG"
echo "" | tee -a "$LOG"

# Segnala a BiometricsSetup che la biometria è già configurata
mkdir -p "$HOME/.config/hypr"
touch "$HOME/.config/hypr/.biometrics_configured"

printf "\n%.0s" {1..2}
