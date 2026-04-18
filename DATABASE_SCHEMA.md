# Database Schema Documentation

**LoyaltyCards v0.2.0**  
**Customer App Database Version:** 6  
**Supplier App Database Version:** 4  
**Last Updated:** April 18, 2026

---

## Overview

LoyaltyCards uses SQLite for local data storage on both customer and supplier devices. Each app maintains its own independent database with no backend synchronization. This document describes the complete schema for both applications.

---

## Customer App Database

**Database Name:** `loyalty_cards.db`  
**Current Version:** 6  
**Foreign Keys:** Enabled  
**Platform:** iOS (via sqflite package)

### Tables

#### 1. `cards`

Stores loyalty cards received from suppliers.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique card identifier (UUID) |
| `business_id` | TEXT | NOT NULL | Supplier's business identifier |
| `business_name` | TEXT | NOT NULL | Display name of the business |
| `business_public_key` | TEXT | NOT NULL | Supplier's public key (ECDSA P-256, base64) |
| `stamps_required` | INTEGER | NOT NULL | Number of stamps needed for redemption |
| `stamps_collected` | INTEGER | NOT NULL | Current stamp count on this card |
| `brand_color` | TEXT | NOT NULL | Hex color code for card branding |
| `logo_index` | INTEGER | NOT NULL, DEFAULT 0 | Icon index for card visual |
| `mode` | TEXT | NOT NULL, DEFAULT 'secure' | Operation mode: 'simple' or 'secure' |
| `created_at` | INTEGER | NOT NULL | Unix timestamp (milliseconds since epoch) |
| `updated_at` | INTEGER | NOT NULL | Unix timestamp (milliseconds since epoch) |
| `is_redeemed` | INTEGER | NOT NULL, DEFAULT 0 | Redemption status (0 = active, 1 = redeemed) |
| `redeemed_at` | INTEGER | NULL | Unix timestamp of redemption |
| `device_id` | TEXT | NULL | Device identifier where card was issued (v6+) |

**Indexes:**
- None on this table (primary key index automatically created)

**Notes:**
- `device_id` added in v6 for multi-device duplication detection (V-005)
- `mode` determines cryptographic validation requirements
- `is_redeemed` is boolean stored as INTEGER (SQLite convention)

---

#### 2. `stamps`

Stores individual stamps collected on each card.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique stamp identifier (UUID from QR token) |
| `card_id` | TEXT | NOT NULL, FOREIGN KEY | References `cards.id` |
| `stamp_number` | INTEGER | NOT NULL | Sequential stamp number (1-based) |
| `timestamp` | INTEGER | NOT NULL | Unix timestamp when stamp was issued |
| `signature` | TEXT | NOT NULL | ECDSA signature of stamp data (base64) |
| `previous_hash` | TEXT | NULL | SHA-256 hash of previous stamp (chain integrity) |
| `device_id` | TEXT | NULL | Device identifier where stamp was issued (v6+) |

**Indexes:**
- `idx_stamps_card_id` ON `stamps (card_id)` - For fast card-based queries

**Foreign Keys:**
- `card_id` REFERENCES `cards (id)` ON DELETE CASCADE

**Notes:**
- `previous_hash` creates a cryptographic hash chain for tamper detection
- First stamp on card has `previous_hash = NULL`
- `device_id` added in v6 for tracking stamp origin device

---

#### 3. `transactions`

Audit log of all card-related activities (issuance, redemption).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique transaction identifier (UUID) |
| `card_id` | TEXT | NOT NULL, FOREIGN KEY | References `cards.id` |
| `type` | TEXT | NOT NULL | Transaction type: 'issue', 'stamp', 'redeem' |
| `timestamp` | INTEGER | NOT NULL | Unix timestamp of transaction |
| `business_name` | TEXT | NOT NULL | Business name (denormalized for history) |
| `details` | TEXT | NULL | Additional transaction details (JSON or text) |

**Indexes:**
- `idx_transactions_card_id` ON `transactions (card_id)` - For card history queries

**Foreign Keys:**
- `card_id` REFERENCES `cards (id)` ON DELETE CASCADE

**Notes:**
- Provides user-visible transaction history
- `business_name` denormalized to preserve history even if card deleted

