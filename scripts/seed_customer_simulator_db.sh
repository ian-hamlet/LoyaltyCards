#!/usr/bin/env bash
set -euo pipefail

# Seeds the customer app SQLite database in an iOS simulator with screenshot data.
# Usage:
#   ./scripts/seed_customer_simulator_db.sh
#   ./scripts/seed_customer_simulator_db.sh <simulator_udid>
#   ./scripts/seed_customer_simulator_db.sh "iPhone SE (3rd generation)"

SIM_INPUT="${1:-iPhone 14 Pro}"
BUNDLE_ID="com.ianhamlet.loyaltycards.customerApp"
DB_NAME="loyalty_cards.db"

resolve_sim_udid() {
  local input="$1"

  if [[ "$input" =~ ^[0-9A-Fa-f-]{36}$ ]]; then
    echo "$input"
    return 0
  fi

  local line
  local udid
  line="$(xcrun simctl list devices available | grep -F "$input (" | head -n 1 || true)"
  udid="$(printf '%s' "$line" | grep -Eo '[0-9A-Fa-f-]{36}' | head -n 1 || true)"

  if [[ -z "$udid" ]]; then
    return 1
  fi

  echo "$udid"
}

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun not found. Install Xcode command line tools first."
  exit 1
fi

if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "sqlite3 not found. Install sqlite3 first (brew install sqlite)."
  exit 1
fi

SIM_UDID="$(resolve_sim_udid "$SIM_INPUT" || true)"
if [[ -z "$SIM_UDID" ]]; then
  cat <<EOF
Could not resolve simulator from input: $SIM_INPUT

Pass either:
1) Simulator UDID (recommended)
2) Exact simulator name from: xcrun simctl list devices available

Examples:
  ./scripts/seed_customer_simulator_db.sh DA697758-8E9F-4217-A5BB-A977A94264C2
  ./scripts/seed_customer_simulator_db.sh "iPhone SE (3rd generation)"
EOF
  exit 1
fi

APP_CONTAINER="$(xcrun simctl get_app_container "$SIM_UDID" "$BUNDLE_ID" data 2>/dev/null || true)"
if [[ -z "$APP_CONTAINER" ]]; then
  cat <<EOF
Could not locate app container.

Make sure:
1) Simulator $SIM_UDID exists and is booted
2) Customer app has been run at least once on that simulator

Then rerun this script.
EOF
  exit 1
fi

DB_PATH="$APP_CONTAINER/Documents/$DB_NAME"
if [[ ! -f "$DB_PATH" ]]; then
  cat <<EOF
Database not found at:
$DB_PATH

Run customer app once on this simulator so sqflite creates the DB, then rerun.
EOF
  exit 1
fi

cp "$DB_PATH" "$DB_PATH.bak.$(date +%Y%m%d_%H%M%S)"

sqlite3 "$DB_PATH" <<'SQL'
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;

DELETE FROM stamps;
DELETE FROM transactions;
DELETE FROM cards;

INSERT INTO cards (
  id, business_id, business_name, business_public_key,
  stamps_required, stamps_collected, brand_color, logo_index,
  mode, created_at, updated_at, is_redeemed, redeemed_at, device_id
) VALUES
('card-001', 'biz-001', 'Test Coffee', 'pubkey-test-001', 5, 0, '#8B4513', 0, 'simple', 1749600000000, 1749600000000, 0, NULL, 'sim-device'),
('card-002', 'biz-002', 'Green Grocer', 'pubkey-test-002', 5, 2, '#2E7D32', 1, 'simple', 1749600100000, 1749600100000, 0, NULL, 'sim-device'),
('card-003', 'biz-003', 'Metro Deli', 'pubkey-test-003', 7, 4, '#1565C0', 2, 'secure', 1749600200000, 1749600200000, 0, NULL, 'sim-device'),
('card-004', 'biz-004', 'Sunny Bakery', 'pubkey-test-004', 10, 9, '#EF6C00', 3, 'simple', 1749600300000, 1749600300000, 0, NULL, 'sim-device'),
('card-005', 'biz-005', 'Zen Spa', 'pubkey-test-005', 8, 8, '#6A1B9A', 4, 'secure', 1749600400000, 1749600400000, 0, NULL, 'sim-device'),
('card-006', 'biz-006', 'City Books', 'pubkey-test-006', 6, 3, '#455A64', 5, 'simple', 1749600500000, 1749600500000, 0, NULL, 'sim-device');

