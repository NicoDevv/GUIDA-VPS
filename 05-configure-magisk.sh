#!/usr/bin/env bash
# STEP 11-12 — Entra nella shell ADB, verifica root, abilita Zygisk e DenyList in Magisk
# Equivalente STEP 11 guida: .\adb.exe shell, whoami, su, Grant
set -euo pipefail

source "$(dirname "$0")/config.env"

export ANDROID_HOME="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"
export DISPLAY="${DISPLAY_NUM}"

ADB="$ANDROID_HOME/platform-tools/adb"

echo ">>> [05] Riavvio server ADB (STEP 11 guida)..."
"$ADB" kill-server
sleep 2
"$ADB" start-server
sleep 2

echo ">>> [05] Verifica dispositivi (.\adb.exe devices)..."
"$ADB" devices

DEVICE=$("$ADB" devices | grep -v "List" | grep "emulator" | awk '{print $1}' | head -1)
if [ -z "$DEVICE" ]; then
    echo "ERRORE: Nessun emulatore connesso."
    exit 1
fi

echo ">>> [05] Verifica shell e root (.\adb.exe shell, whoami, su)..."
echo "    whoami (atteso: shell):"
"$ADB" shell whoami 2>/dev/null || echo "    (non disponibile)"

echo "    Test root (su -c whoami — atteso: root):"
ROOT_CHECK=$("$ADB" shell su -c whoami 2>/dev/null | tr -d '\r' || echo "")
if [ "$ROOT_CHECK" = "root" ]; then
    echo "    Root confermato!"
else
    echo "    ATTENZIONE: Root non confermato (output: '$ROOT_CHECK')"
    echo "    Se l'emulatore chiede GRANT/DENY, accetta dalla finestra VNC/display."
fi

echo ">>> [05] Abilitazione Zygisk in Magisk (STEP 12 guida)..."
# Zygisk è impostato tramite shared preferences di Magisk
"$ADB" shell su -c "
    MAGISK_DB=/data/adb/magisk.db
    sqlite3 \$MAGISK_DB 'REPLACE INTO settings (key, value) VALUES (\"zygisk\", 1);' 2>/dev/null || true
" 2>/dev/null || echo "    (tentativo tramite DB — potrebbe richiedere riavvio)"

# Metodo alternativo via magisk command
"$ADB" shell su -c "magisk --sqlite 'REPLACE INTO settings (key, value) VALUES (\"zygisk\", 1)'" 2>/dev/null \
    && echo "    Zygisk abilitato via magisk CLI." \
    || echo "    (Zygisk da abilitare manualmente nelle Impostazioni Magisk)"

echo ">>> [05] Abilitazione Enforce DenyList..."
"$ADB" shell su -c "magisk --sqlite 'REPLACE INTO settings (key, value) VALUES (\"denylist\", 1)'" 2>/dev/null \
    && echo "    DenyList abilitato." \
    || echo "    (DenyList da abilitare manualmente)"

echo ">>> [05] Riavvio per applicare Zygisk..."
"$ADB" reboot
sleep 5

echo "    Attesa riavvio..."
for i in $(seq 1 60); do
    BOOT_STATUS=$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || echo "")
    if [ "$BOOT_STATUS" = "1" ]; then
        echo "    Riavviato (${i}0s)."
        break
    fi
    echo -n "."
    sleep 10
done
echo ""

echo ""
echo "[05] COMPLETATO — Zygisk e DenyList configurati."
echo "     Prossimo step: ./06-install-spoof.sh"
