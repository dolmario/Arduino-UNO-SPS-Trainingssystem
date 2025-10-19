#!/usr/bin/env bash
set -euo pipefail

# ============================================
#  Arduino-UNO-SPS-Trainingssystem - Installer
#  Robust für frisches Raspberry Pi OS + ESP32
#  - Idempotent
#  - Keine Repo-/Pfadänderungen
# ============================================

# ---------- Einstellungen (anpassbar via ENV) ----------
INSTALL_DIR="${INSTALL_DIR:-$HOME/logo2uno}"
ENABLE_VENV="${ENABLE_VENV:-true}"
ENABLE_DESKTOP_ICON="${ENABLE_DESKTOP_ICON:-true}"
ENABLE_SAMBA_SHARE="${ENABLE_SAMBA_SHARE:-false}"     # true = Samba-Freigabe für generated/
SAMBA_SHARE_NAME="${SAMBA_SHARE_NAME:-logo2uno_generated}"
# Cores
INSTALL_AVR_CORE="${INSTALL_AVR_CORE:-true}"          # arduino:avr (UNO)
INSTALL_ESP32_CORE="${INSTALL_ESP32_CORE:-true}"      # esp32:esp32
# GUI Helfer (für flash_gui.sh)
INSTALL_GUI_EXTRAS="${INSTALL_GUI_EXTRAS:-true}"      # zenity, xterm/gnome-terminal wenn verfügbar

export DEBIAN_FRONTEND=noninteractive

# ---------- Helper ----------
log()   { echo -e "\e[1;32m==>\e[0m $*"; }
warn()  { echo -e "\e[1;33m[!]\e[0m $*"; }
err()   { echo -e "\e[1;31m[✗]\e[0m $*"; }
try_apt(){ sudo apt-get -y -o Dpkg::Options::="--force-confold" "$@" >/dev/null; }

trap 'err "Fehler in Zeile $LINENO. Abbruch."' ERR

# ---------- Vorab-Checks ----------
if ! command -v sudo >/dev/null 2>&1; then
  err "sudo nicht gefunden. Bitte 'sudo apt-get install -y sudo' (als root) und erneut ausführen."
  exit 1
fi

if ! ping -q -c 1 -W 2 deb.debian.org >/dev/null 2>&1; then
  warn "Keine Internet-Verbindung erkannt. Ich versuche es trotzdem (evtl. schlägt Download fehl)."
fi

log "Installationspfad: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR/projects" "$INSTALL_DIR/generated"
cd "$INSTALL_DIR"

# ---------- Systempakete (frisches Raspbian absichern) ----------
log "Aktualisiere Paketquellen… (apt-get update)"
sudo apt-get update -y >/dev/null

BASE_PKGS=(
  ca-certificates curl unzip git build-essential pkg-config
  python3 python3-venv python3-pip
)
if $INSTALL_GUI_EXTRAS; then
  BASE_PKGS+=( zenity )
  # wir probieren beide Terminals
  if ! command -v gnome-terminal >/dev/null 2>&1; then BASE_PKGS+=( gnome-terminal ) || true; fi
  if ! command -v xterm           >/dev/null 2>&1; then BASE_PKGS+=( xterm ) || true; fi
fi

log "Installiere Basis-Pakete: ${BASE_PKGS[*]}"
try_apt install "${BASE_PKGS[@]}" || {
  warn "Einige Pakete konnten nicht installiert werden – ich fahre fort."
}

# ---------- Python Umgebung ----------
if $ENABLE_VENV; then
  if [ ! -d "$INSTALL_DIR/.venv" ]; then
    log "Richte Python venv ein…"
    python3 -m venv "$INSTALL_DIR/.venv"
  fi
  # shellcheck disable=SC1091
  source "$INSTALL_DIR/.venv/bin/activate"
  python -m pip install --upgrade pip >/dev/null
  pip install --disable-pip-version-check pyyaml >/dev/null
