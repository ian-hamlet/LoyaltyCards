# Feedback Change Tracker

**Document Version:** 1.0  
**Created:** 2026-07-03  
**Current App Version:** v1.0.1+7  
**Purpose:** Track testing feedback and ensure customer/supplier code updates include required user and maintenance documentation updates.

---

## How To Use

1. Add one entry for each testing comment, bug report, or enhancement request.
2. Link the entry to customer/supplier code changes and defect IDs where applicable.
3. Complete the documentation impact checklist before marking an item done.
4. Update related documents in the same PR/commit as the code change when possible.

---

## Entry Template

Copy this template for each new feedback item:

```markdown
### FB-XXX: [Short title]
- Date Logged: YYYY-MM-DD
- Source: TestFlight | Internal testing | App Store review | Direct user feedback
- App Scope: Customer | Supplier | Shared | Both
- Priority: P0 | P1 | P2 | P3
- Linked Defect: CR-XXX | TEST-XXX | N/A
- Summary: [One sentence]
- Reproduction/Context: [Steps or scenario]
- Proposed Code Change: [What will change]
- Status: Backlog | In Progress | Ready for Test | Done

Documentation Impact Checklist
- [ ] User docs reviewed
  - [ ] docs/user/USER_GUIDE.md updated if user flow changed
  - [ ] docs/user/SUPPLIER_SETUP_GUIDE.md updated if supplier setup changed
  - [ ] docs/user/ABOUT_LOYALTYCARDS.md updated if feature messaging changed
- [ ] Maintenance docs reviewed
  - [ ] docs/deployment/SUPPORT_PROCEDURES.md updated if support steps changed
  - [ ] docs/deployment/TESTFLIGHT_TESTING_GUIDE.md updated if test cases changed
  - [ ] docs/project-management/DEFECT_TRACKER.md updated if defect status changed
  - [ ] docs/project-management/NEXT_ACTIONS.md updated if priorities changed
- [ ] Version metadata checked where relevant
  - [ ] DOCUMENTATION_INDEX.md metadata aligned
  - [ ] Release/build references aligned with source/shared/pubspec.yaml

Verification
- [ ] Customer app behavior verified
- [ ] Supplier app behavior verified
- [ ] Related docs reviewed by maintainer
```

---

## Active Feedback Items

### FB-001: Post-testing update intake (July 2026)
- Date Logged: 2026-07-03
- Source: Internal testing follow-up
- App Scope: Both
- Priority: P1
- Linked Defect: N/A (intake phase)
- Summary: Batch of new testing comments requires coordinated updates to customer/supplier systems and docs.
- Reproduction/Context: Returning after a testing period with pending updates and comments.
- Proposed Code Change: To be populated as each item is triaged.
- Status: Ready for Test

Documentation Impact Checklist
- [x] User docs reviewed
  - [x] docs/user/USER_GUIDE.md metadata aligned to current release candidate
  - [ ] docs/user/SUPPLIER_SETUP_GUIDE.md reviewed after supplier changes are finalized
  - [ ] docs/user/ABOUT_LOYALTYCARDS.md reviewed after messaging-impacting changes
- [x] Maintenance docs reviewed
  - [x] docs/deployment/SUPPORT_PROCEDURES.md metadata aligned to current release candidate
  - [ ] docs/deployment/TESTFLIGHT_TESTING_GUIDE.md update pending per finalized feedback fixes
  - [ ] docs/project-management/DEFECT_TRACKER.md update pending after defects are logged
  - [ ] docs/project-management/NEXT_ACTIONS.md update pending after prioritization
- [x] Version metadata checked where relevant
  - [x] DOCUMENTATION_INDEX.md metadata aligned
  - [x] Release/build references checked against source/shared/pubspec.yaml (1.0.1+7)

Verification
- [ ] Customer app behavior verified (pending code updates)
- [ ] Supplier app behavior verified (pending code updates)
- [ ] Related docs reviewed by maintainer

