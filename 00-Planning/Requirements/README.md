# Requirements Index

## Document Information
- **Created**: 2026-03-30
- **Last Updated**: 2026-03-30
- **Status**: Draft - Ready for Review
- **Total Requirements**: 20

---

## Requirements Overview

This index provides a complete overview of all requirements for the LoyaltyCards application, organized by category and priority.

---

## Requirements by Priority

### Critical Priority (10 requirements)
| ID | Title | Category | Status |
|----|-------|----------|--------|
| [REQ-001](REQ-001_Digital_Stamp_Card_System.md) | Digital Stamp Card System | Business | Draft |
| [REQ-002](REQ-002_Two_Actor_System.md) | Two-Actor System | Functional | Draft |
| [REQ-003](REQ-003_Mobile_Platform_Support.md) | Mobile Platform Support | Technical | Draft |
| [REQ-005](REQ-005_Minimal_Personal_Data_Collection.md) | Minimal Personal Data Collection | Non-Functional (Privacy) | Draft |
| [REQ-006](REQ-006_Fast_Stamp_Process.md) | Fast Stamp Process | Non-Functional (Performance) | Draft |
| [REQ-009](REQ-009_QR_Barcode_Scanning.md) | QR/Barcode Scanning | Functional | Draft |
| [REQ-010](REQ-010_Data_Synchronization.md) | P2P Data Synchronization | Technical | Draft |
| [REQ-012](REQ-012_Card_Redemption_Reset.md) | Card Redemption and Reset | Functional | Draft |
| [REQ-015](REQ-015_Backend_Data_Storage.md) | Peer-to-Peer Data Architecture | Technical | Draft |
| [REQ-017](REQ-017_Cost_Minimization.md) | Cost Minimization | Business | Draft |
| [REQ-020](REQ-020_Security_Requirements.md) | Security Requirements | Non-Functional (Security) | Draft |

### High Priority (6 requirements)
| ID | Title | Category | Status |
|----|-------|----------|--------|
| [REQ-004](REQ-004_Zero_Entry_Card_Issuance.md) | Zero Data Entry Card Issuance | Functional | Draft |
| [REQ-007](REQ-007_Visual_Stamp_Card_Display.md) | Visual Stamp Card Display | Functional | Draft |
| [REQ-008](REQ-008_Configurable_Stamp_Requirements.md) | Configurable Stamp Requirements | Functional | Draft |
| [REQ-011](REQ-011_Offline_Capability.md) | Offline Capability | Non-Functional (Performance) | Draft |
| [REQ-013](REQ-013_GDPR_Compliance.md) | GDPR Compliance | Non-Functional (Legal) | Draft |
| [REQ-014](REQ-014_Performance_Requirements.md) | Performance Requirements | Non-Functional (Performance) | Draft |

### Medium Priority (2 requirements)
| ID | Title | Category | Status |
|----|-------|----------|--------|
| [REQ-016](REQ-016_Push_Notifications.md) | Push Notifications | Functional | Draft |
| [REQ-018](REQ-018_Transaction_History.md) | Local Transaction History | Functional | Draft |

### Low Priority (1 requirement)
| ID | Title | Category | Status |
|----|-------|----------|--------|
| [REQ-019](REQ-019_Stamp_Expiration.md) | Stamp Expiration | Functional | Draft |

---

## Requirements by Category

### Business Requirements (2)
- [REQ-001](REQ-001_Digital_Stamp_Card_System.md) - Digital Stamp Card System (Critical)
- [REQ-017](REQ-017_Cost_Minimization.md) - Cost Minimization (Critical)

### Functional Requirements (9)
- [REQ-002](REQ-002_Two_Actor_System.md) - Two-Actor System (Critical)
- [REQ-004](REQ-004_Zero_Entry_Card_Issuance.md) - Zero Data Entry Card Issuance (High)
- [REQ-007](REQ-007_Visual_Stamp_Card_Display.md) - Visual Stamp Card Display (High)
- [REQ-008](REQ-008_Configurable_Stamp_Requirements.md) - Configurable Stamp Requirements (High)
- [REQ-009](REQ-009_QR_Barcode_Scanning.md) - QR/Barcode Scanning (Critical)
- [REQ-012](REQ-012_Card_Redemption_Reset.md) - Card Redemption and Reset (Critical)
- [REQ-016](REQ-016_Push_Notifications.md) - Push Notifications (Medium)
- [REQ-018](REQ-018_Transaction_History.md) - Transaction History (Medium)
- [REQ-019](REQ-019_Stamp_Expiration.md) - Stamp Expiration (Low)

