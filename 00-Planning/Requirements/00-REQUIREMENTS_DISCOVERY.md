# LoyaltyCards - Requirements Discovery

## Document Information
- **Created**: 2026-03-30
- **Status**: In Progress
- **Purpose**: Capture initial vision, scope, and requirements discovery for the LoyaltyCards application

---

## Phase 1: Discovery & Vision

### 1. Core Purpose & Problem Statement

#### What problem does LoyaltyCards solve?
**Question**: What is the primary problem this application addresses?
- [ ] Managing physical loyalty cards digitally?
- [ ] Tracking rewards/points across different stores?
- [ ] Preventing loss of loyalty card data?
- [ ] Organizing and accessing cards easily?
- [ ] Other: ___________

**Answer**: 
The application is to be used as an alternative to card and stamp versions of loyalty cards used in small coffee shops and other places.
As physical wallets are being replaced with phones, we plan to have the loyalty card stored in a users phone.

We are not planning to support widespread user analysis and buying habits. It is a simple replacement for the physical stamping of a card after purchase to support a buy 7 get the 8th free type model.

The aggregated accumulated points for a customer at an institution should be safely stored.

It needs to be a quick simple process to locate the card for the customer and simple process to scan the card and add points by the shop.

It should be easy for the customer to find the card in the phone with appropriate simple barnding and to see the number of stamps collected so far.

The stamp card model should suffice, on set up the most common options should be avbailabel ane each card should start off with a set of empty stamps. this wasy the customer can see how many stamps have been accumulated and how many still to go.

On redemption the card should be reset by the coffee shop.

---

### 2. Target Users

#### Who are the primary users?
Will be used primarily by small coffee shop or food outlets and their customers to help try and drive return visits and loyalty.

We therefore have two main actors:
1.  Supplier, responsible for registering their business and configuring the card proposition.
2.  Customer, on visiting a supplier 'picks up' one of the loyalty cards from the supplier, which is stored on the customers phone.
3.  Each time the customer returns to a supplier, the supplier scans the card and updates the stamp. This should be a simple as possible. The customers card will be updated along with the supplier records regarding the transaction.
4.  Needs to be a low cost, simple solution for small sole trader organistions.



### 3. Core Features & Capabilities

#### Essential Features (MVP)
**Question**: What are the must-have features for the first version?

**Potential Features**:
- [ ] Store/manage loyalty card information
- [ ] Scan/add cards (barcode, QR code)
- [ ] Manual card entry (number, name, etc.)
- [ ] Display cards for scanning at checkout
- [ ] Track points/rewards balances
- [ ] Receive notifications about deals/expiring rewards
- [ ] Search and organize cards
- [ ] Share cards across devices
- [ ] Backup/restore card data
- [ ] Other: ___________

**Prioritized List**:
Minimum Personal Data Collected and Stored
Zero data entry to generate and share a new card
Zero data entry to stamp a card, almost scan and done.
Mobile device priority, without a mobile device might as well have th physical card
Should almost just be a bump to issue and a bump to stamp.
Card has human readable code identifier as well as camera readable qr or barcodes
Simple button press by the supplier to reset and redeem previous stamps
Track current progress.
Probably one customer card per supplier.
Customers may have multiple cards for different suppliers
Get a notification on redemption or stamping

---

### 4. Platform & Technical Scope

#### Target Platforms
**Question**: What platforms should the application support?


**Answer**: 
Customer cards to be stored on mobile devices, both andriod and ios
Supplier application to be stored on ios or andriod mobile device.
Might need a simple web interface to get a few more insights from the stored data.
Ideally if the applications can interact directly without backend storage that would be better, almost stored on the customers deveice

#### Connectivity & Sync
**Question**: What are the connectivity requirements?
- [ ] **Offline capability**: Users can access cards without internet
- [ ] **Multi-device sync**: One account, multiple devices
- [ ] **Real-time sync**: Changes sync immediately across devices
- [ ] **Cloud backup**: Automatic backup to cloud storage
- [ ] **Local-only**: No cloud, only device storage

