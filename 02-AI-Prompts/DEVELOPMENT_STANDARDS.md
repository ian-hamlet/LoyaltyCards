# LoyaltyCards Development Standards

**Created:** April 12, 2026  
**Status:** Active Project Standards  
**Purpose:** Core principles and conventions that MUST be followed by all developers and AI assistants

---

## 🚨 Critical: Version Control

### Always Update Version Number

**MANDATORY:** Update `03-Source/shared/lib/version.dart` for EVERY source code change.

**Location:** `03-Source/shared/lib/version.dart`

**Format:**
```dart
/// Build XX Changes:
/// - Feature description
/// - Bug fixes
/// - Breaking changes
/// - etc.

const String appVersion = 'v{major}.{minor}.{patch} (Build {build})';
```

**Workflow:**
1. Make code changes
2. ⚠️ **Update version.dart** (increment build number)
3. Document what changed in comment
4. Test locally
5. Commit with build number in message
6. Deploy

**Why This Matters:**
- Confirms new code deployed to devices
- Essential for TestFlight/pilot testing
- Tracks feature history
- Debugs "which version has this bug?"

---

## 📁 Project Structure

### Source Code Organization

```
03-Source/
├── shared/              # Shared models, constants, utilities
│   ├── lib/models/     # Business, Card, QR tokens, etc.
│   ├── lib/constants/  # App-wide constants
│   └── lib/version.dart # ⚠️ VERSION FILE
├── customer_app/       # Customer-facing app
├── supplier_app/       # Business owner app
└── [other apps]
```

### Planning & Documentation

```
00-Planning/            # Project plans, requirements, progress
01-Design/              # Architecture decisions
02-AI-Prompts/          # THIS FILE - AI context & standards
07-Documentation/       # User guides, setup instructions
```

---

## 🏗️ Architecture Principles

### Current Architecture (Build 47)

1. **P2P (Peer-to-Peer)**: No central server
2. **Local-First**: SQLite databases, offline-capable
3. **QR Code Exchange**: All communication via QR codes
4. **Cryptographic Validation**: RSA signatures for security
5. **Dual-Mode Support** (NEW in Build 47):
   - **Simple Mode**: Trust-based, fast (coffee shops)
   - **Secure Mode**: Crypto validation (high-value rewards)

### Technology Stack

- **Framework**: Flutter (cross-platform)
- **Database**: SQLite via sqflite package
- **Crypto**: pointycastle for RSA
- **State**: Provider pattern
- **QR**: qr_flutter + mobile_scanner

---

## 📊 Database Conventions

### Schema Version Management

- **Current Version**: 4 (as of Build 47)
- **Location**: `shared/lib/constants/constants.dart`
- **Migration**: Always provide migration path in `_onUpgrade()`

### Field Naming

- **Database columns**: `snake_case` (e.g., `business_id`, `created_at`)
- **Dart models**: `camelCase` (e.g., `businessId`, `createdAt`)
- **JSON serialization**: Use `toJson()` / `fromJson()` methods

### Always Include

- `id TEXT PRIMARY KEY` (UUID)
- `created_at INTEGER` (millisecondsSinceEpoch)
- `updated_at INTEGER` (for mutable records)

---

## 🎨 UX/UI Standards (Build 46+)

### Design System

- **Typography**: `AppTypography` class (11pt-28pt scale)
- **Spacing**: `AppSpacing` class (xs=4 to xxl=48)
- **Colors**: Brand colors in Business model
- **Icons**: Logo index (0-99) for business branding

### User Feedback

- **Always use**: `AppFeedback.show*()` methods
- **Never use**: Raw `SnackBar` widgets
- **Categories**: success, error, info, warning
- **Haptics**: Add haptic feedback to all confirmations

### Dialogs

- **Use `actions` parameter**: Keeps buttons visible (iOS/Android)
- **Apply AppSpacing**: Consistent padding
- **Use AppTypography**: Consistent text styles
- **Add haptics**: For destructive actions

---

## 🔐 Security Standards

### Private Keys

- **Storage**: NEVER store in database
- **In-memory only**: Loaded from secure storage
- **Exclusion**: Use `toJson(includePrivateKey: false)`

### Crypto Signatures

- **Algorithm**: RSA-2048
- **Hash**: SHA-256
- **Validation**: Always verify signatures before accepting QR data

### QR Token Expiration

- **Default**: 5 minutes
- **Configurable**: Via `qrCodeExpirationMinutes` constant

---

## 🧪 Testing Standards

### Before Device Testing

1. Run `flutter analyze` - zero warnings
2. Run `flutter test` - all tests pass
3. Build both apps successfully
4. Check version.dart updated

### Device Testing Checklist

See: `00-Planning/BUILD_46_TESTING_CHECKLIST.md`

---

## 📝 Code Style

### Dart Conventions

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `analysis_options.yaml` in each app
- Document public APIs with `///` comments
- Use `const` constructors where possible

### Naming

- **Classes**: `PascalCase`
- **Functions/Variables**: `camelCase`
- **Constants**: `camelCase` with `const`
- **Private**: `_leadingUnderscore`

### Imports

- Dart SDK first
- Flutter packages second
- Third-party packages third
- Local imports last
- Alphabetical within each group

---

## 🚀 Build & Deployment

### Build Numbers

- **Customer App**: Mirror shared version
- **Supplier App**: Mirror shared version
- **Shared Package**: Source of truth

### Git Workflow

- **Branch**: Feature branches for experiments
- **Commit**: Include build number in message
- **Example**: `"Build 47: Add dual-mode operation support"`

### TestFlight

- Always include release notes with build number
- Reference `version.dart` changelog
- Test on physical devices before uploading

---

## 💡 Decision Making

### When to Increment Build

- ✅ Any source code change
- ✅ Model updates
- ✅ Database schema changes
- ✅ UI/UX improvements
- ✅ Bug fixes
- ❌ Documentation-only changes (optional)
- ❌ README updates (optional)

### When to Increment Version

- **Patch (0.1.X)**: Bug fixes, minor improvements
- **Minor (0.X.0)**: New features, significant changes
- **Major (X.0.0)**: Breaking changes, major milestones

---

## 🎯 Current Status (Build 47)

**Phase Completion**: 75% (5 of 9 phases)

**Ready For**: Device testing, TestFlight pilot

**Next Milestone**: Implement dual-mode UI and testing

---

## 📚 Reference Documents

- **Project Plan**: `00-Planning/PROJECT_DEVELOPMENT_PLAN.md`
- **Current Status**: `00-Planning/CURRENT_STATUS.md`
- **Quick Reference**: `00-Planning/QUICK_REFERENCE.md`
- **Requirements**: `00-Planning/Requirements/`
- **Architecture**: `01-Design/Architecture/`

---

**Last Updated**: April 12, 2026 (Build 47)  
**Maintained By**: Project Team + AI Assistants  
**Review Frequency**: Each major build milestone
