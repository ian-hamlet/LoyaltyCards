# AI Agent Response Guidelines

**Project:** LoyaltyCards  
**Purpose:** Standard formatting for AI agent responses  
**Created:** 2026-04-22  
**Status:** Active

---

## Overview

This document defines how AI agents should format responses when working on the LoyaltyCards project. These guidelines help maintain consistency and improve knowledge transfer across development sessions.

**Key Goal:** Help developers learn and navigate the project structure through clear, consistent responses.

---

## File Location Format

### ⭐ Primary Rule: Always Show Folder Structure

When referencing files, **ALWAYS include the folder path**, not just the filename.

#### ❌ DON'T Do This
```
The file is: APP_STORE_SUBMISSION_CHECKLIST.md
See NEXT_ACTIONS.md for details
Located in: DECISION_P2P_Architecture.md
```

**Problem:** Doesn't help learn where things are organized. Filename alone provides no context.

#### ✅ DO This Instead

**Format 1: Explicit Folder + File**
```
Folder: docs/deployment/
File: APP_STORE_SUBMISSION_CHECKLIST.md

Folder: docs/project-management/
File: NEXT_ACTIONS.md

Folder: docs/technical/Architecture/
File: DECISION_P2P_Architecture.md
```

**Format 2: Full Path (preferred for multiple files)**
```
- docs/deployment/APP_STORE_SUBMISSION_CHECKLIST.md
- docs/project-management/NEXT_ACTIONS.md
- docs/technical/Architecture/DECISION_P2P_Architecture.md
```

**Format 3: Markdown Links with Folder Context**
```
**Folder:** `docs/deployment/`  
**File:** [APP_STORE_SUBMISSION_CHECKLIST.md](docs/deployment/APP_STORE_SUBMISSION_CHECKLIST.md)
```

---

## Directory Structure Visualization

When explaining where multiple related files are located, use **tree format**:

### ✅ Good Example

```
docs/
├── deployment/          ← All App Store & TestFlight docs
│   ├── APP_STORE_SUBMISSION_CHECKLIST.md
│   ├── TESTFLIGHT_DEPLOYMENT_GUIDE.md
│   ├── TESTFLIGHT_TESTING_GUIDE.md
│   └── RELEASES.md
│
├── project-management/  ← Planning, requirements, tracking
│   ├── NEXT_ACTIONS.md
│   ├── DEFECT_TRACKER.md
│   └── Requirements/
│       └── *.md
│
└── technical/          ← Architecture, database, security
    ├── Architecture/
    │   ├── DECISION_P2P_Architecture.md
    │   └── DECISION_Flutter_Framework.md
    └── DATABASE_SCHEMA.md
```

### Key Elements

1. **Use tree characters** (`├──`, `└──`, `│`) for visual hierarchy
2. **Add descriptions** with `←` to explain each folder's purpose
3. **Show relevant files** in context, not exhaustive listings
4. **Group related items** under their parent folder

---

## Multiple File References

When listing multiple related documents, **group by folder**:

### ✅ Good Example

```
## Documentation Locations

### App Store Submission
**Folder:** `docs/deployment/`
- APP_STORE_SUBMISSION_CHECKLIST.md (start here)
- TESTFLIGHT_DEPLOYMENT_GUIDE.md
- TESTFLIGHT_TESTING_GUIDE.md

### Privacy & Legal
**Folder:** `docs/legal/`
- PRIVACY_POLICY.md
- TERMS_OF_SERVICE.md
- ACCESSIBILITY_STATEMENT.md

### Architecture Decisions
**Folder:** `docs/technical/Architecture/`
- DECISION_P2P_Architecture.md
- DECISION_Flutter_Framework.md
```

---

## Source Code References

For source code files, include the module context:

### ✅ Good Example

```
**Module:** `source/shared/`
**File:** `lib/models/qr_tokens.dart`
**Path:** source/shared/lib/models/qr_tokens.dart

**Module:** `source/customer_app/`
**File:** `lib/services/card_repository.dart`
**Path:** source/customer_app/lib/services/card_repository.dart
```

---

