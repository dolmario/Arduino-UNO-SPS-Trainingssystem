#!/bin/bash
# LOGO! → Arduino: Komplette Installation für Raspberry Pi
# 
# Installation:
#   curl -fsSL https://raw.githubusercontent.com/dolmario/Arduino-UNO-SPS-Trainingssystem/main/install.sh | bash
#
# Oder manuell:
#   git clone https://github.com/dolmario/Arduino-UNO-SPS-Trainingssystem.git
#   cd logo2uno
#   chmod +x install.sh
#   ./install.sh

set -e  # Exit bei Fehler

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════╗"
    echo "║                                                    ║"
    echo "║    LOGO! → Arduino SPS-Trainingssystem            ║"
    echo "║    Automatische Installation                      ║"
    echo "║                                                    ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
}

print_step() {
    echo -e "${YELLOW}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# ============================================
# Systemprüfung
# ============================================
check_system() {
    print_step "Prüfe System..."
    
    # Raspberry Pi?
    if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
        print_info "Kein Raspberry Pi erkannt, aber Installation läuft auch auf anderen Linux-Systemen"
    else
        print_success "Raspberry Pi erkannt"
    fi
    
    # Debian/Ubuntu?
    if [ ! -f /etc/debian_version ]; then
        print_error "Nur Debian/Ubuntu/Raspbian wird unterstützt!"
        exit 1
    fi
    
    # Root oder sudo?
    if [ "$EUID" -eq 0 ]; then
        SUDO=""
    else
        if ! command -v sudo &> /dev/null; then
            print_error "sudo nicht gefunden! Bitte als root ausführen oder sudo installieren."
            exit 1
        fi
        SUDO="sudo"
    fi
}

# ============================================
# System-Update
# ============================================
update_system() {
    print_step "Aktualisiere System..."
    
    $SUDO apt-get update -qq
    $SUDO apt-get upgrade -y -qq
    
    print_success "System aktualisiert"
}

# ============================================
# Python & Dependencies
# ============================================
install_python_deps() {
    print_step "Installiere Python & Dependencies (PEP-668-sicher)..."
    # Basis
    $SUDO apt-get install -y -qq python3 python3-full python3-pip python3-venv git curl wget

    # Erst über APT (sauber unter Debian/RPi OS – vermeidet PEP 668)
    # Namen unter Debian/RPi OS:
    $SUDO apt-get install -y -qq python3-yaml python3-serial || true

    # Prüfen, ob Module verfügbar sind; wenn nicht -> fallback auf venv
    PY_OK=1
    python3 - <<'PYCHECK' || PY_OK=0
try:
    import yaml, serial
    print("OK")
except Exception as e:
    raise
PYCHECK

    if [ $PY_OK -eq 1 ]; then
        print_success "Python-Module via APT vorhanden (pyyaml, pyserial)"
        return
    fi

    print_info "APT-Module fehlen/zu alt – nutze virtuelle Umgebung (venv)"
    cd "/home/$USER/logo2uno" || mkdir -p "/home/$USER/logo2uno" && cd "/home/$USER/logo2uno"

    # venv anlegen
    if [ ! -d venv ]; then
        python3 -m venv venv
    fi
    source venv/bin/activate

    # In venv mit pip (kein PEP-668-Problem)
    pip install --upgrade pip
    pip install pyyaml pyserial

    # venv-Wrapper-Skript anlegen, damit andere Skripte immer die venv nutzen
    cat > venv_python <<'EOF'
#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/venv/bin/activate"
exec python "$@"
EOF
    chmod +x venv_python

    print_success "Python-Dependencies in venv installiert"
}

# ============================================
# Arduino CLI
# ============================================
install_arduino_cli() {
    print_step "Installiere Arduino CLI..."
    
    # Prüfe ob schon installiert
    if command -v arduino-cli &> /dev/null; then
        print_info "Arduino CLI bereits installiert ($(arduino-cli version))"
        return
    fi
    
    # Download & Install
    cd /tmp
    curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
    
    # Nach /usr/local/bin verschieben
    $SUDO mv bin/arduino-cli /usr/local/bin/
    
    # Konfiguration
    arduino-cli config init
    arduino-cli core update-index
    arduino-cli core install arduino:avr
    
    print_success "Arduino CLI installiert"
}

# ============================================
# Arduino Libraries
# ============================================
install_arduino_libs() {
    print_step "Installiere Arduino Libraries..."
    
    arduino-cli lib install "OneWire"
    arduino-cli lib install "DallasTemperature"
    
    # Optional: Weitere Libraries
    # arduino-cli lib install "Adafruit SSD1306"
    # arduino-cli lib install "Adafruit GFX Library"
    
    print_success "Arduino Libraries installiert"
}

# ============================================
# USB Permissions
# ============================================
setup_usb_permissions() {
    print_step "Richte USB-Berechtigungen ein..."

    # 1) User in die Gruppe 'dialout' (serieller Zugriff)
    $SUDO usermod -a -G dialout "$USER"

    # 2) udev-Regeln für verschiedene Arduino/Clone-Chips
    #    SUBSYSTEM 'tty' ist hier korrekt, weil die seriellen Geräte als /dev/tty* erscheinen.
    cat <<'UDEV' | $SUDO tee /etc/udev/rules.d/99-arduino.rules >/dev/null
# Original Arduino (VID 2341 / 2a03)
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", MODE="0666", GROUP="dialout"
SUBSYSTEM=="tty", ATTRS{idVendor}=="2a03", MODE="0666", GROUP="dialout"
# CH340/CH341 (meist UNO/Nano-Klone)
SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", MODE="0666", GROUP="dialout"
# FTDI-Adapter
SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", MODE="0666", GROUP="dialout"
# CDC-ACM (generisch, z. B. Atmel)
SUBSYSTEM=="tty", KERNEL=="ttyACM*", MODE="0666", GROUP="dialout"
UDEV

    # Regeln neu laden und auf bereits angesteckte Geräte anwenden
    $SUDO udevadm control --reload-rules
    $SUDO udevadm trigger

    print_success "USB-Berechtigungen konfiguriert"
    print_info "Hinweis: Einmal ab- und wieder anmelden (oder reboot), damit die Gruppenmitgliedschaft aktiv wird."
}


# ============================================
# Repository clonen
# ============================================
setup_project() {
    print_step "Richte Projekt ein..."
    
    PROJECT_DIR="/home/$USER/logo2uno"
    
    # Prüfe ob bereits existiert
    if [ -d "$PROJECT_DIR" ]; then
        print_info "Projekt-Verzeichnis existiert bereits"
        cd "$PROJECT_DIR"
        git pull || true
    else
        # Clone Repository (ANPASSEN!)
        # git clone https://github.com/dolmario/Arduino-UNO-SPS-Trainingssystem.git "$PROJECT_DIR"
        
        # Fallback: Erstelle Struktur manuell
        mkdir -p "$PROJECT_DIR"
        cd "$PROJECT_DIR"
        
        mkdir -p examples generated docs
        
        print_info "Repository nicht geclont (URL anpassen!)"
        print_info "Dateien bitte manuell nach $PROJECT_DIR kopieren"
    fi
    
    # Scripts ausführbar machen
    chmod +x build_and_flash.sh 2>/dev/null || true
    chmod +x parser_logo.py 2>/dev/null || true
    chmod +x generator_arduino.py 2>/dev/null || true
    
    print_success "Projekt-Struktur eingerichtet: $PROJECT_DIR"
}

# ============================================
# Test-Beispiele erstellen
# ============================================
create_examples() {
    print_step "Erstelle Test-Beispiele..."
    
    cd /home/$USER/logo2uno/examples
    
    # Beispiel 1: Blinker
    cat > test_blink.csv << 'EOF'
Block,Type,Input1,Input2,Output,Parameter
B001,NOT,I1,,M1,
B002,TON,M1,,Q1,T#1s
EOF
    
    # Beispiel 2: AND-Verknüpfung
    cat > test_and.csv << 'EOF'
Block,Type,Input1,Input2,Output,Parameter
B001,AND,I1,I2,Q1,
EOF
    
    # Beispiel 3: SR-Flipflop
    cat > test_flipflop.csv << 'EOF'
Block,Type,Input1,Input2,Output,Parameter
B001,SR,I1,I2,Q1,
EOF
    
    print_success "Test-Beispiele erstellt"
}

# ============================================
# Systemd Service (Autostart)
# ============================================
create_systemd_service() {
    print_step "Richte Autostart ein..."
    
    # Web-Interface Service (optional)
    cat > /tmp/logo2uno-web.service << EOF
[Unit]
Description=LOGO2UNO Web Interface
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/home/$USER/logo2uno
ExecStart=/usr/bin/python3 web_ui/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Service installieren (wenn web_ui existiert)
    if [ -f "/home/$USER/logo2uno/web_ui/app.py" ]; then
        $SUDO mv /tmp/logo2uno-web.service /etc/systemd/system/
        $SUDO systemctl daemon-reload
        $SUDO systemctl enable logo2uno-web.service
        print_success "Autostart konfiguriert"
    else
        print_info "Web-Interface nicht gefunden, Autostart übersprungen"
    fi
}

# ============================================
# README erstellen
# ============================================
create_readme() {
    print_step "Erstelle README..."
    
    cd /home/$USER/logo2uno
    
    cat > QUICKSTART.md << 'EOF'
# LOGO! → Arduino: Quick Start

## 🚀 Erstes Projekt flashen

```bash
cd ~/logo2uno
./build_and_flash.sh examples/test_blink.csv
```

## 📂 Eigenes Projekt

1. In LOGO! Soft Comfort programmieren
2. Export → CSV speichern
3. Datei nach `~/logo2uno/` kopieren
4. Flashen:

```bash
./build_and_flash.sh mein_projekt.csv
```

## 🔧 Arduino finden

```bash
ls /dev/ttyUSB*
# oder
arduino-cli board list
```

## 🐛 Fehlersuche

**Problem:** `Port not found`
```bash
ls -l /dev/ttyUSB*
sudo chmod 666 /dev/ttyUSB0
```

**Problem:** `Permission denied`
```bash
sudo usermod -a -G dialout $USER
# Neu anmelden!
```

**Problem:** `Compilation failed`
- Prüfe CSV-Syntax
- Logs: `/tmp/logo_*.log`

## 📚 Beispiele

- `examples/test_blink.csv` - LED Blinker
- `examples/test_and.csv` - AND-Verknüpfung
- `examples/test_flipflop.csv` - SR-Flipflop

## ⚙️ Hardware-Profil anpassen

Datei: `hardware_profile.yaml`

Pin-Nummern ändern, Active-LOW/HIGH Flags setzen.

## 🆘 Support

Bei Problemen:
1. Logs prüfen: `cat /tmp/logo_*.log`
2. Arduino neu einstecken
3. Pi neu starten
4. Installation wiederholen: `./install.sh`
EOF
    
    print_success "QUICKSTART.md erstellt"
}

# ============================================
# Installation testen
# ============================================
test_installation() {
    print_step "Teste Installation..."
    
    cd /home/$USER/logo2uno
    
    # Python
    if ! python3 -c "import yaml" 2>/dev/null; then
        print_error "PyYAML nicht importierbar!"
        return 1
    fi
    
    # Arduino CLI
    if ! command -v arduino-cli &> /dev/null; then
        print_error "Arduino CLI nicht gefunden!"
        return 1
    fi
    
    # Scripts
    if [ ! -f "parser_logo.py" ]; then
        print_error "parser_logo.py fehlt!"
        return 1
    fi
    
    print_success "Installation erfolgreich getestet"
}

# ============================================
# Main Installation
# ============================================
main() {
    print_header
    
    echo "Diese Installation wird folgendes tun:"
    echo "  • System aktualisieren"
    echo "  • Python 3 + Dependencies installieren"
    echo "  • Arduino CLI installieren"
    echo "  • Arduino Libraries installieren (OneWire, DallasTemperature)"
    echo "  • USB-Berechtigungen einrichten"
    echo "  • Projekt-Struktur erstellen"
    echo "  • Test-Beispiele anlegen"
    echo ""
    read -p "Fortfahren? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation abgebrochen."
        exit 0
    fi
    
    echo ""
    
    # Installations-Schritte
    check_system
    update_system
    install_python_deps
    install_arduino_cli
    install_arduino_libs
    setup_usb_permissions
    setup_project
    create_examples
    create_systemd_service
    create_readme
    
    # Test
    echo ""
    test_installation
    
    # Zusammenfassung
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                    ║${NC}"
    echo -e "${GREEN}║  ✅ Installation erfolgreich abgeschlossen! ✅    ║${NC}"
    echo -e "${GREEN}║                                                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}📂 Projekt-Verzeichnis:${NC} /home/$USER/logo2uno"
    echo -e "${CYAN}📖 Quick Start:${NC} cat ~/logo2uno/QUICKSTART.md"
    echo ""
    echo -e "${YELLOW}⚠️  WICHTIG:${NC}"
    echo "  1. Neu anmelden oder Pi neu starten (für USB-Rechte)"
    echo "  2. Arduino UNO anschließen"
    echo "  3. Erstes Projekt flashen:"
    echo "     cd ~/logo2uno"
    echo "     ./build_and_flash.sh examples/test_blink.csv"
    echo ""
    echo -e "${BLUE}Viel Erfolg! 🚀${NC}"
    echo ""
}

# Script starten
main
