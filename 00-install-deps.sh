#!/usr/bin/env bash
# STEP 0 — Installa Java, dipendenze di sistema e Xvfb
set -euo pipefail

source "$(dirname "$0")/config.env"

echo ">>> [00] Aggiornamento pacchetti di sistema..."
apt-get update -qq

echo ">>> [00] Installazione dipendenze..."
apt-get install -y -qq \
    openjdk-17-jdk \
    unzip \
    wget \
    curl \
    git \
    xvfb \
    libgl1-mesa-glx \
    libgles2-mesa \
    libgles2-mesa-dev \
    libpulse0 \
    libegl1-mesa \
    libnss3 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxi6 \
    libxtst6 \
    libxrandr2 \
    libasound2 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libgbm1 \
    libxss1 \
    libgtk-3-0 \
    socat \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients

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
