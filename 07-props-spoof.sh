#!/usr/bin/env bash
# STEP 14 — Configura lo spoofing hardware tramite MagiskHidePropsConf (comando props)
# IMPORTANTE: NON modificare ro.build.version.sdk (deve rimanere DISABLED)
# Dispositivo target: Google Pixel 6
set -euo pipefail

source "$(dirname "$0")/config.env"

export ANDROID_HOME="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"
export DISPLAY="${DISPLAY_NUM}"

ADB="$ANDROID_HOME/platform-tools/adb"

# Props Google Pixel 6 (fingerprint ufficiale)
PIXEL6_FINGERPRINT="google/oriole/oriole:13/TQ3A.230901.001/10750268:user/release-keys"
PIXEL6_MANUFACTURER="Google"
PIXEL6_BRAND="google"
PIXEL6_MODEL="Pixel 6"
PIXEL6_DEVICE="oriole"
PIXEL6_PRODUCT="oriole"
PIXEL6_BOARD="oriole"
PIXEL6_HARDWARE="oriole"

echo ">>> [07] Verifica emulatore attivo (STEP 14 guida)..."
"$ADB" devices
DEVICE=$("$ADB" devices | grep -v "List" | grep "emulator" | awk '{print $1}' | head -1)
if [ -z "$DEVICE" ]; then
    echo "ERRORE: Nessun emulatore connesso."
    exit 1
fi

echo ">>> [07] Configurazione props Hardware Spoof — Google $SPOOF_DEVICE..."
echo "    NOTA: ro.build.version.sdk NON viene modificato (rimane DISABLED)"

"$ADB" shell su -c "
    # Verifica che props sia disponibile (MagiskHidePropsConf)
    if ! command -v props > /dev/null 2>&1; then
        echo 'props non trovato nel PATH, uso percorso diretto...'
        PROPS_CMD='/data/adb/modules/MagiskHidePropsConf/system/bin/props'
    else
        PROPS_CMD='props'
    fi

    # Imposta manualmente le system properties tramite resetprop
    # (equivalente alla selezione nel menu props → Device simulation)

    resetprop ro.product.manufacturer '$PIXEL6_MANUFACTURER'
    resetprop ro.product.brand        '$PIXEL6_BRAND'
    resetprop ro.product.model        '$PIXEL6_MODEL'
    resetprop ro.product.device       '$PIXEL6_DEVICE'
    resetprop ro.product.name         '$PIXEL6_PRODUCT'
    resetprop ro.product.board        '$PIXEL6_BOARD'
    resetprop ro.hardware             '$PIXEL6_HARDWARE'
    resetprop ro.build.fingerprint    '$PIXEL6_FINGERPRINT'
    resetprop ro.build.description    'oriole-user 13 TQ3A.230901.001 10750268 release-keys'
    resetprop ro.bootimage.build.fingerprint '$PIXEL6_FINGERPRINT'
    resetprop ro.vendor.build.fingerprint    '$PIXEL6_FINGERPRINT'
    resetprop ro.system.build.fingerprint    '$PIXEL6_FINGERPRINT'

    echo 'Props hardware impostati.'
    echo ''
    echo 'Verifica props attivi:'
    getprop ro.product.model
    getprop ro.product.manufacturer
    getprop ro.build.fingerprint
" 2>/dev/null

echo ">>> [07] Salvataggio props permanente tramite MagiskHidePropsConf..."
# Salva le props nel file di configurazione del modulo per persistenza dopo riavvio
"$ADB" shell su -c "
    PROPS_FILE='/data/adb/modules/MagiskHidePropsConf/system/etc/props.conf'
    mkdir -p \$(dirname \$PROPS_FILE) 2>/dev/null || true

    # Scrivi file props persistente
    cat > /data/adb/magisk_files/propsconf_custom << 'PROPSEOF'
ro.product.manufacturer=$PIXEL6_MANUFACTURER
ro.product.brand=$PIXEL6_BRAND
ro.product.model=$PIXEL6_MODEL
ro.product.device=$PIXEL6_DEVICE
ro.product.name=$PIXEL6_PRODUCT
ro.product.board=$PIXEL6_BOARD
ro.hardware=$PIXEL6_HARDWARE
ro.build.fingerprint=$PIXEL6_FINGERPRINT
ro.build.description=oriole-user 13 TQ3A.230901.001 10750268 release-keys
PROPSEOF
    echo 'Configurazione props salvata.'
" 2>/dev/null || echo "    (salvataggio permanente opzionale — props attivi per questa sessione)"

echo ">>> [07] Verifica finale props dall'esterno (adb shell getprop)..."
echo ""
echo "  Model:        $("$ADB" shell getprop ro.product.model 2>/dev/null | tr -d '\r')"
echo "  Manufacturer: $("$ADB" shell getprop ro.product.manufacturer 2>/dev/null | tr -d '\r')"
echo "  Fingerprint:  $("$ADB" shell getprop ro.build.fingerprint 2>/dev/null | tr -d '\r')"
echo "  SDK (DEVE rimanere 33): $("$ADB" shell getprop ro.build.version.sdk 2>/dev/null | tr -d '\r')"
echo ""

echo ">>> [07] Riavvio finale per consolidare tutte le modifiche..."
"$ADB" reboot
sleep 5

echo "    Attesa riavvio finale..."
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

echo ">>> [07] Verifica props dopo riavvio..."
echo "  Model:        $("$ADB" shell getprop ro.product.model 2>/dev/null | tr -d '\r')"
echo "  Fingerprint:  $("$ADB" shell getprop ro.build.fingerprint 2>/dev/null | tr -d '\r')"

echo ""
echo "[07] COMPLETATO — Hardware spoof configurato come Google $SPOOF_DEVICE"
echo ""
echo "============================="
echo " SETUP COMPLETATO AL 100%"
echo "============================="
echo ""
echo " Dispositivo virtuale: $AVD_NAME"
echo " Spoof hardware:       Google $SPOOF_DEVICE"
echo " Magisk:               Installato e rootato"
echo " Zygisk:               Abilitato"
echo " DenyList:             Abilitato"
echo " HideMagiskSpoof:      Installato"
echo ""
echo " Per verificare: installa 'Device Info HW' sull'emulatore"
echo "   adb install <device-info-hw.apk>"
echo ""
