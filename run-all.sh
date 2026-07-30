#!/usr/bin/env bash
# Script master — esegue l'intera guida dall'inizio alla fine
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.env"

log() { echo ""; echo "=== $* ==="; echo ""; }

log "INIZIO SETUP ANDROID VPS"
echo "Configurazione:"
echo "  AVD: $AVD_NAME  |  API: $API_LEVEL  |  RAM: ${RAM_MB}MB  |  Storage: ${STORAGE_GB}GB"
echo "  Spoof: Google $SPOOF_DEVICE"
echo ""

log "STEP 0 — Dipendenze di sistema"
bash "$SCRIPT_DIR/00-install-deps.sh"

log "STEP 1 — Android SDK"
bash "$SCRIPT_DIR/01-setup-android-sdk.sh"
source /etc/profile.d/android-sdk.sh

log "STEP 2 — Creazione AVD"
bash "$SCRIPT_DIR/02-create-avd.sh"

log "STEP 3 — Avvio emulatore"
bash "$SCRIPT_DIR/03-start-emulator.sh"

log "STEP 4 — Rooting con Magisk (rootAVD)"
bash "$SCRIPT_DIR/04-root-avd.sh"

log "STEP 5 — Configurazione Magisk (Zygisk + DenyList)"
bash "$SCRIPT_DIR/05-configure-magisk.sh"

log "STEP 6 — Installazione HideMagiskSpoof"
bash "$SCRIPT_DIR/06-install-spoof.sh"

log "STEP 7 — Hardware Spoof (Google Pixel 6)"
bash "$SCRIPT_DIR/07-props-spoof.sh"

echo ""
echo "============================================"
echo " SETUP VPS COMPLETATO"
echo "============================================"