### FB-002: Rename operation mode label from Simple to Express
- Date Logged: 2026-07-03
- Source: Direct user feedback
- App Scope: Both
- Priority: P1
- Linked Defect: N/A
- Summary: Replace user-facing "Simple" mode wording with "Express" while preserving compatibility with existing stored/QR mode values.
- Reproduction/Context: Current customer and supplier UIs present two modes as "Simple" and "Secure". Business intent is that the fast trust-based workflow should be called "Express".
- Proposed Code Change:
  - Update shared mode display labels/descriptions to use "Express Mode".
  - Keep backward compatibility by accepting legacy `simple` mode values during parsing.
  - Write new mode values as `express` where mode strings are serialized.
  - Update explicit screen copy in both apps from "Simple" to "Express".
  - Keep compatibility for existing generic stamp token IDs by accepting both legacy and new discriminator values.
- Status: In Progress

Documentation Impact Checklist
- [ ] User docs reviewed
  - [ ] docs/user/USER_GUIDE.md replace user-facing "Simple Mode" with "Express Mode"
  - [ ] docs/user/SUPPLIER_SETUP_GUIDE.md replace supplier-facing "Simple Mode" references with "Express Mode"
  - [ ] docs/user/ABOUT_LOYALTYCARDS.md update mode naming and comparison tables
- [ ] Maintenance docs reviewed
  - [ ] docs/deployment/TESTFLIGHT_TESTING_GUIDE.md update test steps and expected labels
  - [ ] docs/project-management/DEFECT_TRACKER.md note naming migration for mode terminology
  - [ ] docs/project-management/NEXT_ACTIONS.md update mode wording in current phase summary
  - [ ] docs/deployment/SUPPORT_PROCEDURES.md update support macros or troubleshooting text if mode names are mentioned
- [ ] Version metadata checked where relevant
  - [ ] DOCUMENTATION_INDEX.md unchanged unless new migration note doc is added
  - [ ] Release/build references aligned with source/shared/pubspec.yaml after implementation completes

Verification
- [ ] Customer app behavior verified (labels and flow copy show "Express")
- [ ] Supplier app behavior verified (labels and flow copy show "Express")
- [ ] Legacy data compatibility verified (`simple` records still parse correctly)
- [ ] Related docs reviewed by maintainer

### FB-003: Remove "Save to Photos" option for QR code exports
- Date Logged: 2026-07-03
- Source: Direct user feedback
- App Scope: Supplier
- Priority: P2
- Linked Defect: N/A
- Summary: Remove the "Save to Photos" export path for QR codes and keep only supported/share-based options.
- Reproduction/Context: Supplier QR export actions currently include a Photos save option. Requirement is to remove this option from available QR save/share actions.
- Proposed Code Change:
  - Remove "Save to Photos" button/action from supplier QR export UI flows.
  - Remove/deprecate related service calls and user feedback messages tied to Photos saves.
  - Keep remaining export paths (Print, Share via Email, Save to Files) intact.
  - Ensure no photo-library permission messaging remains in affected flows.
- Status: Backlog

Documentation Impact Checklist
- [ ] User docs reviewed
  - [ ] docs/user/USER_GUIDE.md remove or revise any "Save to Photos" QR instructions
  - [ ] docs/user/SUPPLIER_SETUP_GUIDE.md remove Photos-based QR export guidance
  - [ ] docs/user/ABOUT_LOYALTYCARDS.md adjust feature messaging if Photos export is mentioned
- [ ] Maintenance docs reviewed
  - [ ] docs/deployment/TESTFLIGHT_TESTING_GUIDE.md update test cases and expected export options
  - [ ] docs/deployment/SUPPORT_PROCEDURES.md remove Photos troubleshooting steps where applicable
  - [ ] docs/project-management/DEFECT_TRACKER.md add/update implementation status once change starts
  - [ ] docs/project-management/NEXT_ACTIONS.md update only if prioritization changes
- [ ] Version metadata checked where relevant
  - [ ] Release/build references aligned with source/shared/pubspec.yaml after implementation

Verification
- [ ] Supplier app behavior verified (Photos option no longer shown)
- [ ] Remaining export options verified (Print, Email/Share, Files)
- [ ] No Photos permission prompts appear in updated QR export flows
- [ ] Related docs reviewed by maintainer

