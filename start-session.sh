#!/usr/bin/env bash
# Riavvia/ripristina l'intero ambiente (Xvfb, emulatore, x11vnc) dopo una
# disconnessione o un riavvio del server. Controlla cosa è già attivo e
# avvia solo quello che manca, senza wipe-data (preserva root/Magisk/spoof).
set -uo pipefail

source "$(dirname "$0")/config.env"

export ANDROID_HOME="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"
export DISPLAY="${DISPLAY_NUM}"

ADB="$ANDROID_HOME/platform-tools/adb"
EMULATOR_LOG="/tmp/emulator_${AVD_NAME}.log"

echo ">>> Abilitazione lingering (previene la morte dei processi alla disconnessione SSH)..."
loginctl enable-linger root 2>/dev/null || true

echo ">>> Verifica Xvfb..."
if pgrep -f "Xvfb ${DISPLAY_NUM}" > /dev/null; then
    echo "    Xvfb già attivo su ${DISPLAY_NUM}."
else
    echo "    Avvio Xvfb..."
    Xvfb "$DISPLAY_NUM" -screen 0 1920x1080x24 &
    disown
    sleep 2
fi

echo ">>> Verifica emulatore..."
if pgrep -f "qemu-system.*-avd ${AVD_NAME}" > /dev/null; then
    echo "    Emulatore '$AVD_NAME' già attivo."
else
    echo "    Avvio emulatore (nessun wipe-data, dati esistenti preservati)..."
    "$ANDROID_HOME/emulator/emulator" \
        -avd "$AVD_NAME" \
        -no-audio \
        -no-boot-anim \
        -gpu swiftshader_indirect \
        -memory "$RAM_MB" \
        > "$EMULATOR_LOG" 2>&1 &
    disown
fi

echo ">>> Verifica x11vnc..."
if pgrep -x x11vnc > /dev/null; then
    echo "    x11vnc già attivo."
else
    echo "    Avvio x11vnc su porta 5900 (solo localhost)..."
    x11vnc -display "$DISPLAY_NUM" -nopw -localhost -forever -bg -rfbport 5900 -o /tmp/x11vnc.log
fi

echo ""
echo ">>> Attesa boot dell'emulatore..."
"$ADB" wait-for-device
for i in $(seq 1 60); do
    BOOT_STATUS=$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || echo "")
    if [ "$BOOT_STATUS" = "1" ]; then
        echo "    Sistema pronto (${i}0s)."
        break
    fi
    echo -n "."
    sleep 10
done
echo ""

echo ">>> Stato finale:"
"$ADB" devices
ROOT_CHECK=$("$ADB" shell su -c whoami 2>/dev/null | tr -d '\r' || echo "")
MODEL=$("$ADB" shell getprop ro.product.model 2>/dev/null | tr -d '\r' || echo "")
echo "    Root:  $ROOT_CHECK"
echo "    Model: $MODEL"

if [ "$ROOT_CHECK" != "root" ]; then
    echo ""
    echo "    ATTENZIONE: root non attivo. Apri l'app Magisk (tab Superuser) via VNC"
    echo "    e riattiva il toggle [SharedUID] Shell."
fi

echo ""
echo ">>> Per ricollegarti via VNC dal tuo PC (PowerShell):"
echo "    ssh -L 5900:127.0.0.1:5900 root@$(curl -s -4 ifconfig.me 2>/dev/null || echo '<IP_SERVER>')"
echo "    Poi apri un client VNC su localhost:5900"
echo ""
echo ">>> Prima di disconnetterti, spegni pulito con: adb emu kill"
