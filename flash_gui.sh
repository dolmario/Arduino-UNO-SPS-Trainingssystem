#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-$HOME/logo2uno}"

zenity_check() {
  if ! command -v zenity >/dev/null 2>&1; then
    echo "❌ 'zenity' nicht installiert. Installiere mit: sudo apt-get install -y zenity"
    exit 1
  fi
}
zenity_check

CSV=$(zenity --file-selection \
  --title="LOGO! Projekt wählen (CSV oder XML)" \
  --file-filter="CSV | *.csv" \
  --file-filter="XML | *.xml" \
  --filename="$INSTALL_DIR/projects/" 2>/dev/null) || exit 0

# Ports ermitteln
PORTS=$(/usr/local/bin/arduino-cli board list | awk '/tty(USB|ACM)/ {print $1}')
if [ -z "$PORTS" ]; then
  zenity --error --text="Kein serieller Port gefunden.\nUNO anschließen oder Port manuell im Terminal angeben."
  exit 1
fi
PORT=$(echo "$PORTS" | zenity --list --title="Seriellen Port wählen" --column=Port || true)
if [ -z "$PORT" ]; then exit 0; fi

# Terminal auswählen
if command -v gnome-terminal >/dev/null 2>&1; then
  gnome-terminal -- bash -lc "$INSTALL_DIR/build_and_flash.sh \"$CSV\" \"$PORT\"; echo; echo 'Fertig. Schließen mit Enter'; read"
elif command -v xterm >/dev/null 2>&1; then
  xterm -e "$INSTALL_DIR/build_and_flash.sh \"$CSV\" \"$PORT\"; echo; echo 'Fertig. Schließen mit Enter'; read"
else
  bash -lc "$INSTALL_DIR/build_and_flash.sh \"$CSV\" \"$PORT\"; echo; read -p 'Fertig. Enter zum Schließen…'"
fi
