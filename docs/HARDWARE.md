# 🔌 Hardware-Aufbau & Verdrahtung

Komplette Anleitung zum physischen Aufbau des LOGO! → Arduino/ESP32 SPS-Trainingssystems.

---

## 📋 Inhaltsverzeichnis

1. [Systemübersicht](#systemübersicht)
2. [Komponentenliste](#komponentenliste)
3. [Arduino UNO Aufbau](#arduino-uno-aufbau)
4. [ESP32 Aufbau](#esp32-aufbau)
5. [Relais-Modul](#relais-modul)
6. [MOSFET PWM-Modul](#mosfet-pwm-modul)
7. [Sensoren](#sensoren)
8. [Raspberry Pi Setup](#raspberry-pi-setup)
9. [Verkabelungsplan](#verkabelungsplan)
10. [Gehäuse & Montage](#gehäuse--montage)
11. [Troubleshooting](#troubleshooting)

---

## 🏗️ Systemübersicht

```
┌────────────────────────────────────────────────────────────┐
│                    Raspberry Pi 3/4                        │
│  • Kompilier-Server für alle Arbeitsplätze                │
│  • arduino-cli (UNO + ESP32 Support)                      │
│  • Web-GUI (optional)                                      │
│  • Projekt-Verwaltung                                      │
│                                                            │
│  ┌──────────────────────────────────────────────────┐    │
│  │         Powered USB Hub (7-10 Port)              │    │
│  │  ┌────────┬────────┬────────┬────────┬────────┐ │    │
│  │  │ UNO #1 │ UNO #2 │ ESP32  │ UNO #4 │ UNO #5 │ │    │
│  │  │ /USB0  │ /USB1  │ /USB2  │ /USB3  │ /USB4  │ │    │
│  │  └────────┴────────┴────────┴────────┴────────┘ │    │
│  └──────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────┘
              │         │         │         │         │
              ▼         ▼         ▼         ▼         ▼
        [Platz 1] [Platz 2] [Platz 3] [Platz 4] [Platz 5]
         Azubi A   Azubi B   Azubi C   Azubi D   Azubi E
```

**Jeder Arbeitsplatz ist autark:**
- Arduino/ESP32 mit eigenem Relais-Board
- Individuelle Sensoren & Aktoren
- Nach Upload: Stand-Alone Betrieb (kein Pi nötig!)
- USB nur zum Flashen neuer Programme

---

## 📦 Komponentenliste

### Pro Arbeitsplatz (Standard-Setup)

| Komponente | Anzahl | Kosten | Bezugsquelle |
|------------|--------|--------|--------------|
| **Arduino UNO R3** oder **ESP32 DevKit** | 1 | ~8-15€ | AZ-Delivery, Amazon, eBay |
| **4-Kanal Relais-Modul 5V** | 1 | ~5€ | Amazon, Reichelt |
| **MOSFET-Modul IRF540** (2-Kanal) | 1 | ~3€ | AZ-Delivery |
| **DS18B20 Temperatursensor** (wasserdicht) | 1 | ~3€ | Amazon |
| **MQ-135 CO₂/Gas-Sensor** | 1 | ~4€ | Amazon |
| **Potentiometer 10kΩ** | 2 | ~1€ | Reichelt |
| **Taster (Schließer)** | 4 | ~2€ | Reichelt |
| **LED 5mm (Rot/Gelb/Grün)** | 6 | ~1€ | Reichelt |
| **Widerstände 220Ω** (für LEDs) | 6 | ~1€ | Reichelt |
| **Widerstand 4.7kΩ** (Pull-Up DS18B20) | 1 | ~0.20€ | Reichelt |
| **Breadboard 830 Pins** | 1 | ~4€ | Amazon |
| **Jumper-Kabel Set** | 1 | ~5€ | Amazon |
| **USB-Kabel (A zu B für UNO)** | 1 | ~2€ | Reichelt |
| **Netzteil 12V/2A** (für Relais-Last) | 1 | ~8€ | Amazon |
| **Piezo-Buzzer 5V** | 1 | ~1€ | Reichelt |
| **Hutschienen-Gehäuse** (optional) | 1 | ~15€ | Reichelt |

**Gesamt pro Platz:** ~63€ (Arduino UNO) / ~70€ (ESP32)

### Zentral (einmalig)

| Komponente | Anzahl | Kosten |
|------------|--------|--------|
| **Raspberry Pi 3B+ oder 4** | 1 | ~40-60€ |
| **Raspberry Pi Netzteil** | 1 | ~10€ |
| **microSD-Karte 32GB** | 1 | ~8€ |
| **USB-Hub powered (10-Port)** | 1 | ~25€ |
| **Netzwerk-Switch** (optional) | 1 | ~15€ |

**Zentral gesamt:** ~98-118€

### Gesamtkosten für 5 Arbeitsplätze
- **Zentrale:** ~110€
- **5× Arbeitsplätze:** ~315€ (UNO) / ~350€ (ESP32)
- **GESAMT:** ~425-460€

**Vergleich:** 1× LOGO! 8 Modul ≈ 800€ 🎯

---

## 🔧 Arduino UNO Aufbau

### Pinbelegung Standard-Profil

```
        Arduino UNO R3
        ┌─────────┐
    RESET│1  •  28│A5 (SCL)
      3V3│2     27│A4 (SDA)
       5V│3     26│A3 → I4 (Sensor Digital)
      GND│4     25│A2 → I3 (Sensor Digital)
      GND│5     24│A1 → AI2 (NOx Analog)
      Vin│6     23│A0 → AI1 (CO₂ Analog)
          │       │
       A0│14    22│D13 → LED_STATUS
       A1│15    21│D12 → TEMP (DS18B20)
       A2│16    20│D11
       A3│17    19│D10 → I2 (Taster 2)
       A4│18    18│D9  → I1 (Taster 1)
       A5│19    17│D8  → BUZZER
          │       │
       D0│7     16│D7  → Q4 (Relais 4)
       D1│8     15│D6  → AO2_PWM (MOSFET 2)
       D2│9  ▓  14│D5  → Q3 (Relais 3)
       D3│10 ▓  13│D4  → Q2 (Relais 2)
          └─────────┘
    D2 → Q1 (Relais 1)
    D3 → AO1_PWM (MOSFET 1)
    
    ▓ = PWM-fähig
```

### Wichtige Eigenschaften UNO

- **MCU:** ATmega328P (16 MHz)
- **Flash:** 32 KB (2 KB Bootloader)
- **SRAM:** 2 KB (⚠️ begrenzt!)
- **EEPROM:** 1 KB
- **Digital I/O:** 14 (davon 6 PWM)
- **Analog Input:** 6× 10-bit (0-1023)
- **Spannung:** 5V Logik
- **Max. Strom pro Pin:** 40 mA

### Strombegrenzung beachten!

```
⚠️ WICHTIG: Arduino Pin-Ströme
┌────────────────────────────────────┐
│ • Pro Pin max: 40 mA               │
│ • Alle Pins gesamt: 200 mA         │
│ • 5V-Rail gesamt: 500 mA (USB)     │
│                                    │
│ ➜ Relais NIEMALS direkt schalten! │
│ ➜ Immer Transistor/MOSFET nutzen  │
│ ➜ Externe 12V für Lasten          │
└────────────────────────────────────┘
```

---

## 📡 ESP32 Aufbau

### Pinbelegung ESP32 DevKit v1

```
        ESP32 DevKit v1 (38 Pin)
        ┌─────────────┐
     EN│1         38│GND
  VP/36│2         37│D23 (SPI MOSI)
  VN/39│3         36│D22 (I2C SCL)
    D34│4         35│TX0
    D35│5         34│RX0
    D32│6     •   33│D21 (I2C SDA)
    D33│7     •   32│GND
    D25│8         31│D19 (SPI MISO)
    D26│9         30│D18 (SPI SCK)
    D27│10        29│D5  → Q3 (Relais 3)
    D14│11        28│D17 → Q2 (Relais 2)
    D12│12        27│D16 → Q1 (Relais 1)
    GND│13        26│D4  → Q4 (Relais 4)
    D13│14        25│D0  → BOOT (nicht nutzen!)
     D9│15        24│D2  → LED_STATUS
    D10│16        23│D15 → AO2_PWM
    D11│17        22│GND
     5V│18        21│3V3
        └─────────────┘

Analog Input (12-bit: 0-4095):
- VP (GPIO36) → AI1
- VN (GPIO39) → AI2
- D34, D35, D32, D33 auch nutzbar

PWM: Alle GPIO-Pins (16× unabhängig!)
```

### ESP32 Besonderheiten

✅ **Vorteile:**
- Deutlich mehr RAM (520 KB!)
- 12-bit ADC (4096 Stufen statt 1024)
- WiFi + Bluetooth integriert
- 16× PWM-Kanäle (UNO nur 6)
- Mehr Pins verfügbar
- Höhere Taktrate (240 MHz)

⚠️ **Nachteile/Besonderheiten:**
- 3.3V Logik (nicht 5V!)
- Einige Pins haben Boot-Funktion (D0, D2, D12, D15)
- ADC2 nicht nutzbar bei aktiver WiFi
- Komplexeres Pin-Multiplexing

### Boot-Modus beim Flashen

```
ESP32 Upload-Prozess:
┌─────────────────────────────────┐
│ 1. Boot-Taste gedrückt halten   │
│ 2. Reset-Taste kurz drücken     │
│ 3. Upload starten               │
│ 4. Boot-Taste loslassen         │
│                                 │
│ Alternative: Auto-Reset         │
│ (manche Boards haben DTR/RTS)   │
└─────────────────────────────────┘
```

---

## 🔌 Relais-Modul

### 4-Kanal 5V Relais (JQC-3FF)

**Typisches Modul:**
```
    ┌────────────────────────────┐
    │  4-Channel Relay Module    │
    │                            │
    │  [LED] [LED] [LED] [LED]   │
    │   IN1   IN2   IN3   IN4    │
    │  [=====][=====][=====][===] │ ← Relais
    │                            │
    │  VCC GND IN1 IN2 IN3 IN4   │ ← Anschlüsse
    └────────────────────────────┘
         │   │   │   │   │   │
         │   │   └───┴───┴───┴── zu Arduino Dx
         │   └── GND
         └── 5V

Relaiskontakte (pro Kanal):
    COM ─┐
         ├─── NO (Normal Open)
         └─── NC (Normal Closed)
```

### Verdrahtung

| Relais | Arduino | ESP32 | Funktion |
|--------|---------|-------|----------|
| VCC | 5V | 5V* | Versorgung |
| GND | GND | GND | Masse |
| IN1 | D2 | D16 | Relais 1 (Heizung) |
| IN2 | D4 | D17 | Relais 2 (Lüfter) |
| IN3 | D5 | D5 | Relais 3 (Licht) |
| IN4 | D7 | D4 | Relais 4 (Alarm) |

*ESP32: Externe 5V vom Netzteil, nicht vom 3.3V Pin!

### Active-LOW Konfiguration

**Die meisten Relais-Module sind Active-LOW:**

```yaml
# hardware_profile.yaml
flags:
  relays_active_low: true  # ← Standard!
```

Das bedeutet:
- `digitalWrite(LOW)` = Relais EIN (LED leuchtet)
- `digitalWrite(HIGH)` = Relais AUS (LED aus)

**Grund:** Optokoppler im Modul invertiert Signal.

### Lasten anschließen

⚠️ **SICHERHEIT BEACHTEN!**

```
Beispiel: LED über Relais schalten

    +12V ─┬─── [+] LED [-] ──┬── zu Relais COM
          │                   │
          └── [+] LED2 [-] ───┘
          
    Relais NO ───────────────── GND (12V)
    
    ➜ Wenn Relais EIN: LED leuchtet
    ➜ Wenn Relais AUS: LED aus
```

**Maximale Schaltleistung (typisch):**
- 230V AC / 10A
- 30V DC / 10A
- 250V AC / 10A

**Für Azubi-Training:**
- Nur SELV nutzen (≤ 48V DC / ≤ 24V AC)
- 12V DC empfohlen
- Keine 230V ohne Elektrofachkraft!

---

## ⚡ MOSFET PWM-Modul

### IRF540 MOSFET-Board (2-Kanal)

**Typisches Layout:**
```
    ┌─────────────────────┐
    │  PWM → V+ MOSFET    │
    │   │     │    │      │
    │  [▓]   [▓]  [▓]     │ ← Schraubklemmen
    │  PWM   V+   OUT     │
    │                     │
    │  GND                │
    └─────────────────────┘
```

### Anschluss für stufenlose Regelung

**Kanal 1 (Heizung):**
```
Arduino D3 (PWM) ──→ PWM (Kanal 1)
                     V+  ──→ 12V Netzteil (+)
                     OUT ──→ Heizung (+)
                     
Heizung (-) ──→ GND (gemeinsam mit Arduino!)
```

**Kanal 2 (Lüfter):**
```
Arduino D6 (PWM) ──→ PWM (Kanal 2)
                     V+  ──→ 12V
                     OUT ──→ Lüfter (+)
```

### PWM-Werte

```cpp
// 0-255 Bereich (8-bit PWM)
analogWrite(AO1_PWM, 0);    // 0% = AUS
analogWrite(AO1_PWM, 64);   // 25%
analogWrite(AO1_PWM, 128);  // 50%
analogWrite(AO1_PWM, 192);  // 75%
analogWrite(AO1_PWM, 255);  // 100% = Voll
```

### Active-HIGH Konfiguration

**MOSFET-Module sind meist Active-HIGH:**

```yaml
# hardware_profile.yaml
flags:
  mosfet_active_low: false  # ← Standard!
```

Das bedeutet:
- PWM 255 = Maximale Leistung
- PWM 0 = Aus

---

## 🌡️ Sensoren

### DS18B20 Temperatursensor (OneWire)

**Verdrahtung wasserdichter Sensor:**

```
    DS18B20 (wasserdicht)
    ┌────────────┐
    │  Schwarz   │ ── GND
    │  Rot       │ ── 5V (oder 3.3V bei ESP32)
    │  Gelb      │ ── zu Arduino D12
    └────────────┘
         │
      [4.7kΩ]  ← Pull-Up Widerstand
         │
        5V
```

**Arduino-Code (bereits im Generator):**
```cpp
#include <OneWire.h>
#include <DallasTemperature.h>

OneWire oneWire(12);  // D12
DallasTemperature sensors(&oneWire);

void setup() {
  sensors.begin();
}

void loop() {
  sensors.requestTemperatures();
  float tempC = sensors.getTempCByIndex(0);
  // Verwendung in LOGO-Logik...
}
```

**Adressierung mehrerer Sensoren:**
- Jeder DS18B20 hat eindeutige 64-bit Adresse
- Bis zu 127 Sensoren auf einem Bus!
- Abfrage via `getTempCByIndex(n)`

---

### MQ-135 / MQ-x Gas-Sensoren (Analog)

**Anschluss MQ-135 (CO₂/Luftqualität):**

```
    MQ-135 Modul
    ┌──────────┐
    │  VCC     │ ── 5V
    │  GND     │ ── GND
    │  A0      │ ── Arduino A0 (AI1)
    │  D0      │ ── optional: Arduino D16 (A2)
    └──────────┘
```

**Kalibrierung in `hardware_profile.yaml`:**

```yaml
calibration:
  CO2_sensor:
    min_adc: 0
    max_adc: 1023
    min_ppm: 400      # Frischluft
    max_ppm: 5000     # Kritisch
```

**Umrechnung im Code:**
```cpp
int raw = analogRead(AI1);
float ppm = map(raw, 0, 1023, 400, 5000);
```

**Aufheizzeit beachten:**
- MQ-Sensoren brauchen ~24h Burn-In
- Erste 3-5 Minuten Betrieb: Werte instabil
- Empfehlung: Dauerbetrieb oder Vorheizphase

---

### Potentiometer (Sollwert-Einstellung)

**Anschluss:**
```
    Poti 10kΩ
    ┌─────┐
    │  1  │ ── 5V (oder 3.3V bei ESP32)
    │  2  │ ── Arduino A0 (AI1)
    │  3  │ ── GND
    └─────┘
```

**Verwendung:**
- Sollwert-Vorgabe (z.B. Temperatur)
- Drehzahl-Einstellung
- Helligkeitsregelung

---

### Taster (Digital Input)

**Schaltung mit Pull-Up:**

```
    Arduino D9 ──┬── [Taster] ── GND
                 │
              (intern Pull-Up aktiviert)
```

**Code (automatisch im Generator):**
```cpp
pinMode(I1, INPUT_PULLUP);  // Pull-Up aktivieren

// Lesen:
bool pressed = (digitalRead(I1) == LOW);  // LOW = gedrückt!
```

**Vorteil Pull-Up:**
- Keine externen Widerstände nötig
- Taster nur zwischen Pin und GND
- Sichere Funktion (kein Floating)

---

## 🖥️ Raspberry Pi Setup

### Hardware

**Empfohlung:**
- Raspberry Pi 3B+ oder Pi 4 (2GB+)
- 32 GB microSD (Class 10 / A1)
- Powered USB-Hub (mind. 10 Port, 2A pro Port)
- Gehäuse mit Lüfter (optional)

### Netzwerk-Integration

**Variante A – Ethernet (empfohlen):**
```
Router ── [ETH] ── Raspberry Pi
                      │
                   [USB-Hub] ── UNO/ESP32
```

**Variante B – WiFi:**
```
Router ~~~ WiFi ~~~ Raspberry Pi
                      │
                   [USB-Hub] ── UNO/ESP32
```

**Zugriff:**
- SSH: `ssh pi@raspberrypi.local`
- Samba: `\\raspberrypi\logo2uno_generated`
- Web-GUI: `http://raspberrypi.local:5000` (geplant)

### USB-Identifikation

**Symbole Links erstellen (optional):**

```bash
# In /etc/udev/rules.d/99-logo2uno.rules
SUBSYSTEM=="tty", ATTRS{serial}=="75830343638351E0B181", SYMLINK+="arduino_platz1"
SUBSYSTEM=="tty", ATTRS{serial}=="85930343638351E0B191", SYMLINK+="arduino_platz2"
# etc.
```

**Serial-Nummern auslesen:**
```bash
udevadm info -a /dev/ttyUSB0 | grep serial
```

---

## 📐 Verkabelungsplan

### Kompletter Arbeitsplatz (UNO-Basis)

```
┌──────────────────────────────────────────────────────────────┐
│                   TRAININGSARBEITSPLATZ                      │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────┐          ┌─────────────────┐              │
│  │  Arduino   │          │  4-Relais-Modul │              │
│  │   UNO R3   │          │                 │              │
│  │            │  D2 ─────┤ IN1  COM─NO─NC  ├─── Heizung   │
│  │       5V ──┼──────────┤ VCC             │              │
│  │      GND ──┼──────────┤ GND             │              │
│  │       D4 ──┼──────────┤ IN2  COM─NO─NC  ├─── Lüfter    │
│  │       D5 ──┼──────────┤ IN3  COM─NO─NC  ├─── Licht     │
│  │       D7 ──┼──────────┤ IN4  COM─NO─NC  ├─── Alarm     │
│  │            │          └─────────────────┘              │
│  │       D3 ──┼──┐                                         │
│  │       D6 ──┼──┼──┐    ┌──────────────┐                │
│  │            │  │  │    │ MOSFET-Modul │                │
│  │            │  │  └────┤ PWM1         │                │
│  │            │  └───────┤ PWM2         │                │
│  │            │          │ V+ ←── 12V   │                │
│  │            │          │ OUT1 ── Heizung (stufenlos)   │
│  │            │          │ OUT2 ── Lüfter (stufenlos)    │
│  │            │          └──────────────┘                │
│  │            │                                           │
│  │      D12 ──┼──┐  [4.7kΩ]                             │
│  │            │  │     │                                  │
│  │            │  └─────┴── DS18B20 (Gelb)                │
│  │       5V ──┼──────────── DS18B20 (Rot)                │
│  │      GND ──┼──────────── DS18B20 (Schwarz)            │
│  │            │                                           │
│  │       A0 ──┼─────── Poti (Mittel)                     │
│  │       A1 ──┼─────── MQ-135 (A0)                       │
│  │            │                                           │
│  │       D9 ──┼──┬── [Taster I1] ── GND                  │
│  │      D10 ──┼──┴── [Taster I2] ── GND                  │
│  │            │                                           │
│  │       D8 ──┼────── Buzzer (+)                         │
│  │      GND ──┼────── Buzzer (-)                         │
│  │            │                                           │
│  │      USB ──┼══════════════════════╗                   │
│  └────────────┘                      ║                   │
│                                      ║                   │
│         ┌────────────────────────────╨──────┐            │
│         │  Raspberry Pi USB-Hub (Powered)   │            │
│         │  (nur zum Flashen / USB-Trennung  │            │
│         │   für Stand-Alone Betrieb)        │            │
│         └───────────────────────────────────┘            │
└──────────────────────────────────────────────────────────────┘
```

---

## 🏠 Gehäuse & Montage

### Option 1: Breadboard-Aufbau (Prototyp)

**Vorteile:**
- ✅ Schneller Start
- ✅ Flexibel änderbar
- ✅ Lerneffekt hoch

**Nachteile:**
- ❌ Wackelkontakte
- ❌ Nicht transportabel
- ❌ Unordentlich

---

### Option 2: Hutschienengehäuse (Profi)

**Material:**
- Hutschienen-Gehäuse (z.B. Phoenix Contact)
- DIN-Schiene 35mm
- Durchführungen für Kabel

**Montage:**
- Arduino auf DIN-Adapter
- Relais-Modul auf Hutschiene
- Klemmen für I/O

**Vorteile:**
- ✅ Professionell
- ✅ Robust
- ✅ Erweiterbar
- ✅ Wie echte SPS

---

### Option 3: 3D-gedrucktes Gehäuse

**STL-Dateien:** (geplant im Repository)
- `case_uno_relais.stl`
- `case_esp32_complete.stl`
- `mounting_plate.stl`

**Features:**
- Aussparungen für USB, Sensoren
- Befestigung für Breadboard
- Kabelführungen
- Beschriftungsfelder

---

## 🔧 Troubleshooting

### Problem: Relais schaltet nicht

**Checkliste:**
1. Spannung prüfen: VCC = 5V?
2. GND-Verbindung vorhanden?
3. Active-LOW richtig konfiguriert?
4. LED am Relais-Modul leuchtet?
5. Signal-Pin richtig verbunden?

**Test:**
```cpp
digitalWrite(Q1, LOW);  // sollte EIN schalten
delay(1000);
digitalWrite(Q1, HIGH); // sollte AUS schalten
```

---

### Problem: DS18B20 liefert -127°C

**Ursachen:**
- Pull-Up Widerstand fehlt (4.7kΩ!)
- Falsche Verkabelung (VCC/GND vertauscht?)
- Sensor defekt
- OneWire-Adresse falsch

**Debug:**
```cpp
sensors.requestTemperatures();
Serial.println(sensors.getTempCByIndex(0));
// -127.0 = Sensor nicht gefunden
```

---

### Problem: ESP32 bootet nicht

**Mögliche Ursachen:**
- Strapping Pins falsch belegt (D0, D2, D12, D15)
- Zu viel Last am 3.3V Pin
- Fehlerhafte Upload (Boot-Modus nicht aktiviert)

**Lösung:**
- Boot-Taste beim Upload halten
- Strapping Pins nur nach Boot nutzen
- Externe 5V für Relais/Sensoren

---

### Problem: USB-Port nicht gefunden

```bash
# Ports auflisten
ls -l /dev/ttyUSB* /dev/ttyACM*

# Rechte prüfen
groups  # sollte "dialout" enthalten

# UDEV neu laden
sudo udevadm control --reload-rules
sudo udevadm trigger

# Neuanmeldung nötig?
sudo usermod -a -G dialout $USER
# → dann logout/login
```

---

## 📚 Weiterführende Links

- [Arduino UNO Daten