## Rationale: Why This Matters

### 1. Learning Project Structure
Showing folders repeatedly reinforces the organizational logic:
- `docs/deployment/` = deployment-related docs
- `docs/project-management/` = planning and tracking
- `docs/technical/` = architecture and technical specs

### 2. Faster Navigation
Developers can immediately locate files:
- "I need deployment docs" → look in `docs/deployment/`
- "I need requirements" → look in `docs/project-management/Requirements/`

### 3. Reduced Follow-Up Questions
Clear folder context eliminates questions like:
- "Where is that file?"
- "Which folder has the X document?"
- "Is there a Y document somewhere?"

### 4. Context Awareness
Folders provide semantic meaning:
- `docs/legal/` indicates legally binding content
- `docs/quality/` indicates testing/review content
- `source/shared/` indicates shared library code

---

## Special Cases

### Root-Level Files

For files at project root, explicitly state "project root":

```
**Location:** Project root
**File:** README.md
**Path:** README.md

**Location:** Project root
**File:** CHANGELOG.md
**Path:** CHANGELOG.md
```

### Generated/Build Files

For generated files, indicate their temporary nature:

```
**Location:** Generated (not in git)
**Path:** source/customer_app/.dart_tool/
**Note:** These files are auto-generated during build
```

---

## Quick Reference Card

```
✅ DO:
- Show folder path with every file reference
- Use tree diagrams for directory structure
- Group multiple files by folder
- Add folder descriptions with ←

❌ DON'T:
- Show just filename without path
- List files alphabetically across folders
- Assume user knows folder structure
- Use ambiguous "see X.md" without path
```

---

## Integration with Development Workflow

### In Code Reviews
When suggesting file changes, include folder:
```
Update error handling in:
- source/customer_app/lib/services/card_repository.dart
- source/supplier_app/lib/services/key_manager.dart
```

### In Issue Tracking
When referencing related documentation:
```
See acceptance criteria in:
- docs/project-management/Requirements/REQ-004_Zero_Entry_Card_Issuance.md
```

### In Onboarding
When introducing project structure:
```
Start by reading these files in order:
1. README.md (project root)
2. docs/project-management/NEXT_ACTIONS.md
3. docs/technical/Architecture/DECISION_P2P_Architecture.md
4. source/README.md
```

---

## AI Agent Behavior Preferences

### Terminal Command Execution

**⚠️ IMPORTANT: Always ask for permission before executing terminal commands.**

- Do not automatically run commands with `run_in_terminal` tool
- Request user confirmation first before executing any terminal operations
- This applies to **all commands**, including read-only operations like `git status`, `ls`, `cat`, etc.
- User must explicitly approve each command execution

**Rationale:** Gives users control over what commands run in their environment and prevents unintended side effects.

---

### Git Commit Workflow

**⚠️ IMPORTANT: Never automatically commit changes to git.**

- Do **not** run `git add`, `git commit`, or `git push` automatically
- User manages their own git workflow and commit timing
- User will explicitly request git operations when ready

**Helpful Reminders:**
- If significant file changes have been made and no git operations mentioned, you may gently remind: "You have uncommitted changes - would you like to stage and commit them?"
- Appropriate times to remind:
  - After completing a major feature or fix
  - After multiple file edits across a session
  - When user asks "what's next?" or similar wrap-up questions
- Do not nag repeatedly - once per work session is sufficient

**Rationale:** Users have their own commit strategies and timing preferences. Some prefer atomic commits, others batch multiple changes. Respect the user's workflow.

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-04-22 | Initial guidelines created |
| 1.1 | 2026-04-22 | Added AI Agent Behavior Preferences section |
| 1.2 | 2026-04-22 | Added Git Commit Workflow preferences |

---

**Maintained by:** Development Team  
**Last Updated:** April 22, 2026

---

## Related Documents

**Folder:** `docs/development/`
- AI_PROMPTING_GUIDE.md - Patterns for generating quality code
- DEVELOPMENT_STANDARDS.md - Coding standards and conventions
- CODE_REVIEW_PROMPT_TEMPLATE.md - Code review templates
