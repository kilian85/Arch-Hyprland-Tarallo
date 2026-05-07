#!/bin/bash
# 💫 https://github.com/kilian85 💫 #
# Fingerprint reader — ThinkPad T470  #
# Hardware: Validity Sensors 138a:0097 #

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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_fingerprint.log"

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
echo "  Fingerprint — ThinkPad T470 (138a:0097)" | tee -a "$LOG"
echo "  Utente: $CURRENT_USER" | tee -a "$LOG"
echo "============================================================" | tee -a "$LOG"
echo "" | tee -a "$LOG"

# =============================================================================
# STEP 1 — Pacchetti AUR
# =============================================================================
info "Step 1/6: Installazione pacchetti AUR..."

command -v yay &>/dev/null || { echo -e "${RED}[ERROR]${NC} yay non trovato."; exit 1; }
command -v innoextract &>/dev/null || { warn "innoextract mancante, installazione..."; sudo pacman -S --needed --noconfirm innoextract; }

yay -S --needed --noconfirm python-validity open-fprintd fprintd-clients 2>&1 | tee -a "$LOG"

sudo systemctl mask fprintd 2>&1 | tee -a "$LOG"
sudo systemctl enable python3-validity 2>&1 | tee -a "$LOG"
ok "Pacchetti installati, fprintd mascherato"

# =============================================================================
# STEP 2 — Firmware
# =============================================================================
info "Step 2/6: Download firmware sensore..."
sudo validity-sensors-firmware 2>&1 | tee -a "$LOG"
ok "Firmware scaricato"

# =============================================================================
# STEP 3 — Factory reset
# =============================================================================
info "Step 3/6: Factory reset sensore (stato corrotto 0401)..."

sudo systemctl stop python3-validity 2>/dev/null || true

sudo python3 - << 'PYSCRIPT'
from validitysensor.usb import usb
from validitysensor.sensor import factory_reset, RebootException

usb.open()
try:
    usb.send_init()
except Exception as e:
    print(f"send_init: {e} (atteso)")

try:
    factory_reset()
    print("factory_reset OK")
except RebootException:
    print("RebootException — sensore resettato correttamente")
PYSCRIPT

info "Attesa reboot sensore (3s)..."
sleep 3

sudo validity-sensors-firmware 2>&1 | tee -a "$LOG"
ok "Factory reset completato"

# =============================================================================
# STEP 4 — Udev + TLP
# =============================================================================
info "Step 4/6: Udev rule e TLP denylist (anti-autosuspend USB)..."

sudo tee /etc/udev/rules.d/90-fingerprint-autosuspend.rules > /dev/null << 'EOF'
ACTION=="add|change", SUBSYSTEM=="usb", ATTRS{idVendor}=="138a", ATTRS{idProduct}=="0097", TEST=="power/control", ATTR{power/control}="on", ATTR{power/persist}="1"
EOF
sudo udevadm control --reload-rules 2>&1 | tee -a "$LOG"

if [ -f /etc/tlp.conf ]; then
    if grep -q "^#*USB_DENYLIST=" /etc/tlp.conf; then
        sudo sed -i 's|^#*USB_DENYLIST=.*|USB_DENYLIST="138a:0097"|' /etc/tlp.conf
    else
        echo 'USB_DENYLIST="138a:0097"' | sudo tee -a /etc/tlp.conf > /dev/null
    fi
fi
ok "Udev rule e TLP configurati"

# =============================================================================
# STEP 5 — Patch sensor.py
# =============================================================================
info "Step 5/6: Patch sensor.py (gestione reboot USB durante enrollment)..."

SENSOR_PY=$(python3 -c "import validitysensor.sensor, inspect; print(inspect.getfile(validitysensor.sensor))" 2>/dev/null)
[ -z "$SENSOR_PY" ] && { echo -e "${RED}[ERROR]${NC} sensor.py non trovato."; exit 1; }

info "sensor.py: $SENSOR_PY"

if grep -q "_reconnect_needed" "$SENSOR_PY"; then
    warn "Patch già applicata — skip"
else
    sudo cp "$SENSOR_PY" "${SENSOR_PY}.bak"
    info "Backup: ${SENSOR_PY}.bak"

    PATCH_SCRIPT=$(mktemp /tmp/apply_patch_XXXXXX.py)
    cat > "$PATCH_SCRIPT" << 'PYEOF'
import sys, re

path = sys.argv[1]

with open(path, 'r') as f:
    lines = f.readlines()

start = None
end = None
for i, line in enumerate(lines):
    if re.match(r'    def enroll\(self,', line):
        start = i
    elif start is not None and i > start:
        if re.match(r'    def \w', line):
            end = i
            break

if start is None:
    print("ERROR: metodo enroll() non trovato")
    sys.exit(1)

if end is None:
    end = len(lines)

if '_reconnect_needed' in ''.join(lines[start:end]):
    print("Patch già presente")
    sys.exit(0)

