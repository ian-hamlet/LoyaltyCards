# Simulator Database Seeding Guide

This guide captures the repeatable process for seeding screenshot-ready customer data into iOS simulators.

**Need this on a physical device instead?** Use `scripts/seed_customer_device_db.sh` (added 2026-07-20) — same seed data, but pulls/pushes the database via `xcrun devicectl device copy` (app-data-container file access) instead of `simctl get_app_container`, since simulator tooling has no equivalent on real hardware. Usage: `./scripts/seed_customer_device_db.sh "Ians iPhone"` (device name or UDID — see `xcrun devicectl list devices`). Same one-time-setup requirement: the app must have been installed and launched at least once so its database exists. **Warning:** this overwrites whatever is currently in the app on that device; the script keeps a local timestamped backup of the pre-seed database (not written back to the device) but there's no on-device undo.

## Purpose

Use this when you need realistic Wallet screenshots quickly without manually creating cards and stamps.

- Seeds customer app SQLite DB with multiple cards
- Mixes progress states (0, partial, near-complete, complete)
- Adds transaction history entries for timeline screenshots

---

## Script Location

- `scripts/seed_customer_simulator_db.sh` (simulator)
- `scripts/seed_customer_device_db.sh` (physical device)

Both scripts are intentionally kept in-repo for reuse in future screenshot cycles.

---

## Prerequisites

1. Xcode + Simulator installed
2. `xcrun` available
3. `sqlite3` available
4. Customer app installed and opened at least once on target simulator

Check tools:

```bash
command -v xcrun
command -v sqlite3
```

---

## Supported Inputs

The script accepts either:

1. Simulator UDID
2. Exact simulator name

If no argument is passed, it defaults to `iPhone 14 Pro`.

Examples:

```bash
./scripts/seed_customer_simulator_db.sh
./scripts/seed_customer_simulator_db.sh DA697758-8E9F-4217-A5BB-A977A94264C2
./scripts/seed_customer_simulator_db.sh "iPhone SE (3rd generation)"
```

---

## One-Time Setup Per Simulator

Do this once for each target simulator (for example iPhone 14 Pro and iPhone SE):

1. Boot simulator
2. Run customer app once (creates app data container and SQLite DB)
3. Stop app

Boot examples:

```bash
xcrun simctl boot "iPhone 14 Pro"
xcrun simctl boot "iPhone SE (3rd generation)"
open -a Simulator
```

Run app once:

```bash
cd source/customer_app
flutter run -d "iPhone 14 Pro" --no-resident
flutter run -d "iPhone SE (3rd generation)" --no-resident
```

---

## Seed Both Screenshot Simulators

From repo root:

```bash
./scripts/seed_customer_simulator_db.sh "iPhone 14 Pro"
./scripts/seed_customer_simulator_db.sh "iPhone SE (3rd generation)"
```

What the script does:

1. Resolves simulator name/UDID
2. Locates customer app container (`com.ianhamlet.loyaltycards.customerApp`)
3. Backs up current DB file with timestamp suffix
4. Clears existing `cards`, `stamps`, `transactions`
5. Inserts seeded screenshot data

---

## Verify Seeded Data

After running script:

1. Relaunch customer app in simulator
2. Confirm wallet has multiple cards in mixed states
3. Open a card detail screen and history screen

If data does not appear, force-close app and relaunch.

---

## Troubleshooting

### Could not locate app container

Cause: app not installed/launched on that simulator yet.

Fix:

1. Run customer app once on that simulator
2. Rerun seed script

### Database not found

Cause: sqflite DB not created yet.

Fix:

1. Launch customer app fully once
2. Return to wallet screen
3. Quit app and rerun script

### sqlite3 not found

Install:

```bash
brew install sqlite
```

---

## Notes

- This is screenshot seeding, not production migration.
- Supplier secure operations rely on keychain material and are not fully represented by SQLite-only seeding.
- Script currently targets customer DB (`loyalty_cards.db`) only.
