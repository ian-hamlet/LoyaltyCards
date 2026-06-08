# LoyaltyCards Customer App

The customer/user side of the LoyaltyCards loyalty card system. Allows customers to collect digital loyalty cards from participating businesses and earn stamps toward rewards.

## 📋 Documentation

### 🎯 Getting Started

**New to LoyaltyCards?** Start here:
- **[User Guide](../../docs/user/USER_GUIDE.md)** - Complete guide to using the customer app, collecting cards, earning stamps, and redeeming rewards

### 📚 Understanding the System

- **[About LoyaltyCards](../../docs/user/ABOUT_LOYALTYCARDS.md)** - System overview with real-world examples of how the system works
- **[Supplier Setup Guide](../../docs/user/SUPPLIER_SETUP_GUIDE.md)** - Explains the two operation modes (Simple vs Secure) so you understand what to expect from different businesses

---

## 🚀 Quick Start (2 Minutes)

1. **Install:** Download LoyaltyCards from the App Store (or TestFlight for beta)
2. **Get a Card:** Ask a participating business for their card QR code or find it in the app
3. **Scan to Collect:** Point your camera at the QR code to add the card to your wallet
4. **Earn Stamps:** At checkout, scan the business's stamp QR code (or have staff add a stamp)
5. **Redeem:** When you earn enough stamps, scan the redeem QR code to get your reward

---

## 💳 Two Types of Experiences

When you use LoyaltyCards, you'll encounter one of two experiences depending on how the business set up their system:

### Simple Mode (Trust-Based, Fast)
- **Speed:** Ultra fast - scan and go (2 seconds)
- **How:** You scan QR codes yourself to add stamps
- **Example:** Coffee shop - scan the "Add Your Stamp" code at checkout
- **QR Codes:** Static codes printed at the register (never change)
- **Control:** You control when you add stamps to your card

**Best For:** Low-value rewards (free coffee, small discounts), regular customers

### Secure Mode (Cryptographically Validated, Controlled)
- **Speed:** A bit slower but secure (5-10 seconds)
- **How:** Staff member taps a button to generate a QR code for you to scan
- **Example:** Luxury spa - staff creates a new code each time you visit
- **QR Codes:** Time-limited codes (expire after 2 minutes)
- **Control:** Staff member controls when stamps are added

**Best For:** High-value rewards ($50+), premium services, fraud prevention

**You'll notice the difference after your first scan:**
- Simple Mode = instant stamp appears
- Secure Mode = staff member initiates the process, then you scan

---

## 🛠️ Development

This is a Flutter application. For development setup and contribution guidelines, see the main project README.

- [Flutter Setup Guide](../FLUTTER_SETUP_GUIDE.md)
- [Project README](../../README.md)
