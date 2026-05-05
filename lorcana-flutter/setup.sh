#!/bin/bash
# ─────────────────────────────────────────────
# Lorcana Collection – Flutter project setup
# Draai dit één keer vanuit de gewenste map:
#   chmod +x setup.sh && ./setup.sh
# ─────────────────────────────────────────────

set -e

# Check Flutter
if ! command -v flutter &> /dev/null; then
  echo "❌ Flutter niet gevonden. Installeer via: https://docs.flutter.dev/get-started/install/macos"
  exit 1
fi

echo "✅ Flutter gevonden: $(flutter --version | head -1)"

# Maak project aan
echo ""
echo "📦 Flutter project aanmaken..."
flutter create \
  --org nl.karinpieterson \
  --project-name lorcana_collection \
  --platforms ios,android \
  lorcana_collection

echo ""
echo "📁 Bronbestanden kopiëren..."

# Kopieer lib/ vanuit deze map naar het nieuwe project
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cp -r "$SCRIPT_DIR/lib/"* lorcana_collection/lib/
cp "$SCRIPT_DIR/pubspec.yaml" lorcana_collection/pubspec.yaml

cd lorcana_collection

echo ""
echo "📥 Dependencies installeren..."
flutter pub get

echo ""
echo "✅ Klaar! Open het project:"
echo "   open lorcana_collection/ -a Xcode   (voor iOS)"
echo ""
echo "⚠️  Vergeet niet:"
echo "   1. Supabase URL + anon key invullen in lib/config.dart"
echo "   2. Apple Team ID instellen in Xcode → Signing & Capabilities"
echo "   3. Voor Android: google-services.json is niet nodig (geen Firebase)"
