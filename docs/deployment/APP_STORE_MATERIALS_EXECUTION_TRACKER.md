# App Store Materials Execution Tracker

**Project:** LoyaltyCards iOS Public Launch (Customer + Supplier)
**Created:** 2026-06-11
**Target Submission Window:** 2026-06-25 to 2026-06-27
**Status:** In Progress

---

## Objective

Create and finalize all material required to submit both iOS apps to App Store Connect for review:

1. LoyaltyCards (Customer App)
2. LoyaltyCards Business (Supplier App)

This tracker is execution-focused and complements:
- APP_STORE_SUBMISSION_CHECKLIST.md
- APP_STORE_CONFIGURATION.md
- TESTFLIGHT_DEPLOYMENT_GUIDE.md
- V1_0_0_APP_STORE_LAUNCH_PLAN.md

---

## Roles

Assign one person to each role before execution starts.

- [ ] Release Owner: ____________________
- [ ] Metadata Owner: ____________________
- [ ] Screenshot Owner: ____________________
- [ ] Compliance Owner: ____________________
- [ ] Build/Upload Owner: ____________________
- [ ] Reviewer Communications Owner: ____________________

---

## Phase Plan and Timeline

## Phase 0 - Decisions Locked
**Window:** 2026-06-11 to 2026-06-12
**Goal:** Finalize all decisions that affect submission material.

### Tasks
- [ ] Confirm release version/build number policy for both apps
- [ ] Confirm Supplier app price tier
- [ ] Confirm release strategy (manual release after approval vs automatic)
- [ ] Confirm final app names/subtitles for both listings
- [ ] Confirm final support email/contact path

### Deliverables
- [ ] Decision log completed in this file (append below)

### Exit Criteria (Gate)
- [ ] No unresolved product/pricing/release-policy decisions

---

## Phase 1 - Legal and Public URLs
**Window:** 2026-06-12 to 2026-06-14
**Goal:** Produce all required public web links.

### Tasks
- [ ] Publish Privacy Policy page from docs/legal/PRIVACY_POLICY.md
- [ ] Publish Terms of Service page from docs/legal/TERMS_OF_SERVICE.md
- [ ] Publish Support page with support SLA and contact route
- [ ] Validate each URL on desktop and mobile
- [ ] Record canonical URLs in this tracker

### Deliverables
- [ ] Privacy URL: ____________________
- [ ] Terms URL: ____________________
- [ ] Support URL: ____________________
- [ ] Marketing URL (optional): ____________________

### Exit Criteria (Gate)
- [ ] All required URLs are publicly accessible without login
- [ ] No broken links or placeholder text

---

## Phase 2 - Metadata Finalization
**Window:** 2026-06-14 to 2026-06-16
**Goal:** Finalize all App Store textual content for both apps.

### Customer App Metadata Tasks
- [ ] App Name
- [ ] Subtitle
- [ ] Promotional Text
- [ ] Description
- [ ] Keywords
- [ ] Categories
- [ ] Age Rating responses
- [ ] App Review Notes

### Supplier App Metadata Tasks
- [ ] App Name
- [ ] Subtitle
- [ ] Promotional Text
- [ ] Description
- [ ] Keywords
- [ ] Categories
- [ ] Age Rating responses
- [ ] App Review Notes

### Deliverables
- [ ] Final copy-paste metadata packet created (Customer)
- [ ] Final copy-paste metadata packet created (Supplier)

### Exit Criteria (Gate)
- [ ] Character limits validated
- [ ] Messaging consistency validated across both apps
- [ ] Privacy/data-collection claims exactly match implementation

---

## Phase 3 - Screenshot Production and QA
**Window:** 2026-06-16 to 2026-06-20
**Goal:** Produce all required screenshot sets for both apps.

### Shot List Requirements
Each app requires:
- [ ] 6.7 inch set (5 screenshots)
- [ ] 6.5 inch set (5 screenshots)
- [ ] 5.5 inch set (5 screenshots)
- [ ] 12.9 inch iPad set (optional)

