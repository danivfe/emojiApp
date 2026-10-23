#!/bin/bash
# Compila Emojis.app a build/. Amb --install la copia a ~/Applications i l'obre.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release
BIN="$(swift build -c release --show-bin-path)/Emojis"

if [ ! -f Support/AppIcon.icns ]; then
    ICONSET="$(mktemp -d)/AppIcon.iconset"
    swift scripts/make_icon.swift "$ICONSET"
    iconutil -c icns "$ICONSET" -o Support/AppIcon.icns
fi

APP=build/Emojis.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Emojis"
cp Support/Info.plist "$APP/Contents/Info.plist"
cp Support/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp Sources/Emojis/Resources/emojis.json "$APP/Contents/Resources/emojis.json"
codesign --force --sign - "$APP"
echo "Fet: $APP"

if [ "${1:-}" = "--install" ]; then
    pkill -x Emojis || true
    mkdir -p ~/Applications
    rm -rf ~/Applications/Emojis.app
    cp -R "$APP" ~/Applications/
    open ~/Applications/Emojis.app
    echo "Instal·lada a ~/Applications/Emojis.app"
fi