**Answer**: 
customers can see their cards without the internet, but the stamp needs to be synched from the supplier to customer.
If data has to be stored on a back end server then the supplier and customer data should sync.
Changes don't have to be in real-time, though speed would be a nice to have property. The faster teh better

---

### 5. Data & Security

#### What Information Will Be Stored?
**Question**: What card/user data needs to be captured?
- [ ] Card name/brand
- [ ] Card/member number
- [ ] Barcode/QR code image or data
- [ ] Points/rewards balance
- [ ] Expiration dates
- [ ] Customer name on card
- [ ] Physical card image/photo
- [ ] Store location preferences
- [ ] Transaction history
- [ ] Promotional offers
- [ ] Other: ___________

**Answer**: 
Need to capture the supplier name and slimited branding.
The number of qualifying purchases needed
Expiry date for purchases
QR/Bar code simple 8 character code as well as a guid
If we are using a backend we can record the transaction history.
No need to capture customer name, email or phone number (other than to make a wallet or the like work)

#### Security & Privacy Considerations
**Question**: What security measures are needed?
- [ ] User authentication (login/registration)
- [ ] Encrypted data storage
- [ ] Biometric access (fingerprint/face ID)
- [ ] PIN/password protection
- [ ] Multi-factor authentication
- [ ] GDPR compliance
- [ ] Data export/deletion (right to be forgotten)

**Answer**: 
Use exisdting mobile security model to secure the supplier application, there is no current requirement mandating the customer has to login, the supplier almost gives a new customer an account or card

---

### 6. Business Model & Constraints

#### Monetization (if applicable)
**Question**: Is this a personal project, commercial product, or open source?
- [ ] Personal/Portfolio project
- [ ] Free app with ads
- [ ] Freemium (free with premium features)
- [ ] Paid app
- [ ] Subscription model
- [ ] Open source/free
- [ ] Other: ___________

**Answer**: 
this should be a free service for customers and goal of making it free for the supplier.
No subscription model planned, however costs need to be established. Seen as a non-profit application

#### Budget & Timeline Constraints
**Question**: Are there any constraints on development?
- Time constraints:
- Budget constraints:
- Technology preferences/restrictions:
- Team size:

**Answer**: 
No time constraints

---

### 7. Integration & External Systems

#### Third-Party Integrations
**Question**: Should the app integrate with any external services?
- [ ] Retailer APIs for automatic balance updates
- [ ] Payment systems (Apple Pay, Google Pay)
- [ ] Cloud storage (Google Drive, iCloud, Dropbox)
- [ ] Social sharing
- [ ] Analytics platforms
- [ ] Other: ___________

**Answer**: 
Byond having to have core storage and access of the customer/supplier card data no other interfaces beyond notifications are needed

---

### 8. User Experience Priorities

#### Key UX Goals
**Question**: What should the user experience prioritize?
- [ ] Speed (quick access to cards)
- [ ] Simplicity (minimal features, easy to use)
- [ ] Customization (personalize appearance, organization)
- [ ] Accessibility (support for disabilities)
- [ ] Visual appeal (modern, attractive design)

**Answer**: 
speed and ease of use. Will be used in a checkout till environment, do not need to slow the process down

---

## Next Steps

Once the above questions are answered, we will:

1. **Create Business Requirements** (REQ-001, REQ-002, etc.)
2. **Develop User Stories** (US-001, US-002, etc.)
3. **Define Acceptance Criteria** for each requirement
4. **Prioritize Requirements** (Critical → High → Medium → Low)
5. **Identify Dependencies** between requirements
6. **Document Non-Functional Requirements** (performance, security, scalability)
7. **Create Project Vision Statement**
8. **Define Success Metrics**

---

## Notes & Ideas

in terms of architecture, not known how much functionality is available in the mobile devices to work without a back end.
If one could use the customer device for secure storage, the supplier device simply bumps/ scans and securely increments the stamp counter.

---

## References

- Template: [TEMPLATE_Requirement.md](TEMPLATE_Requirement.md)
- User Stories: [../UserStories/](../UserStories/)
- Project Metadata: [../../PROJECT_METADATA.md](../../PROJECT_METADATA.md)