### FB-004: Fix non-functional info icons in supplier onboarding
- Date Logged: 2026-07-03
- Source: Direct user feedback
- App Scope: Supplier
- Priority: P2
- Linked Defect: N/A
- Summary: Info icons next to "Stamps Required" and "Customer Scan Cooldown" appear tappable but currently provide no user feedback.
- Reproduction/Context: In supplier onboarding/configuration UI, tapping the info icons beside these two settings does not show explanatory content.
- Proposed Code Change:
  - Wire both info icons to working tooltip/help behavior.
  - Ensure consistent behavior with other help icons in app (tap target, timing, accessibility semantics).
  - Add clear explanatory text for both settings.
- Implementation Notes:
  - Implemented in `source/supplier_app/lib/screens/supplier/supplier_onboarding.dart`.
  - Both Operation Mode and Customer Scan Cooldown icons now use tap-triggered tooltips with updated explanatory text.
  - Tooltip behavior uses `TooltipTriggerMode.tap` and a 10-second display duration.
- Status: Ready for Test

Documentation Impact Checklist
- [ ] User docs reviewed
  - [ ] docs/user/SUPPLIER_SETUP_GUIDE.md add/clarify explanations for Stamps Required and Customer Scan Cooldown
  - [ ] docs/user/USER_GUIDE.md update supplier setup guidance if wording changes
  - [ ] docs/user/ABOUT_LOYALTYCARDS.md update only if feature messaging changes
- [ ] Maintenance docs reviewed
  - [ ] docs/deployment/TESTFLIGHT_TESTING_GUIDE.md include tap-test for both onboarding info icons
  - [ ] docs/deployment/SUPPORT_PROCEDURES.md add troubleshooting note if users report missing help tips
  - [ ] docs/project-management/DEFECT_TRACKER.md add/update status once implementation starts
  - [ ] docs/project-management/NEXT_ACTIONS.md update only if prioritization changes
- [ ] Version metadata checked where relevant
  - [ ] Release/build references aligned with source/shared/pubspec.yaml after implementation

Verification
- [ ] Supplier app behavior verified (both info icons show expected guidance)
- [ ] Accessibility verified (icons are discoverable and labeled)
- [ ] UI consistency verified against existing help/tooltip patterns
- [ ] Related docs reviewed by maintainer

### FB-005: Update supplier setup heading to "Loyalty Scheme"
- Date Logged: 2026-07-03
- Source: Direct user feedback
- App Scope: Supplier
- Priority: P3
- Linked Defect: N/A
- Summary: Change onboarding heading text from "Configure Your Customer Loyalty Cards" to "Configure Your Customer Loyalty Scheme".
- Reproduction/Context: Supplier business setup screen title language should use "Loyalty Scheme" terminology.
- Proposed Code Change:
  - Update `AppConstants.supplierAppName` text value in shared constants.
  - Verify onboarding screen renders updated heading.
- Implementation Notes:
  - Implemented in `source/shared/lib/constants/constants.dart`.
  - Updated `supplierAppName` to "Configure Your Customer Loyalty Scheme".
- Status: Ready for Test

Documentation Impact Checklist
- [ ] User docs reviewed
  - [ ] docs/user/SUPPLIER_SETUP_GUIDE.md wording aligned with "Loyalty Scheme" terminology if needed
  - [ ] docs/user/USER_GUIDE.md wording aligned if setup heading is referenced
  - [ ] docs/user/ABOUT_LOYALTYCARDS.md update only if marketing copy mirrors onboarding heading
- [ ] Maintenance docs reviewed
  - [ ] docs/deployment/TESTFLIGHT_TESTING_GUIDE.md update expected heading text if captured in test steps
  - [ ] docs/project-management/DEFECT_TRACKER.md update only if tracked as a formal defect
  - [ ] docs/project-management/NEXT_ACTIONS.md update only if language standardization is tracked there
  - [ ] docs/deployment/SUPPORT_PROCEDURES.md update only if macros reference this exact heading
