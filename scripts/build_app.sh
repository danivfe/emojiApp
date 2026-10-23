#!/bin/bash
# Compila Emojis.app a build/ (universal: Apple i Intel).
#   --install  la copia a ~/Applications i l'obre
#   --dmg      crea build/Emojis.dmg per enviar-la (finestra «arrossega a Aplicacions»)
set -euo pipefail
cd "$(dirname "$0")/.."

ARCHS=(--arch arm64 --arch x86_64)
swift build -c release "${ARCHS[@]}"
BIN="$(swift build -c release "${ARCHS[@]}" --show-bin-path)/Emojis"

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

if [ "${1:-}" = "--dmg" ]; then
    if [ ! -f Support/dmg-background.tiff ]; then
        swift scripts/make_dmg_background.swift Support/dmg-background.tiff
    fi
    WORK="$(mktemp -d)"
    STAGE="$WORK/Emojis"
    mkdir -p "$STAGE/.background"
    cp -R "$APP" "$STAGE/"
    ln -s /Applications "$STAGE/Aplicacions"
    cp Support/dmg-background.tiff "$STAGE/.background/background.tiff"

    # Primer un disc d'escriptura per poder col·locar les icones amb el Finder
    hdiutil create -quiet -srcfolder "$STAGE" -volname Emojis -fs HFS+ -format UDRW "$WORK/rw.dmg"
    MOUNT="$WORK/mnt"
    mkdir -p "$MOUNT"
    hdiutil attach -quiet -nobrowse -noautoopen -mountpoint "$MOUNT" "$WORK/rw.dmg"

    # El Finder fa servir el nom del volum; si n'hi ha un altre d'igual, falla
    if ! osascript <<EOF
tell application "Finder"
    set theDisk to disk (POSIX file "$MOUNT" as alias)
    open theDisk
    set win to container window of theDisk
    set current view of win to icon view
    set toolbar visible of win to false
    set statusbar visible of win to false
    set bounds of win to {200, 120, 800, 548}
    set opts to icon view options of win
    set arrangement of opts to not arranged
    set icon size of opts to 112
    set text size of opts to 13
    set background picture of opts to file ".background:background.tiff" of theDisk
    set position of item "Emojis.app" of theDisk to {150, 190}
    set position of item "Aplicacions" of theDisk to {450, 190}
    update theDisk without registering applications
    delay 1
    close win
end tell
EOF
    then
        echo "Avís: no s'ha pogut col·locar la finestra amb el Finder; el .dmg funciona igualment."
    fi
    sync
    hdiutil detach -quiet "$MOUNT"

    rm -f build/Emojis.dmg
    hdiutil convert -quiet "$WORK/rw.dmg" -format UDZO -imagekey zlib-level=9 -o build/Emojis.dmg
    rm -rf "$WORK"
    echo "Fet: build/Emojis.dmg"
fi