else
  pip3 install --user --disable-pip-version-check pyyaml >/dev/null || true
fi

# ---------- arduino-cli ----------
if ! command -v /usr/local/bin/arduino-cli >/dev/null 2>&1; then
  log "Installiere arduino-cli…"
  curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
  sudo mv bin/arduino-cli /usr/local/bin/
  rm -rf bin
else
  log "arduino-cli gefunden: $(/usr/local/bin/arduino-cli version)"
fi

# Erstkonfiguration (idempotent)
if [ ! -f "$HOME/.arduino15/arduino-cli.yaml" ]; then
  /usr/local/bin/arduino-cli config init
fi

# Board Manager URLs (für ESP32)
if $INSTALL_ESP32_CORE; then
  if ! /usr/local/bin/arduino-cli config dump | grep -q 'https://espressif.github.io/arduino-esp32/package_esp32_index.json'; then
    log "Füge ESP32 Board-Manager-URL hinzu…"
    /usr/local/bin/arduino-cli config add board_manager.additional_urls https://espressif.github.io/arduino-esp32/package_esp32_index.json
  fi
fi

log "arduino-cli: Core-Index aktualisieren…"
/usr/local/bin/arduino-cli core update-index

if $INSTALL_AVR_CORE; then
  log "Installiere Core: arduino:avr (UNO)…"
  /usr/local/bin/arduino-cli core install arduino:avr || warn "Core arduino:avr bereits vorhanden oder Installationsproblem."
fi

if $INSTALL_ESP32_CORE; then
  log "Installiere Core: esp32:esp32…"
  /usr/local/bin/arduino-cli core install esp32:esp32 || warn "Core esp32:esp32 bereits vorhanden oder Installationsproblem."
fi

# ---------- Serielle Rechte + UDEV ----------
log "Füge Benutzer '$USER' zur Gruppe 'dialout' hinzu (serieller Zugriff)…"
sudo usermod -a -G dialout "$USER" || true

RULE_FILE="/etc/udev/rules.d/99-usb-serial.rules"
if [ ! -f "$RULE_FILE" ]; then
  log "Schreibe UDEV-Regeln für gängige USB-Seriell-Wandler + Espressif/Arduino…"
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

# ---------- Desktop-Icon ----------
if $ENABLE_DESKTOP_ICON; then
  log "Erzeuge Desktop-Starter…"
  DESK_DIR="$HOME/Desktop"
  mkdir -p "$DESK_DIR"
  cat > "$DESK_DIR/LOGO-zu-UNO-Flash.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=LOGO → UNO/ESP32 Flash
Comment=CSV/XML wählen und Board flashen
Exec=/bin/bash -lc "$INSTALL_DIR/flash_gui.sh"
Terminal=false
Icon=utilities-terminal
Categories=Education;Development;
EOF
  chmod +x "$DESK_DIR/LOGO-zu-UNO-Flash.desktop"
fi

# ---------- Optional: Samba Share ----------
if $ENABLE_SAMBA_SHARE; then
  log "Richte optionale Samba-Freigabe ein…"
  try_apt install samba || warn "Samba-Installation fehlgeschlagen."
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

# ---------- Abschluss ----------
log "Installation abgeschlossen."
echo "-------------------------------------------"
echo " Projektordner:    $INSTALL_DIR/projects"
echo " Build/Logs:       $INSTALL_DIR/generated"
echo " Desktop-Icon:     $HOME/Desktop/LOGO-zu-UNO-Flash.desktop (falls aktiviert)"
echo " arduino-cli:      $(/usr/local/bin/arduino-cli version || echo 'unbekannt')"
echo " Cores installiert:"
/usr/local/bin/arduino-cli core list || true
echo "-------------------------------------------"
warn "Wenn dies die erste Installation war: einmal ab- und wieder anmelden (oder reboot), damit 'dialout' aktiv ist."
