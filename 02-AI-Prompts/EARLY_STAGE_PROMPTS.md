# Early-Stage Project Setup Prompts

**Purpose:** Ready-to-use AI prompts for starting new projects  
**Based on:** LoyaltyCards v0.2.0 lessons learned  
**Use When:** Beginning a new AI-driven development project  
**Last Updated:** April 18, 2026

---

## Table of Contents

1. [Day 1: Project Initialization](#day-1-project-initialization)
2. [Day 1: Quality Infrastructure](#day-1-quality-infrastructure)
3. [Day 1: Documentation Foundation](#day-1-documentation-foundation)
4. [Day 1: First Feature + Test](#day-1-first-feature--test)
5. [Ongoing: Feature Development](#ongoing-feature-development)
6. [Before Deployment: Quality Gate](#before-deployment-quality-gate)

---

## Day 1: Project Initialization

### Prompt 1.1: Create Flutter Project Structure

```markdown
TASK: Create a Flutter project with shared package architecture

PROJECT STRUCTURE:
```
my_project/
├── customer_app/          # Customer-facing mobile app
├── supplier_app/          # Business-facing mobile app
└── shared/                # Shared code package
    ├── lib/
    │   ├── models/        # Data models
    │   ├── utils/         # Utilities (Logger, Crypto, etc.)
    │   ├── constants/     # App constants
    │   └── shared.dart    # Public API
    └── test/              # Shared code tests
```

REQUIREMENTS:
1. Create Flutter projects:
   - `flutter create customer_app`
   - `flutter create supplier_app`
   - Create shared package (Dart package, not Flutter)

2. Configure dependencies in pubspec.yaml:
   ```yaml
   # customer_app/pubspec.yaml and supplier_app/pubspec.yaml
   dependencies:
     shared:
       path: ../shared
     
     # Common dependencies
     sqflite: ^2.3.0
     path_provider: ^2.1.0
     uuid: ^4.3.0
     intl: ^0.20.2
   ```

3. Create shared package structure:
   - lib/models/ directory
   - lib/utils/ directory
   - lib/constants/ directory
   - test/ directory

4. Create .gitignore with Flutter + IDE entries

5. Initialize git repository:
   ```bash
   git init
   git add .
   git commit -m "chore: Initial project structure"
   ```

DELIVERABLES:
- Working project structure
- All three packages created
- Dependencies configured
- Git initialized

DO NOT include any features yet - just structure.
```

---

### Prompt 1.2: Configure Strict Lint Rules

```markdown
TASK: Configure strict lint rules to enforce code quality

CREATE FILE: analysis_options.yaml (in each package)

REQUIREMENTS:
```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # CRITICAL: Prevent bad patterns from LoyaltyCards project
    avoid_print: error                    # Force AppLogger usage
    prefer_const_constructors: true
    require_trailing_commas: true
    always_use_package_imports: true
    avoid_empty_else: true
    avoid_relative_lib_imports: true
    avoid_returning_null_for_future: true
    avoid_slow_async_io: true
    cancel_subscriptions: true
    close_sinks: true
    comment_references: true
    directives_ordering: true
    file_names: true
    hash_and_equals: true
    iterable_contains_unrelated_type: true
    list_remove_unrelated_type: true
    no_adjacent_strings_in_list: true
    no_duplicate_case_values: true
    no_logic_in_create_state: true
    prefer_conditional_assignment: true
    prefer_final_fields: true
    prefer_final_in_for_each: true
    prefer_final_locals: true
    prefer_for_elements_to_map_fromIterable: true
    prefer_function_declarations_over_variables: true
    prefer_if_null_operators: true
    prefer_initializing_formals: true
    prefer_is_empty: true
    prefer_is_not_empty: true
    prefer_null_aware_operators: true
    prefer_relative_imports: false
    prefer_single_quotes: true
    prefer_spread_collections: true
    sort_child_properties_last: true
    sort_constructors_first: true
    unawaited_futures: true
    unnecessary_null_aware_assignments: true
    unnecessary_null_in_if_null_operators: true
    unnecessary_overrides: true
    unnecessary_this: true
    use_full_hex_values_for_flutter_colors: true
    use_function_type_syntax_for_parameters: true
    use_rethrow_when_possible: true

analyzer:
  strong-mode:
    implicit-casts: false
    implicit-dynamic: false
  errors:
    missing_required_param: error
    missing_return: error
    todo: ignore  # Allow TODOs with issue references
  exclude:
    - '**/*.g.dart'
    - '**/*.freezed.dart'
```

APPLY TO:
- customer_app/analysis_options.yaml
- supplier_app/analysis_options.yaml
- shared/analysis_options.yaml

TEST:
Run `flutter analyze` in each package - should show no errors.

RATIONALE:
These rules prevent the issues we encountered in LoyaltyCards:
- avoid_print: error → Forces proper logging
- prefer_final_fields → Better performance
- Strong mode → Catches type errors early
```

---

## Day 1: Quality Infrastructure

### Prompt 2.1: Create AppLogger Utility

```markdown
TASK: Create comprehensive logging utility

CREATE FILE: shared/lib/utils/app_logger.dart

REQUIREMENTS:
```dart
import 'package:flutter/foundation.dart';

/// Centralized logging utility for the entire app.
/// 
/// NEVER use print() directly - always use AppLogger.
/// This is enforced by the lint rule `avoid_print: error`.
/// 
/// Usage:
/// ```dart
/// AppLogger.database('Saving card: $cardId');
/// AppLogger.security('Key pair generated');
/// AppLogger.error('Failed to save: $error');
/// ```
class AppLogger {
  AppLogger._(); // Private constructor - static class only

  /// Log database operations (only in debug mode)
  static void database(String message) {
    if (kDebugMode) {
      debugPrint('[DB] $message');
    }
  }

  /// Log security/crypto operations (only in debug mode)
  static void security(String message) {
    if (kDebugMode) {
      debugPrint('[🔐 SECURITY] $message');
    }
  }

  /// Log network operations (only in debug mode)
  static void network(String message) {
    if (kDebugMode) {
      debugPrint('[🌐 NETWORK] $message');
    }
  }

  /// Log UI events (only in debug mode)
  static void ui(String message) {
    if (kDebugMode) {
      debugPrint('[UI] $message');
    }
  }

  /// Log general info (only in debug mode)
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[ℹ️  INFO] $message');
    }
  }

  /// Log warnings (always shown)
  static void warning(String message) {
    debugPrint('[⚠️  WARNING] $message');
  }

  /// Log errors (always shown)
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[⛔️ ERROR] $message');
    if (error != null) {
      debugPrint('[⛔️ ERROR] Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('[⛔️ ERROR] Stack trace: $stackTrace');
    }
  }

  /// Log critical errors that should never happen (always shown)
  static void critical(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[🚨 CRITICAL] $message');
    if (error != null) {
      debugPrint('[🚨 CRITICAL] Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('[🚨 CRITICAL] Stack trace: $stackTrace');
    }
  }
}
```

ALSO CREATE: shared/lib/utils/result.dart (for error handling)
```dart
/// Result type for operations that can fail.
/// 
/// Use instead of throwing exceptions or returning null.
/// 
/// Example:
/// ```dart
/// Result<Card> loadCard(String id) {
///   try {
///     final card = repository.getCard(id);
///     if (card == null) {
///       return Result.error('Card not found: $id');
///     }
///     return Result.success(card);
///   } catch (e) {
///     AppLogger.error('Failed to load card: $id', e);
///     return Result.error('Failed to load card: ${e.message}');
///   }
/// }
/// ```
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  Result.success(this.data)
      : error = null,
        isSuccess = true;

  Result.error(this.error)
      : data = null,
        isSuccess = false;

  bool get isError => !isSuccess;
}
```

EXPORT in shared/lib/shared.dart:
```dart
export 'utils/app_logger.dart';
export 'utils/result.dart';
```

RATIONALE:
- Prevents 130+ print() statements problem from LoyaltyCards
- Structured logging from Day 1
- Debug logs only in debug mode (performance)
- Result type for clean error handling
```

---

### Prompt 2.2: Create First Test Framework

```markdown
TASK: Set up testing infrastructure and write first passing test

CREATE FILE: shared/test/utils/app_logger_test.dart

REQUIREMENTS:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  group('AppLogger', () {
    test('logs messages without throwing', () {
      // This is a basic smoke test to ensure logger works
      expect(() => AppLogger.database('test'), returnsNormally);
      expect(() => AppLogger.security('test'), returnsNormally);
      expect(() => AppLogger.error('test'), returnsNormally);
    });
  });

  group('Result', () {
    test('creates success result', () {
      final result = Result<String>.success('data');
      expect(result.isSuccess, true);
      expect(result.isError, false);
      expect(result.data, 'data');
      expect(result.error, null);
    });

    test('creates error result', () {
      final result = Result<String>.error('error message');
      expect(result.isSuccess, false);
      expect(result.isError, true);
      expect(result.data, null);
      expect(result.error, 'error message');
    });
  });
}
```

RUN TESTS:
```bash
cd shared
flutter test
```

Expected output: All tests pass ✅

ALSO CREATE: .github/workflows/test.yml (if using GitHub)
```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: cd shared && flutter test
      - run: cd customer_app && flutter test
      - run: cd supplier_app && flutter test
```

RATIONALE:
- Tests from Day 1 (not "we'll add them later")
- CI/CD runs tests on every commit
- Catches issues immediately
```

---

### Prompt 2.3: Create Git Pre-Commit Hook

```markdown
TASK: Create pre-commit hook to enforce quality standards

CREATE FILE: .git/hooks/pre-commit (make executable)

REQUIREMENTS:
```bash
#!/bin/bash
# Pre-commit hook to enforce code quality

echo "🔍 Running pre-commit quality checks..."

# Change to repository root
cd "$(git rev-parse --show-toplevel)"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check 1: No print() statements
echo "Checking for print() statements..."
if git diff --cached --name-only | grep "\.dart$" | xargs grep -n "print(" 2>/dev/null; then
    echo -e "${RED}❌ FAIL: print() statements found${NC}"
    echo "Use AppLogger instead (e.g., AppLogger.database('message'))"
    exit 1
fi
echo -e "${GREEN}✓ No print() statements${NC}"

# Check 2: TODOs have issue references
echo "Checking for TODOs without issue references..."
if git diff --cached --name-only | grep "\.dart$" | xargs grep -n "TODO" 2>/dev/null | grep -v "#[0-9]"; then
    echo -e "${YELLOW}⚠️  WARNING: TODOs found without issue references${NC}"
    echo "Format: // TODO(#123): Description"
    # Don't fail, just warn
fi

# Check 3: No placeholder implementations
echo "Checking for placeholder code..."
if git diff --cached --name-only | grep "\.dart$" | xargs grep -ni "placeholder\|for now\|temporary" 2>/dev/null; then
    echo -e "${RED}❌ FAIL: Placeholder code found${NC}"
    echo "Remove placeholders or throw UnimplementedError()"
    exit 1
fi
echo -e "${GREEN}✓ No placeholder code${NC}"

# Check 4: No .toString() on objects (common AI mistake)
echo "Checking for .toString() on complex objects..."
if git diff --cached --name-only | grep "\.dart$" | xargs grep -n "\.toString()" 2>/dev/null | grep -v "String"; then
    echo -e "${YELLOW}⚠️  WARNING: .toString() found - verify this is intentional${NC}"
    # Don't fail, just warn (sometimes .toString() is correct)
fi

# Check 5: Run dart analyze
echo "Running dart analyze..."
cd shared && flutter analyze --no-pub > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ FAIL: Analysis errors in shared package${NC}"
    cd shared && flutter analyze
    exit 1
fi
echo -e "${GREEN}✓ Shared package analysis passed${NC}"

# Check 6: Run tests (quick)
echo "Running tests..."
cd shared && flutter test > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ FAIL: Tests failed${NC}"
    cd shared && flutter test
    exit 1
fi
echo -e "${GREEN}✓ All tests passed${NC}"

echo -e "${GREEN}✅ All pre-commit checks passed!${NC}"
exit 0
```

MAKE EXECUTABLE:
```bash
chmod +x .git/hooks/pre-commit
```

TEST:
```bash
# Try committing a file with print()
echo "void main() { print('test'); }" > test.dart
git add test.dart
git commit -m "test"
# Should fail ❌

# Remove print() and try again
echo "void main() { AppLogger.info('test'); }" > test.dart
git add test.dart
git commit -m "test"
# Should succeed ✅
```

RATIONALE:
- Prevents bad patterns from entering codebase
- Automated enforcement (no manual checking)
- Catches issues in seconds (not hours later)
```

---

## Day 1: Documentation Foundation

### Prompt 3.1: Create Core Documentation Files

```markdown
TASK: Create documentation foundation before writing any features

CREATE THESE FILES:

1. **DATABASE_SCHEMA.md**
```markdown
# Database Schema

**Version:** 1 (Initial)  
**Last Updated:** [Today's date]

## Customer App Database

### Tables

#### cards
```sql
CREATE TABLE cards (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL,
  business_name TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

Purpose: [Describe purpose]
Indexes: [List indexes]

[Add more tables as you design them]

## Migration History

### v1 (Initial)
- Created cards table
- Created stamps table
- [etc.]

[Update this as you add migrations]
```

2. **SECURITY_CHECKLIST.md**
```markdown
# Security Checklist

## Before Every Commit
- [ ] No secrets, API keys, or tokens in code
- [ ] No private key logging
- [ ] Input validation on all external data
- [ ] Proper error handling (no silent failures)

## Before Every TestFlight/Release
- [ ] Security-focused code review completed
- [ ] Crypto operations audited
- [ ] No sensitive data in logs
- [ ] All authentication working correctly

[Update with project-specific security requirements]
```

3. **DEFINITION_OF_DONE.md**
```markdown
# Definition of Done

A feature is NOT complete until ALL of these are true:

## Code
- [ ] Implementation complete (no placeholders)
- [ ] No print() statements (use AppLogger)
- [ ] No TODOs without GitHub issue references
- [ ] Proper error handling (uses Result<T> type)
- [ ] Duplicated code extracted to shared/ package

## Testing
- [ ] Unit tests written (70% coverage minimum)
- [ ] Integration test (if multi-component feature)
- [ ] Manual test on physical device
- [ ] All tests passing

## Documentation
- [ ] DATABASE_SCHEMA.md updated (if schema changed)
- [ ] USER_GUIDE.md updated (if user-facing change)
- [ ] Inline documentation for complex logic
- [ ] CHANGELOG.md updated

## Review
- [ ] AI code review completed (using review prompt)
- [ ] All review findings addressed
- [ ] No "fix this later" comments

## Security
- [ ] SECURITY_CHECKLIST.md reviewed
- [ ] No sensitive data in code or logs
- [ ] Input validation implemented
```

4. **PERFORMANCE_BASELINES.md**
```markdown
# Performance Baselines

**Targets (to be measured after first build):**

## App Size
- Target: <50 MB (IPA file)
- Maximum: 100 MB

## Launch Time
- Target: <3 seconds (flagship device)
- Maximum: 5 seconds (minimum spec device)

## Database Queries
- Target: <100ms average
- Maximum: 500ms

## Memory Usage
- Target: <100 MB peak
- Maximum: 150 MB

[Update with actual measurements after first build]
```

COMMIT:
```bash
git add .
git commit -m "docs: Create documentation foundation

- DATABASE_SCHEMA.md (schema design template)
- SECURITY_CHECKLIST.md (security requirements)
- DEFINITION_OF_DONE.md (completion criteria)
- PERFORMANCE_BASELINES.md (performance targets)"
```

RATIONALE:
- Documents created BEFORE features (not after)
- Living documents updated as you go
- Clear criteria for "done"
```

---

## Day 1: First Feature + Test

### Prompt 4.1: Implement First Feature (With Test!)

```markdown
TASK: Implement first feature using best practices

FEATURE: [Example: Card data model and repository]

IMPLEMENTATION REQUIREMENTS:

1. **Create Model**
   File: shared/lib/models/card.dart
   ```dart
   class Card {
     final String id;
     final String businessName;
     final DateTime createdAt;
     
     Card({
       required this.id,
       required this.businessName,
       required this.createdAt,
     });
     
     // Add toJson, fromJson, copyWith, etc.
   }
   ```

2. **Create Repository**
   File: customer_app/lib/repositories/card_repository.dart
   ```dart
   class CardRepository {
     Future<Result<List<Card>>> getAllCards() async {
       try {
         AppLogger.database('Loading all cards');
         // Implementation
         return Result.success(cards);
       } catch (e) {
         AppLogger.error('Failed to load cards', e);
         return Result.error('Failed to load cards: ${e.message}');
       }
     }
   }
   ```

3. **Create Tests**
   File: customer_app/test/repositories/card_repository_test.dart
   ```dart
   void main() {
     group('CardRepository', () {
       test('getAllCards returns empty list initially', () async {
         final repo = CardRepository(mockDatabase);
         final result = await repo.getAllCards();
         
         expect(result.isSuccess, true);
         expect(result.data, isEmpty);
       });
       
       test('getAllCards returns error on database failure', () async {
         final repo = CardRepository(failingDatabase);
         final result = await repo.getAllCards();
         
         expect(result.isError, true);
         expect(result.error, contains('Failed to load cards'));
       });
     });
   }
   ```

QUALITY REQUIREMENTS:

MUST INCLUDE:
- [ ] AppLogger for all logging (no print())
- [ ] Result<T> for error handling
- [ ] Unit tests (happy path + error path)
- [ ] Inline documentation for public APIs

MUST NOT INCLUDE:
- [ ] print() statements
- [ ] TODOs without issue references
- [ ] Placeholder implementations
- [ ] try-catch with empty catch blocks

TEST:
- [ ] Run `flutter test` - all pass
- [ ] Run `flutter analyze` - no errors
- [ ] Pre-commit hook passes

DELIVERABLES:
1. Model implementation
2. Repository implementation
3. Unit tests (100% coverage for this feature)
4. Updated DATABASE_SCHEMA.md (if applicable)

This establishes the pattern for ALL future features.
```

---

## Ongoing: Feature Development

### Prompt 5.1: New Feature Template

```markdown
TASK: Implement [Feature Name]

CONTEXT:
[1-2 sentences: What this feature does and why]

REQUIREMENTS:
1. [Specific requirement 1]
2. [Specific requirement 2]
3. [etc.]

TECHNICAL DESIGN:

Database Changes:
```sql
-- If schema changes needed
ALTER TABLE cards ADD COLUMN new_field TEXT;
```

API Surface:
```dart
// Public interfaces this feature exposes
class ExampleService {
  Future<Result<Data>> performAction(Input input);
}
```

IMPLEMENTATION CHECKLIST:

MUST INCLUDE:
- [ ] AppLogger for all logging (no print())
- [ ] Result<T> for error handling
- [ ] Input validation on all parameters
- [ ] Unit tests (minimum 70% coverage)
- [ ] Integration test (if multi-component)
- [ ] Inline documentation for complex logic

MUST NOT INCLUDE:
- [ ] print() statements
- [ ] .toString() on complex objects
- [ ] Placeholder implementations
- [ ] TODOs without issue references (#XXX format)
- [ ] Hardcoded values (use constants)
- [ ] Duplicated code (extract to shared/)

ERROR SCENARIOS TO HANDLE:
- [Error case 1] → [Expected behavior]
- [Error case 2] → [Expected behavior]

TESTING REQUIREMENTS:
- [ ] Happy path test
- [ ] Error path tests (at least 2)
- [ ] Edge case tests (null, empty, boundary)
- [ ] Integration test (if applicable)

DOCUMENTATION UPDATES:
- [ ] DATABASE_SCHEMA.md (if schema changed)
- [ ] USER_GUIDE.md (if user-facing)
- [ ] CHANGELOG.md (if user-facing change)

FILES TO CREATE/MODIFY:
- lib/services/[feature]_service.dart
- lib/repositories/[feature]_repository.dart (if data access)
- test/services/[feature]_service_test.dart
- test/integration/[feature]_test.dart (if applicable)

DELIVERABLES:
1. Implementation code
2. Unit tests (70%+ coverage)
3. Integration test (if applicable)
4. Documentation updates
5. Brief explanation of design decisions
```

---

### Prompt 5.2: Code Review Template

```markdown
TASK: Production-readiness code review

FILES TO REVIEW:
[List files or provide git diff]

REVIEW FOCUS:

1. **SECURITY (CRITICAL):**
   - [ ] No secrets/keys in code or logs
   - [ ] Input validation on external data
   - [ ] Crypto operations use secure patterns
   - [ ] Error messages don't leak sensitive info

2. **CODE QUALITY (HIGH):**
   - [ ] No print() statements
   - [ ] No .toString() on complex objects
   - [ ] No placeholder implementations
   - [ ] No TODOs without issues
   - [ ] Proper error handling (Result<T> used)
   - [ ] AppLogger used correctly

3. **ARCHITECTURE (HIGH):**
   - [ ] No duplicated code (should be in shared/)
   - [ ] Follows repository pattern
   - [ ] Proper separation of concerns
   - [ ] Dependencies injected

4. **TESTING (HIGH):**
   - [ ] Unit tests exist
   - [ ] Tests cover error paths
   - [ ] Coverage >70%
   - [ ] Edge cases tested

5. **PERFORMANCE (MEDIUM):**
   - [ ] No N+1 query problems
   - [ ] Database indexes used
   - [ ] No memory leaks

6. **DOCUMENTATION (MEDIUM):**
   - [ ] Complex logic documented
   - [ ] Public APIs have doc comments
   - [ ] Schema updates documented

OUTPUT FORMAT:
For each issue:
**FILE:** [path:line]
**SEVERITY:** [CRITICAL/HIGH/MEDIUM/LOW]
**ISSUE:** [description]
**FIX:** [specific suggestion]

At end:
**SUMMARY:** X issues (Y critical, Z high)
**RECOMMENDATION:** [APPROVE / FIX REQUIRED / NEEDS DISCUSSION]
```

---

## Before Deployment: Quality Gate

### Prompt 6.1: Pre-TestFlight Checklist

```markdown
TASK: Comprehensive pre-deployment review

RUN THESE CHECKS:

1. **AUTOMATED CHECKS:**
```bash
# No print() statements
grep -r "print(" --include="*.dart" . | grep -v test | grep -v AppLogger
# Expected: No results

# No TODOs without issues
grep -r "TODO" --include="*.dart" . | grep -v "#[0-9]"
# Expected: No results

# All tests pass
flutter test
# Expected: All pass

# No analysis errors
flutter analyze
# Expected: No errors
```

2. **MANUAL SECURITY REVIEW:**
   - [ ] Review all crypto/auth code changes
   - [ ] Check for secrets in code
   - [ ] Verify error messages don't leak internals
   - [ ] Input validation on all external data

3. **MANUAL TESTING:**
   - [ ] Test on minimum spec device (e.g., iPhone SE, iOS 13)
   - [ ] Test on flagship device (e.g., iPhone Pro, latest iOS)
   - [ ] Test database migration (fresh install + upgrade)
   - [ ] Test offline functionality
   - [ ] Test error scenarios (not just happy path)

4. **PERFORMANCE CHECK:**
   - [ ] Cold launch time <3s (flagship)
   - [ ] Cold launch time <5s (minimum spec)
   - [ ] Memory usage <150 MB
   - [ ] App size <50 MB (IPA)

5. **DOCUMENTATION:**
   - [ ] CHANGELOG.md updated with all changes
   - [ ] RELEASES.md updated with build info
   - [ ] USER_GUIDE.md updated (if UI changed)
   - [ ] Known issues documented

If ANY critical issues found, DO NOT DEPLOY.

Provide:
- List of all issues found
- Severity of each
- Recommendation (DEPLOY / FIX FIRST / NEEDS DISCUSSION)
```

---

## Summary: Day 1 Checklist

```markdown
BY END OF DAY 1, YOU SHOULD HAVE:

✅ Project Structure:
   - customer_app, supplier_app, shared packages
   - Dependencies configured
   - Git initialized

✅ Quality Infrastructure:
   - AppLogger utility (no print() allowed)
   - Result<T> type for error handling
   - Strict lint rules configured
   - Pre-commit hooks installed

✅ Testing Framework:
   - First tests written and passing
   - CI/CD configured (if using GitHub)

✅ Documentation:
   - DATABASE_SCHEMA.md (design template)
   - SECURITY_CHECKLIST.md
   - DEFINITION_OF_DONE.md
   - PERFORMANCE_BASELINES.md

✅ First Feature:
   - Implemented with tests
   - Passed all quality checks
   - Demonstrates pattern for future features

TIME INVESTMENT: ~4 hours
EXPECTED SAVINGS: 10-15 hours throughout project
```

---

## Related Documents

- [AI Prompting Guide](AI_PROMPTING_GUIDE.md) - Advanced prompting techniques
- [Process Improvements](../PROCESS_IMPROVEMENTS.md) - Full process recommendations
- [Lessons Learned](../LESSONS_LEARNED.md) - What we learned from LoyaltyCards

**Maintained by:** Development Team  
**Last Updated:** April 18, 2026
