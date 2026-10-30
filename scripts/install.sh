#!/bin/zsh
# Compila em Release e troca a versão instalada em /Applications, como se faz no AsaasDeck.
# Fecha o app antes de copiar: substituir o bundle com ele rodando deixa o processo com
# arquivos que não existem mais.
# Uso: ./scripts/install.sh
set -euo pipefail
cd "${0:A:h}/.."

xcodebuild -project AsaasDaily.xcodeproj -scheme AsaasDaily -configuration Release \
  -destination 'generic/platform=macOS' -derivedDataPath build/DerivedData \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO -quiet build

APP=build/DerivedData/Build/Products/Release/AsaasDaily.app
codesign --verify --deep --strict "$APP"

osascript -e 'tell application "AsaasDaily" to quit' 2>/dev/null || true
pkill -x AsaasDaily 2>/dev/null || true
sleep 1

# ditto, e não cp: preserva atributos estendidos e a assinatura do bundle
ditto "$APP" /Applications/AsaasDaily.app

echo "arquiteturas: $(lipo -archs /Applications/AsaasDaily.app/Contents/MacOS/AsaasDaily)"
open -a AsaasDaily
echo "instalado e aberto: /Applications/AsaasDaily.app"
