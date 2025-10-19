#!/usr/bin/env bash
set -euo pipefail

# =========================================
#  Build & Flash Pipeline
#   - Parser (CSV/XML) → Generator → Compile → Upload
#   - Logs & Artefakte in ~/logo2uno/generated/<name>_<ts>/
# =========================================

INSTALL_DIR="${INSTALL_DIR:-$HOME/logo2uno}"
GEN_DIR="$INSTALL_DIR/generated"
PROJECTS_DIR="$INSTALL_DIR/projects"
CURRENT_LINK="$INSTALL_DIR/current"

INPUT="${1:-}"
PORT="${2:-}"

if [ -z "$INPUT" ]; then
  echo "Usage: $0 <projekt.csv|projekt.xml> [SERIAL_PORT]"
  echo "Tipp: Ablage für Projekte: $PROJECTS_DIR"
  exit 1
fi

if [ ! -f "$INPUT" ]; then
  echo "❌ Datei nicht gefunden: $INPUT"
  exit 1
fi

# Port automatisch raten, wenn nicht übergeben
if [ -z "$PORT" ]; then
  PORT=$( /usr/local/bin/arduino-cli board list | awk '/tty(USB|ACM)/ {print $1; exit}' || true )
  if [ -z "$PORT" ]; then
    echo "❌ Kein serieller Port gefunden. Bitte als 2. Argument angeben."
    exit 1
  fi
fi

# venv, falls vorhanden
if [ -f "$INSTALL_DIR/.venv/bin/activate" ]; then
  # shellcheck disable=SC1091
  source "$INSTALL_DIR/.venv/bin/activate"
fi

mkdir -p "$GEN_DIR"
BASENAME="$(basename "$INPUT")"
NAME="${BASENAME%.*}"
TS="$(date +%Y%m%d-%H%M%S)"
OUTDIR="$GEN_DIR/${NAME}_${TS}"
mkdir -p "$OUTDIR"

#!/usr/bin/env bash
set -euo pipefail

# =========================================
#  Build & Flash Pipeline (UNO/ESP32)
#  Usage:
#   ./build_and_flash.sh <projekt.csv|.xml> <port> [uno|esp32]
#  Default-Board: uno
# =========================================

INSTALL_DIR="${INSTALL_DIR:-$HOME/logo2uno}"
GEN_DIR="$INSTALL_DIR/generated"
PROJECTS_DIR="$INSTALL_DIR/projects"
CURRENT_LINK="$INSTALL_DIR/current"

INPUT="${1:-}"
PORT="${2:-}"
BOARD="${3:-uno}"  # uno | esp32

if [ -z "$INPUT" ]; then
  echo "Usage: $0 <projekt.csv|projekt.xml> [SERIAL_PORT] [uno|esp32]"
  exit 1
fi
[ -f "$INPUT" ] || { echo "❌ Datei nicht gefunden: $INPUT"; exit 1; }

# Port auto-detect
if [ -z "$PORT" ]; then
  PORT=$( /usr/local/bin/arduino-cli board list | awk '/tty(USB|ACM)/ {print $1; exit}' || true )
  [ -n "$PORT" ] || { echo "❌ Kein serieller Port gefunden. Bitte 2. Argument setzen."; exit 1; }
fi

# FQBN anhand BOARD
case "$BOARD" in
  uno)   FQBN="arduino:avr:uno" ;;
  esp32) FQBN="esp32:esp32:esp32" ;;   # generischer ESP32; bei Bedarf spezifisches Board einsetzen
  *) echo "❌ Unbekanntes Board: $BOARD (erwartet: uno|esp32)"; exit 1;;
esac

# venv laden (falls vorhanden)
[ -f "$INSTALL_DIR/.venv/bin/activate" ] && source "$INSTALL_DIR/.venv/bin/activate"

mkdir -p "$GEN_DIR"
BASENAME="$(basename "$INPUT")"
NAME="${BASENAME%.*}"
TS="$(date +%Y%m%d-%H%M%S)"
OUTDIR="$GEN_DIR/${NAME}_${TS}"
mkdir -p "$OUTDIR"

TMPINO="$OUTDIR/${NAME}.ino"
LOG_BUILD="$OUTDIR/build.log"
LOG_UPLD="$OUTDIR/upload.log"
META="$OUTDIR/meta.yaml"

echo "==> Projekt: $INPUT"
echo "==> Board:   $BOARD ($FQBN)"
echo "==> Port:    $PORT"
echo "==> Ausgabe: $OUTDIR"

# 1) Parser
echo "🔎 Parsen…"
python3 parser_logo.py "$INPUT" | tee "$LOG_BUILD"

# 2) Generator
echo "🛠️  Code-Generierung → $TMPINO"
python3 generator_arduino.py "$INPUT" > "$TMPINO"

# 3) Compile
echo "🧱 Kompiliere ($FQBN)…"
/usr/local/bin/arduino-cli compile \
  --fqbn "$FQBN" \
  --output-dir "$OUTDIR" \
  "$TMPINO" >> "$LOG_BUILD" 2>&1

# 4) Upload
echo "⬆️  Flashe auf $PORT…"
/usr/local/bin/arduino-cli upload \
  -p "$PORT" \
  --fqbn "$FQBN" \
  "$TMPINO" > "$LOG_UPLD" 2>&1 || {
    echo "⚠️ Upload fehlgeschlagen. Prüfe Boot/Reset (bei ESP32 ggf. Boot-Taste)."
    exit 1
  }

# 5) Meta & Symlink
ARDVER="$(/usr/local/bin/arduino-cli version || echo unknown)"
cat > "$META" <<EOF
project: "$NAME"
input: "$(realpath "$INPUT" 2>/dev/null || echo "$INPUT")"
port: "$PORT"
board: "$BOARD"
fqbn: "$FQBN"
time: "$TS"
arduino_cli: "$ARDVER"
success: true
EOF

ln -sfn "$OUTDIR" "$CURRENT_LINK"

echo "===================================="
echo "✅ Build & Flash abgeschlossen."
echo "  - HEX/Logs: $OUTDIR"
echo "  - current:  $CURRENT_LINK"
echo "===================================="
