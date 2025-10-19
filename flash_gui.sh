#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-$HOME/logo2uno}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ '$1' fehlt"; exit 1; }; }
need zenity
[ -x "$INSTALL_DIR/build_and_flash.sh" ] || chmod +x "$INSTALL_DIR/build_and_flash.sh"

# 1) Datei wählen (CSV/XML)
FILE=$(zenity --file-selection \
  --title="LOGO! Projekt wählen (CSV oder XML)" \
  --file-filter="LOGO! CSV | *.csv" \
  --file-filter="LOGO! XML | *.xml" \
  --filename="$INSTALL_DIR/projects/" 2>/dev/null) || exit 0

# 2) Board wählen
BOARD=$(zenity --list --title="Board wählen" --column=Board uno esp32 2>/dev/null) || exit 0
[ -n "$BOARD" ] || exit 0

# 3) Port wählen / auto
PORTS=$(/usr/local/bin/arduino-cli board list | awk '/tty(USB|ACM)/ {print $1}')
if [ -z "$PORTS" ]; then
  zenity --error --text="Kein serieller Port gefunden. Schließe UNO/ESP32 an und versuche erneut."
  exit 1
fi
PORT=$(echo "$PORTS" | zenity --list --title="Seriellen Port wählen" --column=Port 2>/dev/null) || exit 0
[ -n "$PORT" ] || exit 0

# 4) Terminal starten
if command -v gnome-terminal >/dev/null 2>&1; then
  gnome-terminal -- bash -lc "$INSTALL_DIR/build_and_flash.sh \"$FILE\" \"$PORT\" \"$BOARD\"; echo; echo 'Fertig. Enter zum Schließen'; read"
elif command -v xterm >/dev/null 2>&1; then
  xterm -e "$INSTALL_DIR/build_and_flash.sh \"$FILE\" \"$PORT\" \"$BOARD\"; echo; echo 'Fertig. Enter zum Schließen'; read"
else
  bash -lc "$INSTALL_DIR/build_and_flash.sh \"$FILE\" \"$PORT\" \"$BOARD\"; echo; read -p 'Fertig. Enter zum Schließen…'"
fi
