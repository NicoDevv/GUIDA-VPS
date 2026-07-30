#!/usr/bin/env bash
# STEP 12-13 — Scarica e installa il modulo HideMagiskSpoof
# Equivalente: trascinare lo ZIP nel file manager VM → Modules → Install from storage → Reboot
set -euo pipefail

source "$(dirname "$0")/config.env"

export ANDROID_HOME="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"
export DISPLAY="${DISPLAY_NUM}"

ADB="$ANDROID_HOME/platform-tools/adb"
ZIP_LOCAL="/tmp/$SPOOF_MODULE_ZIP"

echo ">>> [06] Download modulo HideMagiskSpoof (STEP 12 guida)..."
if [ ! -f "$ZIP_LOCAL" ]; then
    wget -q --show-progress "$SPOOF_MODULE_URL" -O "$ZIP_LOCAL"
else
    echo "    Modulo già presente: $ZIP_LOCAL"
fi

echo ">>> [06] Verifica emulatore..."
"$ADB" devices
DEVICE=$("$ADB" devices | grep -v "List" | grep "emulator" | awk '{print $1}' | head -1)
if [ -z "$DEVICE" ]; then
    echo "ERRORE: Nessun emulatore connesso."
    exit 1
fi

echo ">>> [06] Upload modulo ZIP sull'emulatore..."
"$ADB" push "$ZIP_LOCAL" /sdcard/"$SPOOF_MODULE_ZIP"
echo "    Uploaded: /sdcard/$SPOOF_MODULE_ZIP"

echo ">>> [06] Installazione modulo via Magisk (STEP 13 guida)..."
# Installa il modulo Magisk dallo storage locale
"$ADB" shell su -c "magisk --install-module /sdcard/$SPOOF_MODULE_ZIP" 2>/dev/null \
    && echo "    Modulo installato tramite magisk CLI." \
    || {
        echo "    Tentativo installazione alternativa..."
        # Metodo alternativo: copia nella directory moduli
        "$ADB" shell su -c "
            TMPDIR=/data/local/tmp/magisk_install
            mkdir -p \$TMPDIR
            unzip -o /sdcard/$SPOOF_MODULE_ZIP -d \$TMPDIR
            MODULE_ID=\$(cat \$TMPDIR/module.prop 2>/dev/null | grep '^id=' | cut -d= -f2)
            if [ -n \"\$MODULE_ID\" ]; then
                cp -r \$TMPDIR /data/adb/modules/\$MODULE_ID
                echo done > /data/adb/modules/\$MODULE_ID/update
                echo \"Modulo installato: \$MODULE_ID\"
            fi
            rm -rf \$TMPDIR
        " 2>/dev/null || echo "    AVVISO: installazione manuale potrebbe essere necessaria."
    }

echo ">>> [06] Riavvio emulatore (STEP 13 — Reboot)..."
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

echo ">>> [06] Verifica modulo installato..."
"$ADB" shell su -c "ls /data/adb/modules/" 2>/dev/null || echo "    (verifica manuale necessaria)"

echo ""
echo "[06] COMPLETATO — HideMagiskSpoof installato."
echo "     Prossimo step: ./07-props-spoof.sh"
