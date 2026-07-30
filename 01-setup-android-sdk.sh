#!/usr/bin/env bash
# STEP 1 — Scarica e configura Android SDK command-line tools
# Equivalente a installare Android Studio e configurare platform-tools
set -euo pipefail

source "$(dirname "$0")/config.env"

echo ">>> [01] Scaricamento Android SDK command-line tools..."
mkdir -p "$ANDROID_HOME/cmdline-tools"
cd /tmp

if [ ! -f "cmdline-tools.zip" ]; then
    wget -q --show-progress "$CMDLINE_TOOLS_URL" -O cmdline-tools.zip
fi

echo ">>> [01] Estrazione..."
unzip -q -o cmdline-tools.zip -d "$ANDROID_HOME/cmdline-tools"
mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest" 2>/dev/null || true

echo ">>> [01] Configurazione variabili d'ambiente..."
cat > /etc/profile.d/android-sdk.sh << ENVEOF
export ANDROID_HOME="$ANDROID_HOME"
export PATH="\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/emulator"
ENVEOF

export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"

# Aggiunge anche al .bashrc dell'utente corrente
if ! grep -q "ANDROID_HOME" "$HOME/.bashrc" 2>/dev/null; then
    echo 'source /etc/profile.d/android-sdk.sh' >> "$HOME/.bashrc"
fi

echo ">>> [01] Accettazione licenze SDK..."
yes | sdkmanager --licenses > /dev/null 2>&1 || true

echo ">>> [01] Installazione platform-tools, emulator, e system image API ${API_LEVEL}..."
sdkmanager --install \
    "platform-tools" \
    "emulator" \
    "platforms;android-${API_LEVEL}" \
    "system-images;android-${API_LEVEL};google_apis;x86_64" \
    --channel=0

echo ">>> [01] Verifica adb..."
"$ANDROID_HOME/platform-tools/adb" version

echo ""
echo "[01] COMPLETATO — Android SDK configurato in $ANDROID_HOME"
echo "     Esegui: source /etc/profile.d/android-sdk.sh"
