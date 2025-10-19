# LOGO! → Arduino UNO: Trainingsanleitung

## Schritt 1: Programm in LOGO! Soft erstellen

1. LOGO! Soft Comfort öffnen
2. Neues Projekt anlegen
3. FUP-Editor: Bausteine ziehen (AND, Timer, SR, etc.)
4. Simulieren und testen
5. **Datei → Exportieren → CSV speichern**

## Schritt 2: Datei übertragen

- USB-Stick: `projekt.csv` kopieren
- Auf Raspberry Pi: nach `/home/pi/logo2uno/` kopieren

## Schritt 3: Kompilieren & Flashen
```bash
cd /home/pi/logo2uno
./build_and_flash.sh examples/mein_projekt.csv /dev/ttyUSB0
```

**Ausgabe:**
```
🔧 Parsing LOGO! Projekt...
🔨 Kompiliere Arduino Sketch...
📤 Upload auf /dev/ttyUSB0...
✅ Erfolgreich geflasht!
```

## Schritt 4: Testen

- Arduino ist jetzt **stand-alone**
- Taster drücken → Relais schalten
- Kein PC/Pi mehr nötig!

## Fehlersuche

| Problem | Lösung |
|---------|--------|
| Port nicht gefunden | `ls /dev/ttyUSB*` → richtigen Port finden |
| Kompilierung fehlt | Prüfe CSV-Syntax |
| Relais schaltet falsch | Active-LOW Flag prüfen |