---

#### 4. `app_settings`

Key-value store for application preferences and state.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `key` | TEXT | PRIMARY KEY | Setting identifier |
| `value` | TEXT | NOT NULL | Setting value (string representation) |

**Indexes:**
- None (primary key index only)

**Notes:**
- Used for user preferences, feature flags, cached state
- Values stored as strings, parsed by application code

---

### Migration History

#### v1 → v2
- **Added:** `is_redeemed` column to `cards` table
- **Purpose:** Track redemption status for completed cards

#### v2 → v3
- **Added:** `logo_index` column to `cards` table
- **Purpose:** Support custom business icons/logos

#### v3 → v4
- **Added:** `mode` column to `cards` table
- **Purpose:** Support dual operation modes (Simple vs. Secure)

#### v4 → v5
- **Added:** `redeemed_at` column to `cards` table
- **Purpose:** Track exact timestamp of card redemption

#### v5 → v6 (Build 21 - Current)
- **Added:** `device_id` column to `cards` table
- **Added:** `device_id` column to `stamps` table
- **Purpose:** Multi-device duplication detection (V-005 security fix)
- **Population:** NULL for existing records, captured for new operations

---

## Supplier App Database

**Database Name:** `loyalty_cards_supplier.db`  
**Current Version:** 4  
**Foreign Keys:** Enabled  
**Platform:** iOS (via sqflite package)

### Tables

#### 1. `business`

Stores supplier business configuration (single record).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Unique business identifier (UUID) |
| `name` | TEXT | NOT NULL | Business display name |
| `public_key` | TEXT | NOT NULL | ECDSA P-256 public key (base64 encoded) |
| `stamps_required` | INTEGER | NOT NULL | Default stamps needed for redemption |
| `brand_color` | TEXT | NOT NULL | Hex color code for branding |
| `logo_index` | INTEGER | NOT NULL, DEFAULT 0 | Icon index for business visual |
| `mode` | TEXT | NOT NULL, DEFAULT 'secure' | Operation mode: 'simple' or 'secure' |
| `created_at` | INTEGER | NOT NULL | Unix timestamp of business creation |

**Indexes:**
- None (single record table, primary key only)

**Notes:**
- Typically contains exactly one record (the configured business)
- Private key stored separately in iOS Keychain via `flutter_secure_storage`
- Multi-device support: Same business config cloned across devices

---

#### 2. `issued_cards`

