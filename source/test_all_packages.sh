#!/usr/bin/env bash
#
# Runs the full test suite for all three packages, one after the other.
#
# Usage: from anywhere, run:
#   ./test_all_packages.sh
# or:
#   bash source/test_all_packages.sh
#
# Runs shared first, since customer_app and supplier_app both depend on it
# as a path dependency - if shared is broken, the app-level failures that
# follow are usually just noise from the same root cause.

set -e  # stop immediately on any failure, rather than continuing past a red suite

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

test_package() {
  local package_dir="$1"
  echo ""
  echo "===== Testing $package_dir ====="
  cd "$SCRIPT_DIR/$package_dir"
  flutter test
  echo "===== $package_dir tests finished ====="
}

test_package "shared"
test_package "customer_app"
test_package "supplier_app"

echo ""
echo "===== All packages passed ====="
