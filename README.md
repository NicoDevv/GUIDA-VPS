# Android Emulator Rootato su VPS (Linux Headless)

Questa guida adatta l'installazione di un emulatore Android rootato con Magisk e hardware spoofing per una **VPS Linux headless** (senza interfaccia grafica).

## Prerequisiti

- VPS con Ubuntu 20.04+ / Debian 11+ (minimo 4 GB RAM, 30 GB disco)
- Accesso root o sudo
- Connessione internet

## Struttura degli script

| Script | Descrizione |
|--------|-------------|
| `00-install-deps.sh` | Installa Java, dipendenze di sistema |
| `01-setup-android-sdk.sh` | Scarica e configura Android SDK command-line tools |
| `02-create-avd.sh` | Crea il dispositivo virtuale Android (API 33) |
| `03-start-emulator.sh` | Avvia l'emulatore in modalità headless |
| `04-root-avd.sh` | Clona rootAVD e installa Magisk |
| `05-configure-magisk.sh` | Abilita Zygisk e DenyList tramite ADB |
| `06-install-spoof.sh` | Installa il modulo HideMagiskSpoof |
| `07-props-spoof.sh` | Configura lo spoofing hardware (Pixel 6) |
| `run-all.sh` | Script master che esegue tutto in sequenza |

## Utilizzo rapido

```bash
chmod +x *.sh
./run-all.sh
```

Oppure passo per passo:

```bash
./00-install-deps.sh
./01-setup-android-sdk.sh
source ~/.bashrc
./02-create-avd.sh
./03-start-emulator.sh   # avvia in background
./04-root-avd.sh
# Riavvia emulatore dopo l'installazione di Magisk
./05-configure-magisk.sh
./06-install-spoof.sh
./07-props-spoof.sh
```

## Corrispondenza con la guida originale

| Step guida (Windows) | Equivalente VPS |
|----------------------|-----------------|
| Android Studio → Virtual Device Manager | `avdmanager` da CLI |
| Avvio VM da Android Studio | `emulator -avd ... -no-window` |
| PowerShell → platform-tools | ADB disponibile direttamente |
| `.\adb.exe devices` | `adb devices` |
| `.\adb.exe shell` | `adb shell` |
| rootAVD.bat | `rootAVD.sh` (versione Linux) |
| Xvfb | Display virtuale per l'emulatore |

## Note importanti

- L'emulatore gira su display virtuale (`:99`) tramite Xvfb
- Il dispositivo viene configurato come **Google Pixel 6** (fingerprint + hardware)
- Durante il rooting la VM si spegne automaticamente — è normale
- Dopo `su` nell'ADB shell, l'emulatore chiederà GRANT: usa `adb shell su -c "..."` per automatizzare
- **NON modificare** `ro.build.version.sdk` (rimane DISABLED)

## Variabili configurabili

Nel file `config.env`:

```bash
AVD_NAME="VPS_Device"
API_LEVEL="33"
RAM_MB="2048"
STORAGE_GB="12"
SPOOF_DEVICE="Pixel 6"
```
