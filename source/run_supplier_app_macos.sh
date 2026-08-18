#!/usr/bin/env bash
#
# Runs the Supplier app (LoyaltyCards Business) as a native macOS desktop app.
#
# Usage: from anywhere, run:
#   ./run_supplier_app_macos.sh
# or:
#   bash source/run_supplier_app_macos.sh
#
# Once running: r = hot reload, R = hot restart, q = quit, h = list all commands.
#
# Tip: run this alongside run_customer_app_macos.sh to test the full P2P
# flow on one machine - scan a QR straight from one window's screen into
# the other's camera, or screenshot and use "scan from Photos" if the
# camera can't see the other window cleanly. Each app uses its own local
# SQLite database, so running both side by side is safe.

set -e  # stop immediately on any failure, rather than continuing with a stale/partial run

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/supplier_app"

# If dependencies might have drifted (e.g. it's been a while since this last ran), uncomment:
# flutter pub get

flutter run -d macos
