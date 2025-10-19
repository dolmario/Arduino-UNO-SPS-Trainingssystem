# 🔌 Arduino SPS Trainingssystem – Hardwareaufbau

Dieses Dokument beschreibt den physischen Aufbau und die Verkabelung des Systems.

---

## ⚙️ Systemübersicht

┌─────────────────────────────────────────────┐
│ Raspberry Pi 3 (Server) │
│ • Läuft als LOGO→UNO Bridge │
│ • Kommuniziert über USB (oder RS485) │
│ • Webserver: http://<pi-ip>:5000 │
│ • Flash der Sketches via arduino-cli │
│
│ ┌──────────────────────────┐
│ │ USB-Hub (powered) │
│ │ ├─ UNO #1 (Platz 1) │
│ │ ├─ UNO #2 (Platz 2) │
│ │ ├─ UNO #3 (Platz 3) │
│ │ ├─ UNO #4 (Platz 4) │
│ │ └─ UNO #5 (Platz 5) │
│ └──────────────────────────┘
└─────────────────────────────────────────────┘


Jeder UNO arbeitet als **Trainingsarbeitsplatz**, an dem Azubis reale Ein- und Ausgänge beschalten.

---

## 🧩 Komponentenliste

| Komponente | Beschreibung | Anzahl |
|-------------|--------------|---------|
| Raspberry Pi 3B+ | Zentrale LOGO→UNO Bridge | 1 |
| Arduino UNO R3 | Steuerungsmodul pro Arbeitsplatz | 3–5 |
| 4-Kanal Relais-Board | Digitale Ausgänge | 1 je UNO |
| MOSFET-Modul (IRF540) | PWM-Last / Heizung | optional |
| DS18B20 | Temperaturfühler | 1 |
| Potentiometer 10kΩ | Analogwertgeber | 1 |
| Taster (4x) | Digitale Eingänge | 1 Satz |
| LED (4x) | Anzeigen | 1 Satz |
| Summer (Buzzer) | Signalgeber | optional |
| Breadboard & Jumperkabel | Verbindungskomponenten | je Arbeitsplatz |

---

## 🪛 Verdrahtung pro Arbeitsplatz (UNO)

### Pinbelegung
| UNO Pin | Funktion | Hardware |
|----------|-----------|-----------|
| D2 | Q1 | Relais 1 |
| D3 | Q2 | Relais 2 |
| D4 | Q3 | Relais 3 |
| D5 | Q4 | Relais 4 |
| D8 | I1 | Taster 1 |
| D9 | I2 | Taster 2 |
| D10 | I3 | Taster 3 |
| D11 | I4 | Taster 4 |
| A0 | AI1 | Potentiometer |
| A1 | AI2 | DS18B20 (OneWire) |
| D6 | PWM1 | MOSFET/Heizung |
| GND | Masse | – |
| 5V | Versorgung | Relaisboard / Sensoren |

> **Hinweis:** Alle Eingänge (Taster) mit `INPUT_PULLUP` betreiben → schalten gegen GND.

---

## 🧲 Sensoren anschließen

### DS18B20 Temperaturfühler
- Rot → 5V  
- Schwarz → GND  
- Gelb → A1  
- Zwischen Gelb und Rot: **4.7 kΩ Pull-Up**

### Potentiometer (AI1)
- Außenpins → 5V / GND  
- Mittelabgriff → A0

---

## ⚡ Relaisboard anschließen
- VCC → 5V  
- GND → GND  
- IN1–IN4 → D2–D5  
- Relaiskontakte (COM/NO/NC) je nach Anwendung (z. B. LED, Summer, Heizung)

---

## 🌡️ MOSFET-Modul
- IN → D6  
- + → Versorgung 12 V  
- – → GND (gemeinsam mit UNO)  
- Output → Heizelement oder LED-Last  

> PWM-Funktion getestet mit 5 V und 12 V-Heizmodulen (bis 3 A über externes Netzteil).

---

## 🧠 Erweiterbar
- I2C-Sensoren (z. B. INA219, OLED) → SDA=A4, SCL=A5  
- Display → 0,96" OLED (SSD1306)  
- Buzzer → Digitaler Pin D7  
- Kommunikationsmodul RS485 → A/B Busleitung am Pi oder UNO

---

## 📦 Montagehinweis
- Gehäuse 3D-gedruckt oder Hutschienengehäuse möglich  
- Beschriftung der Ein-/Ausgänge empfohlen (Klebefolie oder Gravur)
- Azubi-Version: **max. 5 V / 12 V SELV-Spannung** – keine 230 V-Lasten!

---