### Production Tasks
- [ ] Define deterministic data/setup state for each screen
- [ ] Capture screenshots in required dimensions
- [ ] Remove debug/dev indicators from all shots
- [ ] Verify readability and safe-area alignment
- [ ] Verify sequence tells a clear product story

### Deliverables
- [ ] Customer screenshots complete (15 required)
- [ ] Supplier screenshots complete (15 required)
- [ ] Screenshot naming convention applied

### Exit Criteria (Gate)
- [ ] 30/30 required screenshots approved
- [ ] Zero dimension mismatches
- [ ] Zero UI truncation issues

---

## Phase 4 - Compliance and Review Packet
**Window:** 2026-06-20 to 2026-06-22
**Goal:** Prepare all compliance answers and reviewer guidance.

### Tasks
- [ ] Complete export compliance answers for both apps
- [ ] Complete App Privacy questionnaire for both apps
- [ ] Finalize reviewer demo flow for two-app testing
- [ ] Finalize physical-device biometrics note
- [ ] Prepare response templates for common rejection reasons

### Deliverables
- [ ] Compliance answer sheet (both apps)
- [ ] App Review instruction sheet (both apps)
- [ ] Rejection response templates

### Exit Criteria (Gate)
- [ ] Compliance answers consistent with cryptography implementation
- [ ] Reviewer can execute full flow without backend credentials

---

## Phase 5 - Build Attachment Readiness
**Window:** 2026-06-22 to 2026-06-24
**Goal:** Attach production builds to complete listings and verify submission readiness.

### Tasks
- [ ] Increment versions/build numbers in both apps
- [ ] Create release branch snapshot
- [ ] Build and upload customer IPA
- [ ] Build and upload supplier IPA
- [ ] Wait for App Store Connect processing
- [ ] Attach builds to correct app versions
- [ ] Run final checklist sweep

### Deliverables
- [ ] Processed build attached to Customer listing
- [ ] Processed build attached to Supplier listing
- [ ] Final pre-submit signoff

### Exit Criteria (Gate)
- [ ] Both listings show no missing required field
- [ ] Both listings ready for Submit for Review action

---

## Submission Day Runbook
**Target:** 2026-06-25 to 2026-06-27

- [ ] Submit Customer app
- [ ] Submit Supplier app
- [ ] Confirm both entered review queue
- [ ] Monitor App Review messages 2x daily
- [ ] Respond to reviewer questions within 24 hours

---

## Daily Standup Template

Use once per day until submission.

- Date:
- Yesterday completed:
- Today planned:
- Blockers:
- Risks raised:
- Owner actions required:

---

## Risks and Mitigations

- [ ] Risk: URL hosting delays
  - Mitigation: Use GitHub Pages fallback immediately
- [ ] Risk: Screenshot quality mismatch
  - Mitigation: Add pre-QA dimension and readability check before export
- [ ] Risk: Metadata-compliance inconsistency
  - Mitigation: Compliance owner performs final claim audit
- [ ] Risk: Build processing delay in App Store Connect
  - Mitigation: Upload at least 48 hours before target submit date
- [ ] Risk: Reviewer confusion due to dual-app workflow
  - Mitigation: Clear step-by-step reviewer instructions included in notes

---

## Decision Log

| Date | Decision | Owner | Notes |
|------|----------|-------|-------|
| 2026-06-11 | Tracker created | Release Owner | Initial execution baseline |

---

## Final Go/No-Go Checklist

- [ ] Legal URLs live and tested
- [ ] Metadata finalized and approved
- [ ] Screenshots approved and uploaded
- [ ] Compliance and privacy answers complete
- [ ] Both builds processed and attached
- [ ] Reviewer notes complete
- [ ] Support inbox monitored
- [ ] Team on standby during review window

**Go/No-Go Decision:** ____________________
**Decision Date:** ____________________
**Approver:** ____________________
