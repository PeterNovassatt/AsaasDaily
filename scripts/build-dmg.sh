#!/usr/bin/env bash
# Gera "dist/AsaasDaily-<versão>.dmg": janela com o fundo da marca, o app à esquerda e o atalho de
# Aplicativos à direita. Usa o Release do dist.sh (roda o build se o app ainda não existir).
# Na primeira vez, o macOS pede para o Terminal controlar o Finder: é o Finder que grava o layout.
# Uso: ./scripts/build-dmg.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

NAME="AsaasDaily"
APP="$ROOT/build/DerivedData/Build/Products/Release/$NAME.app"
BACKGROUND_NAME="DmgBackground.tiff"

# Mesmos números do design/dmg/DmgBackground.swift (janela 660x400, ícones de 128 pt).
WINDOW_WIDTH=660
WINDOW_HEIGHT=400
ICON_SIZE=128
APP_X=170
APPLICATIONS_X=490
ICONS_Y=220

# Sempre compila. Reaproveitar um Release que já estava na pasta empacota um binário
# que ninguém conferiu: foi assim que um .dmg saiu com uma versão de dias antes.
echo "▸ Compilando o Release"
xcodebuild -project AsaasDaily.xcodeproj -scheme AsaasDaily -configuration Release \
  -destination 'generic/platform=macOS' -derivedDataPath build/DerivedData \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO -quiet build

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP/Contents/Info.plist")
DMG="$ROOT/dist/$NAME-$VERSION.dmg"

SIGN_IDENTITY="${CODESIGN_IDENTITY:-$(security find-identity -v -p codesigning 2>/dev/null | grep -oE '"(Developer ID Application|Apple Development): [^"]+"' | head -1 | tr -d '"')}"

WORK="$(mktemp -d /tmp/asaas-daily-dmg.XXXXXX)"
MOUNT=""
cleanup() {
    [ -n "$MOUNT" ] && hdiutil detach "$MOUNT" -quiet -force >/dev/null 2>&1 || true
    rm -rf "$WORK"
}
trap cleanup EXIT

echo "▸ Desenhando o fundo"
swift design/dmg/DmgBackground.swift "$WORK/art" >/dev/null
# Um .tiff com as duas resoluções: o Finder usa a 2x em telas Retina.
tiffutil -cathidpicheck "$WORK/art/background.png" "$WORK/art/background@2x.png" -out "$WORK/art/$BACKGROUND_NAME" 2>/dev/null

echo "▸ Montando o conteúdo"
# O volume tem só o app e o atalho: nada de pasta .background, que aparece para quem usa o Finder
# mostrando arquivos ocultos. O fundo fica dentro do app, e por isso o app é assinado de novo.
STAGE="$WORK/stage"
mkdir -p "$STAGE"
ditto "$APP" "$STAGE/$NAME.app"
cp "$WORK/art/$BACKGROUND_NAME" "$STAGE/$NAME.app/Contents/Resources/$BACKGROUND_NAME"
if [ -n "$SIGN_IDENTITY" ]; then
    codesign --force --deep --timestamp=none --sign "$SIGN_IDENTITY" "$STAGE/$NAME.app"
else
    codesign --force --deep --sign - "$STAGE/$NAME.app"
fi
ln -s /Applications "$STAGE/Aplicativos"

RAW="$WORK/raw.dmg"
hdiutil create -quiet -srcfolder "$STAGE" -volname "$NAME" -fs HFS+ -format UDRW -size 200m "$RAW"
MOUNT="$(hdiutil attach "$RAW" -readwrite -noverify -noautoopen | grep -o '/Volumes/.*$' | tail -1)"
VOLUME="$(basename "$MOUNT")"

echo "▸ Arrumando a janela no Finder"
osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$VOLUME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {200, 120, 200 + $WINDOW_WIDTH, 120 + $WINDOW_HEIGHT + 28}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to $ICON_SIZE
        set text size of viewOptions to 13
        set label position of viewOptions to bottom
        set background picture of viewOptions to file "$NAME.app:Contents:Resources:$BACKGROUND_NAME"
        set position of item "$NAME.app" of container window to {$APP_X, $ICONS_Y}
        set position of item "Aplicativos" of container window to {$APPLICATIONS_X, $ICONS_Y}
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

# O macOS cria o .fseventsd ao montar; ele também apareceria com os arquivos ocultos visíveis.
rm -rf "$MOUNT/.fseventsd"
sync
hdiutil detach "$MOUNT" -quiet
MOUNT=""

echo "▸ Compactando"
mkdir -p "$ROOT/dist"
rm -f "$DMG"
hdiutil convert -quiet "$RAW" -format ULMO -o "$DMG"

if [ -n "$SIGN_IDENTITY" ]; then
    codesign --force --sign "$SIGN_IDENTITY" "$DMG"
fi

echo "✓ $DMG ($(du -h "$DMG" | cut -f1))"
echo "quem receber precisa liberar o Gatekeeper: xattr -dr com.apple.quarantine /Applications/$NAME.app"
