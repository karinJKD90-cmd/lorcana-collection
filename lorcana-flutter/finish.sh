#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Lorcana Flutter – Afronden (camera permission + config check)
# Draai dit in Terminal: bash finish.sh
# ─────────────────────────────────────────────────────────────────────────────

PROJECT="$HOME/Developer/lorcana_collection"

echo ""
echo "════════════════════════════════════════"
echo "  Lorcana – afronding"
echo "════════════════════════════════════════"
echo ""

# ── Camera permission toevoegen aan Info.plist ────────────────────────────────
PLIST="$PROJECT/ios/Runner/Info.plist"

if grep -q "NSCameraUsageDescription" "$PLIST" 2>/dev/null; then
  echo "✅ Camera permission al aanwezig in Info.plist"
else
  /usr/libexec/PlistBuddy \
    -c "Add :NSCameraUsageDescription string 'Lorcana Collection gebruikt de camera om kaarten te scannen.'" \
    "$PLIST" && echo "✅ Camera permission toegevoegd aan Info.plist"
fi

# ── Supabase config controleren ───────────────────────────────────────────────
CONFIG="$PROJECT/lib/config.dart"
echo ""
if grep -q "JOUW_SUPABASE" "$CONFIG"; then
  echo "⚠️  Supabase config nog niet ingevuld: $CONFIG"
  echo ""
  echo "   1. Ga naar https://supabase.com → jouw project"
  echo "   2. Settings → API"
  echo "   3. Kopieer 'Project URL' en 'anon public' key"
  echo "   4. Open dit bestand en vul ze in:"
  echo "      open -a Xcode $CONFIG"
else
  echo "✅ Supabase config ingevuld"
fi

# ── Schema reminder ───────────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────"
echo "  Supabase schema (eenmalig uitvoeren)"
echo "────────────────────────────────────────"
echo "  1. Ga naar https://supabase.com → jouw project"
echo "  2. SQL Editor → New query"
echo "  3. Plak de inhoud van:"
SCHEMA_SRC="$(cd "$(dirname "$0")" && pwd)/supabase_schema.sql"
echo "     $SCHEMA_SRC"
echo "  4. Klik Run"
echo ""

# ── App bouwen ────────────────────────────────────────────────────────────────
echo "────────────────────────────────────────"
echo "  App testen"
echo "────────────────────────────────────────"
echo "  Open in Xcode:"
echo "  open $PROJECT/ios/Runner.xcworkspace"
echo ""
echo "  Of direct starten op simulator:"
echo "  cd $PROJECT && $HOME/Downloads/flutter/bin/flutter run"
echo ""
echo "════════════════════════════════════════"
echo "  Klaar met setup ✅"
echo "════════════════════════════════════════"
