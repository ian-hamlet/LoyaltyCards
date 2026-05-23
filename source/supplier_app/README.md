# LoyaltyCards Supplier App

The supplier/business side of the LoyaltyCards loyalty card system. Allows businesses to create, manage, and redeem customer loyalty cards in either **Simple Mode** (trust-based) or **Secure Mode** (cryptographically validated).

## 📋 Documentation

### 🎯 Setup & Configuration

**First time setting up?** Start here:
- **[Supplier Setup Guide](../../docs/user/SUPPLIER_SETUP_GUIDE.md)** - Complete guide to choosing your operation mode (Simple vs Secure) with real-world examples
- **[User Guide](../../docs/user/USER_GUIDE.md)** - Comprehensive usage guide including initial setup steps

### 📚 Understanding the System

- **[About LoyaltyCards](../../docs/user/ABOUT_LOYALTYCARDS.md)** - System overview with detailed explanations of both operation modes and real-world scenarios
- **[Security Model](../../docs/technical/SECURITY_MODEL.md)** - Technical details on cryptography, mode selection guidance, and security features

---

## 🚀 Quick Start (5 Minutes)

1. **Install:** Open the app from TestFlight (pilot phase)
2. **Create Business:** Enter your business name and settings
3. **Choose Mode:** Decide between Simple Mode or Secure Mode
   - **Simple Mode:** Fast, printed QR codes, trust-based (coffee shops)
   - **Secure Mode:** Controlled, time-limited QR codes, cryptographically secure (luxury goods, spas)
   - 👉 **[Read the full guide](../../docs/user/SUPPLIER_SETUP_GUIDE.md) to choose correctly**
4. **Create Backup:** Protect your business data with a recovery backup
5. **Start Stamping:** Generate QR codes and help customers earn stamps

---

## 📱 Two Operation Modes

### Simple Mode (Trust-Based)
- **QR Codes:** Static, printed, never expire
- **Speed:** 2 seconds per stamp
- **Best For:** Low-value rewards, high transaction volume
- **Example:** Coffee shop - print QR codes, customers scan themselves
- **Security:** Rate limiting (1 stamp per hour per customer)

### Secure Mode (Cryptographically Validated)
- **QR Codes:** Dynamic, time-limited (expire after 2 minutes)
- **Speed:** 5-10 seconds per stamp
- **Best For:** High-value rewards, complete control
- **Example:** Luxury spa - you control each stamp, customer can't cheat
- **Security:** ECDSA P-256 cryptography, hash chain validation

**[→ Detailed comparison and decision guide](../../docs/user/SUPPLIER_SETUP_GUIDE.md)**

---

## 🛠️ Development

This is a Flutter application. For development setup and contribution guidelines, see the main project README.

- [Flutter Setup Guide](../FLUTTER_SETUP_GUIDE.md)
- [Project README](../../README.md)
