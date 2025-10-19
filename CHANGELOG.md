# 🧾 Changelog

Alle nennenswerten Änderungen an diesem Projekt werden in dieser Datei dokumentiert.
Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
und dieses Projekt folgt [Semantic Versioning](https://semver.org/lang/de/).

---

## [Unreleased]

### 🧩 Geplant

* 🌐 Web-Interface für Raspberry Pi
* ⚙️ PID-Regler-Block
* 🔌 Modbus RTU Kommunikation
* 🖥️ I2C OLED Display Support
* 📈 Datenlogging in SQLite
* 📡 OTA-Updates für ESP32
* 🧰 Erweiterter Azubi-Testmodus (automatischer IO-Check)
* 🔄 Optionale LAN-Freigabe mit Live-Log-Anzeige

---

## [1.0.0] – 2025-01-19

### ✨ Added

* 🎉 **Erste stabile Release-Version**
* ✅ Vollständiger LOGO! CSV/XML Parser (`parser_logo.py`)
* ✅ Arduino Code-Generator für UNO & ESP32 (`generator_arduino.py`)
* ✅ Build & Flash Pipeline (`build_and_flash.sh`)
* ✅ GUI-Tool mit Zenity (`flash_gui.sh`)
* ✅ Installer-Script (`install.sh`)

  * 🧩 Python-Pakete (APT + optional venv)
  * ⚙️ Arduino-CLI Setup (UNO & ESP32 Cores)
  * 🔒 Serielle Rechte & UDEV-Regeln
  * 🖥️ Desktop-Icon + optionaler Autostart
* 🧱 Hardware-Profil-System (`hardware_profile.yaml`)
* 🔌 Unterstützte Hardware: Relais, MOSFET, DS18B20, Buzzer, MQ-Sensoren, KY-040, 7-Segment-BCD
* 💾 Automatische Versionierung & Log-Ablage (`~/logo2uno/generated/`)
* 🧰 Desktop-Icon **„LOGO → UNO/ESP32 Flash“** für Ein-Klick-Workflow
* 🧠 Robuste Fehlerbehandlung & idempotente Installation
* 📘 Umfassende Dokumentation (`README.md`, `TRAINING_GUIDE.md`, `SERVER_SETUP.md`)
* 🔒 Sicherheitskonzept (User `pi` in `dialout`, SELV 5 V/12 V)

### 🧰 Improved

* 🔄 Parser erweitert für LOGO! Soft 8.2/8.3 XML
* ⚙️ Generator mit allen LOGO-Grundfunktionen (AND, OR, SR, RS, TON, TOF, CTU, usw.)
* 🧩 Automatische Hardware-Includes im Code
* 💾 Build-Versionierung mit `meta.yaml`
* 🧱 Installationsprozess vollständig wiederholbar

### 🐞 Fixed

* 🔧 Pfadproblem in `flash_gui.sh` (Exec-Kontext) behoben
* 🔧 Arduino-CLI-Erkennung auf Minimal-Systemen verbessert
* 🔧 Parser-Abbruch bei leeren CSV-Zeilen verhindert

---

### 🧭 Hinweis für Tester (v1.0.0)

Diese Version ist für Azubi-Tests mit UNO und ESP32 geeignet.
Bei Problemen bitte `build.log` und `upload.log` im `generated/`-Ordner prüfen.
