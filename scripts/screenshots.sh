#!/usr/bin/env bash
#
# App Store screenshot capture for WhichFood.
#
# Builds a Debug build with the screenshot harness (WFScreenshotSupport),
# installs it on a simulator, then for each language x screen launches the app
# with the right launch arguments and grabs a PNG via `simctl io screenshot`.
#
# The harness injects fixed, localized mock recipes so no live AI / network
# recipe generation is required. Food photos still load over the host network.
#
# Usage:
#   scripts/screenshots.sh [SIMULATOR_UDID]
#
# Defaults to the currently-used simulator if no UDID is given.

set -euo pipefail

cd "$(dirname "$0")/.."

UDID="${1:-CE302350-35E1-426A-B332-14EADEF4CA3F}"
SCHEME="WhichFood"
BUNDLE_ID="com.metehangurgentepe.WhichFood"
DERIVED="build"
OUT_DIR="screenshots"

# language lproj code : matching locale (for number/date formatting)
LANGS=(
  "en:en_US"
  "tr:tr_TR"
  "de:de_DE"
  "es:es_ES"
  "fr:fr_FR"
  "it:it_IT"
  "ja:ja_JP"
  "ko:ko_KR"
  "zh-Hans:zh_CN"
  "ru:ru_RU"
  "pt-PT:pt_PT"
)

SCREENS=(home favorites detail)

echo "▶︎ Simulator: $UDID"
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true

echo "▶︎ Building Debug build (screenshot harness is DEBUG-only)…"
xcodebuild \
  -project WhichFood.xcodeproj \
  -scheme "$SCHEME" \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "id=$UDID" \
  -derivedDataPath "$DERIVED" \
  build | tail -n 20

APP_PATH="$DERIVED/Build/Products/Debug-iphonesimulator/$SCHEME.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "✘ Build product not found at $APP_PATH" >&2
  exit 1
fi

echo "▶︎ Installing $APP_PATH"
xcrun simctl install "$UDID" "$APP_PATH"

# Clean status bar for App Store presentation.
xcrun simctl status_bar "$UDID" override \
  --time "9:41" \
  --batteryState charged --batteryLevel 100 \
  --cellularMode active --cellularBars 4 \
  --wifiMode active --wifiBars 3 >/dev/null 2>&1 || true

for entry in "${LANGS[@]}"; do
  lang="${entry%%:*}"
  locale="${entry##*:}"
  mkdir -p "$OUT_DIR/$lang"

  for screen in "${SCREENS[@]}"; do
    echo "▶︎ $lang / $screen"
    xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true

    xcrun simctl launch "$UDID" "$BUNDLE_ID" \
      -AppleLanguages "($lang)" \
      -AppleLocale "$locale" \
      -UITEST_SCREENSHOT YES \
      -UITEST_SCREEN "$screen" >/dev/null

    # Give the UI time to lay out and the remote food photos time to load.
    sleep 5

    xcrun simctl io "$UDID" screenshot "$OUT_DIR/$lang/$screen.png" >/dev/null
  done
done

xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true

echo "✔ Done. Screenshots in ./$OUT_DIR/<lang>/<screen>.png"
find "$OUT_DIR" -name '*.png' | sort