- [ ] Version metadata checked where relevant
  - [ ] Release/build references aligned with source/shared/pubspec.yaml after implementation

Verification
- [ ] Supplier app behavior verified (onboarding heading shows "Configure Your Customer Loyalty Scheme")
- [ ] Related docs reviewed by maintainer

### FB-006: Supplier home redeem wording should be mode-sensitive
- Date Logged: 2026-07-03
- Source: Direct user feedback
- App Scope: Supplier
- Priority: P2
- Linked Defect: N/A
- Summary: Redeem quick-action subtitle and How It Works redemption text should adapt to operation mode.
- Reproduction/Context: Supplier home currently used scan-centric redemption copy even for Express mode where the customer shows a completed card.
- Proposed Code Change:
  - In supplier home quick actions, show Express-mode subtitle: "Customer shows completed card for redemption".
  - In supplier home How It Works step 3, use mode-sensitive redemption explanation.
- Implementation Notes:
  - Implemented in `source/supplier_app/lib/screens/supplier/supplier_home.dart`.
  - Quick Action Redeem subtitle now branches on mode.
  - How It Works step 3 description now branches on mode.
- Status: Ready for Test

Documentation Impact Checklist
- [ ] User docs reviewed
  - [ ] docs/user/USER_GUIDE.md align supplier redemption wording with mode-specific flow
  - [ ] docs/user/SUPPLIER_SETUP_GUIDE.md align redemption instructions for Express vs Secure
  - [ ] docs/user/ABOUT_LOYALTYCARDS.md update only if feature messaging mirrors these exact phrases
- [ ] Maintenance docs reviewed
  - [ ] docs/deployment/TESTFLIGHT_TESTING_GUIDE.md include mode-specific wording checks on supplier home
  - [ ] docs/project-management/DEFECT_TRACKER.md update only if tracked as a formal defect
  - [ ] docs/project-management/NEXT_ACTIONS.md update only if wording standardization is tracked there
  - [ ] docs/deployment/SUPPORT_PROCEDURES.md update only if macros reference these specific screen phrases
- [ ] Version metadata checked where relevant
  - [ ] Release/build references aligned with source/shared/pubspec.yaml after implementation

Verification
- [ ] Supplier app behavior verified (Express mode shows customer-presents-card wording)
- [ ] Supplier app behavior verified (Secure mode retains scan-for-validation wording)
- [ ] Related docs reviewed by maintainer

### FB-007: Improve dark-mode visibility on supplier issue/new-card, Generate QR action text, and How It Works info boxes
- Date Logged: 2026-07-03
- Source: Direct user feedback
- App Scope: Supplier
- Priority: P2
- Linked Defect: N/A
- Summary: Hints/tips on Issue New Card, subtitle text for Generate QR action, and the three How It Works info-box headings/body text were hard to read in dark mode due to light-theme color assumptions.
- Reproduction/Context: On dark theme, fixed light-palette colors reduced contrast in hint/info blocks, quick-action subtitle text, and informational panel content.
- Proposed Code Change:
  - Replace hardcoded neutral/accent text colors in supplier issue-card hint panels with theme-aware color scheme values.
  - Replace hardcoded quick-action subtitle color in supplier home action cards with theme-aware color.
  - Update How It Works info-box heading/body text to use container-appropriate `on*Container` colors.
  - Keep functional behavior unchanged while improving readability.
- Implementation Notes:
  - Implemented in `source/supplier_app/lib/screens/supplier/supplier_issue_card.dart`, `source/supplier_app/lib/screens/supplier/supplier_home.dart`, and `source/supplier_app/lib/screens/supplier/how_it_works.dart`.
  - Issue-card subtitle/description text and expiry/info panel now use `Theme.of(context).colorScheme` colors.
  - Quick action subtitle text now uses `onSurfaceVariant` for consistent contrast in light/dark mode.
  - How It Works info boxes now use `onPrimaryContainer`, `onSecondaryContainer`, and `onTertiaryContainer` for heading/body readability.
- Status: Ready for Test

