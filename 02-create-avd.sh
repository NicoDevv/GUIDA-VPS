#!/usr/bin/env bash
# STEP 2-4 — Crea il dispositivo virtuale Android (equivalente a Virtual Device Manager)
# Rinomina il device, sceglie API 33, imposta camera NONE, storage 12GB
set -euo pipefail

source "$(dirname "$0")/config.env"

export ANDROID_HOME="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"

echo ">>> [02] Eliminazione eventuale AVD esistente con lo stesso nome..."
avdmanager delete avd -n "$AVD_NAME" 2>/dev/null || true

echo ">>> [02] Creazione AVD: $AVD_NAME (API $API_LEVEL, x86_64)..."
echo "no" | avdmanager create avd \
    --name "$AVD_NAME" \
    --package "system-images;android-${API_LEVEL};google_apis;x86_64" \
    --device "pixel_6" \
    --force

echo ">>> [02] Configurazione AVD (camera NONE, storage ${STORAGE_GB}GB, RAM ${RAM_MB}MB)..."

AVD_CONFIG="$HOME/.android/avd/${AVD_NAME}.avd/config.ini"

# Aggiorna o aggiunge ogni impostazione
set_avd_prop() {
    local key="$1"
    local val="$2"
    if grep -q "^${key}=" "$AVD_CONFIG" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${val}|" "$AVD_CONFIG"
    else
        echo "${key}=${val}" >> "$AVD_CONFIG"
    fi
}

set_avd_prop "hw.camera.back"      "none"
set_avd_prop "hw.camera.front"     "none"
set_avd_prop "disk.dataPartition.size" "${STORAGE_GB}G"
set_avd_prop "hw.ramSize"          "$RAM_MB"
set_avd_prop "hw.gpu.enabled"      "yes"
set_avd_prop "hw.gpu.mode"         "swiftshader_indirect"
set_avd_prop "hw.keyboard"         "yes"
set_avd_prop "showDeviceFrame"     "no"

echo ">>> [02] Configurazione sensori virtuali (dati casuali)..."
# I dati casuali del sensore vengono impostati all'avvio tramite ADB (vedi 03-start-emulator.sh)

echo ""
echo "[02] COMPLETATO — AVD '$AVD_NAME' creato."
avdmanager list avd | grep -A5 "$AVD_NAME" || true
