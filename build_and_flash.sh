#!/bin/bash
set -e

INPUT="$1"                           # CSV/XML
PORT="${2:-/dev/ttyUSB0}"            # default port
NAME="$(basename "$INPUT" | sed 's/\..*$//')"   # Dateiname ohne Endung
STAMP="$(date +%Y%m%d-%H%M%S)"
OUTDIR="$HOME/logo2uno/generated/${NAME}_${STAMP}"
TMPINO="${OUTDIR}/generated.ino"
LOG_BUILD="${OUTDIR}/build.log"
LOG_UPLD="${OUTDIR}/upload.log"
META="${OUTDIR}/meta.yaml"

mkdir -p "$OUTDIR"

# venv auto-activate falls vorhanden
if [ -f "$HOME/logo2uno/venv/bin/activate" ]; then
  source "$HOME/logo2uno/venv/bin/activate"
fi

# 1) Parsen & Generieren
echo "[*] Generiere Sketch..." | tee "$LOG_BUILD"
python "$HOME/logo2uno/parser_logo.py" "$INPUT" > "${OUTDIR}/blocks.json" 2>>"$LOG_BUILD"
python "$HOME/logo2uno/generator_arduino.py" "${OUTDIR}/blocks.json" "$TMPINO" 2>>"$LOG_BUILD"

# 2) Kompilieren
echo "[*] Kompiliere..." | tee -a "$LOG_BUILD"
/usr/local/bin/arduino-cli compile --fqbn arduino:avr:uno "$TMPINO" 2>>"$LOG_BUILD"

# 3) HEX finden (arduino-cli legt es im Sketch-Ordner ab)
HEX_PATH="$(dirname "$TMPINO")/build/arduino.avr.uno/generated.ino.hex"
if [ -f "$HEX_PATH" ]; then
  cp "$HEX_PATH" "${OUTDIR}/firmware.hex"
else
  echo "HEX nicht gefunden!" | tee -a "$LOG_BUILD"
fi

# 4) Upload
echo "[*] Flashe auf $PORT ..." | tee "$LOG_UPLD"
/usr/local/bin/arduino-cli upload -p "$PORT" --fqbn arduino:avr:uno "$TMPINO" 2>>"$LOG_UPLD"

# 5) Meta schreiben
cat > "$META" <<EOF
name: "$NAME"
input: "$(realpath "$INPUT")"
port: "$PORT"
timestamp: "$STAMP"
hardware_profile: "hardware_profile.yaml"
arduino_cli_version: "$(/usr/local/bin/arduino-cli version | awk '{print $3}')"
EOF

# 6) Symlink 'current' setzen
ln -sfn "$OUTDIR" "$HOME/logo2uno/current"

echo "✅ Fertig. Artefakte: $OUTDIR"