PATCHED = '''    def enroll(self, identity: SidIdentity, subtype: int,
               update_cb: typing.Callable[[typing.Any, typing.Optional[Exception]], None]):
        def do_create_finger(final_template: bytes, tid: bytes):
            tinfo = self.make_finger_data(subtype, final_template, tid)

            usr = db.lookup_user(identity)
            if usr is None:
                usr = db.new_user(identity)
            else:
                usr = usr.dbid

            recid = db.new_finger(usr, tinfo)
            try:
                usb.wait_int()
                glow_end_scan()
            except usb_core.USBError:
                pass  # sensor may have rebooted after final scan; record is already saved
            return recid

        key = 0
        template = b\'\'
        self.create_enrollment()
        _reconnect_needed = False
        while True:
            _reconnect_needed = False
            try:
                glow_start_scan()
                self.capture(CaptureMode.ENROLL)
                key = self.enrollment_update_start(key)
                rsp = self.append_new_image(template)
                header, template, tid = rsp
                update_cb(header, None)
                if tid:
                    break

            except usb_core.USBError as e:
                if e.errno in (5, 19):
                    _reconnect_needed = True
                else:
                    raise e
            except CancelledException as e:
                glow_end_scan()
                raise e
            except Exception as e:
                print(e)
                update_cb(None, e)
            finally:
                try:
                    self.enrollment_update_end()
                except usb_core.USBError as e:
                    if e.errno in (5, 19):
                        _reconnect_needed = True

            if _reconnect_needed:
                logging.info(\'Sensor rebooted during enrollment, waiting to reconnect...\')
                sleep(5)
                for _attempt in range(30):
                    try:
                        from .init import open_common
                        usb.close()
                        tls.secure_rx = False
                        tls.secure_tx = False
                        sleep(0.5)
                        usb.open()
                        open_common()
                        break
                    except Exception as _re:
                        logging.debug(\'Reconnect attempt %d failed: %s\' % (_attempt, _re))
                        try:
                            usb.close()
                        except Exception:
                            pass
                        tls.secure_rx = False
                        tls.secure_tx = False
                        sleep(1)
                else:
                    raise Exception(\'Sensor did not reconnect after reboot\')
                key = 0
                template = b\'\'
                self.create_enrollment()
                logging.info(\'Sensor reconnected, resuming enrollment (sensor maintains flash state)\')

        try:
            self.enrollment_update_end()
        except usb_core.USBError as e:
            if e.errno != 19:
                raise e
            logging.info(\'Sensor rebooted after final enroll scan, reconnecting...\')
            sleep(5)
            tls.secure_rx = False
            tls.secure_tx = False
            try:
                usb.close()
            except Exception:
                pass
            usb.open()
            from .init import open_common
            open_common()
        return do_create_finger(template, tid)

'''

new_lines = lines[:start] + [PATCHED] + lines[end:]
with open(path, 'w') as f:
    f.writelines(new_lines)

print(f"Patch applicata con successo a {path}")
PYEOF

    sudo python3 "$PATCH_SCRIPT" "$SENSOR_PY" 2>&1 | tee -a "$LOG"
    rm -f "$PATCH_SCRIPT"
    ok "Patch sensor.py applicata"
fi

# =============================================================================
# STEP 6 — PAM + avvio servizio
# =============================================================================
info "Step 6/6: Configurazione PAM e avvio servizio..."

sudo tee /etc/pam.d/sudo > /dev/null << 'EOF'
#%PAM-1.0
auth		sufficient	pam_fprintd.so
auth		include		system-auth
account		include		system-auth
session		include		system-auth
EOF

sudo tee /etc/pam.d/hyprlock > /dev/null << 'EOF'
# PAM configuration file for hyprlock
auth        sufficient  pam_fprintd.so
auth        include     login
EOF

ok "PAM configurato (sudo, hyprlock)"

sudo systemctl start python3-validity 2>&1 | tee -a "$LOG"
sleep 2
ok "python3-validity avviato"

# =============================================================================
# Riepilogo finale
# =============================================================================
echo "" | tee -a "$LOG"
echo "============================================================" | tee -a "$LOG"
echo -e "${GREEN}  FINGERPRINT COMPLETATO${NC}" | tee -a "$LOG"
echo "============================================================" | tee -a "$LOG"
echo "" | tee -a "$LOG"
echo "  [x] python-validity + open-fprintd + fprintd-clients" | tee -a "$LOG"
echo "  [x] fprintd mascherato, python3-validity abilitato" | tee -a "$LOG"
echo "  [x] Firmware sensore scaricato" | tee -a "$LOG"
echo "  [x] Factory reset sensore" | tee -a "$LOG"
echo "  [x] Udev rule anti-autosuspend + TLP denylist" | tee -a "$LOG"
echo "  [x] Patch sensor.py (reconnect USB)" | tee -a "$LOG"
echo "  [x] PAM: sudo, hyprlock" | tee -a "$LOG"
echo "" | tee -a "$LOG"
echo "  Da fare manualmente:" | tee -a "$LOG"
echo "  [ ] fprintd-enroll -f right-index-finger $CURRENT_USER" | tee -a "$LOG"
echo "  [ ] fprintd-verify $CURRENT_USER" | tee -a "$LOG"
echo "" | tee -a "$LOG"
echo -e "${YELLOW}  NOTA: Se python-validity viene aggiornato, ri-esegui${NC}" | tee -a "$LOG"
echo -e "${YELLOW}  fingerprint.sh per riapplicare la patch sensor.py.${NC}" | tee -a "$LOG"
echo "" | tee -a "$LOG"

# Segnala a BiometricsSetup che la biometria è già configurata
mkdir -p "$HOME/.config/hypr"
touch "$HOME/.config/hypr/.biometrics_configured"

printf "\n%.0s" {1..2}