### Technical Requirements (3)
- [REQ-003](REQ-003_Mobile_Platform_Support.md) - Mobile Platform Support (Critical)
- [REQ-010](REQ-010_Data_Synchronization.md) - Data Synchronization (Critical)
- [REQ-015](REQ-015_Backend_Data_Storage.md) - P2P Data Synchronization (Critical)
- [REQ-015](REQ-015_Backend_Data_Storage.md) - Peer-to-Peer Data Architecture (Critical
### Non-Functional Requirements (6)
- [REQ-005](REQ-005_Minimal_Personal_Data_Collection.md) - Minimal Personal Data Collection - Privacy (Critical)
- [REQ-006](REQ-006_Fast_Stamp_Process.md) - Fast Stamp Process - Performance (Critical)
- [REQ-011](REQ-011_Offline_Capability.md) - Offline Capability - Performance (High)
- [REQ-013](REQ-013_GDPR_Compliance.md) - GDPR Compliance - Legal (High)
- [REQ-014](REQ-014_Performance_Requirements.md) - Performance Requirements (High)
- [REQ-020](REQ-020_Security_Requirements.md) - Security Requirements (Critical)

---

## Core User Flows & Related Requirements

### 1. Customer Picks Up New Card
**Requirements**: REQ-002, REQ-004, REQ-009, REQ-007, REQ-010

### 2. Supplier Stamps Customer Card
**Requirements**: REQ-002, REQ-006, REQ-009, REQ-010, REQ-016, REQ-020

### 3. Customer Views Card Progress
**Requirements**: REQ-007, REQ-011, REQ-018

### 4. Supplier Redeems Completed Card
**Requirements**: REQ-012, REQ-010, REQ-016, REQ-018

### 5. Data Synchronization
**Requirements**: REQ-010, REQ-011, REQ-015

---

## MVP Scope (Minimum Viable Product)

### Must-Have for MVP (Critical Requirements)
1. REQ-001 - Digital Stamp Card System
2. REQ-002 - Two-Actor System
3. REQ-003 - Mobile Platform Support
4. REQ-005 - Minimal Personal Data Collection
5. REQ-006 - Fast Stamp Process
6. REQ-009 - QR/Barcode Scanning
7. REQ-010 - P2P Data Synchronization
8. REQ-012 - Card Redemption and Reset
9. REQ-015 - Peer-to-Peer Data Architecture
10. REQ-017 - Cost Minimization
11. REQ-020 - Security Requirements

### Should-Have for MVP (High Priority)
1. REQ-004 - Zero Data Entry Card Issuance
2. REQ-007 - Visual Stamp Card Display
3. REQ-008 - Configurable Stamp Requirements
4. REQ-011 - Offline Capability
5. REQ-013 - GDPR Compliance
6. REQ-014 - Performance Requirements

### Could6 - Push Notifications
2. REQ-018 - Local Transaction History (enhanced analytics)
3. REQ-018 - Transaction History
4. REQ-019 - Stamp Expiration

---

## Key Architectural Decisions Required

Based on the requirements, the following architectural decisions must be made before design phase:

1. **Data Storage Architecture** (REQ-015) ✅ **DECIDED**
   - **Decision**: Peer-to-peer (P2P) architecture with local device storage
   - **Primary**: QR code exchange for universal compatibility
   - **Enhanced**: NFC tap for supported devices
   - **Backup**: Optional encrypted cloud backup (user's personal cloud storage)
   - **Rationale**: Zero backend costs, maximum privacy, fastest performance, fully offline operation

2. **Mobile Development Framework** (REQ-003)
   - Option A: Native (separate iOS/Android codebases)
   - Option B: React Native (JavaScript, cross-platform)
   - Option C: Flutter (Dart, cross-platform)
   - Option D: Progressive Web App (web-based, mobile-optimized)
   - **Recommendation**: React Native or Flutter for cross-platform efficiency

3. **Synchronization Strategy** (REQ-010) ✅ **DECIDED**
   - **Decision**: Direct device-to-device (P2P) synchronization
   - **Method**: QR code exchange with cryptographic signatures
   - **Flow**: Supplier scans customer card → generates signed stamp token → customer scans to receive
   - **Rationale**: Immediate sync, no network required, tamper-proof via cryptography

4. **QR/Barcode Format** (REQ-009)
   - QR Code primary, human-readable fallback
   - Format: 8-character alphanumeric + GUID
   - **Recommendation**: QR Code with embedded GUID, 8-char as display code

---

## Traceability to Discovery Document

All requirements are traceable to the [Requirements Discovery](00-REQUIREMENTS_DISCOVERY.md) document:

- **Section 1** (Core Purpose) → REQ-001, REQ-017
- **Section 2** (Target Users) → REQ-002
- **Section 3** (Core Features) → REQ-004, REQ-006, REQ-007, REQ-008, REQ-009, REQ-012, REQ-016
- **Section 4** (Platform & Technical Scope) → REQ-003, REQ-010, REQ-011, REQ-015
- **Section 5** (Data & Security) → REQ-005, REQ-009, REQ-013, REQ-018, REQ-019, REQ-020
- **Section 6** (Business Model) → REQ-017
- **Section 8** (UX Priorities) → REQ-006, REQ-014

---

## Next Steps

1. **Review Requirements** - Stakeholder review and approval of all 20 requirements
2. **Create User Stories** - Break down requirements into actionable user stories
3. **Architecture Design** - Make key architectural decisions (data storage, mobile framework)
4. **Technical Specifications** - Detail API, database schema, data models
5. **UI/UX Design** - Create wireframes and mockups for key user flows
6. **Prototype Development** - Build proof-of-concept for core functionality

---

## Related Documents

- [Requirements Discovery](00-REQUIREMENTS_DISCOVERY.md)
- [Template Requirement](TEMPLATE_Requirement.md)
- [User Stories](../UserStories/) (To be created)
- [Project Metadata](../../PROJECT_METADATA.md)
- [Architecture Decisions](../../01-Design/Architecture/ARCHITECTURE_DECISIONS.md)

---

**Document Owner**: Project Team  
**Last Review**: 2026-03-30  
**Next Review**: TBD
