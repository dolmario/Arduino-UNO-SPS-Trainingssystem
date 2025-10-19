cat > ~/logo2uno/flash_gui.sh <<'EOF'
#!/bin/bash
set -e

# venv auto-activate
if [ -f "$HOME/logo2uno/venv/bin/activate" ]; then
  source "$HOME/logo2uno/venv/bin/activate"
fi

CSV=$(zenity --file-selection --title="LOGO! Projekt wählen (CSV/XML)" --filename="$HOME/logo2uno/projects/" --file-filter="CSV/XML | *.csv *.xml" 2>/dev/null) || exit 0

# Ports automatisch auflisten
PORTS=$(/usr/local/bin/arduino-cli board list | awk '/tty/ {print $1}')
if [ -z "$PORTS" ]; then
  zenity --error --text="Kein Arduino-Port gefunden!\nBitte UNO anschließen." 2>/dev/null
  exit 1
fi

PORT=$(echo "$PORTS" | zenity --list --title="Port wählen" --column="Serieller Port" --height=250 2>/dev/null) || exit 0

gnome-terminal -- bash -lc "$HOME/logo2uno/build_and_flash.sh \"$CSV\" \"$PORT\"; echo; echo 'Schließen mit Enter'; read"
EOF
