#!/bin/zsh
# Gera o AsaasDaily.app em Release (Apple Silicon e Intel) e o zip para mandar para o time.
# Uso: ./scripts/dist.sh
set -euo pipefail
cd "${0:A:h}/.."

xcodebuild -project AsaasDaily.xcodeproj -scheme AsaasDaily -configuration Release \
  -destination 'generic/platform=macOS' -derivedDataPath build/DerivedData \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO -quiet build

APP=build/DerivedData/Build/Products/Release/AsaasDaily.app
codesign --verify --deep --strict "$APP"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP/Contents/Info.plist")
ZIP="dist/AsaasDaily-$VERSION.zip"

mkdir -p dist
# ditto, e não zip: o zip comum descarta os atributos estendidos e quebra a assinatura do bundle
ditto -c -k --keepParent "$APP" "$ZIP"

echo "arquiteturas: $(lipo -archs "$APP/Contents/MacOS/AsaasDaily")"
echo "pronto: $ZIP ($(du -h "$ZIP" | cut -f1))"
echo "quem receber precisa liberar o Gatekeeper: xattr -dr com.apple.quarantine <zip>"
