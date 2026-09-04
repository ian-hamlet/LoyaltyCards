#!/usr/bin/env bash
set -euo pipefail

# Seeds the customer app SQLite database on a connected Android device/emulator
# with the same screenshot fixture data as scripts/seed_customer_simulator_db.sh
# (iOS simulator) and scripts/seed_customer_device_db.sh (physical iOS device),
# via `adb run-as` app-data access - the Android equivalent of those two.
#
# Usage:
#   ./scripts/seed_customer_android_db.sh
#   ./scripts/seed_customer_android_db.sh emulator-5554
#
# Requires a DEBUG build of the customer app (release builds aren't
# `run-as`-accessible) already installed and launched at least once on the
# target device/emulator, so its Documents-equivalent database exists:
#   cd source/customer_app && flutter run -d <device>
#
# WARNING: this overwrites the app's local database on the device with
# fixture data. A timestamped backup of the pre-seed database is kept
# locally in $WORKDIR below (not written back to the device).

DEVICE_INPUT="${1:-}"
PACKAGE="com.ianhamlet.loyaltycards.customer"
DB_NAME="loyalty_cards.db"
WORKDIR="$(mktemp -d)"
DB_LOCAL="$WORKDIR/$DB_NAME"

ADB_ARGS=()
if [[ -n "$DEVICE_INPUT" ]]; then
  ADB_ARGS=(-s "$DEVICE_INPUT")
fi

if ! command -v adb >/dev/null 2>&1; then
  echo "adb not found. Install Android SDK platform-tools first."
  exit 1
fi
if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "sqlite3 not found. Install sqlite3 first (brew install sqlite)."
  exit 1
fi

echo "Checking device/app state..."
if ! adb "${ADB_ARGS[@]}" shell run-as "$PACKAGE" ls "databases/$DB_NAME" >/dev/null 2>&1; then
  cat <<EOF

Could not find the database via 'run-as'. Make sure:
1) A device/emulator is connected: adb devices
2) The customer app is a DEBUG build (release builds aren't run-as accessible)
   - installed via 'flutter run', not 'flutter build ... --release'
3) The app has been launched at least once so sqflite created the DB

Then rerun this script.
EOF
  exit 1
fi

echo "Pulling current database from device..."
adb "${ADB_ARGS[@]}" exec-out run-as "$PACKAGE" cat "databases/$DB_NAME" > "$DB_LOCAL"

cp "$DB_LOCAL" "$DB_LOCAL.bak.$(date +%Y%m%d_%H%M%S)"
echo "Local backup kept at: $DB_LOCAL.bak.$(date +%Y%m%d_%H%M%S) (not written back to device)"

sqlite3 "$DB_LOCAL" <<'SQL'
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
('card-001', 'biz-001', 'Test Coffee', 'pubkey-test-001', 5, 0, '#8B4513', 0, 'simple', 1749600000000, 1749600000000, 0, NULL, 'android-emulator'),
('card-002', 'biz-002', 'Green Grocer', 'pubkey-test-002', 5, 2, '#2E7D32', 1, 'simple', 1749600100000, 1749600100000, 0, NULL, 'android-emulator'),
('card-003', 'biz-003', 'Metro Deli', 'AAAAIIrhBs7Bh1h3FcnHY/aSCuZF01nkoi/JZ+PxsGhKmJVsAAAAIM9BE1AXf9YSLJPD6cg75vRjE9EYt6AXAaJJiCGZhA+R', 7, 4, '#1565C0', 2, 'secure', 1749600200000, 1749600200000, 0, NULL, 'android-emulator'),
('card-004', 'biz-004', 'Sunny Bakery', 'pubkey-test-004', 10, 9, '#EF6C00', 3, 'simple', 1749600300000, 1749600300000, 0, NULL, 'android-emulator'),
('card-005', 'biz-005', 'Zen Spa', 'AAAAIPeqF78qCX5RQBzKX/9ieU2j0dnmwSe5aU+wPbdxdfBqAAAAIJttWGBReU+RIuojbFxHeuVcygsppBFOv/rdgwuWjDcC', 8, 8, '#6A1B9A', 4, 'secure', 1749600400000, 1749600400000, 0, NULL, 'android-emulator'),
('card-006', 'biz-006', 'City Books', 'pubkey-test-006', 6, 3, '#455A64', 5, 'simple', 1749600500000, 1749600500000, 0, NULL, 'android-emulator');

