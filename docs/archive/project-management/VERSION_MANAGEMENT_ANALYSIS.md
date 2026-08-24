# Version Management Analysis - TEST-001

**Date:** April 15, 2026  
**Status:** Analysis complete, ready for fix implementation  
**Defect:** TEST-001 - Inconsistent Version Numbers Across Files

---

## 📍 Current State - Where Version Info is Stored

### 1. **Display Version (User-Facing)**
**File:** `source/shared/lib/version.dart`
```dart
const String appVersion = 'v0.2.0 (Build 0)';
```

**Current Value:** `v0.2.0 (Build 0)` ⚠️ **INCORRECT - Should be Build 4**

**Used In:**
- Customer App:
  - `main.dart` line 8 - Console print on startup
  - `customer_home.dart` line 143 - App bar title: "My Loyalty Cards v0.2.0 (Build 0)"
  - `customer_settings.dart` line 273 - About section subtitle
  
- Supplier App:
  - `main.dart` line 8 - Console print on startup
  - `supplier_home.dart` line 86 - App bar title: "{Business Name} v0.2.0 (Build 0)"
  - `supplier_settings.dart` line 172 - About section subtitle

**Import Statement:** Apps import from shared package:
```dart
import 'package:shared/shared.dart'; // Exports appVersion constant
```

---

### 2. **iOS Build Version (App Store/TestFlight)**
**Files:** 
- `source/customer_app/pubspec.yaml`
- `source/supplier_app/pubspec.yaml`

**Current Values:** Both set to:
```yaml
version: 0.2.0+4
```
- `0.2.0` = Version name (displayed as "Version 0.2.0" in App Store)
- `+4` = Build number (displayed as "Build 4" in TestFlight)

**Format:** `{major}.{minor}.{patch}+{buildNumber}`

**How Flutter Uses This:**
When you run `flutter build ios`, Flutter generates:
- `ios/Flutter/Generated.xcconfig` (auto-generated, git-ignored)
  ```
  FLUTTER_BUILD_NAME=0.2.0
  FLUTTER_BUILD_NUMBER=4
  ```

These variables are then injected into `Info.plist`:
- `CFBundleShortVersionString` = `$(FLUTTER_BUILD_NAME)` → "0.2.0"
- `CFBundleVersion` = `$(FLUTTER_BUILD_NUMBER)` → "4"

---

### 3. **Auto-Generated Files (Git-Ignored)**
**Files:**
- `source/customer_app/ios/Flutter/Generated.xcconfig`
- `source/supplier_app/ios/Flutter/Generated.xcconfig`

**Current Values:**
```
FLUTTER_BUILD_NAME=0.2.0
FLUTTER_BUILD_NUMBER=4
```

**Status:** ✅ These are CORRECT (auto-generated from pubspec.yaml)

**Note:** These files are in `.gitignore` and regenerated on each `flutter build`

---

## ⚠️ The Problem - Current Inconsistency

| Location | Version Display | Build Number | Status |
|----------|----------------|--------------|---------|
| `shared/lib/version.dart` | v0.2.0 | Build 0 | ❌ WRONG |
| `customer_app/pubspec.yaml` | 0.2.0 | 4 | ✅ CORRECT |
| `supplier_app/pubspec.yaml` | 0.2.0 | 4 | ✅ CORRECT |
| Generated.xcconfig (both) | 0.2.0 | 4 | ✅ CORRECT |
| App Store Connect | 0.2.0 | 4 | ✅ CORRECT |
| **Displayed to Users** | **v0.2.0 (Build 0)** | **Build 0** | **❌ WRONG** |

**Impact:**
- Users see "Build 0" in the app
- TestFlight shows "Build 4"
- Impossible to verify which version is actually deployed
- Debugging becomes "Is this actually Build 4 or still Build 0?"

---

## 🔧 Solution Options

### Option 1: Manual Three-File Update (Current Process)
**Pros:** Simple, no code changes
**Cons:** Error-prone, forgetful, already failed

**Process:**
1. Edit `shared/lib/version.dart` → Change build number
2. Edit `customer_app/pubspec.yaml` → Change version: X.X.X+Y
3. Edit `supplier_app/pubspec.yaml` → Change version: X.X.X+Y
4. Commit all three files

**Problem:** We've already demonstrated this doesn't work reliably

---

