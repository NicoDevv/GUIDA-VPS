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

## Prima di iniziare: previeni la perdita di dati

Il processo dell'emulatore (e Xvfb/x11vnc) vengono uccisi da systemd quando la
sessione SSH si disconnette, a meno che tu non abiliti il "lingering":

```bash
loginctl enable-linger root
```

Fallo **subito**, prima di lanciare qualunque script — altrimenti una
disconnessione SSH improvvisa può corrompere/perdere le scritture recenti sul
disco virtuale di Android (impostazioni Magisk, modulo spoof, ecc), come
successo più volte durante lo sviluppo di questa guida.

## Utilizzo rapido

```bash
loginctl enable-linger root
chmod +x *.sh
./run-all.sh
```

`run-all.sh` esegue in automatico gli step 00-06. Lo **step 07 richiede
interazione manuale** (vedi sotto) perché il tool `props` del modulo
MagiskHidePropsConf è un menu interattivo non affidabilmente automatizzabile.

Oppure passo per passo:

```bash
./00-install-deps.sh
./01-setup-android-sdk.sh
source /etc/profile.d/android-sdk.sh
./02-create-avd.sh
./03-start-emulator.sh   # avvia in background
./04-root-avd.sh
./05-configure-magisk.sh
./06-install-spoof.sh
./07-props-spoof.sh      # ti guida passo-passo, richiede VNC (vedi sotto)
```

## Accesso visivo (VNC) — necessario per alcuni step

Alcuni passaggi (concedere il permesso di root la prima volta, completare il
setup di Magisk, il menu `props`) richiedono un'interazione visiva con lo
schermo dell'emulatore — non sono automatizzabili alla cieca via ADB.

```bash
apt install -y x11vnc
x11vnc -display :99 -nopw -localhost -forever -bg -rfbport 5900
```

Poi apri un tunnel SSH dal tuo computer:

```bash
ssh -L 5900:127.0.0.1:5900 root@<IP_DEL_TUO_SERVER>
```

E connettiti con un client VNC (es. TigerVNC, RealVNC Viewer) a `localhost:5900`.

## Corrispondenza con la guida originale

| Step guida (Windows) | Equivalente VPS |
|----------------------|-----------------|
| Android Studio → Virtual Device Manager | `avdmanager` da CLI |
| Avvio VM da Android Studio | `emulator -avd ...` su display Xvfb + VNC |
| PowerShell → platform-tools | ADB disponibile direttamente |
| `.\adb.exe devices` | `adb devices` |
| `.\adb.exe shell` | `adb shell` |
| rootAVD.bat | `rootAVD.sh` (versione Linux) |
| Finestra emulatore Android Studio | Xvfb + x11vnc (vedi sopra) |

## Note importanti

- L'emulatore gira su display virtuale (`:99`) tramite Xvfb, visibile via VNC
- **Non usare `-no-window`**: senza una finestra reale non c'è nulla da mostrare via VNC
- Il dispositivo viene configurato come **Google Pixel 6** (fingerprint + hardware)
- Durante il rooting la VM si spegne automaticamente — è normale
- La prima volta che esegui `su`, Magisk mostra un popup Grant/Deny **sullo
  schermo** (visibile solo via VNC) — se scade il timeout senza risposta la
  policy può restare "Deny" permanente: vai in Magisk → tab **Superuser** e
  attiva manualmente il toggle per `[SharedUID] Shell`
- **NON modificare** `ro.build.version.sdk` nel tool `props` (deve restare
  "disabled", opzione 7 nel menu "Device simulation")
- Prima di disconnetterti definitivamente, spegni l'emulatore in modo pulito
  con `adb emu kill` invece di lasciar cadere la sessione SSH

## Variabili configurabili

Nel file `config.env`:

```bash
AVD_NAME="VPS_Device"
API_LEVEL="33"
RAM_MB="2048"
STORAGE_GB="12"
SPOOF_DEVICE="Pixel 6"
```
