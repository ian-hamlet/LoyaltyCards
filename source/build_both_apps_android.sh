#!/usr/bin/env bash
#
# Builds release AABs (Android App Bundles) for both apps, one after the
# other (Android/Google Play). For the iOS/Apple App Store equivalent, see
# build_both_apps_ios.sh.
#
# Usage: from anywhere, run:
#   ./build_both_apps_android.sh
# or:
#   bash source/build_both_apps_android.sh
#
# Run this alone - don't start a second build of either app while this is
# running. Two concurrent `flutter clean`/`flutter build` runs against the
# same app directory will race on shared build output (build/, .gradle) and
# can corrupt each other's build.
#
# Each app's android/key.properties (machine-local, gitignored) must point at
# the shared release keystore for this to produce a properly release-signed
# AAB - if it's missing, build.gradle.kts silently falls back to debug
# signing, so the build still succeeds but Play Console will reject the
# upload. This script checks for it and warns rather than failing outright,
# since a debug-signed build is still useful for local testing.
#
# Output AABs land at:
#   customer_app/build/app/outputs/bundle/release/app-release.aab
#   supplier_app/build/app/outputs/bundle/release/app-release.aab

set -e  # stop immediately on any failure, rather than continuing with a stale/partial build

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

build_app() {
  local app_dir="$1"
  echo ""
  echo "===== Building $app_dir ====="

  if [ ! -f "$SCRIPT_DIR/$app_dir/android/key.properties" ]; then
    echo "WARNING: $app_dir/android/key.properties not found - this build will"
    echo "         fall back to debug signing, which Play Console will reject."
  fi

  cd "$SCRIPT_DIR/$app_dir"
  flutter clean
  flutter pub get
  flutter build appbundle --release
  echo "===== $app_dir build finished ====="
}

build_app "customer_app"
build_app "supplier_app"

echo ""
echo "===== Both builds finished ====="
echo "customer_app.aab: $SCRIPT_DIR/customer_app/build/app/outputs/bundle/release/app-release.aab"
echo "supplier_app.aab: $SCRIPT_DIR/supplier_app/build/app/outputs/bundle/release/app-release.aab"
