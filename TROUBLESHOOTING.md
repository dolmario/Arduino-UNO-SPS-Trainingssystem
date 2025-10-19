**Beispiel:**
```yaml
project: "heizung_v2"
input: "/home/pi/logo2uno/projects/heizung_v2.csv"
port: "/dev/ttyUSB0"
board: "uno"
fqbn: "arduino:avr:uno"
time: "20250119-143022"
arduino_cli: "arduino-cli Version: 0.35.3"
success: true
```

**success: false?** → Upload fehlgeschlagen, upload.log prüfen!

---

## 🔥 ESP32-spezifische Probleme

### Problem: ESP32 bootet in Download-Modus

**Symptom:**
- ESP32 startet, aber Programm läuft nicht
- Serial zeigt: `waiting for download`

**Ursache:** Strapping-Pins falsch belegt

**Betroffene Pins:**
- **GPIO0** (BOOT): Muss HIGH beim Boot sein
- **GPIO2**: Muss LOW beim Boot sein (bei manchen Boards)
- **GPIO12** (MTDI): Spannung beim Boot bestimmt Flash-Voltage
- **GPIO15** (MTDO): Debugging-Output

**Lösung:**

```yaml
# hardware_profile.yaml für ESP32
pins:
  # NICHT verwenden beim Boot:
  # I1: 0   ← FALSCH!
  I1: 13    # ← Sicherer Pin
  
  # GPIO0 nur für Taster (wird als Boot-Button genutzt)
  BOOT_BUTTON: 0
```

**Regel:** Vermeide GPIO0, GPIO2, GPIO12, GPIO15 für kritische I/O!

---

### Problem: ESP32 WiFi funktioniert nicht

**Symptom:**
- WiFi.begin() hängt
- Keine Verbindung

**Ursache 1: ADC2 belegt**

```
ESP32 Regel:
ADC2-Pins können NICHT genutzt werden wenn WiFi aktiv!

ADC2-Pins: GPIO0, GPIO2, GPIO4, GPIO12-15, GPIO25-27

Lösung: Nur ADC1-Pins nutzen (GPIO32-39)
```

**Ursache 2: Antennen-Problem**

```
Manche ESP32-Boards:
- Haben Keramik-Antenne (Board-integriert)
- Haben u.FL-Stecker für externe Antenne

→ Mit Lötbrücke umschalten!
→ Oder externe Antenne anschließen
```

---

### Problem: ESP32 Reset-Loop

**Symptom:**
```
ets Jun  8 2016 00:22:57
rst:0x10 (RTCWDT_RTC_RESET),boot:0x13 (SPI_FAST_FLASH_BOOT)
...
Guru Meditation Error: Core 1 panic'ed (LoadProhibited)
```

**Ursachen:**

1. **Watchdog-Reset:**
   ```cpp
   // Zu lange Blockierung
   void loop() {
     delay(10000);  // ← 10 Sekunden blockiert!
     // Watchdog schlägt zu
   }
   
   // Lösung: Watchdog füttern
   #include "esp_task_wdt.h"
   
   void loop() {
     esp_task_wdt_reset();  // Watchdog zurücksetzen
     // Deine Logik...
   }
   ```

2. **Stack Overflow:**
   ```cpp
   // Zu viele lokale Variablen
   void bigFunction() {
     char buffer[10000];  // ← Zu groß!
   }
   
   // Lösung: Global oder malloc()
   char* buffer = (char*)malloc(10000);
   ```

3. **Defekte Flash:**
   ```bash
   # Flash löschen
   esptool.py --port /dev/ttyUSB0 erase_flash
   
   # Neu flashen
   ./build_and_flash.sh projekt.csv /dev/ttyUSB0 esp32
   ```

---

### Problem: ESP32 brownout detector

**Symptom:**
```
Brownout detector was triggered
ets Jun  8 2016 00:22:57
rst:0x10 (RTCWDT_RTC_RESET)
```

**Ursache:** Spannung bricht ein (< 2.8V)

**Lösungen:**

1. **Besseres Netzteil:**
   - Mind. 1A bei 5V
   - USB 3.0 statt 2.0

2. **Externe Versorgung:**
   ```
   ESP32 Vin ──── 5V Netzteil (+)
   ESP32 GND ──── 5V Netzteil (-)
   
   USB nur für Serial (keine Power!)
   ```

3. **Brownout-Level senken (Notlösung):**
   ```cpp
   #include "soc/rtc_cntl_reg.h"
   #include "soc/soc.h"
   
   void setup() {
     WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0);  // Brownout deaktivieren
     // Vorsicht: Nur mit gutem Netzteil!
   }
   ```

---

## 🔍 Erweiterte Diagnose

### Systematische Fehlersuche

#### Methode 1: Binary Search

**Problem:** Komplexes Programm funktioniert nicht

**Vorgehen:**

1. **Hälfte auskommentieren:**
   ```cpp
   void loop() {
     // Teil 1: Inputs + Logik 1-10
     readInputs();
     logic1();
     
     /* AUSKOMMENTIERT
     // Teil 2: Logik 11-20 + Outputs
     logic2();
     writeOutputs();
     */
   }
   ```

