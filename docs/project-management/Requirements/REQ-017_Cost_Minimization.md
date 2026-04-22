# Requirement: Cost Minimization

## ID
REQ-017

## Status
Draft

## Priority
Critical

## Category
Business

## Description
The system shall be designed to minimize or eliminate operational costs for both suppliers and customers. The service should be free for customers and free or very low-cost for suppliers. Infrastructure, hosting, and third-party service costs must be minimized.

## Rationale
The target market is small businesses and sole traders with limited budgets. High subscription or transaction fees will prevent adoption. The project is positioned as a non-profit application. Cost-effective architecture is essential for sustainability.

## Acceptance Criteria
- [ ] Customer app is free to download and use
- [ ] No subscription fees for customers
- [ ] Supplier app is free to download
- [ ] Supplier operational costs: $0 or minimal (< $10/month)
- [ ] Architecture uses free or low-cost infrastructure
- [ ] Third-party services use free tiers where possible
- [ ] Hosting costs scale efficiently with user growth
- [ ] No transaction-based fees
- [ ] Open-source technologies used where appropriate

## Dependencies
- REQ-001 (Digital Stamp Card System)
- REQ-015 (Backend Data Storage)

## Constraints
- Cannot rely on paid enterprise services
- Must use affordable cloud providers or serverless architectures
- Limited budget for development tools and services

## AI Prompt Reference
Generated from discovery document: 00-REQUIREMENTS_DISCOVERY.md - Section 6

## Related Documents
- [Architecture Decision: Cost-Effective Infrastructure](../../01-Design/Architecture/DECISION_Infrastructure_Cost.md) (To be created)
- [Operating Budget](../../06-Deployment/OPERATING_BUDGET.md) (To be created)

## Notes
Discovery states:
- "This should be a free service for customers"
- "Goal of making it free for the supplier"
- "No subscription model planned"
- "Seen as a non-profit application"
- "Needs to be a low cost, simple solution for small sole trader organizations"

Cost-saving strategies:
1. **Serverless architecture**: AWS Lambda, Azure Functions, Google Cloud Functions (pay per use)
2. **Firebase/Supabase**: Free tiers support small user bases
3. **Open-source frameworks**: React Native, Flutter (cross-platform development)
4. **Static hosting**: Netlify, Vercel, GitHub Pages (free tiers)
5. **Managed services free tiers**: MongoDB Atlas, PostgreSQL on Supabase
6. **Push notifications**: Firebase Cloud Messaging (free)

Estimated costs for small deployment:
- Firebase Free Tier: $0/month (up to 10K users)
- Supabase Free Tier: $0/month (500MB database, 1GB bandwidth)
- Vercel Free Tier: $0/month (static site hosting)
- Domain: ~$12/year

---
**Created**: 2026-03-30  
**Last Updated**: 2026-03-30  
**Owner**: Project Team
