# 🎓 LOGO! → Arduino/ESP32 Trainingsanleitung

Schritt-für-Schritt Anleitung für Azubis und Ausbilder zum Arbeiten mit dem SPS-Trainingssystem.

---

## 📋 Inhaltsverzeichnis

1. [Übersicht](#übersicht)
2. [Erster Start](#erster-start)
3. [Grundlegender Workflow](#grundlegender-workflow)
4. [LOGO! Soft Comfort Basics](#logo-soft-comfort-basics)
5. [Praktische Übungen](#praktische-übungen)
6. [Fehlersuche & Debugging](#fehlersuche--debugging)
7. [Best Practices](#best-practices)
8. [Fortgeschrittene Themen](#fortgeschrittene-themen)

---

## 🎯 Übersicht

### Was lernst du hier?

✅ **SPS-Programmierung** nach IEC 61131-3 (FUP/KOP)  
✅ **Hardware-nahe Programmierung** (Relais, Sensoren, PWM)  
✅ **Logische Verknüpfungen** (AND, OR, Timer, Counter)  
✅ **Regelungstechnik** (Zweipunkt, PWM-Regler)  
✅ **Debugging** & Fehlersuche  
✅ **Dokumentation** von Steuerungsprogrammen

### Workflow im Überblick

```
┌─────────────────┐
│ 1. Programmieren│  LOGO! Soft Comfort
│    in LOGO!     │  (Windows PC)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 2. Exportieren  │  CSV oder XML speichern
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 3. Übertragen   │  USB-Stick oder Netzwerk
└────────┬────────┘     → Raspberry Pi
         │
         ▼
┌─────────────────┐
│ 4. Kompilieren  │  build_and_flash.sh
│    & Flashen    │  oder GUI-Tool
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 5. Testen       │  Arduino läuft stand-alone!
│                 │  Kein PC mehr nötig
└─────────────────┘
```

**Zeit pro Durchlauf:** ~2-5 Minuten

---

## 🚀 Erster Start

### Schritt 1: Hardware prüfen

**Checklist vor dem ersten Test:**

```
□ Arduino/ESP32 per USB am Raspberry Pi
□ Relais-Modul angeschlossen (VCC, GND, IN1-IN4)
□ Taster verdrahtet (I1, I2 mit GND)
□ LED am Pin 13 vorhanden (eingebaut bei UNO)
□ Raspberry Pi gebootet und erreichbar
```

### Schritt 2: Test-Programm flashen

**Via Desktop-Icon (einfachste Methode):**

1. Desktop-Icon **"LOGO → UNO/ESP32 Flash"** doppelklicken
2. Datei wählen: `examples/test_blink.csv`
3. Board wählen: **uno** (oder **esp32**)
4. Port wählen: z.B. `/dev/ttyUSB0` (sollte automatisch erkannt werden)
5. **OK** klicken

**Via Terminal:**

```bash
cd ~/logo2uno
./build_and_flash.sh examples/test_blink.csv /dev/ttyUSB0 uno
```

**Erwartetes Ergebnis:**

```
==> Projekt: examples/test_blink.csv
==> Board:   uno (arduino:avr:uno)
==> Port:    /dev/ttyUSB0
==> Ausgabe: /home/pi/logo2uno/generated/test_blink_20250119-143022
🔎 Parsen…
🛠️  Code-Generierung → test_blink.ino
🧱 Kompiliere (arduino:avr:uno)…
⬆️  Flashe auf /dev/ttyUSB0…
====================================
✅ Build & Flash abgeschlossen.
  - HEX/Logs: /home/pi/logo2uno/generated/test_blink_20250119-143022
  - current:  /home/pi/logo2uno/current
====================================
```

**Arduino LED (Pin 13) sollte jetzt blinken!** 🎉

---

## 📝 Grundlegender Workflow

### Phase 1: Programmierung in LOGO! Soft Comfort

#### 1.1 LOGO! Soft starten

```
Start → Programme → Siemens → LOGO! Soft Comfort V8.3
```

#### 1.2 Neues Projekt anlegen

- **Datei → Neu**
- **Gerätetyp wählen:** LOGO! 8 (generisch)
- **Sprache:** FUP (Funktionsplan) empfohlen

#### 1.3 Programm erstellen

**Beispiel: Einfache Blinkschaltung**

```
Baustein-Bibliothek (links):
→ Basic Functions
  → SF: Special Functions
    → Clock Generator (Taktgenerator)

Programmierung:
┌──────────┐
│  Clock   │
│  T=1s    ├───→ Q1
│  (SF1)   │
└──────────┘

1. Clock Generator auf Arbeitsfläche ziehen
2. Doppelklick → Parameter: T=1s
3. Ausgang mit Q1 verbinden
4. Fertig!
```

#### 1.4 Simulieren & Testen

- **Menü: Tools → Simulation starten** (F5)
- Online-Test: Eingänge schalten, Ausgänge beobachten
- Fehler beheben, bis Programm korrekt funktioniert

#### 1.5 Exportieren

**CSV Export (empfohlen für kleine Projekte):**
```
Datei → Exportieren → CSV-Datei
→ Speichern unter: mein_projekt.csv
```

**XML Export (empfohlen für komplexe Projekte):**
```
Datei → Exportieren → XML-Datei
→ Speichern unter: mein_projekt.xml
```

**Wichtig:** 
- Aussagekräftigen Namen wählen
- Datum im Namen hilft: `heizung_regler_20250119.csv`
- Keine Leerzeichen oder Umlaute!

---

### Phase 2: Datei übertragen

#### Option A: USB-Stick

```
1. CSV/XML auf USB-Stick kopieren
2. USB-Stick am Raspberry Pi einstecken
3. Datei-Manager öffnen
4. Kopieren nach: /home/pi/logo2uno/projects/
```

#### Option B: Netzlaufwerk (wenn eingerichtet)

```
Windows Explorer:
→ \\raspberrypi\logo2uno_projects\
→ Datei hineinkopieren
```

#### Option C: Direkt am Raspberry Pi erstellen

```
Raspberry Pi Desktop:
→ LOGO! Soft Comfort kann auch auf Pi laufen (Wine)
→ Oder: Direktes Editieren der CSV (für Fortgeschrittene)
```

---

### Phase 3: Kompilieren & Flashen

#### Methode 1: GUI (empfohlen für Azubis)

**Schritt-für-Schritt:**

1. **Desktop-Icon anklicken**  
   → "LOGO → UNO/ESP32 Flash"

2. **Datei wählen**  
   → Im Dialog: `/home/pi/logo2uno/projects/`  
   → Deine CSV/XML-Datei anklicken  
   → **OK**

3. **Board wählen**  
   → Liste erscheint: `uno` oder `esp32`  
   → Auswahl bestätigen

4. **Port wählen**  
   → Automatisch erkannter Port (z.B. `/dev/ttyUSB0`)  
   → Oder manuell auswählen wenn mehrere

5. **Terminal beobachten**  
   → Zeigt Build-Fortschritt  
   → Bei Erfolg: "✅ Build & Flash abgeschlossen"  
   → Bei Fehler: Fehlermeldung lesen!

6. **Arduino testen**  
   → USB kann jetzt getrennt werden  
   → Arduino läuft stand-alone  
   → Externe 12V Versorgung für Relais/Lasten

**Tipps:**
- Bei ESP32: **Boot-Taste** ggf. beim Upload gedrückt halten
- USB-Kabel direkt am Pi (kein Hub während Upload)
- Bei Fehlern: `build.log` in `~/logo2uno/generated/current/` prüfen

---

#### Methode 2: Kommandozeile (für Fortgeschrittene)

**Terminal öffnen:**
```bash
cd ~/logo2uno
```

**Arduino UNO flashen:**
```bash
./build_and_flash.sh projects/mein_projekt.csv /dev/ttyUSB0 uno
```

**ESP32 flashen:**
```bash
./build_and_flash.sh projects/mein_projekt.csv /dev/ttyUSB0 esp32
```

**Port automatisch erkennen (letzter Parameter weglassen):**
```bash
./build_and_flash.sh projects/mein_projekt.csv
# Script findet automatisch /dev/ttyUSB0 oder /dev/ttyACM0
```

**Nur kompilieren ohne Upload:**
```bash
python3 generator_arduino.py projects/mein_projekt.csv > test.ino
/usr/local/bin/arduino-cli compile --fqbn arduino:avr:uno test.ino
```

---

### Phase 4: Testen & Debuggen

#### Hardware-Test

**Checklist:**

```
□ Arduino läuft (LED 13 blinkt bei Test-Programm?)
□ Relais schalten hörbar (Klick-Geräusch)
□ Relais-LEDs leuchten bei Aktivierung
□ Taster reagieren (Pull-Up richtig konfiguriert?)
□ Sensoren liefern plausible Werte
□ PWM-Ausgabe funktioniert (MOSFET regelt)
```

#### Serial Monitor (optional, für Debug)

**Hardware-Änderung nötig:**

Im generierten `.ino` ist Serial standardmäßig **auskommentar**:

```cpp
void setup() {
  // Serial.begin(115200);  // ← auskommentiert
}
```

**Aktivieren:**
1. Datei öffnen: `~/logo2uno/generated/current/*.ino`
2. Kommentar entfernen: `Serial.begin(115200);`
3. Debug-Ausgaben einfügen:
   ```cpp
   Serial.print("Temperatur: ");
   Serial.println(tempC);
   ```
4. Neu kompilieren & flashen
5. Serial Monitor öffnen:
   ```bash
   /usr/local/bin/arduino-cli monitor -p /dev/ttyUSB0 -c baudrate=115200
   ```

**Tipp:** Für permanentes Debugging besser Hardware-Änderung in `generator_arduino.py` vornehmen.

---

## 📚 LOGO! Soft Comfort Basics

### Wichtigste Bausteine

#### Logik-Bausteine

| Baustein | Symbol | Funktion | Beispiel |
|----------|--------|----------|----------|
| **AND** | `&` | Alle Eingänge HIGH → Ausgang HIGH | Sicherheitsschaltung (alle OK) |
| **OR** | `≥1` | Mind. 1 Eingang HIGH → Ausgang HIGH | Mehrere Taster für eine Lampe |
| **NOT** | `1` | Invertiert Signal | Notaus-Logik |
| **XOR** | `=1` | Genau 1 Eingang HIGH | Wechselschaltung |

#### Timer

| Typ | Name | Funktion |
|-----|------|----------|
| **TON** | On-Delay | Verzögertes Einschalten |
| **TOF** | Off-Delay | Verzögertes Ausschalten |

**TON Beispiel (Treppenlicht):**
```
I1 (Taster) ──┐
              ├─→ TON (T=5s) ──→ Q1 (Licht)
         ─────┘

Funktion:
- Taster drücken: Licht geht sofort an
- Taster loslassen: Licht bleibt 5s an, dann aus
```

**Zeit-Parameter:**
- `T#500ms` = 500 Millisekunden
- `T#5s` = 5 Sekunden
- `T#2m` = 2 Minuten
- `T#1h` = 1 Stunde

#### Flipflops

| Typ | Funktion |
|-----|----------|
| **SR** | Set-Reset (Set dominiert) |
| **RS** | Reset-Set (Reset dominiert) |

**SR Beispiel (Start-Stop-Schaltung):**
```
I1 (Start)  ──→ S ┐
                  ├─ SR ──→ Q1 (Motor)
I2 (Stop)   ──→ R ┘

Funktion:
- Start drücken: Motor läuft
- Stop drücken: Motor stoppt
- Start hat Priorität bei gleichzeitiger Betätigung
```

#### Zähler

| Typ | Name | Funktion |
|-----|------|----------|
| **CTU** | Count Up | Hochzählen bis Preset |
| **CTD** | Count Down | Runterzählen von Preset |

**CTU Beispiel (Stückzähler):**
```
I1 (Sensor) ──→ CU ┐
                   ├─ CTU (PV=10) ──→ Q (Voll-Meldung)
I2 (Reset)  ──→ R  ┘

Funktion:
- Jeder Sensor-Impuls zählt hoch
- Bei 10 Stück: Ausgang Q wird HIGH
- Reset-Taster: Zähler auf 0
```

#### Vergleicher

| Symbol | Funktion | Beispiel |
|--------|----------|----------|
| **>** | Greater Than | Temperatur > 25°C |
| **<** | Less Than | Füllstand < 10% |
| **≥** | Greater Equal | temp ≥ Sollwert |
| **≤** | Less Equal | Drehzahl ≤ max |
| **=** | Equal | Position = Ziel |
| **≠** | Not Equal | Fehlercode ≠ 0 |

---

### Analoge Werte verarbeiten

#### Beispiel: Temperatur-Regelung

**LOGO! Programm:**
```
AI1 (Poti Sollwert) ──┐
                      ├─→ [>] ──→ Q1 (Heizung)
TEMP (DS18B20)     ───┘

Logik:
Wenn Temperatur < Sollwert → Heizung EIN
```

**In hardware_profile.yaml:**
```yaml
pins:
  AI1: A0          # Poti für Sollwert
  TEMP_DS18B20: 12 # DS18B20 Sensor
  Q1: 2            # Relais Heizung
```

**Automatische Code-Generierung:**
```cpp
// Wird automatisch erzeugt:
int sollwert = analogRead(A0);         // 0-1023
sensors.requestTemperatures();
float tempC = sensors.getTempCByIndex(0);

if (tempC < map(sollwert, 0, 1023, 10, 40)) {
  digitalWrite(Q1, RELAYS_ACTIVE_LOW ? LOW : HIGH);  // Heizung EIN
} else {
  digitalWrite(Q1, RELAYS_ACTIVE_LOW ? HIGH : LOW);  // Heizung AUS
}
```

---

## 🎯 Praktische Übungen

### Übung 1: LED-Blinkschaltung ⭐

**Ziel:** Verständnis für Taktgenerator und Ausgänge

**Aufgabe:**
- LED an Q1 soll jede Sekunde blinken
- Taster an I1: Blinken starten/stoppen

**LOGO! Programm:**
```
I1 ──┐
     ├─→ Clock (T=1s) ──→ Q1
     │
     └─→ [Enable]
```

**Hardware:**
- I1 = D9 (Taster gegen GND)
- Q1 = D2 (Relais mit LED)

**Test:**
1. Programm in LOGO! erstellen
2. Als `uebung1_blink.csv` exportieren
3. Flashen auf Arduino
4. Taster drücken → LED blinkt
5. Taster erneut → LED stoppt

---

### Übung 2: Treppenlicht mit Nachlauf ⭐⭐

**Ziel:** Timer verstehen (TON, TOF)

**Aufgabe:**
- Taster drücken → Licht geht an
- Licht bleibt 10 Sekunden nach Loslassen an
- Während Nachlauf: Taster drücken = Zeit verlängern

**LOGO! Programm:**
```
I1 (Taster) ──→ TOF (T=10s) ──→ Q1 (Licht)
```

**Erweiterung:**
- Zweiter Taster I2: Sofort ausschalten (Override)

```
I1 ──→ TOF (T=10s) ──┐
                     ├─ AND ──→ Q1
I2 ──→ NOT ──────────┘
```

---

### Übung 3: Heizungssteuerung ⭐⭐⭐

**Ziel:** Zweipunkt-Regler mit Hysterese

**Aufgabe:**
- DS18B20 misst Temperatur
- Poti an AI1 gibt Sollwert vor
- Heizung (Q1) schaltet bei Unterschreitung
- Hysterese: 2°C (verhindert Takten)

**LOGO! Programm:**
```
TEMP ──┐
       ├─→ [<] ──→ SR ──→ Q1 (Heizung)
AI1 ───┘      │      ↑
              │      │
         (Sollwert)  │
                     │
TEMP ──┐             │
       ├─→ [>] ──────┘ (Reset bei Sollwert+2°C)
AI1+2─ ┘
```

**Hardware:**
- DS18B20 an D12 (mit 4.7kΩ Pull-Up!)
- Poti an A0 (Sollwert 15-30°C)
- Q1 an D2 (Relais für Heizung)

**Test:**
1. Poti auf Mitte drehen (~22°C Sollwert)
2. Mit Fön Sensor erwärmen → Relais geht AUS
3. Abkühlen lassen → Relais schaltet EIN

---

### Übung 4: PWM-Lüfterregelung ⭐⭐⭐

**Ziel:** Analoge Ausgabe (PWM) verstehen

**Aufgabe:**
- CO₂-Sensor (MQ-135) an AI1
- Lüfter-Drehzahl proportional zu CO₂-Wert
- PWM-Ausgang AO1 (0-255)
- Schwellwerte:
  - < 800 ppm: Lüfter aus
  - 800-2000 ppm: proportional 50-100%
  - > 2000 ppm: Lüfter 100% + Alarm (Q1)

**LOGO! Programm:**
```
AI1 (CO₂) ──┐
            ├─→ [Linearisierung] ──→ AO1 (PWM)
            │
            ├─→ [> 2000] ──→ Q1 (Alarm)
            └─→ [< 800] ──→ [NOT] ──→ [Enable PWM]
```

**Hardware:**
- MQ-135 an A0
- MOSFET PWM an D3 (12V Lüfter)
- Relais Q1 an D2 (Alarm-LED)

**Tipp:** MQ-135 braucht ~5 Min Aufheizzeit!

---

### Übung 5: Ampelsteuerung ⭐⭐⭐⭐

**Ziel:** Komplexe Ablaufsteuerung mit Timern

**Aufgabe:**
- 3 Ausgänge: Q1 (Rot), Q2 (Gelb), Q3 (Grün)
- Sequenz:
  1. Rot: 5s
  2. Rot+Gelb: 2s
  3. Grün: 5s
  4. Gelb: 2s
  5. Zurück zu 1.
- Taster I1: Fußgänger-Anforderung (verkürzt Grün)

**LOGO! Programm (vereinfacht):**
```
[Takt] ──→ CTU(5s) ──→ State1 (Rot)
              ↓
         CTU(2s) ──→ State2 (Rot+Gelb)
              ↓
         CTU(5s) ──→ State3 (Grün)
              ↓
         CTU(2s) ──→ State4 (Gelb)
              ↓
         [Reset]
```

**Hardware:**
- Q1 = D2 (Rot)
- Q2 = D4 (Gelb)
- Q3 = D5 (Grün)
- I1 = D9 (Fußgängertaster)

**Zusatz:** Nachtmodus mit Gelb-Blinken (22-6 Uhr)

---

## 🐛 Fehlersuche & Debugging

### Häufige Fehler

#### Fehler 1: "Port nicht gefunden"

**Symptom:**
```
❌ Kein serieller Port gefunden. Schließe UNO/ESP32 an.
```

**Lösung:**
```bash
# Prüfen ob Gerät erkannt wird
ls -l /dev/ttyUSB* /dev/ttyACM*

# Falls leer: USB-Kabel prüfen oder anderen Port probieren
# Falls vorhanden aber Fehler: Rechte prüfen
groups  # sollte "dialout" enthalten

# Falls dialout fehlt:
sudo usermod -a -G dialout $USER
# Dann ab- und wieder anmelden!
```

---

#### Fehler 2: "Kompilierung fehlgeschlagen"

**Symptom:**
```
🧱 Kompiliere (arduino:avr:uno)…
⚠️ Upload fehlgeschlagen.
```

**Debug-Schritte:**

1. **Build-Log prüfen:**
   ```bash
   cat ~/logo2uno/generated/current/build.log
   ```

2. **Häufige Ursachen:**
   - Nicht unterstützter LOGO!-Baustein → Log zeigt "noch nicht implementiert"
   - Syntax-Fehler in CSV/XML
   - Zu viele Variablen (SRAM-Überlauf bei UNO)

3. **Parser-Test:**
   ```bash
   python3 parser_logo.py projects/mein_projekt.csv
   # Zeigt erkannte Blöcke und Warnungen
   ```

4. **Generator-Test:**
   ```bash
   python3 generator_arduino.py projects/mein_projekt.csv > test.ino
   # Öffne test.ino und prüfe auf Syntax-Fehler
   ```

---

#### Fehler 3: Relais schaltet falsch herum

**Symptom:**
- LOGO! sagt "Ausgang AN"
- Relais-LED ist AUS
- Umgekehrt bei "Ausgang AUS"

**Lösung:**

`hardware_profile.yaml` anpassen:

```yaml
flags:
  relays_active_low: false  # ← auf false setzen
```

Dann neu flashen!

**Erklärung:** Die meisten Relais-Module sind Active-LOW, manche aber Active-HIGH.

---

#### Fehler 4: ESP32 bootet nicht / Upload-Fehler

**Symptom:**
```
A fatal error occurred: Failed to connect to ESP32
```

**Lösungen:**

1. **Boot-Modus manuell:**
   - Boot-Taste gedrückt halten
   - Reset-Taste kurz drücken
   - Boot-Taste halten
   - Upload starten
   - Boot-Taste loslassen bei "Connecting..."

2. **Richtigen Port prüfen:**
   ```bash
   ls -l /dev/ttyUSB*
   # ESP32 meist /dev/ttyUSB0 oder /dev/ttyUSB1
   ```

3. **USB-Kabel direkt am Pi (kein Hub während Upload!)**

4. **CH340 Treiber:**
   ```bash
   # Sollte bereits via install.sh installiert sein
   lsmod | grep ch341
   ```

---

#### Fehler 5: DS18B20 zeigt -127°C

**Symptom:**
- Serial Monitor zeigt `-127.00`
- Temperatur funktioniert nicht

**Ursachen & Lösungen:**

1. **Pull-Up Widerstand fehlt:**
   - 4.7kΩ zwischen Daten-Pin und 5V löten/stecken

2. **Falsche Verkabelung:**
   ```
   Richtig:           Falsch:
   Rot → 5V           Rot → GND  ✗
   Schwarz → GND      Schwarz → 5V  ✗
   Gelb → D12         Gelb → irgendwo  ✗
   ```

3. **Sensor defekt:**
   - Mit Multimeter durchmessen
   - Anderen Sensor testen

4. **Pin-Nummer falsch:**
   - `hardware_profile.yaml` prüfen:
     ```yaml
     pins:
       TEMP_DS18B20: 12  # ← muss korrekt sein!
     ```

---

### Debug-Tipps

#### LED-Status-Codes einbauen

**Im LOGO! Programm:**
```
[Error] ──→ Clock (T=100ms) ──→ Q1 (LED)  # Schnelles Blinken = Fehler
[OK]    ──→ Q1                            # Dauerlicht = OK
```

#### Serial Debugging aktivieren

**Temporär im generierten Code:**

```cpp
// In ~/logo2uno/generated/current/*.ino

void loop() {
  // Deine LOGO-Logik...
  
  // Debug-Ausgaben hinzufügen:
  Serial.print("Temp: ");
  Serial.print(tempC);
  Serial.print(" | Sollwert: ");
  Serial.println(sollwert);
  
  delay(50);
}
```

**Dann neu kompilieren & Serial Monitor öffnen:**
```bash
/usr/local/bin/arduino-cli monitor -p /dev/ttyUSB0 -c baudrate=115200
```

---

## 💡 Best Practices

### 1. Immer in LOGO! Soft simulieren!

✅ **Vor jedem Flash:**
- Programm in LOGO! Simulation testen
- Alle Eingangskombinationen durchspielen
- Timer-Funktionen überprüfen

❌ **Nicht blind flashen** → Zeitverlust bei Fehlern!

---

### 2. Sprechende Namen verwenden

**Gut:**
```
heizung_zweipunkt_regler_v2.csv
ampel_fussgaenger_20250119.csv
luefter_co2_pwm.csv
```

**Schlecht:**
```
test.csv
projekt1.csv
neu.csv
```

---

### 3. Versionen dokumentieren

**In LOGO! Projekt-Kommentar:**
```
Projekt: Heizungssteuerung Werkstatt
Version: 2.1
Datum: 2025-01-19
Autor: Max Mustermann
Änderungen:
- Hysterese von 1°C auf 2°C erhöht
- Notaus-Funktion ergänzt (I4)
- PWM-Regelung statt binär

Hardware:
- Arduino UNO R3
- DS18B20 an D12
- Relais Q1 (Heizung)
- MOSFET D3 (PWM-Regelung)
```

**Versionierung mit Git (optional):**
```bash
cd ~/logo2uno/projects
git init
git add heizung_v2.csv
git commit -m "Hysterese auf 2°C erhöht"
```

---

### 4. Hardware-Profil dokumentieren

**Eigene Datei pro Arbeitsplatz:**

```yaml
# hardware_profile_platz1.yaml
meta:
  arbeitsplatz: "Platz 1 - Azubi Max"
  board: "Arduino UNO R3"
  datum: "2025-01-19"
  
pins:
  I1: 9   # Taster Start (grün)
  I2: 10  # Taster Stop (rot)
  Q1: 2   # Relais Heizung (Siemens 12V)
  Q2: 4   # Relais Lüfter (Omron 24V)
  # ... weitere Pins
  
calibration:
  CO2_sensor:
    offset: +50  # Kalibriert am 2025-01-15
```

---

### 5. Sicherheit beachten

#### Elektrische Sicherheit

```
⚠️ WICHTIG:
┌────────────────────────────────────────┐
│ • Nur SELV-Spannung (≤ 48V DC)        │
│ • 12V DC empfohlen für Training       │
│ • Nie 230V ohne Elektrofachkraft!    │
│ • Relais-Nennstrom beachten           │
│ • Schutzleiter bei Metallgehäusen    │
│ • NOT-AUS immer einbauen!             │
└────────────────────────────────────────┘
```

#### Software-Sicherheit

**NOT-AUS immer mit höchster Priorität:**

```
LOGO! Programm:
I4 (NOT-AUS) ──→ NOT ──┐
                       ├─ AND ──→ alle Ausgänge
[Normale Logik] ───────┘

➜ NOT-AUS gedrückt = alle Ausgänge AUS
```

**Im Code:**
```cpp
// Jede Schleife zuerst NOT-AUS prüfen!
void loop() {
  bool notaus = (digitalRead(I4) == LOW);
  if (notaus) {
    // ALLE Ausgänge sofort AUS
    digitalWrite(Q1, RELAYS_ACTIVE_LOW ? HIGH : LOW);
    digitalWrite(Q2, RELAYS_ACTIVE_LOW ? HIGH : LOW);
    digitalWrite(Q3, RELAYS_ACTIVE_LOW ? HIGH : LOW);
    digitalWrite(Q4, RELAYS_ACTIVE_LOW ? HIGH : LOW);
    return; // Keine weitere Logik!
  }
  
  // Normale LOGO-Logik erst danach...
}
```

---

### 6. Test-Driven Programming

**Workflow:**

1. **Klein anfangen:**
   - Zuerst nur 1 Ausgang testen
   - Dann 1 Eingang + 1 Ausgang
   - Schrittweise erweitern

2. **Test-Cases definieren:**
   ```
   Test 1: Taster I1 drücken → Q1 EIN
   Test 2: Taster I1 loslassen → Q1 AUS
   Test 3: Taster I1 + I2 → Q1 UND Q2 EIN
   ...
   ```

3. **Checkliste abhaken:**
   ```
   □ Alle Eingänge getestet
   □ Alle Ausgänge getestet
   □ Timer-Funktionen geprüft
   □ Grenzwerte getestet
   □ NOT-AUS funktioniert
   □ Langzeit-Test (>1h) erfolgreich
   ```

---

### 7. Backup & Wiederherstellung

**Automatisches Backup (eingerichtet via install.sh):**

```bash
# Läuft täglich um 3 Uhr
# Backup in ~/logo2uno_backups/

# Manuelles Backup:
cd ~/logo2uno
tar czf backup_$(date +%Y%m%d).tar.gz projects/ hardware_profile.yaml
```

**Wiederherstellen:**
```bash
cd ~
tar xzf logo2uno_backups/backup_20250119.tar.gz -C logo2uno/
```

---

## 🚀 Fortgeschrittene Themen

### Mehrere Arduinos verwalten

**Szenario:** 5 Arbeitsplätze, jeder mit eigenem Arduino

#### Symbole Links für feste Zuordnung

```bash
# In /etc/udev/rules.d/99-logo2uno-arbeitsplaetze.rules

# Platz 1 - Max
SUBSYSTEM=="tty", ATTRS{serial}=="7583034...", SYMLINK+="arduino_platz1"

# Platz 2 - Lisa
SUBSYSTEM=="tty", ATTRS{serial}=="8593034...", SYMLINK+="arduino_platz2"

# etc.
```

**Serial-Nummer herausfinden:**
```bash
udevadm info -a /dev/ttyUSB0 | grep serial
```

**Flashen auf bestimmten Platz:**
```bash
./build_and_flash.sh projects/max_projekt.csv /dev/arduino_platz1 uno
```

---

### ESP32 WiFi-Integration (geplant)

**Zukunfts-Features:**

```cpp
// ESP32 sendet Status per WiFi
#include <WiFi.h>

void setup() {
  WiFi.begin("SSID", "password");
  // LOGO-Logik läuft parallel
}

void loop() {
  // LOGO-Logik...
  
  // Status per MQTT senden:
  mqttClient.publish("platz1/temperatur", String(tempC));
}
```

**Use-Cases:**
- Fernüberwachung aller Arbeitsplätze
- Daten-Logging in Datenbank
- Web-Dashboard für Ausbilder

---

### I2C-Display Integration

**Hardware:**
- 0.96" OLED (SSD1306)
- Anschluss an SDA=A4, SCL=A5 (UNO)

**Anzeige:**
```
┌────────────────┐
│ Heizung: EIN   │
│ Temp: 22.5°C   │
│ Soll: 20.0°C   │
│ PWM:  75%      │
└────────────────┘
```

**Library:** bereits in arduino-cli installierbar:
```bash
/usr/local/bin/arduino-cli lib install "Adafruit SSD1306"
```

**Im generator_arduino.py ergänzen** (für Fortgeschrittene)

---

### PID-Regler implementieren

**Ziel:** Präzise Temperaturregelung statt Zweipunkt

**LOGO! hat keinen PID-Baustein** → im Generator ergänzen:

```cpp
// PID-Struktur (im Generator)
struct PID {
  float kp, ki, kd;
  float integral, lastError;
  
  float compute(float setpoint, float input, float dt) {
    float error = setpoint - input;
    integral += error * dt;
    float derivative = (error - lastError) / dt;
    lastError = error;
    
    return kp * error + ki * integral + kd * derivative;
  }
};
```

**Verwendung in LOGO! (als Mathematik-Block):**
```
Sollwert ──┐
           ├─→ [PID] ──→ AO1 (PWM)
Ist-Wert ──┘
```

**Parameter tunen:**
```yaml
# hardware_profile.yaml
pid_heizung:
  kp: 10.0
  ki: 0.5
  kd: 2.0
```

---

### Custom LOGO!-Bausteine hinzufügen

**Beispiel: Neuer Baustein "BLINK"**

#### 1. Parser erweitern

```python
# parser_logo.py
SUPPORTED_TYPES.add("BLINK")
```

#### 2. Generator erweitern

```python
# generator_arduino.py

elif t == "BLINK":
    freq = b.get('param', 'T#1s')
    ms = parse_time_param(freq)
    lines.append(f"""
  static unsigned long _blink_last_{bid} = 0;
  static bool _blink_state_{bid} = false;
  if (millis() - _blink_last_{bid} >= {ms}) {{
    _blink_state_{bid} = !_blink_state_{bid};
    _blink_last_{bid} = millis();
  }}
  bool {bid}_q = _blink_state_{bid};
    """)
    if out.startswith('Q'):
        pin = f"PIN_{out}"
        lines.append(f"digitalWrite({pin}, {bid}_q ? (RELAYS_ACTIVE_LOW?LOW:HIGH):(RELAYS_ACTIVE_LOW?HIGH:LOW));")
```

#### 3. In LOGO! CSV manuell einfügen

```csv
Block,Type,Input1,Input2,Output,Parameter
B001,BLINK,,,Q1,T#500ms
```

#### 4. Testen

```bash
./build_and_flash.sh projects/test_blink.csv
```

**Pull Request willkommen!** → Neue Bausteine ins Repository einfließen lassen

---

### Hardware-Erweiterungen

#### 7-Segment-Anzeige (BCD)

**Hardware:**
- 7408 Decoder + 7-Segment Display
- Pins: BCD_A (D14), BCD_B (D15), BCD_C (D16), BCD_D (D17)

**Funktion:**
```cpp
// Zeigt Ziffern 0-9 an
void bcdWrite(uint8_t digit) {
  digitalWrite(PIN_BCD_A, (digit >> 0) & 1);
  digitalWrite(PIN_BCD_B, (digit >> 1) & 1);
  digitalWrite(PIN_BCD_C, (digit >> 2) & 1);
  digitalWrite(PIN_BCD_D, (digit >> 3) & 1);
}
```

**LOGO! Verwendung:**
- Zähler-Ausgang → BCD-Anzeige
- Zeigt Stückzahl / Füllstand / etc.

---

#### Rotary Encoder (KY-040)

**Hardware:**
- KY-040 Drehgeber
- CLK → D18 (A4)
- DT → D19 (A5)
- SW → D7 (Taster)

**Verwendung:**
- Sollwert-Einstellung
- Menü-Navigation
- Feineinstellung Parameter

**Code (bereits im Generator):**
```cpp
#include <Encoder.h>
Encoder enc(PIN_ENC_A, PIN_ENC_B);

void loop() {
  long pos = enc.read();
  // Position als LOGO-Variable
}
```

---

## 📋 Checkliste für Azubis

### Vor dem Start

```
□ Hardware-Aufbau geprüft (siehe HARDWARE.md)
□ Arduino am Raspberry Pi angeschlossen
□ LOGO! Soft Comfort installiert und getestet
□ Zugriff auf Raspberry Pi (SSH oder Desktop)
□ Beispiel-Projekt erfolgreich geflasht
```

### Projekt-Durchführung

```
□ LOGO! Programm erstellt
□ In LOGO! Simulation getestet
□ Als CSV/XML exportiert
□ Auf Pi übertragen (USB/Netzwerk)
□ Kompiliert & geflasht (GUI oder Terminal)
□ Hardware-Test durchgeführt
□ Dokumentation erstellt
□ Projekt im Git gesichert (optional)
```

### Abnahme durch Ausbilder

```
□ Programm funktioniert fehlerfrei
□ Alle Anforderungen erfüllt
□ NOT-AUS funktioniert
□ Dokumentation vollständig
□ Code-Qualität in Ordnung
□ Sicherheitsaspekte beachtet
```

---

## 📚 Weiterführende Ressourcen

### Dokumentation

- **LOGO! Soft Comfort Handbuch:** Siemens Industry Online Support
- **Arduino Reference:** https://www.arduino.cc/reference/de/
- **ESP32 Docs:** https://docs.espressif.com/
- **IEC 61131-3 Standard:** Grundlagen SPS-Programmierung

### Video-Tutorials (empfohlen)

- "LOGO! Soft Comfort Basics" - Siemens YouTube
- "Arduino für Einsteiger" - kreativekiste.de
- "SPS-Programmierung FUP" - Elektrotechnik einfach erklärt

### Community & Support

- **GitHub Issues:** Fehler melden, Features vorschlagen
- **GitHub Discussions:** Fragen stellen, Erfahrungen teilen
- **Wiki:** Tipps & Tricks der Community

---

## 🎓 Zertifizierungs-Projekt (Vorschlag)

### Abschlussprojekt: Komplette Heizungsanlage

**Anforderungen:**

1. **Temperaturregelung**
   - DS18B20 Temperatursensor
   - Sollwert über Poti einstellbar
   - Zweipunkt-Regler mit Hysterese

2. **Lüftersteuerung**
   - PWM-Regelung proportional zu Temperatur
   - Nachlauf nach Heizung AUS (2 Minuten)

3. **Sicherheitsfunktionen**
   - NOT-AUS schaltet alles ab
   - Überhitzungsschutz (>80°C)
   - Frostschutz (<5°C)

4. **Bedienung**
   - 3 Taster: Start, Stop, Reset
   - LEDs: Betrieb (grün), Störung (rot), Heizung (gelb)
   - Buzzer bei Alarm

5. **Dokumentation**
   - FUP-Programm in LOGO! Soft
   - Schaltplan / Verdrahtungsplan
   - Inbetriebnahme-Protokoll
   - Test-Dokumentation

**Bewertungskriterien:**
- Funktionalität: 40%
- Code-Qualität: 20%
- Dokumentation: 20%
- Sicherheit: 20%

**Zeitrahmen:** 2-3 Tage (inklusive Dokumentation)

---

## 📝 Musterlösungen

### Musterlösung: Heizungssteuerung

**LOGO! CSV (vereinfacht):**
```csv
Block,Type,Input1,Input2,Output,Parameter
B001,TEMP_READ,,,M1,
B002,ANALOG_READ,AI1,,M2,
B003,LT,M1,M2,M3,
B004,GT,M1,M2+2,M4,
B005,SR,M3,M4,Q1,
```

**Erklärung:**
- B001: Temperatur von DS18B20 lesen → M1
- B002: Sollwert von Poti lesen → M2
- B003: Ist < Soll? → M3 (Set)
- B004: Ist > Soll+2? → M4 (Reset)
- B005: SR-Flipflop schaltet Heizung Q1

**Hardware-Profil:**
```yaml
pins:
  TEMP_DS18B20: 12
  AI1: A0
  Q1: 2

flags:
  relays_active_low: true

calibration:
  temperature:
    offset: -0.5  # Sensor-Kalibrierung
```

**Test-Protokoll:**
```
Test 1: Poti auf Min → Heizung EIN
Test 2: Mit Fön erwärmen → bei Soll+2 AUS
Test 3: Abkühlen → bei Soll EIN
Test 4: Hysterese überprüft: 2°C ✓
```

---

## 🎉 Abschluss

Herzlichen Glückwunsch! Du hast jetzt alle Grundlagen für die Arbeit mit dem LOGO! → Arduino/ESP32 SPS-Trainingssystem gelernt.

**Was du jetzt kannst:**
✅ SPS-Programme in LOGO! Soft Comfort erstellen  
✅ Programme auf Arduino/ESP32 flashen  
✅ Hardware verdrahten und in Betrieb nehmen  
✅ Fehler finden und beheben  
✅ Eigene Projekte planen und umsetzen

**Nächste Schritte:**
1. Eigene Projekte entwickeln
2. Komplexere Regelungen ausprobieren
3. ESP32 WiFi-Features nutzen (wenn verfügbar)
4. Community beitragen (Pull Requests!)

**Viel Erfolg bei deinen Projekten! 🚀**

---

**Feedback & Verbesserungen:**  
Dieses Trainings-Dokument wird ständig verbessert. Deine Rückmeldungen sind willkommen!

→ [GitHub Issues](https://github.com/dolmario/Arduino-UNO-SPS-Trainingssystem/issues)  
→ [GitHub Discussions](https://github.com/dolmario/Arduino-UNO-SPS-Trainingssystem/discussions)
