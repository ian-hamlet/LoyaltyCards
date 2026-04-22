# Code Review Prompt Template
## Comprehensive Security & Quality Analysis

**Purpose:** Trigger deep-dive code review that catches security vulnerabilities, error handling gaps, and code quality issues (not just design patterns).

**Last Updated:** 21 April 2026  
**Proven Effective:** v0.3.1 review found SEC-001, SEC-002, ERROR-001 that v0.3.0 missed

---

## The Complete Prompt

Use this exact wording to trigger comprehensive analysis:

```
Conduct a comprehensive expert-level code review of the entire codebase including:

1. SECURITY AUDIT - Deep analysis of:
   - Cryptographic operations (key generation, storage, signatures, HMAC)
   - Authentication mechanisms (biometric, passcode)
   - Authorization and access control
   - Data backup and recovery security
   - Timing attack vulnerabilities
   - Hardcoded secrets or keys
   - Input validation on security-critical operations
   - Key exposure in logs or error messages

2. ERROR HANDLING AUDIT - Systematic scan for:
   - Missing try-catch blocks
   - Empty catch blocks or silent failures
   - Database operations without error handling
   - Network operations without timeout or error handling
   - Async operations without error handling
   - Raw exceptions exposed to users
   - Missing error logging
   - No user feedback on failures

3. CODE QUALITY ANALYSIS - Search for:
   - TODO, FIXME, HACK, XXX comments
   - Dead code or commented-out code
   - Debug print statements (print, debugPrint)
   - Inconsistent error handling patterns
   - Missing input validation
   - Magic numbers or hardcoded values
   - Code duplication

4. TEST COVERAGE VERIFICATION - Check:
   - Which source files have corresponding test files
   - Critical operations without test coverage
   - New features added without tests
   - Security-critical code without tests
   - Error handling paths without tests

5. COMPREHENSIVE FINDINGS REPORT - Generate:
   - CRITICAL issues (security vulnerabilities, data loss risks)
   - HIGH priority issues (crashes, silent failures, poor UX)
   - MEDIUM priority issues (code smells, maintainability)
   - Positive findings (what's done well)
   - Specific file paths and line numbers
   - Attack scenarios for security issues
   - Recommended fixes with code examples
   - Estimated fix time for each issue

Focus on production readiness, not just code style. Assume this code is about to ship to customers.
```

---

## Why This Prompt Works

### Key Phrases That Trigger Deep Analysis

1. **"comprehensive expert-level"** - Signals this is not a quick review
2. **"including:" with numbered list** - Forces systematic coverage
3. **"SECURITY AUDIT - Deep analysis"** - Triggers crypto security subagent
4. **"ERROR HANDLING AUDIT - Systematic scan"** - Triggers error handling subagent
5. **"entire codebase"** - Prevents limiting scope to changed files
6. **"production readiness"** - Changes mindset from "does it work" to "is it safe"
7. **"about to ship to customers"** - Increases scrutiny level

### What Makes This Different From v0.3.0 Prompt

**v0.3.0 Prompt (what was used):**
```
"Review the code and identify high-priority issues"
```
- ❌ No mention of security
- ❌ No mention of error handling audit
- ❌ No mention of cryptographic analysis
- ❌ Focused on finding "next tasks" not "all issues"

**v0.3.1 Prompt (what should be used):**
```
"Conduct comprehensive expert-level code review of entire codebase including security audit..."
```
- ✅ Explicitly requests security audit
- ✅ Explicitly requests error handling scan
- ✅ Lists specific vulnerability types to search for
- ✅ Requests complete findings, not just top 3

---

## When to Use This Prompt

### Required Before:
- ✅ Any TestFlight deployment
- ✅ Any production release
- ✅ Major feature merges to develop/main
- ✅ After implementing security-related code
- ✅ After implementing database/backup code
- ✅ After implementing cryptographic operations

### Optional (Can Use Lighter Review):
- Code review during active development (use pattern-based review)
- Reviewing small UI changes
- Reviewing documentation updates
- Reviewing test additions

---

## Customization for Specific Contexts

### For New Feature Review (Before Merge)

Add to the prompt:
```
Additionally, verify that:
- All new code has corresponding tests
- New features have user documentation
- Breaking changes are documented
- Migration path exists for existing data
```

### For Security-Critical Code Review

Add to the prompt:
```
Pay special attention to:
- Attack surface analysis (what can an attacker control?)
- Privilege escalation possibilities
- Data exfiltration vectors
- Replay attack vulnerabilities
- Man-in-the-middle attack vectors
```

### For Pre-Production Release Review

Add to the prompt:
```
Additionally assess:
- Rollback procedures if deployment fails
- Data migration safety (can we roll back schema changes?)
- Error monitoring and alerting capabilities
- User data backup and recovery procedures
- Support team documentation for common issues
```

---

## What You'll Get Back

### Expected Output Structure

1. **Executive Summary**
   - Overall assessment score
   - Critical issues count
   - High/Medium/Low breakdown
   - Production readiness verdict

2. **Critical Issues Section**
   - Each issue with:
     - Severity rating
     - File path and line number
     - Code snippet showing the problem
     - Attack scenario or failure mode
     - Recommended fix with code example
     - Estimated fix time

3. **Security Audit Results**
   - Cryptographic implementation review
   - Authentication/authorization review
   - Data protection review
   - Attack vector analysis

4. **Error Handling Audit Results**
   - Missing error handling locations
   - Silent failure patterns
   - User-facing error quality
   - Logging completeness

5. **Test Coverage Analysis**
   - Files without tests
   - Critical paths untested
   - Test quality assessment

6. **Positive Findings**
   - What's implemented correctly
   - Best practices followed
   - Security measures that work well

