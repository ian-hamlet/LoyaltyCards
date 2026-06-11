# Version Numbering Standard

**Created:** May 23, 2026  
**Status:** Active  
**Scope:** Both Customer App and Supplier App

---

## Versioning Scheme

LoyaltyCards uses **semantic versioning with build numbers**:

```
major.minor.patch+build
```

### Components

| Component | Meaning | Example | When to Change |
|-----------|---------|---------|-----------------|
| **major** | Breaking changes, major features | `0`, `1` | Major releases (e.g., production launch) |
| **minor** | New features, backward compatible | `0`, `1`, `2`, `3` | Feature releases, significant improvements |
| **patch** | Bug fixes, security patches | `0`, `1` | Patch releases |
| **build** | Internal build/iteration number | `+1`, `+2`, `+23` | Every TestFlight build, every App Store release |

### Examples

- `0.2.0+15` — Version 0.2.0, build 15 (pilot testing phase)
- `0.3.0+1` — Version 0.3.0, build 1 (current production)
- `1.0.0+1` — Version 1.0.0, build 1 (first public App Store release)
- `1.0.0+2` — Version 1.0.0, build 2 (hotfix for v1.0.0)

---

## Where Versions Appear

### Source Code (Always Update These)

| File | Format | Component | Example |
|------|--------|-----------|---------|
| `source/customer_app/pubspec.yaml` | `version: X.Y.Z+N` | Full version | `0.3.0+1` |
| `source/supplier_app/pubspec.yaml` | `version: X.Y.Z+N` | Full version | `0.3.0+1` |
| `source/shared/pubspec.yaml` | `version: X.Y.Z+N` | Full version | `0.3.0+1` |

**iOS Configuration (Auto-Updated)**
- `source/customer_app/ios/Runner/Info.plist` — Uses `$(FLUTTER_BUILD_NAME)` and `$(FLUTTER_BUILD_NUMBER)` from pubspec
- `source/supplier_app/ios/Runner/Info.plist` — Uses `$(FLUTTER_BUILD_NAME)` and `$(FLUTTER_BUILD_NUMBER)` from pubspec

**Android Configuration (Auto-Updated)**
- `source/customer_app/android/app/build.gradle.kts` — Uses Flutter's `versionCode` and `versionName`
- `source/supplier_app/android/app/build.gradle.kts` — Uses Flutter's `versionCode` and `versionName`

### Documentation (Update for Current Release Only)

| File | When to Update | Format | What NOT to Change |
|------|----------------|--------|-------------------|
| `README.md` | Every release | `v0.3.0+1` or `Status: v0.3.0+1` | N/A (no historical content) |
| `docs/meta/PROJECT_METADATA.md` | Every release | `v0.3.0+1 Production - Build 23 in TestFlight` | N/A (no historical content) |
| `docs/project-management/NEXT_ACTIONS.md` | Every release | Version references in current status | DO NOT change old phase completions |
| `docs/deployment/RELEASES.md` | Every release | Add new release section, update current status | DO NOT remove/edit historical releases |
| `docs/user/USER_GUIDE.md` | Every release | Update version in header | DO NOT touch historical notes |
| `docs/user/ABOUT_LOYALTYCARDS.md` | Every release | Update version number displayed to users | DO NOT change feature descriptions |

### Documentation (Never Update)

| File | Reason | Content Type |
|------|--------|--------------|
| `CHANGELOG.md` | Historical record | Keep all entries, add new entries at top |
| `source/shared/lib/version.dart` | Historical build notes | Keep all build entries, add new at bottom |
| `docs/quality/VULNERABILITIES.md` | Historical record | Keep version context, add new section if needed |
| `docs/quality/LESSONS_LEARNED.md` | Historical record | Archive at version boundary, start fresh |
| `docs/technical/PERFORMANCE_BASELINES.md` | Historical record | Keep baseline data, add new benchmarks when needed |
| All docs in `docs/project-management/Requirements/` | Requirements are static | Version context only, don't change requirement text |

---

## Update Procedure: Bumping the Version

### Step 1: Decide New Version

Determine what changed:
- **Bug fix only** → Increment patch (e.g., `0.3.0+1` → `0.3.1+1`)
- **New feature** → Increment minor, reset patch to 0 (e.g., `0.3.0+1` → `0.4.0+1`)
- **Major feature/breaking change** → Increment major, reset minor and patch (e.g., `0.3.0+1` → `1.0.0+1`)
- **New build of same version** → Increment build only (e.g., `0.3.0+1` → `0.3.0+2`)

### Step 2: Update Source Code

**Command line (from project root):**

```bash
# For version 0.3.0 (example)
# Edit customer_app/pubspec.yaml
version: 0.3.0+1

# Edit supplier_app/pubspec.yaml
version: 0.3.0+1

# Edit shared/pubspec.yaml
version: 0.3.0+1
```

All three must match.

**Verification:**
```bash
cd source/customer_app && grep "^version:" pubspec.yaml
cd source/supplier_app && grep "^version:" pubspec.yaml
cd source/shared && grep "^version:" pubspec.yaml
# All three should output: version: 0.3.0+1
```

### Step 3: Update Documentation

Update **only the current-release sections** in these files:

**README.md**
```markdown
**Status:** v1.0.0+6 - Release Candidate, App Store Submission Prep
**Current Version:** v1.0.0+6
```

**docs/meta/PROJECT_METADATA.md**
```markdown
- **Status**: v1.0.0+6 Release Candidate - Build 6
```

