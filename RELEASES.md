# Release Branches

## Purpose

Release branches preserve permanent snapshots of code deployed to TestFlight and App Store.

## Naming Convention

```
releases/v{version}-build{number}
```

Examples:
- `releases/v0.2.0-build4` - Initial TestFlight deployment
- `releases/v0.2.1-build7` - Bug fix release
- `releases/v1.0.0-build12` - First App Store production release

## Current Releases

### v0.2.0-build4 (TestFlight Pilot)
- **Date:** April 14, 2026
- **Platform:** TestFlight (Internal Testing)
- **Commit:** da1c19a
- **Features:**
  - Custom app icons
  - Dual operation modes (Simple & Secure)
  - Multi-device supplier support (backup & clone)
  - Privacy-first architecture
  - QR-based stamp issuance and redemption
- **Apps:**
  - LoyaltyCards - Digital Stamps (Customer)
  - LoyaltyCards Business (Supplier)

## Workflow

### Creating a Release Branch

When deploying to TestFlight or App Store:

```bash
# From main branch (after merging develop)
git checkout main
git checkout -b releases/v{version}-build{number}
git push origin releases/v{version}-build{number}
git checkout develop
```

### Using Release Branches

**To check deployed code:**
```bash
git checkout releases/v0.2.0-build4
```

**To compare with current development:**
```bash
git diff releases/v0.2.0-build4 develop
```

**To see all releases:**
```bash
git branch -a | grep releases
```

## Branch Protection

Release branches should:
- ✅ Never be deleted
- ✅ Never have new commits (read-only snapshot)
- ✅ Always match what was uploaded to TestFlight/App Store

If you need to deploy a fix, create a **new release branch** with incremented build number.

## Tags vs Branches

We use **branches** instead of tags because:
- Easier to checkout and browse in most Git tools
- Clearer in GitHub UI
- Can include in pull request comparisons
- More visible in `git branch -a` output

## Future Releases

When creating new releases:

1. Work in `develop` branch
2. Increment version in `pubspec.yaml` files
3. Test thoroughly
4. Merge `develop` → `main`
5. Create release branch from `main`
6. Build and upload to TestFlight/App Store
7. Return to `develop` for continued work

---

**Current branch structure:**
- `main` - Production-ready code
- `develop` - Active development
- `releases/v*` - Deployment snapshots (read-only)
- `feature/*` - Feature development (temporary)