### Option 2: ⭐ Single Source of Truth in pubspec.yaml (RECOMMENDED)
**Pros:** Simple, leverages Flutter's native system, minimal code
**Cons:** Requires reading package_info_plus at runtime

**Implementation:**

1. **Add dependency to both apps:**
   ```yaml
   dependencies:
     package_info_plus: ^8.0.0
   ```

2. **Update version.dart to read from package info:**
   ```dart
   // Before (static):
   const String appVersion = 'v0.2.0 (Build 0)';
   
   // After (async):
   import 'package:package_info_plus/package_info_plus.dart';
   
   Future<String> getAppVersion() async {
     final info = await PackageInfo.fromPlatform();
     return 'v${info.version} (Build ${info.buildNumber})';
   }
   ```

3. **Update UI code to use FutureBuilder:**
   ```dart
   // In customer_home.dart, supplier_home.dart, settings screens:
   FutureBuilder<String>(
     future: getAppVersion(),
     builder: (context, snapshot) {
       return Text(snapshot.data ?? 'Loading...');
     },
   )
   ```

4. **Single update location:**
   - Only edit `pubspec.yaml` files (customer & supplier)
   - App auto-reads correct version at runtime
   - No manual sync needed

**Effort:** 2-3 hours (modify version.dart, update 6 UI locations)

---

### Option 3: Build Script Automation
**Pros:** Bulletproof, single command updates everything
**Cons:** More complex, requires shell script or Dart script

**Implementation:**

Create `tools/update_version.sh`:
```bash
#!/bin/bash
VERSION=$1
BUILD=$2

# Update shared/lib/version.dart
echo "const String appVersion = 'v$VERSION (Build $BUILD)';" > source/shared/lib/version.dart

# Update customer_app/pubspec.yaml
sed -i '' "s/^version: .*/version: $VERSION+$BUILD/" source/customer_app/pubspec.yaml

# Update supplier_app/pubspec.yaml
sed -i '' "s/^version: .*/version: $VERSION+$BUILD/" source/supplier_app/pubspec.yaml

echo "✅ Updated to v$VERSION (Build $BUILD)"
```

**Usage:**
```bash
./tools/update_version.sh 0.2.1 5
```

**Effort:** 1 hour to create, 5 seconds per use

---

### Option 4: Pre-commit Git Hook
**Pros:** Validates versions match before commit
**Cons:** Doesn't auto-fix, just warns

**Implementation:**

Create `.git/hooks/pre-commit`:
```bash
#!/bin/bash
VERSION_DART=$(grep "appVersion = " source/shared/lib/version.dart | grep -o "Build [0-9]*" | grep -o "[0-9]*")
CUSTOMER_BUILD=$(grep "^version:" source/customer_app/pubspec.yaml | grep -o "+[0-9]*" | grep -o "[0-9]*")
SUPPLIER_BUILD=$(grep "^version:" source/supplier_app/pubspec.yaml | grep -o "+[0-9]*" | grep -o "[0-9]*")

if [ "$VERSION_DART" != "$CUSTOMER_BUILD" ] || [ "$VERSION_DART" != "$SUPPLIER_BUILD" ]; then
  echo "❌ Version mismatch detected!"
  echo "  version.dart: Build $VERSION_DART"
  echo "  customer_app: Build $CUSTOMER_BUILD"
  echo "  supplier_app: Build $SUPPLIER_BUILD"
  exit 1
fi
```

**Effort:** 30 minutes

---

## 📋 Recommended Implementation Plan (Option 2)

### Phase 1: Immediate Fix (Build 5)
**Goal:** Synchronize all version numbers to match reality

**Steps:**
1. Update `shared/lib/version.dart`:
   ```dart
   const String appVersion = 'v0.2.0 (Build 4)';
   ```

2. Verify `pubspec.yaml` files already show:
   ```yaml
   version: 0.2.0+4
   ```

3. Commit as "fix: TEST-001 - Sync version.dart to Build 4"

4. Test: Launch apps, verify "Build 4" displays in About screens

**Effort:** 5 minutes

---

### Phase 2: Future-Proof Solution (Build 6-10)
**Goal:** Single source of truth using package_info_plus

**Steps:**

1. **Add dependency (both apps):**
   ```bash
   cd source/customer_app
   flutter pub add package_info_plus
   
   cd ../supplier_app
   flutter pub add package_info_plus
   ```

