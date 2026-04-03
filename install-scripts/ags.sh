#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Aylur's GTK Shell v 1.9.0 #
# per panoramica desktop

if [[ $USE_PRESET = [Yy] ]]; then
  source ./preset.sh
fi

ags=(
    typescript
    npm
    meson
    glib2-devel
    gjs 
    gtk3 
    gtk-layer-shell 
    upower
    networkmanager 
    gobject-introspection 
    libdbusmenu-gtk3 
    libsoup3
)

# tag specifici da scaricare
ags_tag="v1.9.0"

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

# Fallisci presto e fai fallire le pipeline se qualsiasi comando fallisce
set -eo pipefail

# Imposta il nome del file di log per includere la data e l'ora corrente
LOG="Install-Logs/install-$(date +%d-%H%M%S)_ags.log"
MLOG="install-$(date +%d-%H%M%S)_ags2.log"

# NOTA: Intenzionalmente NON eseguiamo `ags -v` qui, perché un'installazione AGS
# rotta (GUtils mancanti, ecc.) crasherebbe gjs e spamerebbe errori
# durante l'installazione. Reinstalliamo sempre v1.9.0 quando questo script viene eseguito.
# Installazione dei componenti principali
printf "\n%s - Installazione delle dipendenze di ${SKY_BLUE}Aylur's GTK shell $ags_tag${RESET} \n" "${NOTE}"

# Installazione delle dipendenze ags
for PKG1 in "${ags[@]}"; do
    install_package "$PKG1" "$LOG"
done

printf "\n%.0s" {1..1}

# ags v1
printf "${NOTE} Installazione e compilazione di ${SKY_BLUE}Aylur's GTK shell $ags_tag${RESET}..\n"

# Verifica se la directory esiste e rimuovila
if [ -d "ags_v1.9.0" ]; then
    printf "${NOTE} Rimozione della directory ags esistente...\n"
    rm -rf "ags_v1.9.0"
fi

printf "\n%.0s" {1..1}
printf "${INFO} Attendere...clonazione e compilazione di ${SKY_BLUE}Aylur's GTK shell $ags_tag${RESET}...\n"
printf "\n%.0s" {1..1}
# Clona il repository con il tag specificato e compila AGS
if git clone --depth=1 https://github.com/JaKooLit/ags_v1.9.0.git; then
    cd ags_v1.9.0 || exit 1

    # Patch tsconfig per evitare il fallimento TS5107 (deprecazione moduleResolution=node10)
    if [ -f tsconfig.json ]; then
        # 1) Assicurati che ignoreDeprecations sia presente
        if ! grep -q '"ignoreDeprecations"[[:space:]]*:' tsconfig.json; then
            sed -i 's/"compilerOptions":[[:space:]]*{/"compilerOptions": {\n    "ignoreDeprecations": "6.0",/' tsconfig.json
        fi
        # 2) Aumenta moduleResolution da node10 a node16 se presente
        if grep -q '"moduleResolution"[[:space:]]*:[[:space:]]*"node10"' tsconfig.json; then
            sed -i 's/"moduleResolution"[[:space:]]*:[[:space:]]*"node10"/"moduleResolution": "node16"/' tsconfig.json || true
        fi
        # 3) Fallback con Node per riscrivere JSON se sed non ha catturato i pattern
        if grep -q '"moduleResolution"[[:space:]]*:[[:space:]]*"node10"' tsconfig.json; then
            if command -v node >/dev/null 2>&1; then
                node -e '\n                const fs = require("fs");\n                const p = "tsconfig.json";\n                const j = JSON.parse(fs.readFileSync(p, "utf8"));\n                j.compilerOptions = j.compilerOptions || {};\n                if (j.compilerOptions.moduleResolution === "node10") j.compilerOptions.moduleResolution = "node16";\n                if (j.compilerOptions.ignoreDeprecations === undefined) j.compilerOptions.ignoreDeprecations = "6.0";\n                fs.writeFileSync(p, JSON.stringify(j, null, 2));\n                '
            fi
        fi
        # Registra cosa abbiamo ottenuto per la risoluzione dei problemi
        echo "== tsconfig.json dopo patch ==" >> "$MLOG"
        grep -n 'moduleResolution\|ignoreDeprecations' tsconfig.json >> "$MLOG" || true
    fi

    # Sostituisci pam.ts con uno stub che NON dipende affatto da GUtils.
    # La panoramica desktop non usa PAM, e il supporto typelib GUtils è
    # incoerente tra le distribuzioni, quindi disabilitiamo questi helper invece di
    # crashare all'avvio quando il typelib è mancante.
    if [ -f src/utils/pam.ts ]; then
        printf "%s Sostituzione di src/utils/pam.ts con stub PAM (nessuna dipendenza da GUtils)...\\n" "${NOTE}" | tee -a "$MLOG"
        cat > src/utils/pam.ts <<'PAM_STUB'
