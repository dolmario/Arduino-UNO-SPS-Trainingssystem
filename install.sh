#!/usr/bin/env bash
set -euo pipefail

# ============================================
#  Arduino-UNO-SPS-Trainingssystem - Installer
#  - Frisches RPi OS ready
#  - UNO und ESP32 Support
#  - Python-Devices über APT
#  - Desktop-Icon + ausführbare Skripte
#  - Idempotent, keine Repo-/Pfad-Änderungen
# ============================================

export DEBIAN_FRONTEND=noninteractive

# ---- Einstellungen ----
INSTALL_DIR="${INSTALL_DIR:-$HOME/logo2uno}"
ENABLE_VENV="${ENABLE_VENV:-false}"                 # APT-only reicht, venv optional
ENABLE_DESKTOP_ICON="${ENABLE_DESKTOP_ICON:-true}"
ENABLE_SAMBA_SHARE="${ENABLE_SAMBA_SHARE:-false}"   # optional
SAMBA_SHARE_NAME="${SAMBA_SHARE_NAME:-logo2uno_generated}"

INSTALL_AVR_CORE="${INSTALL_AVR_CORE:-true}"
INSTALL_ESP32_CORE="${INSTALL_ESP32_CORE:-true}"

log(){ echo -e "\e[1;32m==>\e[0m $*"; }
warn(){ echo -e "\e[1;33m[!]\e[0m $*"; }
err(){ echo -e "\e[1;31m[✗]\e[0m $*"; }

trap 'err "Fehler in Zeile $LINENO. Abbruch."' ERR

# ---- Ordner anlegen ----
mkdir -p "$INSTALL_DIR/projects" "$INSTALL_DIR/generated"
cd "$INSTALL_DIR"

# ---- Systempakete (inkl. python devices) ----
log "apt-get update…"
sudo apt-get update -y >/dev/null

PKGS=(
  ca-certificates curl unzip git build-essential pkg-config
  python3 python3-pip python3-venv
  python3-yaml python3-serial python3-dev python3-rpi.gpio python3-spidev
  i2c-tools
  zenity gnome-terminal xterm
)
log "Installiere Basis-Pakete und Python-Devices über APT…"
sudo apt-get install -y "${PKGS[@]}"

# ---- Optional venv (nicht nötig, APT deckt ab) ----
if $ENABLE_VENV; then
  if [ ! -d "$INSTALL_DIR/.venv" ]; then
    log "Richte Python venv ein…"
    python3 -m venv "$INSTALL_DIR/.venv"
  fi
  # shellcheck disable=SC1091
  source "$INSTALL_DIR/.venv/bin/activate"
  python -m pip install --upgrade pip >/dev/null
  pip install pyyaml pyserial >/dev/null
fi

# ---- arduino-cli ----
if ! command -v /usr/local/bin/arduino-cli >/dev/null 2>&1; then
  log "Installiere arduino-cli…"
  curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
  sudo mv bin/arduino-cli /usr/local/bin/
  rm -rf bin
else
  log "arduino-cli gefunden: $(/usr/local/bin/arduino-cli version)"
fi

# Erstkonfiguration
[ -f "$HOME/.arduino15/arduino-cli.yaml" ] || /usr/local/bin/arduino-cli config init

# Board-Manager URL für ESP32
if $INSTALL_ESP32_CORE; then
  if ! /usr/local/bin/arduino-cli config dump | grep -q 'https://espressif.github.io/arduino-esp32/package_esp32_index.json'; then
    /usr/local/bin/arduino-cli config add board_manager.additional_urls https://espressif.github.io/arduino-esp32/package_esp32_index.json
  fi
fi

log "arduino-cli: Core-Index aktualisieren…"
/usr/local/bin/arduino-cli core update-index

if $INSTALL_AVR_CORE; then
  log "Installiere Core arduino:avr (UNO)…"
  /usr/local/bin/arduino-cli core install arduino:avr || warn "arduino:avr evtl. schon installiert."
fi

if $INSTALL_ESP32_CORE; then
  log "Installiere Core esp32:esp32…"
  /usr/local/bin/arduino-cli core install esp32:esp32 || warn "esp32:esp32 evtl. schon installiert."
fi

# ---- Serielle Rechte + UDEV ----
log "Serielle Rechte + UDEV-Regeln…"
sudo usermod -a -G dialout "$USER" || true
RULE_FILE="/etc/udev/rules.d/99-usb-serial.rules"
if [ ! -f "$RULE_FILE" ]; then
  sudo tee "$RULE_FILE" >/dev/null <<'EOF'
# FTDI
SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", MODE:="0666", GROUP:="dialout"
# WCH/CH340/CH9102
SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", MODE:="0666", GROUP:="dialout"
# Prolific
SUBSYSTEM=="tty", ATTRS{idVendor}=="067b", MODE:="0666", GROUP:="dialout"
# Silicon Labs CP210x
SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", MODE:="0666", GROUP:="dialout"
# Arduino SA
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", MODE:="0666", GROUP:="dialout"
# Espressif
SUBSYSTEM=="tty", ATTRS{idVendor}=="303a", MODE:="0666", GROUP:="dialout"
EOF
  sudo udevadm control --reload-rules && sudo udevadm trigger
fi

# ---- Skripte ausführbar machen ----
log "Setze Ausführungsrechte für Skripte…"
chmod +x "$INSTALL_DIR"/build_and_flash.sh || true
chmod +x "$INSTALL_DIR"/flash_gui.sh || true
chmod +x "$INSTALL_DIR"/install.sh || true

# ---- Desktop-Icon ----
if $ENABLE_DESKTOP_ICON; then
  log "Erzeuge Desktop-Starter…"
  DESK_DIR="$HOME/Desktop"
  mkdir -p "$DESK_DIR"
  cat > "$DESK_DIR/LOGO-zu-UNO-ESP32-Flash.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=LOGO → UNO/ESP32 Flash
Comment=CSV/XML wählen, Board & Port wählen, flashen
Exec=/bin/bash -lc "$INSTALL_DIR/flash_gui.sh"
Terminal=false
Icon=utilities-terminal
Categories=Education;Development;
EOF
  chmod +x "$DESK_DIR/LOGO-zu-UNO-ESP32-Flash.desktop"
fi

# ---- Optional: Samba Share für generated/ ----
if $ENABLE_SAMBA_SHARE; then
  log "Richte optionale Samba-Freigabe ein…"
  sudo apt-get install -y samba
  if ! grep -q "^\[$SAMBA_SHARE_NAME\]" /etc/samba/smb.conf; then
    sudo tee -a /etc/samba/smb.conf >/dev/null <<EOF

[$SAMBA_SHARE_NAME]
   path = $INSTALL_DIR/generated
   browseable = yes
   read only = no
   guest ok = yes
   create mask = 0775
   directory mask = 0775
EOF
    sudo systemctl restart smbd nmbd || sudo systemctl restart smbd || true
  fi
fi

log "Installation abgeschlossen."
echo "-------------------------------------------"
echo " Projektordner:    $INSTALL_DIR/projects"
echo " Build/Logs:       $INSTALL_DIR/generated"
echo " Desktop-Icon:     $HOME/Desktop/LOGO-zu-UNO-ESP32-Flash.desktop"
echo " arduino-cli:      $(/usr/local/bin/arduino-cli version || echo 'unbekannt')"
/usr/local/bin/arduino-cli core list || true
echo "-------------------------------------------"
echo "Hinweis: Nach erster Installation ggf. einmal ab- und wieder anmelden (Gruppe 'dialout')."

