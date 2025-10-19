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

TMPINO="$OUTDIR/${NAME}.ino"
LOG_BUILD="$OUTDIR/build.log"
LOG_UPLD="$OUTDIR/upload.log"
META="$OUTDIR/meta.yaml"

echo "==> Projekt: $INPUT"
echo "==> Port:    $PORT"
echo "==> Ausgabe: $OUTDIR"

# 1) Parser-Analyse (CSV/XML)
echo "🔎 Parsen…"
python3 parser_logo.py "$INPUT" | tee "$LOG_BUILD"

# 2) Code-Generierung
echo "🛠️  Code-Generierung → $TMPINO"
python3 generator_arduino.py "$INPUT" > "$TMPINO"

# 3) Kompilieren
echo "🧱 Kompiliere (arduino:avr:uno)…"
/usr/local/bin/arduino-cli compile \
  --fqbn arduino:avr:uno \
  --output-dir "$OUTDIR" \
  "$TMPINO" >> "$LOG_BUILD" 2>&1

# 4) Upload
echo "⬆️  Flashe auf $PORT…"
/usr/local/bin/arduino-cli upload \
  -p "$PORT" \
  --fqbn arduino:avr:uno \
  "$TMPINO" > "$LOG_UPLD" 2>&1

# 5) Meta + Symlink
ARDVER="$(/usr/local/bin/arduino-cli version || echo unknown)"
cat > "$META" <<EOF
project: "$NAME"
input: "$(realpath "$INPUT" 2>/dev/null || echo "$INPUT")"
port: "$PORT"
time: "$TS"
arduino_cli: "$ARDVER"
success: true
EOF

# current → letzter erfolgreicher Build
ln -sfn "$OUTDIR" "$CURRENT_LINK"

echo "===================================="
echo "✅ Build & Flash abgeschlossen."
echo "  - HEX/Logs: $OUTDIR"
echo "  - current:  $CURRENT_LINK"
echo "===================================="