Tracks cards issued to customers (for analytics).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Card identifier (matches customer's card ID) |
| `business_id` | TEXT | NOT NULL, FOREIGN KEY | References `business.id` |
| `issued_at` | INTEGER | NOT NULL | Unix timestamp when card was issued |

**Indexes:**
- `idx_issued_cards_business` ON `issued_cards (business_id)`

**Foreign Keys:**
- `business_id` REFERENCES `business (id)` ON DELETE CASCADE

**Notes:**
- Optional analytics feature
- P2P architecture limitation: No ongoing sync with customer device

---

#### 3. `stamp_history`

Tracks individual stamps issued to customers (for analytics).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Stamp identifier (UUID) |
| `card_id` | TEXT | NOT NULL | Customer's card ID |
| `stamp_number` | INTEGER | NOT NULL | Stamp number issued (1-based) |
| `issued_at` | INTEGER | NOT NULL | Unix timestamp when stamp was issued |
| `business_id` | TEXT | NOT NULL, FOREIGN KEY | References `business.id` |

**Indexes:**
- `idx_stamp_history_business` ON `stamp_history (business_id)`

**Foreign Keys:**
- `business_id` REFERENCES `business (id)` ON DELETE CASCADE

**Notes:**
- Enables supplier analytics (stamps per day, popular times, etc.)
- No foreign key to `issued_cards` (customer may scan without issued record)

---

#### 4. `redemptions`

Tracks card redemptions (for analytics and fraud detection).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Redemption transaction identifier (UUID) |
| `card_id` | TEXT | NOT NULL | Customer's card ID |
| `stamps_redeemed` | INTEGER | NOT NULL | Number of stamps on redeemed card |
| `redeemed_at` | INTEGER | NOT NULL | Unix timestamp of redemption |
| `business_id` | TEXT | NOT NULL, FOREIGN KEY | References `business.id` |

**Indexes:**
- `idx_redemptions_business` ON `redemptions (business_id)`

**Foreign Keys:**
- `business_id` REFERENCES `business (id)` ON DELETE CASCADE

**Notes:**
- Added in v2 migration
- Tracks redemption completions for business analytics

---

#### 5. `app_settings`

Key-value store for supplier app preferences.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `key` | TEXT | PRIMARY KEY | Setting identifier |
| `value` | TEXT | NOT NULL | Setting value (string representation) |

**Indexes:**
- None (primary key index only)

**Notes:**
- Stores preferences, device configuration, feature flags

---

### Migration History

#### v1 → v2
- **Added:** `redemptions` table with index
- **Purpose:** Track card redemptions for analytics

#### v2 → v3
- **Added:** `logo_index` column to `business` table
- **Purpose:** Support custom business icons

#### v3 → v4 (Current)
- **Added:** `mode` column to `business` table
- **Purpose:** Support dual operation modes (Simple vs. Secure)

---

## Data Retention Policy

### Customer App
- **Active Cards:** Retained indefinitely
- **Redeemed Cards:** Retained for transaction history (user can manually delete)
- **Stamps:** Retained with card (CASCADE delete when card deleted)
- **Transactions:** Retained with card (CASCADE delete when card deleted)
- **Settings:** Retained until app uninstall

### Supplier App
- **Business Config:** Retained indefinitely (single record)
- **Analytics Data:** Retained indefinitely (issued_cards, stamp_history, redemptions)
- **Backup Strategy:** Manual export via Recovery Backup QR code

---

## Performance Considerations

### Indexes
All critical query paths have indexes to ensure fast operation:
- `idx_stamps_card_id` - Fast stamp lookup by card
- `idx_transactions_card_id` - Fast transaction history
- `idx_issued_cards_business` - Fast supplier analytics
- `idx_stamp_history_business` - Fast supplier analytics
- `idx_redemptions_business` - Fast redemption tracking

### Foreign Keys
- Foreign keys enforced via `PRAGMA foreign_keys = ON`
- CASCADE deletes ensure referential integrity
- Prevents orphaned records in child tables

### Query Optimization
- Use prepared statements (handled by sqflite)
- Batch operations where possible
- Minimize UI-blocking database calls (use async/await)

---

## Backup and Recovery

### Customer App
- **No cloud backup** (privacy-first design)
- **Local device backup** via iOS backup (encrypted if user enabled)
- **Data migration** handled automatically during app updates
- **Manual reset** available via Settings → Clear All Data

### Supplier App
- **Critical Data:** Private keys stored in iOS Keychain (backed up)
- **Recovery QR:** Manual export creates portable backup of business config
- **Clone Device:** Manual export for multi-device configuration
- **Database backup** via iOS device backup

---

## Security Considerations

### Encryption
- **At Rest:** SQLite files not separately encrypted (relies on iOS device encryption)
- **In Transit:** All data transfer via QR codes (P2P, no network transmission)
- **Private Keys:** Stored in iOS Keychain (hardware-backed when available)

### Data Validation
- All foreign key constraints enforced
- Application-level validation before database writes
- Cryptographic signature validation (Secure Mode)
- Hash chain integrity checks

### Privacy
- No user identification data stored
- No personal information collected
- Device ID: iOS identifierForVendor (app-scoped, ephemeral)
- GDPR compliant data minimization

---

## Testing Data Generation

### Reset Commands
```dart
// Customer App - Complete database reset
await DatabaseHelper().deleteDatabase();

// Customer App - Clear data (keep schema)
await DatabaseHelper().clearAllData();

// Supplier App - Complete database reset
await SupplierDatabaseHelper().deleteDatabase();

// Supplier App - Clear data (keep schema)
await SupplierDatabaseHelper().clearAllData();
```

---

**References:**
- [Customer Database Helper](03-Source/customer_app/lib/services/database_helper.dart)
- [Supplier Database Helper](03-Source/supplier_app/lib/services/supplier_database_helper.dart)
- [Shared Constants](03-Source/shared/lib/constants/constants.dart)

**Maintained by:** Development Team  
**Last Updated:** April 18, 2026