2. **Testen:**
   - Teil 1 funktioniert? → Fehler in Teil 2
   - Teil 1 funktioniert nicht? → Fehler in Teil 1

3. **Wiederholen** bis Fehler gefunden

---

#### Methode 2: LED-Debug

**Ohne Serial Monitor debuggen:**

```cpp
// Debug-LED an D13 (eingebaut)
#define DEBUG_LED 13

void debugBlink(int count) {
  for (int i = 0; i < count; i++) {
    digitalWrite(DEBUG_LED, HIGH);
    delay(200);
    digitalWrite(DEBUG_LED, LOW);
    delay(200);
  }
  delay(1000);
}

void loop() {
  // Checkpoint 1
  debugBlink(1);  // 1× blinken
  
  // ... Code ...
  
  // Checkpoint 2
  debugBlink(2);  // 2× blinken
  
  // ... Code ...
  
  if (error) {
    debugBlink(10);  // Schnelles Blinken = Fehler
    while(1);  // Stop
  }
}
```

---

#### Methode 3: Oszilloskop

**Für Profis: Hardware-Timing prüfen**

```cpp
// Trigger-Pulse für Oszilloskop
#define TRIGGER_PIN 8

void loop() {
  digitalWrite(TRIGGER_PIN, HIGH);  // Puls Start
  
  // Zu messende Funktion
  criticalFunction();
  
  digitalWrite(TRIGGER_PIN, LOW);   // Puls Ende
  
  // Mit Oszilloskop an D8: Puls-Länge = Laufzeit
}
```

---

### Profiling & Performance-Messung

```cpp
// Timing-Makros
#define TIME_START(name) unsigned long _time_##name = micros()
#define TIME_END(name) Serial.print(#name); Serial.print(": "); \
                       Serial.print(micros() - _time_##name); \
                       Serial.println(" us")

void loop() {
  TIME_START(sensors);
  sensors.requestTemperatures();
  TIME_END(sensors);
  
  TIME_START(logic);
  // LOGO-Logik
  TIME_END(logic);
  
  TIME_START(outputs);
  writeOutputs();
  TIME_END(outputs);
}

// Output:
// sensors: 750123 us
// logic: 450 us
// outputs: 120 us
```

---

## 🆘 Häufigste Fehler & Schnellfixes

### Top 10 Fehler

| # | Problem | Schnellfix |
|---|---------|------------|
| 1 | Port nicht gefunden | `sudo usermod -a -G dialout $USER` + Logout |
| 2 | Relais falsch herum | `relays_active_low: false` in YAML |
| 3 | DS18B20 = -127°C | 4.7kΩ Pull-Up vergessen! |
| 4 | ESP32 bootet nicht | Boot-Taste beim Upload halten |
| 5 | Kompilierung fehlgeschlagen | Core installieren: `arduino-cli core install arduino:avr` |
| 6 | Upload hängt | Serial Monitor schließen! |
| 7 | Sketch zu groß | Auf ESP32 wechseln |
| 8 | RAM-Überlauf | Weniger Merker nutzen |
| 9 | PWM ohne Wirkung | Gemeinsame GND prüfen! |
| 10 | Brownout ESP32 | Besseres Netzteil (min 1A) |

---

## 📞 Support & Community

### Bevor du fragst...

**Checkliste für Support-Anfragen:**

```
Bitte bereitstellen:
□ Welches Board? (UNO / ESP32)
□ Raspberry Pi OS Version?
□ arduino-cli Version? (/usr/local/bin/arduino-cli version)
□ Fehlermeldung (kompletter Output!)
□ build.log Inhalt
□ upload.log Inhalt
□ hardware_profile.yaml
□ LOGO-Programm (CSV oder Screenshot)
□ Was schon versucht wurde
```

**Log-Dateien teilen:**

```bash
# Alle relevanten Logs in eine Datei
cd ~/logo2uno/generated/current
cat meta.yaml build.log upload.log > ~/debug_output.txt

# Dann debug_output.txt im Forum posten
```

---

### GitHub Issues

**Bug melden:**

