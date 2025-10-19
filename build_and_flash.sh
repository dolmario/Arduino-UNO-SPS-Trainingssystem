#!/bin/bash
# Auto-Compile und Upload auf Arduino UNO

PROJECT=$1
PORT=${2:-/dev/ttyUSB0}

if [ -z "$PROJECT" ]; then
    echo "Usage: ./build_and_flash.sh <projekt.csv> [port]"
    exit 1
fi

echo "🔧 Parsing LOGO! Projekt..."
python3 generator_arduino.py "$PROJECT"

SKETCH_DIR="generated/sketch_$(basename $PROJECT .csv)"

echo "🔨 Kompiliere Arduino Sketch..."
arduino-cli compile --fqbn arduino:avr:uno "$SKETCH_DIR"

if [ $? -ne 0 ]; then
    echo "❌ Kompilierung fehlgeschlagen!"
    exit 1
fi

echo "📤 Upload auf $PORT..."
arduino-cli upload -p "$PORT" --fqbn arduino:avr:uno "$SKETCH_DIR"

if [ $? -eq 0 ]; then
    echo "✅ Erfolgreich geflasht!"
else
    echo "❌ Upload fehlgeschlagen!"
    exit 1
fi
