#!/bin/bash
# ============================================================
# build_ipa.sh  — GlucoseDirect IPA builder for testing
# Usage: chmod +x build_ipa.sh && ./build_ipa.sh
# ============================================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="GlucoseDirect.xcodeproj"
SCHEME="GlucoseDirectApp"
CONFIGURATION="Release"
ARCHIVE_PATH="$PROJECT_DIR/build/GlucoseDirectApp.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/IPA"
EXPORT_PLIST="$PROJECT_DIR/build/ExportOptions.plist"

# Detect Xcode
echo "🔍 Checking Xcode..."
XCODE_PATH=$(mdfind "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'" 2>/dev/null | head -1)
if [ -z "$XCODE_PATH" ]; then
    echo "❌ Xcode not found. Install from https://apps.apple.com/app/xcode/id497799835"
    exit 1
fi
export DEVELOPER_DIR="$XCODE_PATH/Contents/Developer"
echo "✅ Using: $XCODE_PATH"
xcodebuild -version

mkdir -p "$PROJECT_DIR/build"

# Write ExportOptions.plist
cat > "$EXPORT_PLIST" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>9JNYW2DG9D</string>
    <key>compileBitcode</key>
    <false/>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string><none></string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF

echo ""
echo "🧹 Cleaning..."
xcodebuild clean \
    -project "$PROJECT_DIR/$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    2>&1 | tail -3

echo ""
echo "📦 Archiving (takes 2-5 minutes)..."
xcodebuild archive \
    -project "$PROJECT_DIR/$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=iOS" \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM=9JNYW2DG9D \
    2>&1 | tee /tmp/glucosedirect_build.log | grep -E "^(error:|Build FAILED|** ARCHIVE)" || true

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "❌ Archive failed. Full log: /tmp/glucosedirect_build.log"
    exit 1
fi
echo "✅ Archive: $ARCHIVE_PATH"

echo ""
echo "📤 Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_PLIST" \
    2>&1 | grep -E "^(error:|Export)" || true

IPA_FILE=$(find "$EXPORT_PATH" -name "*.ipa" 2>/dev/null | head -1)
if [ -z "$IPA_FILE" ]; then
    echo "❌ IPA export failed."
    exit 1
fi

echo ""
echo "✅ ============================================"
echo "   IPA ready: $IPA_FILE"
echo "   ============================================"
echo ""
echo "📲 Install options:"
echo "  • Xcode → Window → Devices → drag IPA onto device"
echo "  • ideviceinstaller -i '$IPA_FILE'"
echo "  • Upload to TestFlight via Transporter app"
