#!/usr/bin/env bash
# STEP 4-5 — Avvia l'emulatore in modalità headless (no-window)
# Su VPS usiamo Xvfb come display virtuale invece di un monitor fisico
set -euo pipefail

source "$(dirname "$0")/config.env"

export ANDROID_HOME="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"

EMULATOR_LOG="/tmp/emulator_${AVD_NAME}.log"

echo ">>> [03] Avvio display virtuale Xvfb su $DISPLAY_NUM..."
pkill Xvfb 2>/dev/null || true
Xvfb "$DISPLAY_NUM" -screen 0 1280x720x24 &
XVFB_PID=$!
export DISPLAY="$DISPLAY_NUM"
sleep 2

echo ">>> [03] Avvio emulatore Android AVD: $AVD_NAME su display virtuale $DISPLAY_NUM..."
pkill -f "emulator.*$AVD_NAME" 2>/dev/null || true
sleep 1

# NON usiamo -no-window: la UI dell'emulatore deve renderizzare sul display
# Xvfb virtuale, così è visibile via VNC per gli step che richiedono
# interazione manuale (Grant root, setup Magisk, ecc). Il tutto resta comunque
# "headless" nel senso che non serve un monitor fisico: Xvfb è invisibile
# finché non ci si collega con un client VNC.
"$ANDROID_HOME/emulator/emulator" \
    -avd "$AVD_NAME" \
    -no-audio \
    -no-boot-anim \
    -gpu swiftshader_indirect \
    -memory "$RAM_MB" \
    -wipe-data \
    > "$EMULATOR_LOG" 2>&1 &

EMULATOR_PID=$!
echo "    Emulatore PID: $EMULATOR_PID — Log: $EMULATOR_LOG"

echo ">>> [03] Attesa avvio completo (può richiedere 2-3 minuti)..."
ADB="$ANDROID_HOME/platform-tools/adb"

for i in $(seq 1 60); do
    BOOT_STATUS=$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || echo "")
    if [ "$BOOT_STATUS" = "1" ]; then
        echo "    Emulatore avviato correttamente (attesa ${i}0s)."
        break
    fi
    echo -n "."
    sleep 10
done
echo ""

if [ "$BOOT_STATUS" != "1" ]; then
    echo "ERRORE: L'emulatore non si è avviato in tempo."
    echo "Controlla il log: $EMULATOR_LOG"
    exit 1
fi

echo ">>> [03] Verifica connessione ADB..."
"$ADB" devices

echo ">>> [03] Impostazione dati sensori casuali (STEP 4 guida)..."
# Battery level casuale
BATTERY_LEVEL=$((RANDOM % 40 + 60))
"$ADB" shell dumpsys battery set level "$BATTERY_LEVEL" 2>/dev/null || true

echo "    Livello batteria impostato: ${BATTERY_LEVEL}%"
echo ""
echo "[03] COMPLETATO — Emulatore attivo su DISPLAY=$DISPLAY_NUM"
echo "     Prossimo step: ./04-root-avd.sh"
