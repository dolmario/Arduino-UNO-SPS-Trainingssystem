# ⚡ Quickstart Guide - In 10 Minuten loslegen!

Minimale Anleitung für den schnellsten Einstieg ins LOGO! → Arduino/ESP32 System.

---

## 🎯 Was du brauchst (Minimum-Setup)

```
✓ Raspberry Pi 3/4 mit Raspberry Pi OS
✓ Arduino UNO oder ESP32
✓ USB-Kabel (A zu B)
✓ 1× Taster (zwischen Pin D9 und GND)
✓ Optional: LED + 220Ω Widerstand an Relais-Pin
```

**Das war's!** Mehr brauchst du nicht für den ersten Test.

---

## 📥 Schritt 1: Installation (3 Minuten)

**Öffne Terminal auf dem Raspberry Pi:**

```bash
# Ein-Kommando-Installation
curl -fsSL https://raw.githubusercontent.com/dolmario/Arduino-UNO-SPS-Trainingssystem/main/install.sh | bash
```

**Was passiert:**
- Python 3 + Dependencies werden installiert
- arduino-cli wird eingerichtet
- Arduino AVR Core (UNO) wird installiert
- ESP32 Core wird installiert
- Serielle Rechte werden gesetzt
- Desktop-Icon wird erstellt

**Nach Abschluss:**
```bash
sudo reboot
# ← Neustart für Gruppenrechte!
```

**Fertig!** Das System ist jetzt einsatzbereit.

---

## 🔌 Schritt 2: Hardware anschließen (2 Minuten)

### Minimal-Verkabelung für ersten Test

```
Arduino UNO:
┌────────────┐
│     D13    ├─── [eingebaute LED]
│            │
│     D9     ├─── [Taster] ─── GND
│            │
│     GND    ├─── Taster (andere Seite)
│            │
│     USB    ╞═══════════════════╗
└────────────┘                   ║
                                 ║
                    ┌────────────╨──────┐
                    │  Raspberry Pi USB │
                    └───────────────────┘
```

**Das reicht für den ersten Test!**

Optional (für Relais-Test):
```
D2 ─── [Relais IN1]
5V ─── [Relais VCC]
GND ─── [Relais GND]
```

---

## 🎮 Schritt 3: Ersten Sketch flashen (5 Minuten)

### Option A: Mit GUI (am einfachsten)

**1. Desktop-Icon doppelklicken:**
```
"LOGO → UNO/ESP32 Flash"
```

**2. Datei wählen:**
```
→ examples/test_blink.csv
```

**3. Board wählen:**
```
→ uno (oder esp32)
```

**4. Port wählen:**
```
→ /dev/ttyUSB0 (automatisch erkannt)
```

**5. Warten…**
```
✅ Build & Flash abgeschlossen.
```

**Fertig!** LED blinkt jetzt.

---

### Option B: Mit Terminal

```bash
cd ~/logo2uno
./build_and_flash.sh examples/test_blink.csv /dev/ttyUSB0 uno
```

**Ausgabe sollte sein:**
```
==> Projekt: examples/test_blink.csv
==> Board:   uno (arduino:avr:uno)
==> Port:    /dev/ttyUSB0
🔎 Parsen…
🛠️  Code-Generierung → test_blink.ino
🧱 Kompiliere (arduino:avr:uno)…
⬆️  Flashe auf /dev/ttyUSB0…
====================================
✅ Build & Flash abgeschlossen.
====================================
```

**LED D13 blinkt jetzt im Sekundentakt!** 🎉

---

## 🧪 Erste eigene Modifikation

### Blink-Geschwindigkeit ändern

**1. LOGO! Soft Comfort öffnen (auf Windows-PC):**

