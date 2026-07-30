#!/usr/bin/env bash
# STEP 14 — Configura lo spoofing hardware tramite MagiskHidePropsConf (comando props)
# IMPORTANTE: NON modificare ro.build.version.sdk (deve rimanere DISABLED)
# Dispositivo target: Google Pixel 6
#
# Il tool "props" del modulo MagiskHidePropsConf è un menu interattivo — non è
# automatizzabile in modo affidabile in modalità non interattiva (testato: sia
# resetprop diretto che l'input piped tramite adb shell producono risultati
# inconsistenti/silenziosamente falliti). Questo script quindi guida l'utente
# attraverso i passaggi esatti da eseguire a mano via `adb shell`, poi verifica
# il risultato reale invece di assumere che sia andato a buon fine.
set -euo pipefail

source "$(dirname "$0")/config.env"

export ANDROID_HOME="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"
export DISPLAY="${DISPLAY_NUM}"

ADB="$ANDROID_HOME/platform-tools/adb"

echo ">>> [07] Verifica emulatore attivo e root..."
"$ADB" devices
DEVICE=$("$ADB" devices | grep -v "List" | grep "emulator" | awk '{print $1}' | head -1)
if [ -z "$DEVICE" ]; then
    echo "ERRORE: Nessun emulatore connesso."
    exit 1
fi

ROOT_CHECK=$("$ADB" shell su -c whoami 2>/dev/null | tr -d '\r' || echo "")
if [ "$ROOT_CHECK" != "root" ]; then
    echo "ERRORE: Root non attivo (su -c whoami ha restituito '$ROOT_CHECK')."
    echo "Vai nell'app Magisk -> tab Superuser -> attiva il toggle per [SharedUID] Shell,"
    echo "poi rilancia questo script."
    exit 1
fi

cat << 'EOF'

=====================================================================
 STEP 14 — Configurazione manuale spoof hardware (Google Pixel 6)
=====================================================================

Apri una shell root sul device ed esegui il tool "props":

    adb shell
    su
    props

Segui questa sequenza esatta (un'opzione alla volta, invio dopo ognuna):

  1. Nel menu principale:            1        (Edit device fingerprint)
  2.                                 f        (Pick a certified fingerprint)
  3.                                 7        (Google)
  4.                                 28       (Google Pixel 6)
  5. Conferma:                       y
  6. NON riavviare ancora:           n
  7. Torna al menu principale:       b  (ripeti "b" finché non vedi
                                          "Select an option below" con
                                          "1 - Edit device fingerprint (active)")
  8. Entra in Device simulation:     3
  9. Attiva il toggle principale:    s
 10. Conferma:                       y
 11. NON riavviare ancora:           n
 12. Abilita, UNA ALLA VOLTA, confermando "y" e poi "n" (non riavviare)
     dopo ognuna, le seguenti opzioni:

         1  2  3  4  5  6  8  9  10

     *** NON TOCCARE MAI L'OPZIONE 7 (ro.build.version.sdk) ***
     *** Deve restare "disabled", altrimenti la VM si rompe  ***

 13. Quando tutte le opzioni 1,2,3,4,5,6,8,9,10 risultano "(enabled)"
     e la 7 risulta ancora "(disabled)": torna al menu principale con "b"
 14. Riavvia dal menu principale:    b        (Reboot device)
 15. Conferma:                       y

=====================================================================
EOF

read -rp "Premi INVIO quando hai completato tutti i passaggi sopra e il device si è riavviato... " _

echo ""
echo ">>> [07] Attesa boot completo..."
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

echo ">>> [07] Verifica reale dei props (nessuna assunzione di successo)..."
MODEL=$("$ADB" shell getprop ro.product.model 2>/dev/null | tr -d '\r')
MANUFACTURER=$("$ADB" shell getprop ro.product.manufacturer 2>/dev/null | tr -d '\r')
FINGERPRINT=$("$ADB" shell getprop ro.build.fingerprint 2>/dev/null | tr -d '\r')
SDK=$("$ADB" shell getprop ro.build.version.sdk 2>/dev/null | tr -d '\r')

echo ""
echo "  Model:        $MODEL"
echo "  Manufacturer: $MANUFACTURER"
echo "  Fingerprint:  $FINGERPRINT"
echo "  SDK:          $SDK"
echo ""

if [ "$MODEL" = "Pixel 6" ] && [ "$SDK" = "$API_LEVEL" ]; then
    echo "[07] COMPLETATO — Hardware spoof confermato: Google Pixel 6, SDK $API_LEVEL intatto."
else
    echo "[07] ATTENZIONE — I valori non corrispondono a quanto atteso."
    echo "     Model atteso 'Pixel 6', SDK atteso '$API_LEVEL'."
    echo "     Ripeti i passaggi manuali sopra oppure verifica via VNC nell'app Magisk."
    exit 1
fi

echo ""
echo "============================="
echo " SETUP COMPLETATO"
echo "============================="
echo ""
echo " Dispositivo virtuale: $AVD_NAME"
echo " Spoof hardware:       Google $SPOOF_DEVICE"
echo " Magisk:               Installato e rootato"
echo " Zygisk / DenyList:    Verifica manuale in Settings -> Magisk"
echo ""
echo " Per verificare visivamente: installa un'app tipo 'Device Info HW' sull'emulatore"
echo "   adb install <device-info-hw.apk>"
echo ""
