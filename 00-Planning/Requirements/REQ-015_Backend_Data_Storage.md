# Requirement: Backend Data Storage

## ID
REQ-015

## Status
Draft

## Priority
Medium

## Category
Technical

## Description
The system shall evaluate and implement appropriate data storage architecture. Options include: (1) backend server with centralized database, (2) distributed peer-to-peer storage on customer devices, or (3) hybrid approach. If backend storage is used, transaction history shall be recorded for auditing and analytics.

## Rationale
The discovery notes indicate preference for device-to-device interaction without backend storage if possible, to minimize infrastructure costs. However, backend storage provides benefits: transaction history, data recovery, fraud prevention, and future analytics. The architecture decision must balance cost, complexity, and functionality.

## Acceptance Criteria
- [ ] Architecture decision documented with rationale
- [ ] Data storage solution supports required synchronization patterns
- [ ] Supplier and customer data can sync reliably
- [ ] If backend used: transaction history recorded (supplier ID, customer card ID, timestamp, action)
- [ ] If backend used: API endpoints defined for mobile apps
- [ ] If backend used: database schema designed and documented
- [ ] If backend used: data backup and recovery procedures defined
- [ ] If device-only: conflict resolution strategy defined
- [ ] Solution supports scalability for future growth

## Dependencies
- REQ-010 (Data Synchronization)
- REQ-013 (GDPR Compliance)
- REQ-017 (Cost Minimization)

## Constraints
- Must minimize or eliminate cost for suppliers and customers
- Must comply with data privacy regulations
- Must be maintainable by small development team

## AI Prompt Reference
Generated from discovery document: 00-REQUIREMENTS_DISCOVERY.md - Sections 4, Notes

## Related Documents
- [Architecture Decision: Data Storage](../../01-Design/Architecture/DECISION_Data_Storage.md) (To be created)
- [Database Schema](../../01-Design/Database/SCHEMA.md) (To be created if backend chosen)
- [API Specification](../../01-Design/API/API_SPEC.md) (To be created if backend chosen)

## Notes
Discovery mentions:
- "Ideally if the applications can interact directly without backend storage that would be better"
- "Almost stored on the customer's device"
- "If data has to be stored on a backend server then the supplier and customer data should sync"
- "If we are using a backend we can record the transaction history"

Options to evaluate:
1. **No backend**: Peer-to-peer sync using Bluetooth, NFC, or direct WiFi. Challenges: sync reliability, data recovery.
2. **Minimal backend**: Lightweight sync service, no app logic. Examples: Firebase, AWS AppSync.
3. **Full backend**: Traditional client-server. Provides full features but higher cost and complexity.

Recommendation: Start with minimal backend (Firebase/Supabase) for MVP reliability, evaluate P2P for future.

---
**Created**: 2026-03-30  
**Last Updated**: 2026-03-30  
**Owner**: Project Team