7. **Actionable Recommendations**
   - Prioritized fix list
   - Phase-based implementation plan
   - Time estimates

---

## Example: Triggering the Review

### In Chat Interface

```
Conduct a comprehensive expert-level code review of the entire codebase including:

1. SECURITY AUDIT - Deep analysis of:
   - Cryptographic operations (key generation, storage, signatures, HMAC)
   - Authentication mechanisms (biometric, passcode)
   - Authorization and access control
   - Data backup and recovery security
   - Timing attack vulnerabilities
   - Hardcoded secrets or keys
   - Input validation on security-critical operations
   - Key exposure in logs or error messages

[... rest of template ...]

Focus on production readiness, not just code style. Assume this code is about to ship to customers.
```

### Expected Response

The agent will:
1. Launch crypto security subagent (searches for SEC-001, SEC-002 type issues)
2. Launch error handling subagent (searches for ERROR-001 type issues)
3. Perform code quality scans (TODO, print statements, etc.)
4. Analyze test coverage by file count
5. Generate comprehensive report with specific issues

---

## Comparison: Quick vs. Comprehensive Review

### Pattern-Based Review (Quick - 30 min)

**Prompt:** "Review this code and suggest improvements"

**Result:**
- Finds obvious code smells
- Identifies design pattern issues
- Quick turnaround
- **Misses:** Security issues, error handling gaps, untested code

**Use for:** In-progress development, quick feedback

---

### Comprehensive Security Review (Deep - 2-3 hours)

**Prompt:** Use full template above

**Result:**
- Finds security vulnerabilities (SEC-001, SEC-002)
- Finds error handling gaps (ERROR-001)
- Finds test coverage gaps (TEST-001, TEST-002)
- Generates detailed report with fixes
- **Catches:** Everything pattern-based review misses

**Use for:** Pre-release, security-critical code, production readiness

---

## Integration with Development Workflow

### Recommended Process

```
Feature Development:
├─ 1. Implement feature
├─ 2. Write tests
├─ 3. Pattern-based review ← Quick feedback
│    └─ Prompt: "Review for code quality and best practices"
├─ 4. Fix identified issues
├─ 5. Create pull request
└─ 6. Comprehensive security review ← Before merge
     └─ Prompt: Use full template from this document
```

### Pre-Release Checklist

```
Before TestFlight/Production:
☐ Run full comprehensive review (use template)
☐ Address all CRITICAL issues
☐ Address all HIGH issues
☐ Document any MEDIUM issues accepted as technical debt
☐ Verify all security-critical code has tests
☐ Verify error handling in all user-facing operations
```

---

## Template Variations

### For Flutter/Dart Specific Review

Add to prompt:
```
Additionally, check Flutter/Dart specific issues:
- Proper use of async/await (avoid blocking UI)
- Memory leaks (unsubscribed streams, controllers)
- Build performance (unnecessary rebuilds)
- Platform-specific code properly isolated
- Proper disposal of resources
```

### For Database-Heavy Code

Add to prompt:
```
Additionally, check database operations:
- Transactions properly scoped
- Indexes on frequently queried columns
- N+1 query problems
- Connection pooling and limits
- Migration rollback procedures tested
```

### For Cryptographic Code

Add to prompt:
```
Additionally, check cryptographic operations:
- Key sizes meet current standards (256-bit minimum)
- Algorithms are current (no MD5, SHA1, DES)
- Random number generation is cryptographically secure
- Keys never logged or exposed in errors
- Constant-time comparison for secrets
- Proper key derivation functions used
```

---

## Measuring Review Quality

### How to Know if Review Was Comprehensive

A comprehensive review should find:
- ✅ At least 2-3 security considerations (even if "done correctly")
- ✅ At least 3-5 error handling issues or confirmations
- ✅ Test coverage gaps
- ✅ Specific line numbers and file paths
- ✅ Code examples of recommended fixes
- ✅ Both problems AND positive findings

If review only says "looks good" → **Not comprehensive enough**

If review finds 10+ issues → **Probably comprehensive** (unless codebase is very small)

---

## Common Mistakes to Avoid

### ❌ Don't Do This

**Vague Prompt:**
```
"Review my code"
```
**Result:** Generic, surface-level feedback

**Too Specific:**
```
"Check if BackupStorageService has error handling"
```
**Result:** Only reviews that one file, misses issues elsewhere

**Pattern-Only:**
```
"Find code smells and anti-patterns"
```
**Result:** Misses security issues (SEC-001, SEC-002 type)

### ✅ Do This

**Comprehensive Prompt:**
```
[Use full template from this document]
```
**Result:** Finds security, error handling, quality issues across entire codebase

---

## Version History

### v1.0 - Initial Template (21 April 2026)
- Created based on lessons learned from v0.3.0 vs v0.3.1 review comparison
- Proven to catch SEC-001, SEC-002, ERROR-001 type issues
- Includes security audit, error handling audit, code quality scan
- Designed for production readiness assessment

### Future Enhancements (Planned)
- Add performance analysis section
- Add accessibility audit section
- Add internationalization readiness check
- Add monitoring/observability assessment

---

## Summary

**Use this prompt template whenever you need:**
- Security-critical code reviewed
- Pre-release production readiness check
- Verification that AI-generated code is safe
- Comprehensive audit before deployment

**The key difference:**
- **Pattern-based review** → "Are there code smells?"
- **Comprehensive security review** → "Is this safe to ship?"

**This template ensures** you get the v0.3.1 level of scrutiny (finds SEC-001, SEC-002, ERROR-001) instead of the v0.3.0 level (misses security issues).

---

**To use right now, copy the "Complete Prompt" section and paste it verbatim.**