2. **Update `shared/lib/version.dart`:**
   ```dart
   import 'package:package_info_plus/package_info_plus.dart';
   
   /// Get app version from package info at runtime
   /// This ensures version displayed matches the actual build version
   Future<String> getAppVersion() async {
     final info = await PackageInfo.fromPlatform();
     return 'v${info.version} (Build ${info.buildNumber})';
   }
   
   /// Synchronous fallback for contexts that can't use async
   /// NOTE: This will be removed in future, migrate to getAppVersion()
   @Deprecated('Use getAppVersion() instead')
   const String appVersion = 'v0.2.0 (Build 4)';
   ```

3. **Update customer_home.dart:**
   ```dart
   // Old:
   title: Text('My Loyalty Cards $appVersion'),
   
   // New:
   title: FutureBuilder<String>(
     future: getAppVersion(),
     builder: (context, snapshot) {
       return Text('My Loyalty Cards ${snapshot.data ?? ''}');
     },
   ),
   ```

4. **Update supplier_home.dart:**
   ```dart
   // Old:
   title: Text('${_business!.name} $appVersion'),
   
   // New:
   title: FutureBuilder<String>(
     future: getAppVersion(),
     builder: (context, snapshot) {
       return Text('${_business!.name} ${snapshot.data ?? ''}');
     },
   ),
   ```

5. **Update settings screens (both apps):**
   ```dart
   // Old:
   ListTile(
     title: Text('Version'),
     subtitle: Text(appVersion),
   )
   
   // New:
   FutureBuilder<String>(
     future: getAppVersion(),
     builder: (context, snapshot) {
       return ListTile(
         title: Text('Version'),
         subtitle: Text(snapshot.data ?? 'Loading...'),
       );
     },
   )
   ```

6. **Update main.dart (both apps):**
   ```dart
   // Old:
   print('Version: $appVersion');
   
   // New:
   getAppVersion().then((version) {
     print('Version: $version');
   });
   ```

7. **Test:**
   - Update `pubspec.yaml` to `version: 0.2.1+5`
   - Build apps
   - Launch and verify "v0.2.1 (Build 5)" displays everywhere
   - Verify it matches TestFlight/App Store Connect

**Effort:** 2-3 hours

---

### Phase 3: Optional Automation (Future)
**Goal:** Script to update version in one command

**Create:** `tools/update_version.sh` (Option 3 above)

**Usage:**
```bash
./tools/update_version.sh 0.3.0 10
# Updates both pubspec.yaml files automatically
```

**Effort:** 1 hour

---

## ✅ Testing Checklist (After Fix)

- [ ] Update both `pubspec.yaml` to same version (e.g., 0.2.1+5)
- [ ] Build both apps: `flutter build ipa --release`
- [ ] Check Generated.xcconfig shows correct build number
- [ ] Launch customer app
  - [ ] Home screen title shows correct version
  - [ ] Settings → About shows correct version
  - [ ] Console print shows correct version
- [ ] Launch supplier app
  - [ ] Home screen title shows correct version
  - [ ] Settings → About shows correct version
  - [ ] Console print shows correct version
- [ ] Upload to TestFlight
- [ ] Verify TestFlight shows correct version: "0.2.1 (5)"
- [ ] Install on device via TestFlight
- [ ] Open apps and verify version displayed matches TestFlight

---

## 🎯 Recommendation

**For Build 5 (Immediate):**
- Quick fix: Sync version.dart to Build 4 (5 minutes)

**For Build 6-10 (Proper Fix):**
- Implement Option 2 (package_info_plus) (2-3 hours)
- Single source of truth = pubspec.yaml
- UI auto-displays correct version
- No manual sync needed ever again

**For Future (Optional):**
- Add update script (Option 3) for convenience
- Add pre-commit hook (Option 4) for validation

---

## 📝 Current File Contents

### shared/lib/version.dart
```dart
const String appVersion = 'v0.2.0 (Build 0)';  // ❌ WRONG
```

### customer_app/pubspec.yaml
```yaml
version: 0.2.0+4  # ✅ CORRECT
```

### supplier_app/pubspec.yaml
```yaml
version: 0.2.0+4  # ✅ CORRECT
```

---

**Status:** Ready to implement Phase 1 (quick fix) immediately  
**Next:** Update version.dart to Build 4, then plan Phase 2 implementation
