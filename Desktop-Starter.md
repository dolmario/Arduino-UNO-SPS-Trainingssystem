cat > ~/Desktop/LOGO2UNO.desktop <<'EOF'
[Desktop Entry]
Name=LOGO → UNO Flash
Comment=CSV/XML wählen und auf den UNO flashen
Exec=/home/%u/logo2uno/flash_gui.sh
Icon=arduino
Terminal=false
Type=Application
Categories=Education;Development;
EOF
# %u durch deinen echten User ersetzen:
sed -i "s|%u|$USER|g" ~/Desktop/LOGO2UNO.desktop
chmod +x ~/Desktop/LOGO2UNO.desktop
