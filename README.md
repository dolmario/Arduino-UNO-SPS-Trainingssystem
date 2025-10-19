# LOGO! → Arduino UNO SPS-Trainingssystem

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Raspberry Pi](https://img.shields.io/badge/Platform-Raspberry%20Pi-red.svg)](https://www.raspberrypi.org/)
[![Arduino: UNO](https://img.shields.io/badge/Arduino-UNO-00979D.svg)](https://www.arduino.cc/)

**Programmiere mit LOGO! Soft Comfort – Führe aus auf Arduino UNO Hardware!**

Dieses Projekt ermöglicht Azubis, SPS-Programme in der vertrauten LOGO! Soft Comfort Umgebung zu entwickeln und auf kostengünstiger Arduino-Hardware auszuführen. Der Arduino läuft **stand-alone** – kein PC/Pi während des Betriebs nötig!

---

## 🎯 Zielsetzung

- ✅ **Bekannte Software**: Azubis nutzen LOGO! Soft Comfort (FUP/KOP)
- ✅ **Billige Hardware**: Arduino UNO + Relais + Sensoren (~30€ statt 800€)
- ✅ **Stand-Alone Betrieb**: Arduino arbeitet nach Upload autark
- ✅ **Reale I/O**: Echte Relais, Temperatursensoren, PWM, Analog-Signale
- ✅ **Einfach skalierbar**: 1 Raspberry Pi bedient 5+ Arbeitsplätze

---

## 🏗️ Architektur

```
┌─────────────────────────┐
│  LOGO! Soft Comfort     │  ← Azubi programmiert hier
│  (Windows PC)           │
└────────┬────────────────┘
         │ CSV Export
         ▼
┌─────────────────────────┐
│  Raspberry Pi 3         │  ← Kompilier-Server
│  • Parser               │
│  • Code-Generator       │
│  • arduino-cli          │
└────────┬────────────────┘
         │ USB (nur zum Flashen)
         ▼
┌─────────────────────────┐
│  Arduino UNO            │  ← Stand-Alone SPS
│  • 4× Relais            │
│  • 2× PWM (MOSFET)      │
│  • Analog/Digital I/O   │
│  • DS18B20 Temp-Sensor  │
└─────────────────────────┘
```

---

## 🚀 Schnellstart (3 Minuten)

### 1. Installation auf Raspberry Pi

```bash
# Komplett-Installation (empfohlen)
curl -fsSL https://raw.githubusercontent.com/DEIN-USER/logo2uno/main/install.sh | bash

# Oder manuell
git clone https://github.com/DEIN-USER/logo2uno.git
cd logo2uno
chmod +x install.sh
./install.sh
```

**Nach Installation:** Pi neu starten!

### 2. Arduino anschließen

- Arduino UNO per USB an Raspberry Pi
- Relais-Board, Sensoren verdrahten (siehe [Hardware-Guide](docs/HARDWARE.md))

### 3. Erstes Projekt flashen

```bash
cd ~/logo2uno
./build_and_flash.sh examples/test_blink.csv
```

**Erfolg:** Arduino-LED (Pin 13) blinkt!

---

## 📖 Workflow für Azubis

### Schritt 1: In LOGO! Soft programmieren

1. LOGO! Soft Comfort V8.3 öffnen
2. FUP-Editor: Programm erstellen
3. Simulieren & testen
4. **Datei → Exportieren → CSV**

### Schritt 2: Auf Pi übertragen

- USB-Stick: CSV nach `~/logo2uno/` kopieren
- Oder Netzlaufwerk: `\\raspberrypi\logo2uno\`

### Schritt 3: Kompilieren & Flashen

```bash
./build_and_flash.sh mein_projekt.csv
```

**Das war's!** Arduino läuft jetzt stand-alone.

---

## 🔧 Hardware-Profil

Alle Pin-Zuordnungen in `hardware_profile.yaml`:

| LOGO! | Arduino | Hardware |
|-------|---------|----------|
| I1 | D9 | Taster 1 |
| I2 | D10 | Taster 2 |
| Q1 | D2 | Relais 1 (Heizung) |
| Q2 | D4 | Relais 2 (Lüfter) |
| AO1_PWM | D3 | MOSFET PWM (0-255) |
| AI1 | A0 | Analog Input (0-1023) |
| TEMP | D12 | DS18B20 (OneWire) |

**Anpassbar!** Einfach `hardware_profile.yaml` editieren.

---

## 📚 Unterstützte LOGO! Bausteine

### Logik
- ✅ AND, OR, NOT, XOR
- ✅ SR-Flipflop, RS-Flipflop

### Timer
- ✅ TON (On-Delay)
- ✅ TOF (Off-Delay)

### Counter
- ✅ CTU (Count Up)
- 🚧 CTD (Count Down) - in Arbeit

### Vergleicher
- ✅ GT, LT, GE, LE, EQ, NE

### Analog
- ✅ PWM-Output (0-255)
- ✅ Analog-Input (0-1023)
- 🚧 PID-Regler - geplant

---

## 🛠️ Projektstruktur

```
logo2uno/
├── install.sh              # Ein-Klick-Installation
├── requirements.txt        # Python Dependencies
├── hardware_profile.yaml   # Pin-Mapping
│
├── parser_logo.
