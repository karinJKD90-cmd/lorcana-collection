#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Lorcana Flutter – Bootstrap
# Pakt Flutter op vanuit ~/Downloads, maakt het project aan en opent Xcode.
# ─────────────────────────────────────────────────────────────────────────────
set -e

DOWNLOADS="$HOME/Downloads"
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_NAME="lorcana_collection"
PROJECT_PARENT="$HOME/Developer"   # Project komt hier te staan

echo ""
echo "════════════════════════════════════════"
echo "  Lorcana Collection – Flutter setup"
echo "════════════════════════════════════════"
echo ""

# ── Stap 1: Flutter vinden ────────────────────────────────────────────────────
echo "▶ Flutter zoeken in ~/Downloads..."

FLUTTER_DIR=""

# Al uitgepakt?
if [ -d "$DOWNLOADS/flutter" ]; then
  FLUTTER_DIR="$DOWNLOADS/flutter"
  echo "  ✅ Gevonden: $FLUTTER_DIR"

# Zip aanwezig?
elif ls "$DOWNLOADS"/flutter_macos_*.zip 1>/dev/null 2>&1; then
  ZIP=$(ls "$DOWNLOADS"/flutter_macos_*.zip | head -1)
  echo "  📦 Uitpakken: $ZIP"
  unzip -q "$ZIP" -d "$DOWNLOADS"
  FLUTTER_DIR="$DOWNLOADS/flutter"
  echo "  ✅ Uitgepakt naar: $FLUTTER_DIR"

# Arm64 zip?
elif ls "$DOWNLOADS"/flutter_macos_arm64_*.zip 1>/dev/null 2>&1; then
  ZIP=$(ls "$DOWNLOADS"/flutter_macos_arm64_*.zip | head -1)
  echo "  📦 Uitpakken: $ZIP"
  unzip -q "$ZIP" -d "$DOWNLOADS"
  FLUTTER_DIR="$DOWNLOADS/flutter"
  echo "  ✅ Uitgepakt naar: $FLUTTER_DIR"

else
  echo ""
  echo "  ❌ Flutter niet gevonden in ~/Downloads."
  echo "     Download via: https://docs.flutter.dev/get-started/install/macos/mobile-ios"
  echo "     Pak het zip-bestand uit en probeer opnieuw."
  exit 1
fi

FLUTTER="$FLUTTER_DIR/bin/flutter"
export PATH="$FLUTTER_DIR/bin:$PATH"

echo ""
echo "▶ Flutter versie controleren..."
"$FLUTTER" --version

# ── Stap 2: Project aanmaken ──────────────────────────────────────────────────
echo ""
echo "▶ Project aanmaken in $PROJECT_PARENT/$PROJECT_NAME ..."
mkdir -p "$PROJECT_PARENT"

if [ -d "$PROJECT_PARENT/$PROJECT_NAME" ]; then
  echo "  ⚠️  Map bestaat al — wordt overschreven (lib/ en pubspec.yaml)."
else
  "$FLUTTER" create \
    --org nl.karinpieterson \
    --project-name "$PROJECT_NAME" \
    --platforms ios,android \
    "$PROJECT_PARENT/$PROJECT_NAME"
fi

# ── Stap 3: Bronbestanden kopiëren ────────────────────────────────────────────
echo ""
echo "▶ Bronbestanden kopiëren..."
cp -r "$SOURCE_DIR/lib/"* "$PROJECT_PARENT/$PROJECT_NAME/lib/"
cp "$SOURCE_DIR/pubspec.yaml" "$PROJECT_PARENT/$PROJECT_NAME/pubspec.yaml"

# ── Stap 4: Dependencies ─────────────────────────────────────────────────────
echo ""
echo "▶ Dependencies installeren..."
cd "$PROJECT_PARENT/$PROJECT_NAME"
"$FLUTTER" pub get

# ── Stap 5: Xcode openen ─────────────────────────────────────────────────────
echo ""
echo "▶ Xcode openen..."
open ios/Runner.xcworkspace

echo ""
echo "════════════════════════════════════════"
echo "  ✅ Klaar!"
echo ""
echo "  Project staat op:"
echo "  $PROJECT_PARENT/$PROJECT_NAME"
echo ""
echo "  Vergeet niet:"
echo "  1. lib/config.dart → Supabase URL + anon key invullen"
echo "  2. Xcode → Signing & Capabilities → je Apple Team selecteren"
echo "  3. supabase_schema.sql uitvoeren in Supabase SQL Editor"
echo "════════════════════════════════════════"
echo ""