Falls nicht installiert: [Download bei Siemens](https://support.industry.siemens.com/)

**2. Neues Projekt anlegen:**
```
Datei → Neu
→ LOGO! 8 wählen
→ FUP (Funktionsplan)
```

**3. Baustein hinzufügen:**
```
Bibliothek links:
→ Special Functions
  → Clock Generator

Auf Arbeitsfläche ziehen
Doppelklick darauf:
→ Parameter: T=2s (statt 1s)
```

**4. Mit Ausgang verbinden:**
```
Clock-Ausgang anklicken
→ Linie ziehen zu Q1
```

**Dein Programm sieht jetzt so aus:**
```
┌──────────────┐
│ Clock Gen    │
│ T=2s         ├────→ Q1
│              │
└──────────────┘
```

**5. Exportieren:**
```
Datei → Exportieren → CSV-Datei
→ Speichern als: mein_blink.csv
```

**6. Auf Raspberry Pi übertragen:**
- USB-Stick: Datei kopieren nach `/home/pi/logo2uno/projects/`
- Oder direkt auf Pi erstellen

**7. Flashen:**
```bash
./build_and_flash.sh projects/mein_blink.csv
```

**LED blinkt jetzt alle 2 Sekunden!** ✨

---

## 🎯 Test-Checklist

Prüfe ob alles funktioniert:

```
□ LED D13 blinkt nach Flash
□ Geschwindigkeit entspricht LOGO-Einstellung (1s oder 2s)
□ Arduino läuft auch ohne USB (externe 12V)
□ Taster an D9 wird erkannt (falls angeschlossen)
□ Relais schaltet (falls angeschlossen)
□ Keine Fehlermeldungen im Terminal
```

**Alles grün?** → System läuft perfekt! 🚀

---

## ❓ Häufigste Probleme

### Problem: "Port nicht gefunden"

**Lösung:**
```bash
# Ports anzeigen
ls -l /dev/ttyUSB* /dev/ttyACM*

# Falls leer: USB-Kabel wechseln oder anderen Port probieren
```

---

### Problem: "Kompilierung fehlgeschlagen"

**Lösung:**
```bash
# Core installiert?
/usr/local/bin/arduino-cli core list

# Falls arduino:avr fehlt:
/usr/local/bin/arduino-cli core install arduino:avr
```

---

### Problem: ESP32 - "Failed to connect"

**Lösung:**
- Boot-Taste beim Upload gedrückt halten
- USB direkt am Pi (kein Hub)
- CH340 Treiber prüfen: `lsmod | grep ch341`

---

### Problem: Relais schaltet falsch herum

**Lösung:**

`hardware_profile.yaml` bearbeiten:
```yaml
flags:
  relays_active_low: true  # ← auf false ändern
```

Dann neu flashen!

---

## 📚 Nächste Schritte

Du hast jetzt das System zum Laufen gebracht! 🎉

**Was jetzt?**

1. **[TRAINING_GUIDE.md](TRAINING_GUIDE.md) lesen**  
   → Vollständiger Workflow von LOGO! Soft bis Arduino

2. **[HARDWARE.md](docs/HARDWARE.md) studieren**  
   → Relais, Sensoren, MOSFET anschließen

3. **Beispiele durcharbeiten:**
   ```bash
   cd ~/logo2uno/examples
   ls *.csv
   # test_blink.csv
   # heizung_basic.csv
   # ampel_simple.csv
   # ...
   ```

4. **Eigenes erstes Projekt:**
   - Taster → Lampe (einfachstes SPS-Programm)
   - Mit Selbsthaltung (SR-Flipflop)
   - Mit Timer (Treppenlicht)

5. **Community beitreten:**
   - [GitHub Issues](https://github.com/dolmario/Arduino-UNO-SPS-Trainingssystem/issues)
   - [GitHub Discussions](https://github.com/dolmario/Arduino-UNO-SPS-Trainingssystem/discussions)

---

## 🎓 Mini-Übung: Taster → LED

**Ziel:** Taster an I1 schaltet LED an Q1

### LOGO! Programm (ultra-einfach)

```
I1 ────→ Q1

Das war's! Ein Baustein reicht.
```

### CSV erstellen (von Hand)

Erstelle Datei `test_taster.csv`:
```csv
Block,Type,Input1,Input2,Output,Parameter
B001,MOVE,I1,,Q1,
```

### Hardware

```
D9 ──┬── [Taster] ── GND
     │
(intern Pull-Up aktiviert)

D2 ── [Relais IN1]
```

### Flashen

```bash
./build_and_flash.sh projects/test_taster.csv
```

### Test

- **Taster drücken:** Relais klickt → LED leuchtet
- **Taster loslassen:** Relais klickt → LED aus

**Funktioniert?** Gratulation! Du hast dein erstes SPS-Programm zum Laufen gebracht! 🏆

---

## 💡 Pro-Tipps

### 1. Serielle Ports merken

Bei mehreren Arduinos:
```bash
# Beschriftung auf Arduino kleben
echo "Platz 1" | sudo tee /dev/arduino_platz1
```

### 2. Backup vor jedem Flash

```bash
# Automatisch via Alias
alias flash='cp projects/*.csv backups/ && ./build_and_flash.sh'
```

### 3. Quick-Edit für Profis

```bash
# CSV direkt editieren statt LOGO! Soft
nano projects/mein_projekt.csv
# Dann flashen
```

### 4. Log-Dateien bei Problemen

```bash
# Letzter Build
cat ~/logo2uno/generated/current/build.log

# Alle Builds
ls -ltr ~/logo2uno/generated/
```

---

## 🎉 Geschafft!

**Du hast in 10 Minuten gelernt:**
✅ System installieren  
✅ Hardware anschließen  
✅ Erstes Programm flashen  
✅ Eigene Modifikation vornehmen  
✅ Probleme selbst lösen

**Jetzt bist du bereit für echte Projekte!**

→ Weiter mit [TRAINING_GUIDE.md](TRAINING_GUIDE.md) für vollständigen Workflow  
→ Oder direkt mit [Übung 1: Blinkschaltung](TRAINING_GUIDE.md#übung-1-led-blinkschaltung-) starten

**Viel Erfolg! 🚀**
