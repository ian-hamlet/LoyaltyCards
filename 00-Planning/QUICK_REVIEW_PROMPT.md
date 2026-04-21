# Quick Reference: Comprehensive Code Review Prompt

**File:** For quick copy-paste when you need deep security review  
**Last Updated:** 21 April 2026

---

## The Prompt (Copy This Exactly)

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

## What This Catches

**v0.3.1 Review (Using This Prompt):**
- ✅ SEC-001: Hardcoded HMAC key
- ✅ SEC-002: Non-constant-time comparison
- ✅ ERROR-001: TransactionRepository no error handling
- ✅ TEST-001/002: No tests for HP fixes

**v0.3.0 Review (Without This Prompt):**
- ❌ Missed all of the above

---

## When to Use

**REQUIRED before:**
- TestFlight deployment
- Production release
- Merging security-related code

**OPTIONAL for:**
- In-progress development
- Small UI changes
- Documentation updates

---

**See:** [CODE_REVIEW_PROMPT_TEMPLATE.md](CODE_REVIEW_PROMPT_TEMPLATE.md) for full explanation and variations
