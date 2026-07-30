#!/usr/bin/env bash
# STEP 0 — Installa Java, dipendenze di sistema e Xvfb
set -euo pipefail

source "$(dirname "$0")/config.env"

echo ">>> [00] Aggiornamento pacchetti di sistema..."
apt-get update -qq

echo ">>> [00] Installazione dipendenze..."
# I nomi dei pacchetti mesa/audio/gtk cambiano tra le versioni Ubuntu
# (es. rinominati con suffisso t64 dalla 24.04 in poi). Per ogni pacchetto
# proviamo prima il nome moderno, poi la variante t64 come fallback.
PACKAGES=(
    openjdk-17-jdk
    unzip
    wget
    curl
    git
    xvfb
    libgl1
    libgles2
    libpulse0
    libegl1
    libnss3
    libxcomposite1
    libxcursor1
    libxdamage1
    libxi6
    libxtst6
    libxrandr2
    libasound2
    libatk1.0-0
    libatk-bridge2.0-0
    libcups2
    libdrm2
    libgbm1
    libxss1
    libgtk-3-0
    socat
    qemu-kvm
    libvirt-daemon-system
    libvirt-clients
)

for pkg in "${PACKAGES[@]}"; do
    if apt-get install -y -qq "$pkg" > /dev/null 2>&1; then
        continue
    elif apt-get install -y -qq "${pkg}t64" > /dev/null 2>&1; then
        echo "    (usato ${pkg}t64 al posto di ${pkg})"
    else
        echo "    ATTENZIONE: impossibile installare ${pkg} (né ${pkg}t64)"
    fi
done

echo ">>> [00] Verifica KVM (accelerazione hardware)..."
if grep -q -E "(vmx|svm)" /proc/cpuinfo; then
    echo "    KVM supportato."
    modprobe kvm || true
    modprobe kvm_intel || modprobe kvm_amd || true
    # Permessi /dev/kvm
    if [ -e /dev/kvm ]; then
        chmod 666 /dev/kvm
        echo "    /dev/kvm accessibile."
    fi
else
    echo "    ATTENZIONE: KVM non supportato. L'emulatore userà software rendering (più lento)."
fi

echo ">>> [00] Verifica Java..."
java -version

echo ""
echo "[00] COMPLETATO — Dipendenze installate."
