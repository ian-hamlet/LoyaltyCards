#!/usr/bin/env bash
#
# Builds release IPAs for both apps, one after the other.
#
# Usage: from anywhere, run:
#   ./build_both_apps.sh
# or:
#   bash source/build_both_apps.sh
#
# Run this alone - don't start a second build of either app while this is
# running. Two concurrent `flutter clean`/`pod install` runs against the
# same app directory will corrupt each other's Pods sandbox and fail with
# "The sandbox is not in sync with the Podfile.lock."
#
# Output IPAs land at:
#   customer_app/build/ios/ipa/customer_app.ipa
#   supplier_app/build/ios/ipa/supplier_app.ipa

set -e  # stop immediately on any failure, rather than continuing with a stale/partial build

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

build_app() {
  local app_dir="$1"
  echo ""
  echo "===== Building $app_dir ====="
  cd "$SCRIPT_DIR/$app_dir"
  flutter clean
  flutter pub get
  flutter build ipa --release
  echo "===== $app_dir build finished ====="
}

build_app "customer_app"
build_app "supplier_app"

echo ""
echo "===== Both builds finished ====="
echo "customer_app.ipa: $SCRIPT_DIR/customer_app/build/ios/ipa/customer_app.ipa"
echo "supplier_app.ipa: $SCRIPT_DIR/supplier_app/build/ios/ipa/supplier_app.ipa"
