# AI Prompting Guide for Quality Code Generation

**Project:** LoyaltyCards  
**Purpose:** Prompt engineering patterns for AI-driven development  
**Based on:** Lessons learned from v0.2.0 development  
**Last Updated:** April 18, 2026

---

## Table of Contents

1. [Core Principles](#core-principles)
2. [The Two-Agent Pattern](#the-two-agent-pattern)
3. [Prompt Templates](#prompt-templates)
4. [Anti-Patterns to Avoid](#anti-patterns-to-avoid)
5. [Project-Specific Context](#project-specific-context)
6. [Quality Checklist Prompts](#quality-checklist-prompts)

---

## Core Principles

### Principle 1: Be Explicit About What NOT to Do

**Problem:** AI optimize for "working code" and may use shortcuts

**BAD PROMPT:**
```
"Implement card issuance with QR code generation"
```

**GOOD PROMPT:**
```
"Implement card issuance with QR code generation.

MUST USE:
- AppLogger for all logging (not print())
- Proper base64 encoding for public keys
- Input validation on all parameters

MUST NOT USE:
- .toString() on complex objects like ECPublicKey
- Placeholder implementations (throw UnimplementedError if incomplete)
- TODO comments without GitHub issue numbers
```

**Why:** AI needs to know the pitfalls to avoid them

---

### Principle 2: Request Tests With Implementation

**BAD PROMPT:**
```
"Create a CardRepository with CRUD operations"
```

**GOOD PROMPT:**
```
"Create a CardRepository with CRUD operations.

Include:
1. Implementation in lib/services/card_repository.dart
2. Unit tests in test/services/card_repository_test.dart
3. Test coverage for:
   - Happy path (create, read, update, delete)
   - Error cases (invalid IDs, database errors)
   - Edge cases (null values, empty lists)
   
Minimum 70% code coverage."
```

**Why:** Tests catch AI mistakes and provide regression safety

---

### Principle 3: Provide Project Context

**BAD PROMPT:**
```
"Add logging to the app"
```

**GOOD PROMPT:**
```
"Add logging using our AppLogger utility (shared/lib/utils/app_logger.dart).

Project standards:
- Never use print() directly (lint rule enforces this)
- Use AppLogger.database() for DB operations
- Use AppLogger.security() for crypto operations
- Use AppLogger.error() for exceptions
- Debug logs only appear in debug mode (kDebugMode)

Update these files to replace print() with AppLogger:
- [list specific files]
```

**Why:** AI needs project-specific patterns to follow

---

## The Two-Agent Pattern

### Overview

Use TWO separate AI conversations for every feature:
1. **Agent 1:** Implementation (optimizes for working code)
2. **Agent 2:** Review (optimizes for finding issues)

### Agent 1: Implementation Prompt

```markdown
TASK: Implement [Feature Name]

REQUIREMENTS:
1. [Explicit requirement 1]
2. [Explicit requirement 2]
3. [etc.]

TECHNICAL SPECIFICATIONS:
- Database: [schema details if applicable]
- API: [interfaces to implement]
- Error Handling: [expected error scenarios]

PROJECT STANDARDS:
- Logging: Use AppLogger (no print() statements)
- Architecture: Follow repository pattern
- Shared Code: Extract common logic to shared/lib/utils/
- Testing: Include unit tests with implementation

CRITICAL CONSTRAINTS:
- [Known pitfall 1 and how to avoid]
- [Security consideration]
- [Performance requirement]

DELIVERABLES:
1. Implementation code (lib/...)
2. Unit tests (test/...)
3. Integration test (if multi-component)
4. Documentation update (if public API)

SUCCESS CRITERIA:
- All tests passing
- No print() statements (use AppLogger)
- No TODOs without issue references
- Proper error handling (not just try-catch-ignore)
```

### Agent 2: Review Prompt

```markdown
TASK: Production readiness code review

CODE CONTEXT:
This code implements [feature name] for [purpose].
[Paste code or provide file paths]

REVIEW CHECKLIST:

1. SECURITY (CRITICAL):
   [ ] No secrets/keys in code or logs
   [ ] Input validation on all external data
   [ ] Crypto operations use secure patterns
   [ ] Error messages don't leak sensitive info
   [ ] SQL injection prevention (if applicable)

2. CODE QUALITY (HIGH):
   [ ] No print() statements (must use AppLogger)
   [ ] No placeholder implementations (no ".toString()" on objects)
   [ ] No TODOs without GitHub issue references
   [ ] Error handling doesn't silently swallow exceptions
   [ ] Logging at appropriate levels (debug/info/warning/error)

3. ARCHITECTURE (HIGH):
   [ ] Duplicated code extracted to shared/ package
   [ ] Follows repository pattern
   [ ] Proper separation of concerns
   [ ] Dependencies injected (not hardcoded)

4. TESTING (HIGH):
   [ ] Unit tests exist and pass
   [ ] Tests cover error paths (not just happy path)
   [ ] Test coverage >70% for new code
   [ ] Edge cases tested (null, empty, invalid input)

5. PERFORMANCE (MEDIUM):
   [ ] No N+1 query problems
   [ ] Database indexes used appropriately
   [ ] No memory leaks (async operations cleaned up)
   [ ] Crypto operations <100ms

6. DOCUMENTATION (MEDIUM):
   [ ] Complex logic has inline documentation
   [ ] Public APIs have doc comments
   [ ] DATABASE_SCHEMA.md updated (if schema changed)
   [ ] CHANGELOG.md updated (if user-facing)

OUTPUT FORMAT:
For each issue found, provide:

**FILE:** [file path and line number]
**SEVERITY:** [CRITICAL / HIGH / MEDIUM / LOW]
**ISSUE:** [description of the problem]
**WHY BAD:** [why this is a problem]
**FIX:** [specific code change needed]
**EXAMPLE:** [code snippet showing the fix]

At the end, provide:
**SUMMARY:** X issues found (Y critical, Z high, ...)
**RECOMMENDATION:** [APPROVE / FIX REQUIRED / NEEDS DISCUSSION]
```

### Timing

- **Same Day:** Run both agents on the same day
- **Immediate Fix:** Fix review findings before moving to next feature
- **Context Fresh:** Easiest to fix while context is in your head

---

## Prompt Templates

### Template: New Feature Implementation

```markdown
# Feature Implementation: [Feature Name]

## Context
[1-2 sentence description of what this feature does and why]

## Requirements
1. [User story or requirement]
2. [Technical constraint]
3. [Integration points]

## Technical Design

### Database Changes (if applicable)
```sql
-- New tables or columns
CREATE TABLE example (...);
ALTER TABLE existing ADD COLUMN new_field ...;
```

### API Surface
```dart
// Public interfaces this feature exposes
class ExampleService {
  Future<Result> performAction(Input data);
}
```

### Error Scenarios
- [Error case 1] → [Expected behavior]
- [Error case 2] → [Expected behavior]

## Implementation Guidelines

### MUST Include:
- [ ] AppLogger for all logging (no print())
- [ ] Input validation on all external data
- [ ] Proper error handling (not just try-catch-ignore)
- [ ] Unit tests (minimum 70% coverage)
- [ ] Integration test (if touches multiple components)
- [ ] Documentation for complex logic

### MUST NOT Include:
- [ ] print() statements
- [ ] .toString() on complex objects
- [ ] Placeholder implementations (throw UnimplementedError instead)
- [ ] TODOs without issue references
- [ ] Hardcoded values (use constants)
- [ ] Duplicated code (extract to shared/)

### Performance Requirements:
- Database queries: <100ms
- API calls: <500ms
- UI updates: <16ms (60 FPS)

### Security Requirements:
- No secrets in code or logs
- All external input validated
- Crypto operations use established patterns (shared/utils/crypto_utils.dart)

## File Structure
```
lib/
  services/
    [feature]_service.dart        # Business logic
  repositories/
    [feature]_repository.dart     # Data access
test/
  services/
    [feature]_service_test.dart   # Unit tests
  integration_test/
    [feature]_test.dart            # Integration tests
```

## Testing Checklist
- [ ] Happy path test
- [ ] Error path tests (invalid input, database errors, etc.)
- [ ] Edge case tests (null, empty, boundary values)
- [ ] Integration test (if multi-component)

## Documentation Updates
- [ ] DATABASE_SCHEMA.md (if schema changed)
- [ ] USER_GUIDE.md (if user-facing)
- [ ] Inline documentation for complex logic

## Deliverables
Please provide:
1. Implementation code
2. Unit tests
3. Integration test (if applicable)
4. Documentation updates
5. Brief explanation of design decisions
```

---

### Template: Bug Fix

```markdown
# Bug Fix: [Bug ID or Description]

## Bug Report
**Symptom:** [What user sees/experiences]
**Expected:** [What should happen]
**Actual:** [What actually happens]
**Severity:** [CRITICAL / HIGH / MEDIUM / LOW]

## Root Cause Analysis
[Explain why this bug exists - be specific]

## Fix Strategy
[Describe the fix approach before implementing]

## Implementation Requirements

### Fix Must:
- [ ] Address root cause (not just symptoms)
- [ ] Include test that reproduces the bug
- [ ] Include test that verifies the fix
- [ ] Not break existing functionality (regression test)
- [ ] Use AppLogger to log the error scenario

### Fix Must Not:
- [ ] Introduce new print() statements
- [ ] Add TODOs without issue references
- [ ] Use try-catch to hide the error
- [ ] Change behavior outside the bug scope

## Testing Checklist
- [ ] Test that reproduces original bug (should fail before fix)
- [ ] Test that verifies fix (should pass after fix)
- [ ] Regression tests (existing features still work)
- [ ] Edge cases related to this bug

## Documentation
- [ ] Update DEFECT_TRACKER.md (mark bug as FIXED)
- [ ] Update CHANGELOG.md (user-facing bugs only)
- [ ] Add inline comment explaining the fix (if non-obvious)

## Deliverables
1. Fix implementation
2. Test reproducing the bug
3. Test verifying the fix
4. Explanation of root cause and fix
```

---

### Template: Refactoring

```markdown
# Refactoring: [What's Being Refactored]

## Motivation
[Why is this refactoring needed?]

## Current State
[Describe current code structure/issues]

## Target State
[Describe desired code structure after refactoring]

## Refactoring Plan

### Changes:
1. [Specific change 1]
2. [Specific change 2]
3. [etc.]

### Non-Changes:
- [What will NOT change - important for clarity]

## Safety Requirements

### MUST:
- [ ] All existing tests must pass after refactoring
- [ ] No functional behavior changes
- [ ] Extract duplicated code to shared/ package
- [ ] Use AppLogger (no print() statements)
- [ ] Maintain existing API contracts (or version properly)

### TESTING:
- [ ] All existing unit tests pass
- [ ] All existing integration tests pass
- [ ] Manual smoke test on device
- [ ] No performance degradation

## Deliverables
1. Refactored code
2. Confirmation that all tests pass
3. Performance comparison (before/after)
4. Documentation of new code structure
```

---

### Template: Code Review Request

```markdown
# Code Review: [Feature/Fix Name]

## What Changed
[Brief description of changes]

## Files Changed
```
lib/services/example.dart       # Added new service
test/services/example_test.dart # Added tests
shared/lib/utils/helper.dart    # Extracted common logic
```

## Review Focus Areas

Please review for:

1. **Security:**
   - Any secrets or keys exposed?
   - Input validation on external data?
   - Crypto operations secure?

2. **Quality:**
   - Any print() statements? (should be AppLogger)
   - Any placeholders or TODOs without issues?
   - Proper error handling?

3. **Architecture:**
   - Code duplication that should be in shared/?
   - Follows repository pattern?
   - Proper separation of concerns?

4. **Testing:**
   - Tests exist and cover critical paths?
   - Error paths tested?
   - Coverage >70%?

5. **Performance:**
   - Any potential performance issues?
   - Database queries optimized?

## Specific Questions
[Any specific areas you're uncertain about]

## Testing Done
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual test on device
- [ ] Regression tests pass

## Checklist Before Review
- [ ] No print() statements in code
- [ ] No TODOs without issue references
- [ ] All tests passing
- [ ] Documentation updated
- [ ] CHANGELOG.md updated (if user-facing)

Please provide review feedback using this format:
**FILE:** [path:line]
**SEVERITY:** [CRITICAL/HIGH/MEDIUM/LOW]
**ISSUE:** [description]
**FIX:** [suggestion]
```

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Vague Requirements

**BAD:**
```
"Make the app faster"
```

**GOOD:**
```
"Optimize card loading on home screen:
- Current: 500ms for 50 cards
- Target: <200ms for 50 cards
- Profile with Xcode Instruments
- Focus on database query optimization
- Test on iPhone SE (minimum spec device)"
```

---

### Anti-Pattern 2: Missing Negative Constraints

**BAD:**
```
"Add error handling to the repository"
```

**GOOD:**
```
"Add error handling to the repository.

DO:
- Log errors with AppLogger.error()
- Return Result<T> type
- Provide user-friendly error messages

DON'T:
- Use print() for logging
- Use empty try-catch blocks
- Return null on errors (use Result type)
- Expose stack traces to users"
```

---

### Anti-Pattern 3: Implementation Without Tests

**BAD:**
```
"Implement stamp verification logic"
```

**GOOD:**
```
"Implement stamp verification logic with comprehensive tests.

Implementation: lib/services/stamp_verifier.dart
Tests: test/services/stamp_verifier_test.dart

Test cases required:
1. Valid stamp with correct signature → returns true
2. Invalid signature → returns false and logs reason
3. Expired stamp → returns false with appropriate error
4. Tampered data → returns false
5. Null/invalid input → throws ArgumentError

Minimum 80% coverage for security-critical code."
```

---

### Anti-Pattern 4: No Context About Project

**BAD:**
```
"Add logging"
```

**GOOD:**
```
"Add logging using our AppLogger utility.

Project context:
- Location: shared/lib/utils/app_logger.dart
- Methods: database(), security(), error(), info()
- Rule: No print() statements (enforced by lint)
- Debug logs only in debug mode (kDebugMode check)

Replace all print() in:
- lib/services/card_repository.dart
- lib/services/stamp_repository.dart

Example:
Before: print('Saving card: $cardId');
After:  AppLogger.database('Saving card: $cardId');"
```

---

## Project-Specific Context

### LoyaltyCards Architecture

**When prompting, provide this context:**

```markdown
## Project Structure
```
LoyaltyCards/
├── customer_app/          # Customer-facing iOS app
├── supplier_app/          # Business-facing iOS app
└── shared/                # Shared code package
    ├── lib/
    │   ├── models/        # Data models (Card, Stamp, Business, etc.)
    │   ├── utils/         # Utilities (AppLogger, CryptoUtils, etc.)
    │   └── constants/     # App constants
    └── test/              # Shared code tests
```

## Architecture Patterns
- **Repository Pattern:** Data access abstracted behind repositories
- **Database:** SQLite via sqflite package
- **Crypto:** ECDSA P-256 via pointycastle package
- **Security:** Private keys in iOS Keychain via flutter_secure_storage
- **Logging:** AppLogger utility (no print() allowed)

## Key Principles
1. **Privacy First:** No user data collection, local storage only
2. **Offline Capable:** All features work without internet
3. **P2P Architecture:** No backend, QR codes for data exchange
4. **Security:** Cryptographic signatures prevent fraud

## Code Quality Standards
- No print() statements (lint rule enforces)
- No TODOs without GitHub issue references
- Test coverage >70% for all new code
- All crypto code in shared/utils/crypto_utils.dart
- All logging via AppLogger

## Common Pitfalls
- Don't use .toString() on ECPublicKey (use proper encoding)
- Don't swallow errors in try-catch (log with AppLogger.error())
- Don't duplicate code between apps (extract to shared/)
```

---

## Quality Checklist Prompts

### Before Committing Code

```markdown
Please review this code before commit:

AUTOMATED CHECKS:
1. Run: `grep -r "print(" --include="*.dart" .`
   Expected: No results (use AppLogger instead)

2. Run: `grep -r "TODO" --include="*.dart" . | grep -v "#"`
   Expected: No TODOs without issue references

3. Run: `flutter analyze`
   Expected: No errors or warnings

4. Run: `flutter test`
   Expected: All tests pass

MANUAL CHECKS:
[ ] No placeholder implementations (use UnimplementedError)
[ ] No .toString() on complex objects
[ ] Error handling doesn't silently swallow errors
[ ] Duplicated code extracted to shared/
[ ] Documentation updated for public APIs

If all checks pass, provide commit message in this format:
```
<type>(<scope>): <subject>

<body explaining what and why>

Related: #<issue number>
```

Types: feat, fix, docs, test, refactor, perf, chore
```

---

### Before Merging to Develop

```markdown
Please perform pre-merge review:

CODE QUALITY:
[ ] All tests passing (unit + integration)
[ ] Test coverage >70% for new code
[ ] No print() statements
[ ] No TODOs without issues
[ ] No placeholder implementations

SECURITY:
[ ] No secrets in code or logs
[ ] Input validation on external data
[ ] Crypto operations use shared/utils/crypto_utils.dart
[ ] Error messages don't leak sensitive information

ARCHITECTURE:
[ ] No code duplication between customer_app and supplier_app
[ ] Shared code in shared/ package
[ ] Follows repository pattern
[ ] Database queries use indexes

DOCUMENTATION:
[ ] DATABASE_SCHEMA.md updated (if schema changed)
[ ] CHANGELOG.md updated (if user-facing)
[ ] Inline docs for complex logic

PERFORMANCE:
[ ] No obvious performance issues
[ ] Database queries <100ms
[ ] Memory usage reasonable

If any issues found, provide:
- Issue description
- Severity (CRITICAL/HIGH/MEDIUM/LOW)
- Specific fix needed
```

---

### Before TestFlight Deployment

```markdown
Please perform comprehensive pre-deployment review:

ZERO TOLERANCE:
[ ] Zero print() statements: `grep -r "print(" --include="*.dart" 03-Source/`
[ ] Zero TODOs without issues: `grep -r "TODO" --include="*.dart" 03-Source/ | grep -v "#"`
[ ] Zero placeholder implementations
[ ] All tests passing (unit + integration)

SECURITY REVIEW:
[ ] No secrets, keys, or tokens in code
[ ] No private key logging (check AppLogger calls)
[ ] All external input validated
[ ] Crypto operations audited
[ ] Error messages don't leak internals

TESTING:
[ ] Tested on iPhone SE (iOS 13.0 - minimum spec)
[ ] Tested on iPhone Pro (latest iOS - flagship)
[ ] Tested on iPad (if supported)
[ ] Database migration tested (fresh + upgrade)
[ ] Offline functionality verified
[ ] Error scenarios tested

PERFORMANCE:
[ ] Cold launch <3 seconds (iPhone Pro)
[ ] Cold launch <5 seconds (iPhone SE)
[ ] QR scan flow <3 seconds
[ ] Memory usage <150 MB
[ ] App size <50 MB

DOCUMENTATION:
[ ] CHANGELOG.md updated with all changes
[ ] RELEASES.md updated with build info
[ ] BUILD_XX_TESTING_GUIDE.md created
[ ] Known issues documented

If any CRITICAL issues found, DO NOT DEPLOY.
Provide detailed list of all issues found.
```

---

## Advanced Prompting Techniques

### Technique 1: Constraint-Based Prompting

Instead of describing what you want, describe what you DON'T want:

```markdown
Implement feature X with these CONSTRAINTS:

FORBIDDEN:
- print() statements
- .toString() on complex objects
- try-catch without logging
- Hardcoded values
- Duplicated code
- TODOs without issues

REQUIRED:
- AppLogger for logging
- Input validation
- Error handling
- Unit tests
- Documentation
```

**Why:** Constraints are clearer than aspirations

---

### Technique 2: Example-Driven Prompting

Provide examples of good vs bad code:

```markdown
Implement stamp verification.

BAD EXAMPLE (don't do this):
```dart
bool verify(Stamp stamp) {
  try {
    // Verification logic
    return true;
  } catch (e) {
    return false;  // ❌ Silent failure
  }
}
```

GOOD EXAMPLE (do this):
```dart
Result<bool> verify(Stamp stamp) {
  try {
    // Validation
    if (stamp.id == null) {
      AppLogger.error('Stamp ID is null');
      return Result.error('Invalid stamp: missing ID');
    }
    
    // Verification logic
    final isValid = verifySignature(stamp);
    
    if (!isValid) {
      AppLogger.security('Stamp signature verification failed for ${stamp.id}');
    }
    
    return Result.success(isValid);
  } catch (e) {
    AppLogger.error('Stamp verification exception: $e');
    return Result.error('Verification failed: ${e.message}');
  }
}
```

Now implement following the GOOD EXAMPLE pattern.
```

---

### Technique 3: Iterative Refinement

Start broad, refine with follow-ups:

```markdown
PROMPT 1: "Design database schema for loyalty cards"
(AI provides initial schema)

PROMPT 2: "Good start. Now add:
- device_id tracking for multi-device detection
- Indexes for common queries
- Migration path from v5 to v6
- Foreign key constraints with CASCADE delete"
(AI refines schema)

PROMPT 3: "Implement this schema in database_helper.dart with:
- Migration logic in _onUpgrade
- Logging for each migration step
- Tests verifying migration works"
(AI implements)
```

---

## Emergency Debugging Prompts

### When Tests Are Failing

```markdown
These tests are failing:
[paste test failures]

Please:
1. Analyze the failure output
2. Identify the root cause (not just symptoms)
3. Explain why it's failing (in plain English)
4. Provide a fix
5. Verify the fix with the test

Constraints:
- Don't just catch the exception
- Fix the underlying issue
- Add logging to help debug in future
```

---

### When Performance Is Bad

```markdown
This operation is slow:
[describe operation and current timing]

Please:
1. Profile the code (conceptually)
2. Identify bottlenecks (likely suspects: DB queries, crypto, loops)
3. Suggest optimizations with expected improvement
4. Implement highest-ROI optimization first
5. Verify improvement with measurement

Constraints:
- Don't sacrifice correctness for speed
- Add performance logging (AppLogger)
- Consider caching if appropriate
```

---

## Conclusion

**Key Principles:**
1. **Be explicit** about what not to do
2. **Request tests** with implementation
3. **Provide context** about project patterns
4. **Use two agents** (implement + review)
5. **Iterate** on prompts based on results

**Success Metrics:**
- Fewer review findings over time
- Higher test coverage automatically
- Less rework after code review
- Faster feature velocity

**Continuous Improvement:**
- Document patterns that work
- Share failed prompts and fixes
- Update this guide as you learn
- Track metrics to measure improvement

---

**Related Documents:**
- [Development Standards](DEVELOPMENT_STANDARDS.md)
- [Process Improvements](../PROCESS_IMPROVEMENTS.md)
- [Lessons Learned](../LESSONS_LEARNED.md)

**Maintained by:** Development Team  
**Last Updated:** April 18, 2026
