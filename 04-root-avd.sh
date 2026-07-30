#!/usr/bin/env bash
# STEP 5-10 — Installa Magisk tramite rootAVD (equivalente agli step PowerShell nella guida)
# Questo è l'equivalente Linux di rootAVD.bat
set -euo pipefail

source "$(dirname "$0")/config.env"

export ANDROID_HOME="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"
export DISPLAY="${DISPLAY_NUM}"

ADB="$ANDROID_HOME/platform-tools/adb"

echo ">>> [04] Verifica emulatore attivo (equivalente: .\\adb.exe devices)..."
"$ADB" devices
DEVICE=$("$ADB" devices | grep -v "List" | grep "emulator" | awk '{print $1}' | head -1)

if [ -z "$DEVICE" ]; then
    echo "ERRORE: Nessun emulatore connesso. Esegui prima ./03-start-emulator.sh"
    exit 1
fi
echo "    Dispositivo: $DEVICE"

echo ">>> [04] Clonazione rootAVD (STEP 7 guida)..."
# Equivalente: git clone https://gitlab.com/newbit/rootAVD.git
if [ -d "$ROOTAVD_DIR" ]; then
    echo "    rootAVD già presente, aggiornamento..."
    git -C "$ROOTAVD_DIR" pull --ff-only 2>/dev/null || true
else
    git clone "$ROOTAVD_REPO" "$ROOTAVD_DIR"
fi

echo ">>> [04] Lista AVD disponibili (STEP 7A — .\rootAVD.bat listAllAvds)..."
cd "$ROOTAVD_DIR"
bash rootAVD.sh listAllAvds

echo ""
echo ">>> [04] Identificazione ramdisk per API $API_LEVEL..."
# Cerca il ramdisk dell'AVD creato (x86_64, API 33, google_apis)
RAMDISK=$(bash rootAVD.sh listAllAvds 2>/dev/null | grep -i "x86_64" | grep "${API_LEVEL}" | grep -i "google_apis" | head -1 | awk '{print $NF}')

if [ -z "$RAMDISK" ]; then
    echo "    ATTENZIONE: ramdisk non rilevato automaticamente."
    echo "    Output completo disponibili:"
    bash rootAVD.sh listAllAvds
    echo ""
    read -rp "Incolla qui il percorso ramdisk completo (es: system-images/android-33/google_apis/x86_64/ramdisk.img): " RAMDISK
fi

echo "    Ramdisk selezionato: $RAMDISK"

echo ""
echo ">>> [04] Avvio rooting (STEP 8-9 guida)..."
echo "    L'emulatore si SPEGNERÀ automaticamente — è normale."
echo "    Equivalente: ./<ramdisk_path>"
echo ""

bash rootAVD.sh "$RAMDISK"

echo ""
echo ">>> [04] Riavvio emulatore dopo installazione Magisk (STEP 10)..."
sleep 5

"$ANDROID_HOME/emulator/emulator" \
    -avd "$AVD_NAME" \
    -no-window \
    -no-audio \
    -no-boot-anim \
    -gpu swiftshader_indirect \
    -memory "$RAM_MB" \
    >> "/tmp/emulator_${AVD_NAME}.log" 2>&1 &

echo "    Attesa riavvio emulatore..."
for i in $(seq 1 60); do
    BOOT_STATUS=$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || echo "")
    if [ "$BOOT_STATUS" = "1" ]; then
        echo "    Emulatore riavviato (${i}0s)."
        break
    fi
    echo -n "."
    sleep 10
done
echo ""

echo ">>> [04] Verifica installazione Magisk..."
MAGISK_PKG=$("$ADB" shell pm list packages 2>/dev/null | grep -i magisk | head -1 || echo "")
if [ -n "$MAGISK_PKG" ]; then
    echo "    Magisk installato: $MAGISK_PKG"
else
    echo "    ATTENZIONE: Magisk non trovato nei pacchetti. Potrebbe richiedere setup aggiuntivo."
fi

echo ""
echo ">>> [04] REQUIRES ADDITIONAL SETUP — Magisk (STEP 10)..."
echo "    Gestione automatica setup aggiuntivo Magisk..."
sleep 10

# Tenta di accettare il setup aggiuntivo via input automatico
"$ADB" shell input tap 500 600 2>/dev/null || true
sleep 3

echo "    Attesa riavvio automatico VM dopo Magisk setup..."
sleep 30

for i in $(seq 1 30); do
    BOOT_STATUS=$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || echo "")
    if [ "$BOOT_STATUS" = "1" ]; then
        echo "    VM pronta dopo Magisk setup (${i}0s)."
        break
    fi
    echo -n "."
    sleep 10
done
echo ""

echo ""
echo "[04] COMPLETATO — Magisk installato e rootAVD completato."
echo "     Prossimo step: ./05-configure-magisk.sh"