1. [Issue erstellen](https://github.com/dolmario/Arduino-UNO-SPS-Trainingssystem/issues/new)
2. Template ausfüllen:
   ```markdown
   **Beschreibung:**
   [Was funktioniert nicht?]
   
   **Erwartetes Verhalten:**
   [Was sollte passieren?]
   
   **Tatsächliches Verhalten:**
   [Was passiert stattdessen?]
   
   **Schritte zur Reproduktion:**
   1. ...
   2. ...
   
   **System:**
   - Board: [UNO / ESP32]
   - Raspberry Pi OS: [Version]
   - arduino-cli: [Version]
   
   **Logs:**
   [build.log hier einfügen]
   ```

---

### GitHub Discussions

**Fragen stellen:**

[Discussions](https://github.com/dolmario/Arduino-UNO-SPS-Trainingssystem/discussions)

**Kategorien:**
- 💡 Ideen & Feature-Requests
- 🙋 Q&A (Fragen & Antworten)
- 📣 Ankündigungen
- 🎓 Tutorials & Projekte

---

## 🧰 Diagnose-Skripte

### System-Check Script

```bash
#!/bin/bash
# system_check.sh - Vollständige System-Diagnose

echo "=== LOGO2UNO System Check ==="
echo ""

# Arduino-CLI
echo "1. arduino-cli:"
if command -v /usr/local/bin/arduino-cli >/dev/null 2>&1; then
  /usr/local/bin/arduino-cli version
  echo "✅ OK"
else
  echo "❌ Nicht gefunden!"
fi
echo ""

# Python
echo "2. Python & Pakete:"
python3 --version
python3 -c "import yaml; print('✅ yaml OK')" 2>/dev/null || echo "❌ yaml fehlt"
python3 -c "import serial; print('✅ serial OK')" 2>/dev/null || echo "❌ serial fehlt"
echo ""

# Cores
echo "3. Arduino Cores:"
/usr/local/bin/arduino-cli core list
echo ""

# Serielle Ports
echo "4. Serielle Ports:"
ls -l /dev/ttyUSB* /dev/ttyACM* 2>/dev/null || echo "Keine gefunden"
echo ""

# Rechte
echo "5. Benutzer-Rechte:"
groups | grep -q dialout && echo "✅ dialout OK" || echo "❌ dialout fehlt!"
echo ""

# Boards
echo "6. Angeschlossene Boards:"
/usr/local/bin/arduino-cli board list
echo ""

echo "=== Check abgeschlossen ==="
```

**Ausführen:**
```bash
chmod +x system_check.sh
./system_check.sh
```

---

### Port-Diagnose Script

```bash
#!/bin/bash
# port_diagnosis.sh - Serielle Port-Diagnose

echo "=== Serielle Port-Diagnose ==="
echo ""

for port in /dev/ttyUSB* /dev/ttyACM*; do
  [ -e "$port" ] || continue
  
  echo "Port: $port"
  echo "  Rechte: $(ls -l $port | awk '{print $1, $3, $4}')"
  echo "  Vendor/Product:"
  udevadm info -a $port | grep -E 'idVendor|idProduct' | head -2
  echo "  Serial:"
  udevadm info -a $port | grep 'ATTRS{serial}' | head -1
  echo ""
done

echo "=== Board-Detection ==="
/usr/local/bin/arduino-cli board list
```

---

## 📚 Weiterführende Links

### Offizielle Dokumentation

- [Arduino Reference](https://www.arduino.cc/reference/en/)
- [ESP32 Docs](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/)
- [arduino-cli Docs](https://arduino.github.io/arduino-cli/)
- [LOGO! Soft Comfort Handbuch](https://support.industry.siemens.com/)

### Community-Ressourcen

- [Arduino Forum](https://forum.arduino.cc/)
- [ESP32 Forum](https://www.esp32.com/)
- [Raspberry Pi Forum](https://forums.raspberrypi.com/)

### Video-Tutorials

- "Arduino Debugging" - Adafruit
- "ESP32 Troubleshooting" - Random Nerd Tutorials
- "LOGO! Programming Basics" - Siemens

---

## ✅ Checkliste für Problemlösung

### Bevor du aufgibst...

```
□ Neustart versucht? (Arduino + Raspberry Pi)
□ USB-Kabel gewechselt?
□ Anderen USB-Port probiert?
□ Build-Log gelesen?
□ Test-Sketch funktioniert?
□ Hardware mit Multimeter geprüft?
□ Andere arduino-cli Version probiert?
□ Google nach Fehlermeldung gesucht?
□ GitHub Issues durchgesehen?
□ Auf ESP32 gewechselt? (wenn UNO)
□ Community gefragt?
```

**Immer noch Problem?**

→ [GitHub Issue erstellen](https://github.com/dolmario/Arduino-UNO-SPS-Trainingssystem/issues/new) mit allen Details!

---

## 🎯 Zusammenfassung

**Die häufigsten Lösungen:**

1. **90% der Probleme:** Neustart + Rechte prüfen
2. **Port-Probleme:** `sudo usermod -a -G dialout $USER` + Logout
3. **Relais falsch:** `relays_active_low` Toggle in YAML
4. **ESP32 Upload:** Boot-Taste halten
5. **Sketch zu groß:** ESP32 nutzen
6. **Sensor -127°C:** Pull-Up Widerstand!

**Bei weiteren Fragen:**

📧 [GitHub Discussions](https://github.com/dolmario/Arduino-UNO-SPS-Trainingssystem/discussions)  
🐛 [GitHub Issues](https://github.com/dolmario/Arduino-UNO-SPS-Trainingssystem/issues)  
📖 [Wiki](https://github.com/dolmario/Arduino-UNO-SPS-Trainingssystem/wiki)

**Viel Erfolg beim Troubleshooting! 🔧****Symptom:**
- Relais schaltet mehrfach schnell hintereinander
- Hörbares Rattern/Prellen

**Ursachen:**

1. **Taster prellt:**
   ```
   LOGO! Programm:
   I1 ────→ R_TRIG ────→ Q1
   
   ➜ R_TRIG = Flankenerkennung entprellt!
   ```

2. **Grenzwert-Oszillation:**
   ```
   Temperatur schwankt um 20°C
   Schwelle bei 20°C
   → Relais schaltet ständig
   
   Lösung: Hysterese!
   EIN bei < 19°C
   AUS bei > 21°C
   ```

3. **Zu kurze Zykluszeit:**
   ```cpp
   // Im generierten Code:
   void loop() {
     // ...
     delay(50);  // ← Mind. 50ms für Relais!
   }
   ```

---

### Sensor-Probleme

#### Problem: DS18B20 zeigt -127°C

**Bedeutung:** Sensor nicht gefunden!

**Checkliste:**

```
□ Pull-Up Widerstand 4.7kΩ vorhanden?
□ Verkabelung korrekt? (Rot=5V, Schwarz=GND, Gelb=Data)
□ Pin-Nummer in hardware_profile.yaml korrekt?
□ Sensor defekt? (mit anderem testen)
```

**Diagnose-Code:**

```cpp
#include <OneWire.h>
#include <DallasTemperature.h>

OneWire oneWire(12);  // Pin anpassen!
DallasTemperature sensors(&oneWire);

void setup() {
  Serial.begin(115200);
  sensors.begin();
  
  Serial.print("Gefundene Sensoren: ");
  Serial.println(sensors.getDeviceCount());
}

void loop() {
  sensors.requestTemperatures();
  float temp = sensors.getTempCByIndex(0);
  
  Serial.print("Temperatur: ");
  Serial.println(temp);
  
  delay(1000);
}
```

**Erwartete Ausgabe:**
```
Gefundene Sensoren: 1
Temperatur: 22.50
Temperatur: 22.48
...
```

**Ausgabe "Gefundene Sensoren: 0":**
- Pull-Up fehlt!
- Verkabelung falsch!

---

#### Problem: MQ-Sensor liefert konstanten Wert

**Symptom:**
- MQ-135 zeigt immer 512 (analogRead)
- Wert ändert sich nicht

**Ursachen:**

1. **Aufheizzeit nicht abgewartet:**
   - MQ-Sensoren brauchen 24-48h Burn-In
   - Erste 3-5 Min nach Power-On: Werte instabil

2. **Falsche Verkabelung:**
   ```
   MQ-135 Modul:
   VCC → 5V
   GND → GND
   A0  → Arduino A0  ← Analog-Ausgang!
   D0  → (optional) Digital
   ```

3. **Poti am Modul falsch eingestellt:**
   - Viele MQ-Module haben Trim-Poti
   - Drehe Poti bis LED gerade NICHT leuchtet (Schwelle)

**Test:**
```cpp
void setup() {
  Serial.begin(115200);
}

void loop() {
  int raw = analogRead(A0);
  Serial.println(raw);
  delay(500);
}
```

**An Sensor pusten → Wert sollte sich ändern!**

---

#### Problem: Analog-Werte rauschen stark

**Symptom:**
- Werte springen zwischen 450-550 (sollte 500 sein)

**Lösung 1: Software-Filterung**

```cpp
// Mittelwert über 10 Messungen
int readAnalogFiltered(int pin) {
  long sum = 0;
  for (int i = 0; i < 10; i++) {
    sum += analogRead(pin);
    delay(1);
  }
  return sum / 10;
}
```

**Lösung 2: Hardware-Filterung**

```
     AI0 ──┬── 100nF ── GND
           │
        (Keramik-Kondensator)
```

**Lösung 3: Referenzspannung stabilisieren**

Für UNO: Externe 5V Referenz an AREF

---

### PWM / MOSFET-Probleme

#### Problem: PWM hat keine Wirkung

**Checkliste:**

```
□ Pin ist PWM-fähig? (UNO: D3,D5,D6,D9,D10,D11)
□ analogWrite() wird aufgerufen?
□ MOSFET richtig herum?
□ Last angeschlossen?
□ Gemeinsame GND zwischen Arduino & Last?
```

**Test-Code:**

```cpp
void setup() {
  pinMode(3, OUTPUT);  // PWM-Pin
}

void loop() {
  for (int i = 0; i <= 255; i += 5) {
    analogWrite(3, i);
    delay(100);
  }
}
```

**LED an D3 sollte langsam heller werden!**

---

#### Problem: MOSFET wird heiß

**Ursache:** MOSFET nicht voll durchgesteuert

**Lösung:**

1. **Logic-Level MOSFET verwenden:**
   - IRF540N (nicht IRF540!)
   - IRL540N besser für 5V Logik

2. **Gate-Widerstand:**
   ```
   Arduino D3 ──[220Ω]── MOSFET Gate
   ```

3. **Kühlkörper montieren**

---

## 📊 Performance & Speicher

### Problem: Arduino läuft langsam

**Symptom:**
- Verzögerungen bei Reaktionen
- Timer ungenau

**Diagnose:**

```cpp
// Zykluszeit messen
void loop() {
  unsigned long start = millis();
  
  // LOGO-Logik hier
  
  unsigned long duration = millis() - start;
  Serial.print("Zykluszeit: ");
  Serial.print(duration);
  Serial.println(" ms");
  
  delay(50);
}
```

**Sollte sein:** < 10ms bei einfachen Programmen

**Ursachen:**

1. **Zu viele Sensoren abgefragt:**
   ```cpp
   // Langsam (jede Schleife):
   sensors.requestTemperatures();  // 750ms!
   
   // Besser (alle 1 Sekunde):
   static unsigned long lastRead = 0;
   if (millis() - lastRead > 1000) {
     sensors.requestTemperatures();
     lastRead = millis();
   }
   ```

2. **delay() zu kurz:**
   ```cpp
   void loop() {
     // ...
     delay(5);  // ← Zu kurz! CPU-Last 100%
   }
   
   // Besser:
   delay(50);  // 20 Hz = typische LOGO-Zykluszeit
   ```

3. **Serial Print in jedem Zyklus:**
   ```cpp
   // Langsam:
   Serial.println("Debug");  // ~1ms!
   
   // Besser: Nur bei Bedarf
   if (DEBUG_MODE) {
     static unsigned long lastPrint = 0;
     if (millis() - lastPrint > 1000) {
       Serial.println("Debug");
       lastPrint = millis();
     }
   }
   ```

---

### Problem: RAM-Überlauf (UNO)

**Symptom:**
```
Low memory available, stability problems may occur.
Global variables use 1856 bytes (90%) of dynamic memory.
```

**Folgen:**
- Unerwartetes Verhalten
- Sporadische Resets
- Variablen überschreiben sich

**Lösungen:**

1. **Strings in Flash (PROGMEM):**
   ```cpp
   // Schlecht (RAM):
   char msg[] = "Lange Nachricht...";
   
   // Gut (Flash):
   const char msg[] PROGMEM = "Lange Nachricht...";
   ```

2. **Weniger globale Variablen:**
   - Nur benötigte Merker M1-M10
   - Nicht M1-M50

3. **Auf ESP32 wechseln:**
   - 520 KB RAM statt 2 KB!

---

## 📝 Log-Dateien analysieren

### Build-Log prüfen

```bash
# Letzter Build
cat ~/logo2uno/generated/current/build.log

# Alle Builds anzeigen
ls -ltr ~/logo2uno/generated/

# Bestimmten Build
cat ~/logo2uno/generated/projekt_20250119-143022/build.log
```

**Wichtige Zeilen:**

```
Sketch uses X bytes (Y%) of program storage space. Maximum is Z bytes.
Global variables use A bytes (B%) of dynamic memory, leaving C bytes for local variables.
```

- **X > Z:** Programm zu groß → ESP32 nutzen
- **B > 75%:** RAM-Problem wahrscheinlich
- **C < 200:** Kritisch wenig Stack!

---

### Upload-Log prüfen

```bash
cat ~/logo2uno/generated/current/upload.log
```

**Erfolg:**
```
avrdude: 32056 bytes of flash written
avrdude: verifying flash memory against projekt.ino.hex:
avrdude: load data flash data from input file projekt.ino.hex:
avrdude: input file projekt.ino.hex contains 32056 bytes
avrdude: reading on-chip flash data:
avrdude: verifying ...
avrdude: 32056 bytes of flash verified

avrdude done. Thank you.
```

**Fehler:**
```
avrdude: stk500_recv(): programmer is not responding
avrdude: stk500_getsync() attempt 10 of 10: not in sync: resp=0x00
```
→ [Upload-Probleme](#upload--flash)

---

### Meta-Datei analysieren

```bash
cat ~/logo2uno/generated/current/meta.yaml
```

**Beispiel:**
```yaml
project: "heizung_v2"
input: "/home/pi/logo2uno/projects/heizung_v2.csv"
port: "/dev/ttyUSB0"
board: "uno"
fqbn: "arduino:avr:uno"
time: "20250119-143022"# 🔧 Troubleshooting Guide

Systematische Fehlersuche für das LOGO! → Arduino/ESP32 SPS-Trainingssystem.

---

## 📋 Inhaltsverzeichnis

1. [Schnelldiagnose](#schnelldiagnose)
2. [Installation & Setup](#installation--setup)
3. [USB & Serielle Verbindung](#usb--serielle-verbindung)
4. [Kompilierung & Build](#kompilierung--build)
5. [Upload & Flash](#upload--flash)
6. [Hardware-Probleme](#hardware-probleme)
7. [LOGO! Export-Probleme](#logo-export-probleme)
8. [Performance & Speicher](#performance--speicher)
9. [Log-Dateien analysieren](#log-dateien-analysieren)
10. [ESP32-spezifische Probleme](#esp32-spezifische-probleme)

---

## 🚨 Schnelldiagnose

### Diagnose-Baum

```
Fehler beim Flashen?
├─ YES → Port nicht gefunden?
│  ├─ YES → [USB & Serielle Verbindung](#usb--serielle-verbindung)
│  └─ NO  → Kompilierung fehlgeschlagen?
│     ├─ YES → [Kompilierung & Build](#kompilierung--build)
│     └─ NO  → Upload-Fehler?
│        ├─ YES → [Upload & Flash](#upload--flash)
│        └─ NO  → Funktioniert nicht wie erwartet?
│           └─ YES → [Hardware-Probleme](#hardware-probleme)
└─ NO → Hardware funktioniert nicht?
   ├─ YES → Relais schaltet nicht?
   │  └─ [Relais-Probleme](#relais-probleme)
   ├─ Sensor liefert falsche Werte?
   │  └─ [Sensor-Probleme](#sensor-probleme)
   └─ System langsam/hängt?
      └─ [Performance & Speicher](#performance--speicher)
```

---

## 🛠️ Installation & Setup

### Problem: install.sh schlägt fehl

**Symptom:**
```
❌ Fehler in Zeile 123. Abbruch.
```

**Diagnose:**
```bash
# Installation mit Debug-Output
bash -x install.sh 2>&1 | tee install_debug.log
```

**Häufige Ursachen:**

#### 1. Keine Internet-Verbindung

```bash
# Prüfen
ping -c 3 google.com

# Lösung: Netzwerk einrichten
sudo raspi-config
# → System Options → Wireless LAN
```

#### 2. Veraltetes Raspberry Pi OS

```bash
# Prüfen
cat /etc/os-release

# Sollte sein: Debian Bullseye (11) oder neuer
# Lösung: System aktualisieren
sudo apt-get update
sudo apt-get upgrade
```

#### 3. Zu wenig Speicherplatz

```bash
# Prüfen
df -h

# Mindestens 2 GB frei nötig
# Lösung: Platz schaffen
sudo apt-get clean
sudo apt-get autoremove
```

#### 4. Fehlende Rechte

```bash
# Lösung: Mit sudo ausführen (nur install.sh!)
sudo ./install.sh
```

---

### Problem: arduino-cli nicht gefunden

**Symptom:**
```
arduino-cli: command not found
```

**Lösung:**
```bash
# arduino-cli manuell installieren
cd ~
curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
sudo mv bin/arduino-cli /usr/local/bin/
rm -rf bin

# Testen
/usr/local/bin/arduino-cli version
```

---

### Problem: Python-Pakete fehlen

**Symptom:**
```
ModuleNotFoundError: No module named 'yaml'
```

**Lösung:**
```bash
# APT-Pakete installieren (bevorzugt)
sudo apt-get install -y python3-yaml python3-serial

# Oder via pip (falls APT nicht geht)
pip3 install pyyaml pyserial
```

---

## 🔌 USB & Serielle Verbindung

### Problem: Port nicht gefunden

**Symptom:**
```
❌ Kein serieller Port gefunden. Schließe UNO/ESP32 an.
```

**Diagnose Schritt-für-Schritt:**

#### 1. Ist das Gerät physisch angeschlossen?

```bash
# Vor Anschluss
ls /dev/ttyUSB* /dev/ttyACM*

# Arduino anschließen

# Nach Anschluss (sollte mehr Einträge zeigen)
ls /dev/ttyUSB* /dev/ttyACM*
```

**Erwartetes Ergebnis:**
```
# Vorher: (leer oder weniger Einträge)
# Nachher:
/dev/ttyUSB0
```

**Nichts erscheint?** → Weiter zu Schritt 2

---

#### 2. USB-Kabel defekt?

```bash
# Test mit dmesg
dmesg | tail -20

# Erwartete Ausgabe beim Anschließen:
# usb 1-1.3: new full-speed USB device number 5 using dwc_otg
# usb 1-1.3: New USB device found, idVendor=2341, idProduct=0043
# ch341 1-1.3:1.0: ch341-uart converter detected
```

**Keine Meldung?**
- USB-Kabel wechseln (viele Kabel sind nur Ladekabel ohne Datenleitung!)
- Anderen USB-Port am Pi probieren
- Arduino/ESP32 an anderem PC testen

---

#### 3. Treiber geladen?

```bash
# CH340/CH341 Treiber (Clone-Boards)
lsmod | grep ch341

# FTDI Treiber (Original Arduino)
lsmod | grep ftdi_sio

# Sollte Einträge zeigen!
```

**Nichts gefunden?**
```bash
# Treiber manuell laden
sudo modprobe ch341
sudo modprobe ftdi_sio

# Dauerhaft aktivieren
echo "ch341" | sudo tee -a /etc/modules
echo "ftdi_sio" | sudo tee -a /etc/modules
```

---

#### 4. Rechte vorhanden?

```bash
# Prüfen ob User in Gruppe dialout
groups

# Sollte enthalten: dialout
```

**dialout fehlt?**
```bash
# User zur Gruppe hinzufügen
sudo usermod -a -G dialout $USER

# WICHTIG: Logout/Login erforderlich!
# Oder:
su - $USER  # neue Shell mit neuen Rechten
```

---

#### 5. Port wird genutzt?

```bash
# Prüfen ob Port blockiert ist
sudo lsof | grep ttyUSB0

# Falls Output: Prozess killen
sudo killall python3
# oder
sudo fuser -k /dev/ttyUSB0
```

---

### Problem: Mehrere Ports - welcher ist richtig?

**Situation:**
```bash
$ ls /dev/ttyUSB*
/dev/ttyUSB0  /dev/ttyUSB1  /dev/ttyUSB2
```

**Lösung 1: arduino-cli Board-Detection**
```bash
/usr/local/bin/arduino-cli board list

# Zeigt z.B.:
# Port         Protocol Type              Board Name  FQBN            Core
# /dev/ttyUSB0 serial   Serial Port (USB) Arduino Uno arduino:avr:uno arduino:avr
# /dev/ttyUSB1 serial   Serial Port (USB) Unknown
```

**Lösung 2: Seriennummer auslesen**
```bash
for port in /dev/ttyUSB*; do
  echo "=== $port ==="
  udevadm info -a $port | grep -E 'serial|idVendor|idProduct'
done
```

**Lösung 3: Systematisch testen**
```bash
# Arduino abziehen → wieder einstecken → welcher Port erscheint neu?
```

---

### Problem: Permission denied

**Symptom:**
```
error: permission denied on /dev/ttyUSB0
```

**Sofort-Lösung (temporär):**
```bash
sudo chmod 666 /dev/ttyUSB0
```

**Dauerhafte Lösung:**
```bash
# UDEV-Regel erstellen
sudo tee /etc/udev/rules.d/99-arduino.rules <<EOF
# Arduino UNO
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0043", MODE="0666"
# CH340/CH341 Clone
SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0666"
# ESP32
SUBSYSTEM=="tty", ATTRS{idVendor}=="303a", MODE="0666"
EOF

# Regel aktivieren
sudo udevadm control --reload-rules
sudo udevadm trigger

# Arduino ab- und wieder anstecken
```

---

## 🏗️ Kompilierung & Build

### Problem: Kompilierung schlägt fehl

**Symptom:**
```
🧱 Kompiliere (arduino:avr:uno)…
⚠️ Upload fehlgeschlagen. Prüfe Boot/Reset.
```

**Schritt 1: Build-Log prüfen**

```bash
cat ~/logo2uno/generated/current/build.log
```

**Häufige Fehler:**

---

#### Fehler: "Board not found"

**Log zeigt:**
```
Error: Unknown FQBN: arduino:avr:uno
```

**Lösung:**
```bash
# Core installieren
/usr/local/bin/arduino-cli core install arduino:avr

# Prüfen
/usr/local/bin/arduino-cli core list
```

---

#### Fehler: "Library not found"

**Log zeigt:**
```
fatal error: OneWire.h: No such file or directory
```

**Lösung:**
```bash
# Fehlende Bibliothek installieren
/usr/local/bin/arduino-cli lib install OneWire
/usr/local/bin/arduino-cli lib install "DallasTemperature"

# Oder alle Standard-Libs:
/usr/local/bin/arduino-cli lib install OneWire DallasTemperature Encoder
```

---

#### Fehler: "Sketch too big"

**Log zeigt:**
```
Sketch uses 34056 bytes (105%) of program storage space. Maximum is 32256 bytes.
```

**Erklärung:** Arduino UNO hat nur 32 KB Flash!

**Lösungen:**

1. **LOGO-Programm vereinfachen:**
   - Weniger Bausteine nutzen
   - Komplexe Timer durch einfache ersetzen

2. **Auf ESP32 wechseln:**
   ```bash
   ./build_and_flash.sh projekt.csv /dev/ttyUSB0 esp32
   # ESP32 hat 4 MB Flash!
   ```

3. **Compiler-Optimierung (Fortgeschrittene):**
   ```bash
   # In ~/.arduino15/preferences.txt
   compiler.optimization_flags=-Os
   ```

---

#### Fehler: "RAM overflow"

**Log zeigt:**
```
Low memory available, stability problems may occur.
```

**Erklärung:** UNO hat nur 2 KB SRAM!

**Lösungen:**

1. **Strings in PROGMEM:**
   ```cpp
   // Im Generator ändern (fortgeschritten)
   const char str[] PROGMEM = "Nachricht";
   ```

2. **Weniger globale Variablen:**
   - Merker M1-M10 statt M1-M50

3. **ESP32 nutzen** (520 KB RAM!)

---

### Problem: Parser-Fehler

**Symptom:**
```
🔎 Parsen…
❌ Block B005: Typ 'XYZ' (noch) nicht unterstützt
```

**Lösung 1: Unterstützte Bausteine prüfen**

```bash
# Liste der unterstützten Bausteine
python3 parser_logo.py --help

# Oder in parser_logo.py nachsehen:
grep "SUPPORTED_TYPES" parser_logo.py
```

**Lösung 2: Baustein durch ähnlichen ersetzen**

Beispiel:
- `TP` (Pulse Timer) → `TON` mit Reset nutzen
- `CTU_D` (Dual Counter) → 2× `CTU` nutzen

**Lösung 3: Feature-Request stellen**

[GitHub Issue](https://github.com/dolmario/Arduino-UNO-SPS-Trainingssystem/issues) mit Beschreibung des gewünschten Bausteins.

---

### Problem: CSV/XML fehlerhaft

**Symptom:**
```
🔎 Parsen…
Error: CSV parse error at line 12
```

**Diagnose:**
```bash
# CSV manuell prüfen
cat projects/mein_projekt.csv

# Zeile 12 ansehen
sed -n '12p' projects/mein_projekt.csv
```

**Häufige Fehler in CSV:**

1. **Falsche Spaltenanzahl:**
   ```csv
   # Falsch (zu wenig Spalten):
   B001,AND,I1,I2,Q1
   
   # Richtig (alle Spalten):
   B001,AND,I1,I2,,,Q1,
   ```

2. **Sonderzeichen im Namen:**
   ```csv
   # Falsch:
   B001,AND,I1 (Taster),I2,Q1,
   
   # Richtig:
   B001,AND,I1,I2,Q1,
   ```

3. **UTF-8 BOM:**
   ```bash
   # BOM entfernen
   sed -i '1s/^\xEF\xBB\xBF//' projects/mein_projekt.csv
   ```

**Lösung:** CSV neu aus LOGO! Soft exportieren!

---

## 📤 Upload & Flash

### Problem: Upload funktioniert nicht

**Symptom:**
```
⬆️  Flashe auf /dev/ttyUSB0…
avrdude: stk500_recv(): programmer is not responding
```

---

#### Arduino UNO - Upload-Fehler

**Checkliste:**

```
□ USB-Kabel angeschlossen?
□ Richtiger Port? (ls /dev/ttyUSB*)
□ Arduino hat Strom? (LED leuchtet?)
□ Kein Serial Monitor offen?
□ Reset-Button vor Upload drücken?
```

**Lösung 1: Anderen Bootloader?**

Manche Clone-Boards haben alten Bootloader:

```bash
# Old Bootloader probieren
/usr/local/bin/arduino-cli upload \
  -p /dev/ttyUSB0 \
  --fqbn arduino:avr:uno:cpu=atmega328old \
  sketch.ino
```

**Lösung 2: Baudrate reduzieren**

```bash
# In ~/.arduino15/preferences.txt
upload.speed=57600  # statt 115200
```

---

#### ESP32 - Upload-Fehler

**Symptom:**
```
A fatal error occurred: Failed to connect to ESP32
```

**Lösung - Boot-Modus manuell:**

```
Schritt-für-Schritt:
1. BOOT-Taste gedrückt halten
2. RESET-Taste kurz drücken (während BOOT gehalten)
3. BOOT-Taste weiter halten
4. Upload starten
5. Bei "Connecting..." BOOT loslassen
```

**Automatischer Boot-Modus:**

Manche ESP32-Boards unterstützen DTR/RTS:

```bash
# Prüfen ob auto-reset vorhanden
/usr/local/bin/arduino-cli board list | grep ESP32

# Wenn "Serial Port (USB)" steht: sollte automatisch gehen
# Wenn "Unknown": manueller Boot-Modus nötig
```

**ESP32 erkennt USB nicht:**

```bash
# CH340-Treiber prüfen
lsmod | grep ch341

# Sollte geladen sein!
# Falls nicht:
sudo modprobe ch341
```

---

### Problem: Upload klappt, Arduino startet nicht

**Symptom:**
- Upload erfolgreich
- Aber Arduino LED blinkt nicht / Programm läuft nicht

**Diagnose:**

#### 1. Wurde wirklich geflasht?

```bash
# Meta-Info prüfen
cat ~/logo2uno/generated/current/meta.yaml

# success: true?
```

#### 2. Bootloop?

```bash
# Serial Monitor öffnen
/usr/local/bin/arduino-cli monitor -p /dev/ttyUSB0 -c baudrate=115200

# Zeigt Fehlermeldungen oder Neustarts?
```

#### 3. Watchdog-Reset?

Mögliche Ursachen:
- Unendliche Schleife im Code
- Stack Overflow
- Zu viele Interrupts

**Lösung:** Test-Sketch flashen:

```bash
./build_and_flash.sh examples/test_blink.csv
# Läuft der? → Problem im eigenen Code
```

---

## 🔧 Hardware-Probleme

### Relais-Probleme

#### Problem: Relais schaltet nicht

**Checkliste:**

```
□ VCC an 5V?
□ GND verbunden?
□ Signal-Pin (IN1-IN4) richtig verbunden?
□ Relais-LED leuchtet beim Schalten?
□ Arduino-Pin kann Strom liefern? (max 40mA)
```

**Test-Code (direkt auf Arduino):**

```cpp
void setup() {
  pinMode(2, OUTPUT);  // Relais an D2
}

void loop() {
  digitalWrite(2, LOW);   // EIN (bei Active-LOW)
  delay(1000);
  digitalWrite(2, HIGH);  // AUS
  delay(1000);
}
```

Flash mit arduino-cli:

```bash
echo 'void setup() { pinMode(2, OUTPUT); }
void loop() { digitalWrite(2, LOW); delay(1000); digitalWrite(2, HIGH); delay(1000); }' > test.ino

/usr/local/bin/arduino-cli compile --fqbn arduino:avr:uno test.ino
/usr/local/bin/arduino-cli upload -p /dev/ttyUSB0 --fqbn arduino:avr:uno test.ino
```

**Relais klickt?** → Hardware OK, Problem im LOGO-Programm  
**Relais klickt nicht?** → Hardware-Problem

---

#### Problem: Relais schaltet falsch herum

**Symptom:**
- LOGO! sagt "Q1 = AN"
- Relais ist AUS (LED aus)

**Ursache:** Active-LOW vs Active-HIGH

**Lösung:**

```yaml
# hardware_profile.yaml
flags:
  relays_active_low: true   # ← Meistens true!
  # false nur bei speziellen Modulen
```

**Test welcher Wert richtig ist:**

```bash
# Temporär im generierten Code ändern
nano ~/logo2uno/generated/current/*.ino

# Suche: RELAYS_ACTIVE_LOW
# Ändere true ↔ false
# Neu kompilieren & testen
```

---

#### Problem: Relais rattert (Prellen)

**Symptom:**
- Relais schaltet mehrfach schnell hintereinander
- Hör