INSERT INTO stamps (id, card_id, stamp_number, timestamp, signature, previous_hash, device_id) VALUES
('stamp-002-1', 'card-002', 1, 1749600101000, 'sig-test', NULL, 'sim-device'),
('stamp-002-2', 'card-002', 2, 1749600102000, 'sig-test', 'hash-002-1', 'sim-device'),
('stamp-003-1', 'card-003', 1, 1749600201000, 'sig-test', NULL, 'sim-device'),
('stamp-003-2', 'card-003', 2, 1749600202000, 'sig-test', 'hash-003-1', 'sim-device'),
('stamp-003-3', 'card-003', 3, 1749600203000, 'sig-test', 'hash-003-2', 'sim-device'),
('stamp-003-4', 'card-003', 4, 1749600204000, 'sig-test', 'hash-003-3', 'sim-device'),
('stamp-004-1', 'card-004', 1, 1749600301000, 'sig-test', NULL, 'sim-device'),
('stamp-004-2', 'card-004', 2, 1749600302000, 'sig-test', 'hash-004-1', 'sim-device'),
('stamp-004-3', 'card-004', 3, 1749600303000, 'sig-test', 'hash-004-2', 'sim-device'),
('stamp-004-4', 'card-004', 4, 1749600304000, 'sig-test', 'hash-004-3', 'sim-device'),
('stamp-004-5', 'card-004', 5, 1749600305000, 'sig-test', 'hash-004-4', 'sim-device'),
('stamp-004-6', 'card-004', 6, 1749600306000, 'sig-test', 'hash-004-5', 'sim-device'),
('stamp-004-7', 'card-004', 7, 1749600307000, 'sig-test', 'hash-004-6', 'sim-device'),
('stamp-004-8', 'card-004', 8, 1749600308000, 'sig-test', 'hash-004-7', 'sim-device'),
('stamp-004-9', 'card-004', 9, 1749600309000, 'sig-test', 'hash-004-8', 'sim-device'),
('stamp-005-1', 'card-005', 1, 1749600401000, 'sig-test', NULL, 'sim-device'),
('stamp-005-2', 'card-005', 2, 1749600402000, 'sig-test', 'hash-005-1', 'sim-device'),
('stamp-005-3', 'card-005', 3, 1749600403000, 'sig-test', 'hash-005-2', 'sim-device'),
('stamp-005-4', 'card-005', 4, 1749600404000, 'sig-test', 'hash-005-3', 'sim-device'),
('stamp-005-5', 'card-005', 5, 1749600405000, 'sig-test', 'hash-005-4', 'sim-device'),
('stamp-005-6', 'card-005', 6, 1749600406000, 'sig-test', 'hash-005-5', 'sim-device'),
('stamp-005-7', 'card-005', 7, 1749600407000, 'sig-test', 'hash-005-6', 'sim-device'),
('stamp-005-8', 'card-005', 8, 1749600408000, 'sig-test', 'hash-005-7', 'sim-device'),
('stamp-006-1', 'card-006', 1, 1749600501000, 'sig-test', NULL, 'sim-device'),
('stamp-006-2', 'card-006', 2, 1749600502000, 'sig-test', 'hash-006-1', 'sim-device'),
('stamp-006-3', 'card-006', 3, 1749600503000, 'sig-test', 'hash-006-2', 'sim-device');

INSERT INTO transactions (id, card_id, type, timestamp, business_name, details) VALUES
('txn-001-issue', 'card-001', 'issue', 1749600000000, 'Test Coffee', 'Card issued'),
('txn-002-issue', 'card-002', 'issue', 1749600100000, 'Green Grocer', 'Card issued'),
('txn-002-stamp1', 'card-002', 'stamp', 1749600101000, 'Green Grocer', 'Stamp 1 of 5'),
('txn-002-stamp2', 'card-002', 'stamp', 1749600102000, 'Green Grocer', 'Stamp 2 of 5'),
('txn-003-issue', 'card-003', 'issue', 1749600200000, 'Metro Deli', 'Card issued'),
('txn-003-stamp4', 'card-003', 'stamp', 1749600204000, 'Metro Deli', 'Stamp 4 of 7'),
('txn-004-issue', 'card-004', 'issue', 1749600300000, 'Sunny Bakery', 'Card issued'),
('txn-004-stamp9', 'card-004', 'stamp', 1749600309000, 'Sunny Bakery', 'Stamp 9 of 10'),
('txn-005-issue', 'card-005', 'issue', 1749600400000, 'Zen Spa', 'Card issued'),
('txn-005-ready', 'card-005', 'stamp', 1749600408000, 'Zen Spa', 'Card ready to redeem'),
('txn-006-issue', 'card-006', 'issue', 1749600500000, 'City Books', 'Card issued'),
('txn-006-stamp3', 'card-006', 'stamp', 1749600503000, 'City Books', 'Stamp 3 of 6');

COMMIT;
SQL

echo "Simulator input: $SIM_INPUT"
echo "Resolved UDID: $SIM_UDID"
echo "Seed complete: $DB_PATH"
echo "Relaunch customer app in simulator to view seeded cards/stamps."
