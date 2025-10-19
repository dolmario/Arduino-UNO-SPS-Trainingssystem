#!/bin/bash
# Autostart-Konfiguration für Raspberry Pi
# Startet wichtige Services beim Booten

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() {
    echo -e "${YELLOW}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Root-Check
if [ "$EUID" -ne 0 ]; then
    echo "Bitte als root ausführen: sudo ./setup_autostart.sh"
    exit 1
fi

# ============================================
# 1. USB-Geräte beim Boot erkennen
# ============================================
print_step "Konfiguriere USB-Auto-Mount..."

cat > /etc/udev/rules.d/99-arduino-auto.rules << 'EOF'
# Arduino UNO automatisch erkennen
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0043", SYMLINK+="arduino_uno", MODE="0666"
SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", SYMLINK+="arduino_clone", MODE="0666"

# LED-Indikator (optional)
ACTION=="add", SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", RUN+="/bin/sh -c 'echo 1 > /sys/class/leds/led0/brightness'"
EOF

udevadm control --reload-rules
print_success "USB Auto-Mount konfiguriert"

# ============================================
# 2. Watchdog (Pi startet bei Hänger neu)
# ============================================
print_step "Aktiviere Hardware Watchdog..."

# Modul laden
if ! grep -q "bcm2835_wdt" /etc/modules; then
    echo "bcm2835_wdt" >> /etc/modules
fi

# Watchdog installieren
apt-get install -y watchdog

# Konfiguration
cat > /etc/watchdog.conf << 'EOF'
watchdog-device = /dev/watchdog
watchdog-timeout = 15
max-load-1 = 24
EOF

systemctl enable watchdog
systemctl start watchdog

print_success "Watchdog aktiviert"

# ============================================
# 3. Auto-Update beim Boot (optional)
# ============================================
print_step "Erstelle Boot-Update-Service..."

cat > /etc/systemd/system/logo2uno-update.service << EOF
[Unit]
Description=LOGO2UNO Repository Update
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=$(logname)
WorkingDirectory=/home/$(logname)/logo2uno
ExecStart=/usr/bin/git pull origin main
RemainAfterExit=true
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

# Service aktivieren (aber nicht starten)
systemctl daemon-reload
# systemctl enable logo2uno-update.service
print_success "Update-Service erstellt (deaktiviert)"

# ============================================
# 4. Status-LED beim Boot
# ============================================
print_step "Konfiguriere Status-LED..."

cat > /usr/local/bin/logo2uno-status-led.sh << 'EOF'
#!/bin/bash
# Status-LED Indikator

LED=/sys/class/leds/led0/brightness

# Blinken: System startet
for i in {1..5}; do
    echo 1 > $LED
    sleep 0.2
    echo 0 > $LED
    sleep 0.2
done

# Dauerlicht: System bereit
echo 1 > $LED
EOF

chmod +x /usr/local/bin/logo2uno-status-led.sh

# rc.local Hook (falls vorhanden)
if [ -f /etc/rc.local ]; then
    if ! grep -q "logo2uno-status-led" /etc/rc.local; then
        sed -i '/^exit 0/i /usr/local/bin/logo2uno-status-led.sh &' /etc/rc.local
    fi
fi

print_success "Status-LED konfiguriert"

# ============================================
# 5. Auto-Login (optional, für Kiosk-Modus)
# ============================================
read -p "Auto-Login aktivieren? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_step "Konfiguriere Auto-Login..."
    
    # getty überschreiben
    mkdir -p /etc/systemd/system/getty@tty1.service.d
    cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $(logname) --noclear %I \$TERM
EOF
    
    print_success "Auto-Login aktiviert"
fi

# ============================================
# 6. Netzwerk-Wait (wichtig für Git-Pull)
# ============================================
print_step "Aktiviere Network-Wait..."

systemctl enable systemd-networkd-wait-online.service

print_success "Network-Wait aktiviert"

# ============================================
# 7. Cronjob für tägliches Backup
# ============================================
print_step "Erstelle Backup-Cronjob..."

CRON_USER=$(logname)
CRON_SCRIPT="/home/$CRON_USER/logo2uno/backup.sh"

# Backup-Script erstellen
cat > "$CRON_SCRIPT" << 'EOF'
#!/bin/bash
# Tägliches Backup der Projekte

BACKUP_DIR="/home/$USER/logo2uno_backups"
mkdir -p "$BACKUP_DIR"

cd /home/$USER/logo2uno
tar czf "$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).tar.gz" \
    examples/ generated/ hardware_profile.yaml *.py *.sh

# Nur letzte 7 Backups behalten
ls -t "$BACKUP_DIR"/backup_*.tar.gz | tail -n +8 | xargs rm -f

echo "Backup erstellt: $(date)" >> "$BACKUP_DIR/backup.log"
EOF

chmod +x "$CRON_SCRIPT"

# Crontab eintragen (täglich 3 Uhr)
(crontab -u $CRON_USER -l 2>/dev/null; echo "0 3 * * * $CRON_SCRIPT") | crontab -u $CRON_USER -

print_success "Backup-Cronjob erstellt"

# ============================================
# Zusammenfassung
# ============================================
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Autostart erfolgreich konfiguriert  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Folgende Features sind aktiv:"
echo "  ✅ USB Auto-Mount für Arduino"
echo "  ✅ Hardware Watchdog"
echo "  ✅ Status-LED beim Boot"
echo "  ✅ Netzwerk-Wait"
echo "  ✅ Tägliches Backup (3 Uhr)"
echo ""
echo "Optional aktivierbar:"
echo "  ⚪ Auto-Update beim Boot: sudo systemctl enable logo2uno-update"
echo "  ⚪ Auto-Login: bereits konfiguriert (falls gewählt)"
echo ""
echo "Nächster Schritt:"
echo "  sudo reboot"
echo ""