Documentation Impact Checklist
- [ ] User docs reviewed
  - [ ] docs/user/USER_GUIDE.md update only if dark-mode behavior is explicitly documented
  - [ ] docs/user/SUPPLIER_SETUP_GUIDE.md add note only if visual guidance screenshots/text need refresh
  - [ ] docs/user/ABOUT_LOYALTYCARDS.md update only if UI screenshot/copy references affected styles
- [ ] Maintenance docs reviewed
  - [ ] docs/deployment/TESTFLIGHT_TESTING_GUIDE.md add dark-mode readability checks for supplier issue/new-card flow
  - [ ] docs/project-management/DEFECT_TRACKER.md update only if tracked as formal defect entry
  - [ ] docs/project-management/NEXT_ACTIONS.md update only if accessibility/UX polish priorities are adjusted
  - [ ] docs/deployment/SUPPORT_PROCEDURES.md update only if support scripts mention these specific visuals
- [ ] Version metadata checked where relevant
  - [ ] Release/build references aligned with source/shared/pubspec.yaml after implementation

Verification
- [ ] Supplier app behavior verified in dark mode (Issue New Card hints/tips readable)
- [ ] Supplier app behavior verified in dark mode (Generate QR quick-action subtitle readable)
- [ ] Supplier app behavior verified in dark mode (How It Works info-box headings/body readable)
- [ ] Supplier app behavior verified in light mode (no contrast regressions)
- [ ] Related docs reviewed by maintainer

### FB-008: Expand How It Works steps with mode guidance and backup emphasis
- Date Logged: 2026-07-03
- Source: Direct user feedback
- App Scope: Supplier
- Priority: P2
- Linked Defect: N/A
- Summary: Add explicit Express vs Secure guidance to Step 1 and introduce a dedicated backup step highlighting key restoration importance after device change.
- Reproduction/Context: Existing How It Works flow did not explicitly explain mode choice in Step 1 and lacked an early step emphasizing backup importance for cryptographic key continuity.
- Proposed Code Change:
  - Extend Step 1 description with a concise Express vs Secure recommendation sentence.
  - Insert a new Step 2 focused on backup/recovery of business configuration and cryptographic keys.
  - Renumber subsequent steps accordingly.
- Implementation Notes:
  - Implemented in `source/supplier_app/lib/screens/supplier/how_it_works.dart`.
  - Step 1 now includes Express vs Secure wording.
  - New Step 2 added: "Back Up Your Business Configuration" with restore/key continuity messaging.
  - Existing steps shifted from 2/3/4 to 3/4/5.
  - Step 5 redemption description now explicitly explains Express (manual confirmation) vs Secure (QR scan + cryptographic verification) flow.
- Status: Ready for Test

Documentation Impact Checklist
- [ ] User docs reviewed
  - [ ] docs/user/SUPPLIER_SETUP_GUIDE.md align setup guidance with explicit mode-choice explanation and backup emphasis
  - [ ] docs/user/USER_GUIDE.md update only if supplier workflow steps are mirrored there
  - [ ] docs/user/ABOUT_LOYALTYCARDS.md update only if marketing flow overview includes step sequence
- [ ] Maintenance docs reviewed
  - [ ] docs/deployment/TESTFLIGHT_TESTING_GUIDE.md add/adjust validation checks for revised How It Works steps
  - [ ] docs/project-management/DEFECT_TRACKER.md update only if tracked as formal defect
  - [ ] docs/project-management/NEXT_ACTIONS.md update only if documentation refresh task is prioritized
  - [ ] docs/deployment/SUPPORT_PROCEDURES.md update only if support scripts reference old step wording/order
- [ ] Version metadata checked where relevant
  - [ ] Release/build references aligned with source/shared/pubspec.yaml after implementation

Verification
- [ ] Supplier app behavior verified (Step 1 includes mode-choice sentence)
- [ ] Supplier app behavior verified (new backup Step 2 present with key-restore guidance)
- [ ] Supplier app behavior verified (Step 5 includes detailed mode-specific redemption explanation)
- [ ] Supplier app behavior verified (step order is now 1-5 and copy reads correctly)
- [ ] Related docs reviewed by maintainer