INSERT INTO stamps (id, card_id, stamp_number, timestamp, signature, previous_hash, device_id) VALUES
('stamp-002-1', 'card-002', 1, 1749600101000, 'sig-test', NULL, 'android-emulator'),
('stamp-002-2', 'card-002', 2, 1749600102000, 'sig-test', 'hash-002-1', 'android-emulator'),
('stamp-003-1', 'card-003', 1, 1749600201000, 'AAAAIGlRgIHoZBLuViXubPHd1RN8SkP3FrIY28dJJMG/73dnAAAAIANOeT1eBAEI0wZov8/bWMGNWB+f56k7qRVMu5U+yxs2', NULL, 'android-emulator'),
('stamp-003-2', 'card-003', 2, 1749600202000, 'AAAAIFMXaddereUupHCqCGlcdF7xKgukqQ+Yt5r/Wj9EDIlFAAAAIPJnmkSl8llLML6XkRvzgeSG98rBesyYoyfSm3y4jZaF', 'AAAAIGlRgIHoZBLuViXubPHd1RN8SkP3FrIY28dJJMG/73dnAAAAIANOeT1eBAEI0wZov8/bWMGNWB+f56k7qRVMu5U+yxs2', 'android-emulator'),
('stamp-003-3', 'card-003', 3, 1749600203000, 'AAAAIEvj936UGP8ITM0iph6+Y6r0MuFVJegB0zM0IEzcqfCXAAAAIP4uwzE63NDBZ5RKZ7K06joPNsCrocJZ3tyd6nqYbSHu', 'AAAAIFMXaddereUupHCqCGlcdF7xKgukqQ+Yt5r/Wj9EDIlFAAAAIPJnmkSl8llLML6XkRvzgeSG98rBesyYoyfSm3y4jZaF', 'android-emulator'),
('stamp-003-4', 'card-003', 4, 1749600204000, 'AAAAIJ+fS7CNvp9z7tN2IB8KHjwuEORrqo/iqBAgWvPkvI6JAAAAIDR9Fyvy5VDQkjxGi3GhvS4404IdQNK6ijcD78OT2s7t', 'AAAAIEvj936UGP8ITM0iph6+Y6r0MuFVJegB0zM0IEzcqfCXAAAAIP4uwzE63NDBZ5RKZ7K06joPNsCrocJZ3tyd6nqYbSHu', 'android-emulator'),
('stamp-004-1', 'card-004', 1, 1749600301000, 'sig-test', NULL, 'android-emulator'),
('stamp-004-2', 'card-004', 2, 1749600302000, 'sig-test', 'hash-004-1', 'android-emulator'),
('stamp-004-3', 'card-004', 3, 1749600303000, 'sig-test', 'hash-004-2', 'android-emulator'),
('stamp-004-4', 'card-004', 4, 1749600304000, 'sig-test', 'hash-004-3', 'android-emulator'),
('stamp-004-5', 'card-004', 5, 1749600305000, 'sig-test', 'hash-004-4', 'android-emulator'),
('stamp-004-6', 'card-004', 6, 1749600306000, 'sig-test', 'hash-004-5', 'android-emulator'),
('stamp-004-7', 'card-004', 7, 1749600307000, 'sig-test', 'hash-004-6', 'android-emulator'),
('stamp-004-8', 'card-004', 8, 1749600308000, 'sig-test', 'hash-004-7', 'android-emulator'),
('stamp-004-9', 'card-004', 9, 1749600309000, 'sig-test', 'hash-004-8', 'android-emulator'),
('stamp-005-1', 'card-005', 1, 1749600401000, 'AAAAILVnbUONJIR3VVn0V1bt+kGMui9wIvkreULgZ7zf6T3hAAAAIAFkH9GDcPUs4VoLP5QIAX+BZkkCv97WxLiUy8d1vSGX', NULL, 'android-emulator'),
('stamp-005-2', 'card-005', 2, 1749600402000, 'AAAAIO5i8Dl7xvr0rEoHSjvlLynbOtpdK1x0V75ZuXXA/g7rAAAAIBmBYXOvL/ry+uQYlVYX8sTgrgSb+QU2teqTAef5y7rF', 'AAAAILVnbUONJIR3VVn0V1bt+kGMui9wIvkreULgZ7zf6T3hAAAAIAFkH9GDcPUs4VoLP5QIAX+BZkkCv97WxLiUy8d1vSGX', 'android-emulator'),
('stamp-005-3', 'card-005', 3, 1749600403000, 'AAAAIPhsoo0XcAlPLHlpJqGlAMzIjVI3ylsIWHoD7N9cos3TAAAAINwmoNkRmP/TpuSwJ/rAUvBhCGwpdx4FFe6Kl7+tGid3', 'AAAAIO5i8Dl7xvr0rEoHSjvlLynbOtpdK1x0V75ZuXXA/g7rAAAAIBmBYXOvL/ry+uQYlVYX8sTgrgSb+QU2teqTAef5y7rF', 'android-emulator'),
('stamp-005-4', 'card-005', 4, 1749600404000, 'AAAAIGlvGzQNpv0KQXtUxz/nHh2gb1k2NRT3uz5mSPgW/07fAAAAIGbMpDHW1TqPwi6kmCJ5hEm9zVw7O2815Kcg9Ef9H1VN', 'AAAAIPhsoo0XcAlPLHlpJqGlAMzIjVI3ylsIWHoD7N9cos3TAAAAINwmoNkRmP/TpuSwJ/rAUvBhCGwpdx4FFe6Kl7+tGid3', 'android-emulator'),
('stamp-005-5', 'card-005', 5, 1749600405000, 'AAAAIKMa0oc259X/FXBAKXMSEldVP7vd1OQZjTzVcgDR1ppVAAAAIC+hO9I8+lGD0y8Do7lvYobPjD7mW0VgTpk72OvhTP/n', 'AAAAIGlvGzQNpv0KQXtUxz/nHh2gb1k2NRT3uz5mSPgW/07fAAAAIGbMpDHW1TqPwi6kmCJ5hEm9zVw7O2815Kcg9Ef9H1VN', 'android-emulator'),
('stamp-005-6', 'card-005', 6, 1749600406000, 'AAAAINdHLTnK+U9YmRTO0GlvhoSgh4Fv4sjCZZIvDDZN2/0eAAAAICnWOAFktVCKrIJxIgIha5P79XLJrD7J7S/mB48XthND', 'AAAAIKMa0oc259X/FXBAKXMSEldVP7vd1OQZjTzVcgDR1ppVAAAAIC+hO9I8+lGD0y8Do7lvYobPjD7mW0VgTpk72OvhTP/n', 'android-emulator'),
('stamp-005-7', 'card-005', 7, 1749600407000, 'AAAAIMOfn6JF10pPfKU5iFiVGeAfkT77ZPrFYMAwtGCJKIKxAAAAINUDPiHNTnchV+TYRssbc76qD6U7PsW/Be1ZFzAXFCJC', 'AAAAINdHLTnK+U9YmRTO0GlvhoSgh4Fv4sjCZZIvDDZN2/0eAAAAICnWOAFktVCKrIJxIgIha5P79XLJrD7J7S/mB48XthND', 'android-emulator'),
('stamp-005-8', 'card-005', 8, 1749600408000, 'AAAAIITu47LRoeN3AHALPma560OVikU+QrOaOt2RQC0OBr6mAAAAIKugEX4buLhW4fnXAskJSRbyoJB1+wcY5u06aRmLaTOw', 'AAAAIMOfn6JF10pPfKU5iFiVGeAfkT77ZPrFYMAwtGCJKIKxAAAAINUDPiHNTnchV+TYRssbc76qD6U7PsW/Be1ZFzAXFCJC', 'android-emulator'),
('stamp-006-1', 'card-006', 1, 1749600501000, 'sig-test', NULL, 'android-emulator'),
('stamp-006-2', 'card-006', 2, 1749600502000, 'sig-test', 'hash-006-1', 'android-emulator'),
('stamp-006-3', 'card-006', 3, 1749600503000, 'sig-test', 'hash-006-2', 'android-emulator');

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

echo "Pushing seeded database back to device..."
# run-as has no stdin-write primitive, so stage via /data/local/tmp (always
# adb-writable) and have the app's own run-as shell copy it into place -
# the standard no-root pattern for writing into an app's private storage.
adb "${ADB_ARGS[@]}" push "$DB_LOCAL" /data/local/tmp/seed_loyalty_cards.db >/dev/null
adb "${ADB_ARGS[@]}" shell run-as "$PACKAGE" cp /data/local/tmp/seed_loyalty_cards.db "databases/$DB_NAME"
adb "${ADB_ARGS[@]}" shell rm -f /data/local/tmp/seed_loyalty_cards.db
adb "${ADB_ARGS[@]}" shell run-as "$PACKAGE" rm -f "databases/$DB_NAME-journal" "databases/$DB_NAME-wal" "databases/$DB_NAME-shm" 2>/dev/null || true

echo ""
echo "Seed complete on device."
echo "Force-stop and relaunch LoyaltyCards on the device to see seeded cards:"
echo "  adb shell am force-stop $PACKAGE"