// Stubbed PAM auth per AGS installato via Arch-Hyprland.
// La panoramica desktop non usa PAM, e il supporto typelib GUtils
// è inaffidabile tra le distribuzioni, quindi disabilitiamo questi helper qui.

export function authenticate(password: string): Promise<number> {
    return Promise.reject(new Error("Autenticazione PAM disabilitata su questo sistema (nessun GUtils)"));
}

export function authenticateUser(username: string, password: string): Promise<number> {
    return Promise.reject(new Error("Autenticazione PAM disabilitata su questo sistema (nessun GUtils)"));
}
PAM_STUB
    fi

    npm install
    meson setup build
    if sudo meson install -C build 2>&1 | tee -a "$MLOG"; then
        printf "\n${OK} ${YELLOW}Aylur's GTK shell $ags_tag${RESET} installato con successo.\n" 2>&1 | tee -a "$MLOG"
    else
        echo -e "\n${ERROR} ${YELLOW}Installazione di Aylur's GTK shell $ags_tag${RESET} fallita\n " 2>&1 | tee -a "$MLOG"
        # Interrompi qui in caso di fallimento build/install in modo da NON installare un launcher rotto
        # o riportare successo quando i binari AGS sono mancanti.
        mv "$MLOG" ../Install-Logs/ || true
        cd ..
        exit 1
    fi

    LAUNCHER_DIR="/usr/local/share/com.github.Aylur.ags"
    LAUNCHER_PATH="$LAUNCHER_DIR/com.github.Aylur.ags"
    sudo mkdir -p "$LAUNCHER_DIR"

    # Installa il launcher conosciuto-buono che abbiamo catturato da un sistema funzionante.
    # Questo script di ingresso JS usa GLib per impostare GI_TYPELIB_PATH e non
    # dipende da GIRepository, che evita crash per typelib mancanti.
    LAUNCHER_SRC="$SCRIPT_DIR/ags.launcher.com.github.Aylur.ags"
    if [ -f "$LAUNCHER_SRC" ]; then
        sudo install -m 755 "$LAUNCHER_SRC" "$LAUNCHER_PATH"
    else
        printf "${WARN} Launcher salvato non trovato in %s; launcher installato da Meson lasciato intatto.\\n" "$LAUNCHER_SRC" | tee -a "$MLOG"
    fi

    # Assicurati che /usr/local/bin/ags punti allo script di ingresso JS.
    sudo mkdir -p /usr/local/bin
    sudo ln -srf "$LAUNCHER_PATH" /usr/local/bin/ags
    printf "${OK} Launcher AGS installato.\\n"
    # Sposta i log nella directory Install-Logs
    mv "$MLOG" ../Install-Logs/ || true
    cd ..
else
    echo -e "\n${ERROR} Scaricamento fallito di ${YELLOW}Aylur's GTK shell $ags_tag${RESET} Controlla la tua connessione\n" 2>&1 | tee -a "$LOG"
    mv "$MLOG" ../Install-Logs/ || true
    exit 1
fi

printf "\n%.0s" {1..2}