**docs/project-management/NEXT_ACTIONS.md**
```markdown
**Current Version:** v1.0.0+6
```

**docs/user/USER_GUIDE.md**
```markdown
**Version 0.3.0+1**
```

**docs/user/ABOUT_LOYALTYCARDS.md**
```markdown
**Version: Version 0.3.0+1**
```

### Step 4: Add Build Notes (Optional)

If this is a significant build, add entry to `source/shared/lib/version.dart`:

```dart
/// Build 24 Changes:
/// - Description of changes
/// - Another change
```

### Step 5: Add Release Entry (If Public Release)

If releasing to TestFlight or App Store, add entry to `CHANGELOG.md`:

```markdown
## [0.3.0] - 2026-05-23

### Added
- Feature 1
- Feature 2

### Fixed
- Bug fix 1
- Bug fix 2
```

---

## Checklist: Version Update

When bumping to a new version, use this checklist:

### Source Code Updates
- [ ] `source/customer_app/pubspec.yaml` — Updated version
- [ ] `source/supplier_app/pubspec.yaml` — Updated version
- [ ] `source/shared/pubspec.yaml` — Updated version
- [ ] All three versions match

### Documentation Updates
- [ ] `README.md` — Status line updated
- [ ] `docs/meta/PROJECT_METADATA.md` — Status updated
- [ ] `docs/project-management/NEXT_ACTIONS.md` — Current version updated
- [ ] `docs/user/USER_GUIDE.md` — Version header updated
- [ ] `docs/user/ABOUT_LOYALTYCARDS.md` — Version number updated

### Optional But Recommended
- [ ] `source/shared/lib/version.dart` — Build notes added (for significant builds)
- [ ] `CHANGELOG.md` — New release entry added (for public releases)
- [ ] `docs/deployment/RELEASES.md` — New release entry added (for App Store releases)

### Files to NOT Touch
- [ ] CHANGELOG.md (only add new entries, never edit old ones)
- [ ] Historical build notes in version.dart (only add new entries)
- [ ] Vulnerability docs
- [ ] Lessons learned docs
- [ ] Performance baselines
- [ ] Requirements documents

---

## Common Scenarios

### Scenario 1: Minor Bug Fix in Production

**Current:** v1.0.0+6 in TestFlight/App Store submission prep  
**Action:** New build for TestFlight

1. Update pubspec files: `0.3.0+2`
2. Update `README.md`: "v0.3.0+2"
3. Add entry to `CHANGELOG.md`

### Scenario 2: New Feature Ready for Release

**Current:** v1.0.0+6 in TestFlight/App Store submission prep  
**Action:** Feature release

1. Update pubspec files: `0.4.0+1`
2. Update all doc files (README, NEXT_ACTIONS, etc.) to `0.4.0+1`
3. Add build notes to `version.dart`
4. Add release entry to `CHANGELOG.md`

### Scenario 3: App Store First Release

**Current:** v1.0.0+6 on TestFlight  
**Action:** Launch to App Store

1. Decide if same version or bump (typically same): `1.0.0+1`
2. Update pubspec files: `1.0.0+1`
3. Update all doc files
4. Add release entry to `docs/deployment/RELEASES.md`
5. Add entry to `CHANGELOG.md`

### Scenario 4: App Store Hotfix

**Current:** v1.0.0+1 on App Store  
**Action:** Critical security fix

1. Update pubspec files: `1.0.1+1` (or `1.0.0+2` if same version, different build)
2. Update all doc files
3. Add build notes
4. Add release entry to `CHANGELOG.md`

---

## Consistency Rules

### Rule 1: Pubspec Versions Must Match
All three pubspec files must always have identical version numbers.

**Verification:**
```bash
grep "^version:" source/*/pubspec.yaml source/shared/pubspec.yaml
```

All lines should be identical.

### Rule 2: Source Code Is Truth
When in doubt, the pubspec files are the authoritative version.  
Documentation is derived from this.

### Rule 3: Version Appears in Format
- In code: `1.0.0+6` (no 'v' prefix)
- In docs: `v1.0.0+6` or `Version 1.0.0+6` (with 'v' or 'Version' prefix for clarity)

### Rule 4: Build Number Tracks Deployments
- TestFlight increments build: `0.3.0+1`, `0.3.0+2`, `0.3.0+23`
- App Store increments build: `1.0.0+1`, `1.0.0+2`, `1.0.1+1`
- Development builds may skip numbers, but deployed versions are sequential

---

## Quick Reference

**Current Version:** v1.0.0+6  
**Status:** Release candidate, deployed to TestFlight  
**Next Version:** To be determined based on changes

**Files to Update on Next Release:**
1. `source/customer_app/pubspec.yaml`
2. `source/supplier_app/pubspec.yaml`
3. `source/shared/pubspec.yaml`
4. `README.md`
5. `docs/meta/PROJECT_METADATA.md`
6. `docs/project-management/NEXT_ACTIONS.md`
7. `docs/user/USER_GUIDE.md`
8. `docs/user/ABOUT_LOYALTYCARDS.md`
9. `CHANGELOG.md` (new entry only)
10. `source/shared/lib/version.dart` (new build notes, if significant)

---

## History

| Date | Version | Event |
|------|---------|-------|
| 2026-03-30 | 0.1.0 | Project started |
| 2026-04-10 | 0.2.0 | Pilot testing phase |
| 2026-04-21 | 0.3.0+1 | Production deployment to TestFlight |
| 2026-05-23 | - | Versioning standard documented |

