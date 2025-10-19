# LOGO! → Arduino UNO/ESP32 SPS-Trainingssystem

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Raspberry Pi](https://img.shields.io/badge/Platform-Raspberry%20Pi-red.svg)](https://www.raspberrypi.org/)
[![Arduino: UNO/ESP32](https://img.shields.io/badge/Arduino-UNO%2FESP32-00979D.svg)](https://www.arduino.cc/)

**Programmiere mit LOGO! Soft Comfort – Führe aus auf Arduino UNO oder ESP32 Hardware!**

Dieses Projekt ermöglicht Azubis, SPS-Programme in der vertrauten LOGO! Soft Comfort Umgebung zu entwickeln und auf kostengünstiger Arduino-Hardware (UNO oder ESP32) auszuführen. Der Arduino/ESP32 läuft **stand-alone** – kein PC/Pi während des Betriebs nötig!

---

## 🎯 Zielsetzung

- ✅ **Bekannte Software**: Azubis nutzen LOGO! Soft Comfort (FUP/KOP)
- ✅ **Billige Hardware**: Arduino UNO/ESP32 + Relais + Sensoren (~30€ statt 800€)
- ✅ **Stand-Alone Betrieb**: Arduino/ESP32 arbeitet nach Upload autark
- ✅ **Reale I/O**: Echte Relais, Temperatursensoren, PWM, Analog-Signale
- ✅ **Einfach skalierbar**: 1 Raspberry Pi bedient 5+ Arbeitsplätze
- ✅ **Multi-Board Support**: UNO (AVR) und ESP32 werden unterstützt

---

## 🏗️ Architektur

```
┌─────────────────────────┐
│  LOGO! Soft Comfort     │  ← Azubi programmiert hier
│  (Windows PC)           │
└────────┬────────────────┘
         │ CSV/XML Export
         ▼
┌─────────────────────────┐
│  Raspberry Pi 3/4       │  ← Kompilier-Server
│  • Parser (CSV/XML)     │
│  • Code-Generator       │
│  • arduino-cli          │
│  • Support: UNO + ESP32 │
└────────┬────────────────┘
         │ USB (nur zum Flashen)
         ▼
┌─────────────────────────┐
│  Arduino UNO / ESP32    │  ← Stand-Alone SPS
│  • 4× Relais            │
│  • 2× PWM (MOSFET)      │
│  • Analog/Digital I/O   │
│  • DS18B20 Temp-Sensor  │
│  • Optional: OLED, etc. │
└─────────────────────────┘
```

---

## 🚀 Schnellstart (3 Minuten)

### 1. Installation auf Raspberry Pi

```bash
# Komplett-Installation (empfohlen)
curl -fsSL https://raw.githubusercontent.com/dolmario/Arduino-UNO-SPS-Trainingssystem/main/install.sh | bash

# Oder manuell
git clone https://github.com/dolmario/Arduino-UNO-SPS-Trainingssystem.git ~/logo2uno
cd ~/logo2uno
chmod +x install.sh
./install.sh
```

**Nach Installation:** Pi neu starten für Gruppenrechte (dialout)!

Der Installer richtet automatisch ein:
- Python 3 mit allen Dependencies (über APT)
- arduino-cli mit AVR Core (Arduino UNO)
- arduino-cli mit ESP32 Core (optional)
- Serielle Rechte & UDEV-Regeln
- Desktop-Icon für GUI-Flash-Tool
- Projektordner `~/logo2uno/projects` und `~/logo2uno/generated`

### 2. Arduino/ESP32 anschließen

- Arduino UNO oder ESP32 per USB an Raspberry Pi
- Relais-Board, Sensoren verdrahten (siehe [Hardware-Guide](docs/HARDWARE.md))

### 3. Erstes Projekt flashen

#### Kommandozeile (UNO):
```bash
cd ~/logo2uno
./build_and_flash.sh projects/test_blink.csv /dev/ttyUSB0 uno
```

#### Kommandozeile (ESP32):
```bash
cd ~/logo2uno
./build_and_flash.sh projects/test_blink.csv /dev/ttyUSB0 esp32
```

#### GUI (empfohlen für Azubis):
Desktop-Icon **"LOGO → UNO/ESP32 Flash"** anklicken:
1. CSV/XML-Datei wählen
2. Board wählen (uno/esp32)
3. Port wählen (automatisch erkannt)
4. Terminal zeigt Build & Upload

**Erfolg:** Arduino-LED blinkt oder ESP32 führt Programm aus!

---

## 📖 Workflow für Azubis

### Schritt 1: In LOGO! Soft programmieren

1. LOGO! Soft Comfort V8.3 öffnen
2. FUP-Editor: Programm erstellen
3. Simulieren & testen
4. **Datei → Exportieren → CSV** oder **XML speichern**

### Schritt 2: Auf Pi übertragen

- **USB-Stick**: CSV/XML nach `~/logo2uno/projects/` kopieren
- **Netzlaufwerk**: `\\raspberrypi\logo2uno\projects\`
- **SCP/SFTP**: Direkter Upload via Netzwerk

### Schritt 3: Kompilieren & Flashen

**Option A – GUI (einfachste Methode):**
1. Desktop-Icon anklicken
2. Projekt wählen
3. Board wählen (uno/esp32)
4. Port wählen
5. Warten bis "✅ Build & Flash abgeschlossen"

**Option B – Kommandozeile:**
```bash
./build_and_flash.sh projects/mein_projekt.csv /dev/ttyUSB0 uno
# oder für ESP32:
./build_and_flash.sh projects/mein_projekt.csv /dev/ttyUSB0 esp32
```

**Das war's!** Arduino/ESP32 läuft jetzt stand-alone.

---

## 🔧 Hardware-Profil

Alle Pin-Zuordnungen in `hardware_profile.yaml`:

### Arduino UNO Standardbelegung

| LOGO! | Arduino | Hardware |
|-------|---------|----------|
| I1 | D9 | Taster 1 (Pull-Up) |
| I2 | D10 | Taster 2 (Pull-Up) |
| I3 | A2 | Sensor Digital |
| I4 | A3 | Sensor Digital |
| Q1 | D2 | Relais 1 (Heizung) |
| Q2 | D4 | Relais 2 (Lüfter) |
| Q3 | D5 | Relais 3 (Licht) |
| Q4 | D7 | Relais 4 (Alarm) |
| AO1_PWM | D3 | MOSFET PWM 1 (0-255) |
| AO2_PWM | D6 | MOSFET PWM 2 (0-255) |
| AI1 | A0 | Analog Input CO₂ (0-1023) |
| AI2 | A1 | Analog Input NOx (0-1023) |
| TEMP | D12 | DS18B20 (OneWire) |
| BUZZER | D8 | Piezo-Summer |

### ESP32 Hinweise

Bei ESP32 können die Pins flexibel in `hardware_profile.yaml` angepasst werden. Beachte:
- PWM auf jedem digitalen Pin möglich
- ADC1 bevorzugt (ADC2 nicht mit WiFi nutzbar)
- Touch-Pins verfügbar
- Mehr RAM & Flash als UNO

**Anpassbar!** Einfach `hardware_profile.yaml` editieren.

---

## 📚 Unterstützte LOGO! Bausteine

### Logik
- ✅ AND, OR, NOT, XOR, NAND, NOR

### Speicher & Flanken
- ✅ SR-Flipflop, RS-Flipflop
- ✅ R_TRIG (Positive Flanke), F_TRIG (Negative Flanke)

### Timer
- ✅ TON (On-Delay Timer)
- ✅ TOF (Off-Delay Timer)

### Zähler
- ✅ CTU (Count Up)
- ✅ CTD (Count Down)
- 🚧 CTUD (Up/Down) - in Arbeit

### Vergleicher
- ✅ GT (>), LT (<), GE (≥), LE (≤), EQ (=), NE (≠)

### Mathematik
- ✅ ADD (+), SUB (-), MUL (×), DIV (÷)
- ✅ MOVE (Zuweisung)

### Analog/PWM
- ✅ PWM-Output (0-255)
- ✅ Analog-Input (0-1023 UNO, 0-4095 ESP32)
- 🚧 PID-Regler - geplant

### Sensoren & Peripherie
- ✅ DS18B20 Temperatursensor (OneWire)
- ✅ MQ-x Gassensoren (analog)
- ✅ 7-Segment BCD-Ausgabe
- ✅ KY-040 Rotary Encoder
- 🚧 I2C OLED Display - in Arbeit
- 🚧 INA219 Strom/Spannung - geplant

---

## 🛠️ Projektstruktur

```
logo2uno/
├── install.sh                  # Ein-Klick-Installation
├── hardware_profile.yaml       # Pin-Mapping & Kalibrierung
│
├── parser_logo.py              # CSV/XML → Python Blöcke
├── generator_arduino.py        # Python Blöcke → .ino Sketch
├── build_and_flash.sh          # Build & Upload Pipeline
├── flash_gui.sh                # Zenity GUI für Azubis
│
├── projects/                   # LOGO! CSV/XML Projekte
│   ├── test_blink.csv
│   ├── heizung_regler.xml
│   └── ...
│
├── generated/                  # Build-Artefakte
│   ├── projekt_20250119-143022/
│   │   ├── projekt.ino
│   │   ├── projekt.ino.hex
│   │   ├── build.log
│   │   └── meta.yaml
│   └── current -> projekt_.../ # Symlink zum letzten Build
│
├── examples/                   # Beispielprojekte
├── docs/                       # Dokumentation
│   ├── HARDWARE.md
│   └── TRAINING_GUIDE.md
│
└── template.ino                # Arduino-Sketch-Vorlage
```

---

## 🎓 Trainingsszenarien

### 1. Heizungssteuerung
- Temperatursensor DS18B20
- Zweipunkt-Regler (TON/TOF)
- PWM-MOSFET für stufenlose Leistung
- Notabschaltung bei Übertemperatur

### 2. Lüftungsanlage
- CO₂-Sensor (MQ-135)
- 3-Stufen-Steuerung via Relais
- Zeitverzögerung beim Nachlauf
- Störungsanzeige (Buzzer + LED)

### 3. Ampelsteuerung
- 3× Relais (Rot/Gelb/Grün)
- Timer-Sequenzen
- Taster für Fußgänger-Anforderung
- Nacht-Modus (Gelb-Blinken)

### 4. Förderband-Simulation
- 2× Motoren (PWM-Drehzahlregelung)
- Encoder für Position
- NOT-AUS mit sicherem Halt
- Zähler für Werkstücke

---

## 🔍 Fehlersuche

### Port nicht gefunden
```bash
# Alle seriellen Ports auflisten
ls -l /dev/ttyUSB* /dev/ttyACM*

# arduino-cli Board-Liste
/usr/local/bin/arduino-cli board list

# Rechte prüfen
groups  # sollte "dialout" enthalten
```

### ESP32 Upload-Fehler
- **Boot-Taste** gedrückt halten während Upload
- USB-Kabel direkt an Pi (kein Hub)
- Anderes USB-Kabel testen
- CH340-Treiber prüfen (sollte via install.sh vorhanden sein)

### Kompilierung schlägt fehl
```bash
# Parser-Test
python3 parser_logo.py projects/mein_projekt.csv

# Generator-Test
python3 generator_arduino.py projects/mein_projekt.csv > test.ino

# Logs prüfen
cat generated/current/build.log
```

### Relais schaltet falsch herum
In `hardware_profile.yaml`:
```yaml
flags:
  relays_active_low: true  # LOW = EIN (häufigster Fall)
  # oder
  relays_active_low: false # HIGH = EIN
```

---

## 🔐 Sicherheit & Best Practices

### Elektrische Sicherheit
- ⚠️ **Nur SELV-Spannungen** (≤ 48V DC / ≤ 24V AC) für Azubi-Training!
- **Keine 230V-Lasten** ohne Elektrofachkraft
- Relais-Last max. 10A @ 230V AC (siehe Datenblatt)
- Schutzleiter bei Metallgehäusen

### Code-Qualität
- Immer in LOGO! Soft simulieren vor dem Flash
- Hardware-Tests mit LED/Summer statt teuren Aktoren
- Versionierung via Git empfohlen

### Datensicherung
Automatisches Backup via Cron (siehe `setup_autostart.sh`):
```bash
# Manuelles Backup
cd ~/logo2uno
tar czf backup_$(date +%Y%m%d).tar.gz projects/ hardware_profile.yaml
```

---

## 🌐 Netzwerk-Features

### Samba-Share (optional)
Windows-Netzlaufwerk für einfachen Dateizugriff:
```bash
# In install.sh aktivieren:
ENABLE_SAMBA_SHARE=true ./install.sh

# Windows-Zugriff:
\\raspberrypi\logo2uno_generated
```

### Webinterface (geplant)
- Upload via Browser
- Live-Monitoring der Arduinos
- Online-Editor für `hardware_profile.yaml`

---

## 🧪 Entwicklung & Beitragen

### Neuen LOGO!-Block hinzufügen

1. **Parser erweitern** (`parser_logo.py`):
   ```python
   SUPPORTED_TYPES.add("MEIN_BLOCK")
   ```

2. **Generator ergänzen** (`generator_arduino.py`):
   ```python
   elif t == "MEIN_BLOCK":
       # Code-Generierung hier
   ```

3. **Testen**:
   ```bash
   ./build_and_flash.sh examples/test_mein_block.csv
   ```

### Pull Requests willkommen!
- Neue Bausteine (PID, Hysterese, etc.)
- Sensor-Bibliotheken (BME280, INA219, etc.)
- ESP32-spezifische Features (WiFi, Bluetooth)
- Dokumentation & Tutorials

---

## 📦 Abhängigkeiten

### Raspberry Pi
- Raspberry Pi OS (Bullseye oder neuer)
- Python 3.9+
- arduino-cli 0.35+

### Arduino Libraries (automatisch installiert)
- OneWire (DS18B20)
- DallasTemperature
- Encoder (optional)

### Python Packages (via APT)
- python3-yaml
- python3-serial
- python3-rpi.gpio

---

## 📝 Lizenz

MIT License - siehe [LICENSE](LICENSE)

**Frei nutzbar für Ausbildung, Lehre und kommerzielle Zwecke!**

---

## 🙏 Danksagungen

- Siemens LOGO! Soft Comfort für die intuitive Programmierumgebung
- Arduino & ESP32 Community
- Alle Ausbilder & Azubis, die Feedback geben

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/dolmario/Arduino-UNO-SPS-Trainingssystem/issues)
- **Diskussionen**: [GitHub Discussions](https://github.com/dolmario/Arduino-UNO-SPS-Trainingssystem/discussions)
- **Wiki**: [Projekt-Wiki](https://github.com/dolmario/Arduino-UNO-SPS-Trainingssystem/wiki)

**Viel Erfolg beim Training! 🎓🔧**
