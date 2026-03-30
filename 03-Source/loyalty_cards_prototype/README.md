# LoyaltyCards Flutter Prototype

## Overview

This is an **interactive prototype** of the LoyaltyCards P2P loyalty card system built with Flutter. It demonstrates the key user interactions between suppliers and customers through QR code exchange.

## What This Prototype Demonstrates

✅ **Supplier Onboarding** - Business setup and configuration  
✅ **Customer Card Pickup** - Scanning supplier QR to add card  
✅ **Stamp Application** - P2P stamping via QR exchange  
✅ **Card Redemption** - Completing and resetting cards  
✅ **Visual Card Display** - Intuitive stamp progress visualization  
✅ **Transaction History** - Basic activity tracking  

## Project Structure

```
lib/
├── main.dart                                  # App entry point
├── screens/
│   ├── home_screen.dart                       # Choose Customer or Supplier mode
│   ├── customer/
│   │   ├── customer_home.dart                 # Customer wallet view
│   │   ├── customer_add_card.dart             # Scan supplier QR to add card
│   │   └── customer_card_detail.dart          # Card detail with stamp display
│   └── supplier/
│       ├── supplier_home.dart                 # Supplier dashboard
│       ├── supplier_onboarding.dart           # Business setup
│       ├── supplier_issue_card.dart           # Show QR for customer pickup
│       ├── supplier_stamp_card.dart           # Scan customer card & add stamp
│       └── supplier_redeem_card.dart          # Redeem completed cards
```

## Prerequisites

Before running this prototype, you need:

1. **Flutter SDK** (3.19+) - See [../FLUTTER_SETUP_GUIDE.md](../FLUTTER_SETUP_GUIDE.md)
2. **Android Studio** (for Android development)
3. **VS Code** (recommended) with Flutter extension
4. **Physical device or emulator** (for QR scanning)

## Quick Start

### 1. Install Dependencies

```bash
cd loyalty_cards_prototype
flutter pub get
```

### 2. Run on Emulator/Device

```bash
# Check connected devices
flutter devices

# Run the app
flutter run
```

### 3. Test the User Flows

#### Flow 1: Supplier Issues Card to Customer

**On Device 1 (Supplier)**:
1. Launch app → Choose "Supplier"
2. Complete onboarding (business name, stamp count)
3. Tap "Issue Card"
4. Display QR code on screen

**On Device 2 (Customer)**:
1. Launch app → Choose "Customer"
2. Tap "Add Card" (+ button)
3. Scan supplier QR code (from Device 1)
4. Card appears in wallet!

#### Flow 2: Apply Stamp

**On Device 2 (Customer)**:
1. Open card from wallet
2. Tap "Show QR to Get Stamp"
3. Display customer QR code

**On Device 1 (Supplier)**:
1. Tap "Stamp Card"
2. Scan customer QR code (from Device 2)
3. Confirm stamp addition
4. Display stamp token QR code

**On Device 2 (Customer)**:
1. Scan supplier stamp token QR code
2. Card updates with new stamp!

#### Flow 3: Redeem Card

**On Device 2 (Customer)** (with completed card):
1. Open completed card (7/7 stamps)
2. Tap "Show QR to Redeem"
3. Display redemption QR code

**On Device 1 (Supplier)**:
1. Tap "Redeem Card"
2. Scan customer redemption QR code
3. Confirm redemption
4. Card resets to 0 stamps

## Testing Without Two Devices

If you only have one device:

### Option 1: Mock Data Button

In the "Add Card" screen, there's a **"Use Mock Data"** button that simulates scanning a supplier QR code without actually scanning.

### Option 2: Display QR on Computer Screen

1. Run supplier app on device
2. Display QR code (e.g., "Issue Card")
3. Screenshot or display on computer monitor
4. Scan computer screen with device camera

### Option 3: Two Emulators (Limited)

- Run two emulators simultaneously
- Good for UI testing
- ❌ QR scanning won't work (emulators don't have cameras)
- Use mock data buttons instead

## Current Limitations (Prototype)

⚠️ **This is a UI/UX prototype**. The following are not yet implemented:

- ❌ No cryptographic signatures (security placeholder)
- ❌ No persistent SQLite storage (data lost on restart)
- ❌ No actual QR code validation (any QR displays)
- ❌ No network communication (all local only)
- ❌ Mock transaction history (hardcoded)

These will be implemented in Phase 2 (see [DECISION_Flutter_Framework.md](../../01-Design/Architecture/DECISION_Flutter_Framework.md))

## Key Features for Testing

### Visual Design

- **Gradient Cards** - Each business has a unique color
- **Progress Circles** - Visual stamp collection progress
- **Completion State** - Green badges for completed cards
- **QR Display** - Large, scannable QR codes

### User Experience

- **Simple Navigation** - Minimal taps to complete actions
- **Clear Instructions** - Contextual help at each step
- **Immediate Feedback** - Visual confirmations
- **Error Handling** - Graceful failures with helpful messages

## Troubleshooting

### QR Code Won't Scan

- Ensure good lighting
- Hold camera steady
- Increase QR code size (pinch to zoom if needed)
- Try toggling flash (lightning icon)
- Use "Enter Card ID Manually" fallback

### Camera Permission Denied

```bash
# Check AndroidManifest.xml has camera permission
<uses-permission android:name="android.permission.CAMERA"/>
```

Grant permission manually in device settings if needed.

### Build Errors

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Hot Reload Not Working

- Press `R` in terminal (capital R for hot restart)
- Or save file in VS Code (auto hot reload)

## Next Steps After Testing

Once you've tested the prototype and gathered feedback:

1. **Review UX** - Did the flows make sense?
2. **Identify Pain Points** - What was confusing?
3. **Measure Performance** - How long did stamping take?
4. **Collect Feedback** - Show to actual coffee shop owners/customers

Then proceed to **Phase 2**:
- Implement real cryptographic signatures
- Add SQLite database persistence
- Build proper QR validation
- Add error handling
- Performance optimization

## Resources

- [Flutter Setup Guide](../FLUTTER_SETUP_GUIDE.md) - Installation instructions
- [Architecture Decision](../../01-Design/Architecture/DECISION_Flutter_Framework.md) - Why Flutter?
- [P2P Architecture](../../01-Design/Architecture/DECISION_P2P_Architecture.md) - How P2P works
- [Requirements](../../00-Planning/Requirements/README.md) - Full requirements

## Contributing

This is a prototype for testing. Feedback welcome!

To modify:
1. Edit screens in `lib/screens/`
2. Save file (triggers hot reload)
3. See changes instantly on device

---

**Version**: 0.1.0 (Prototype)  
**Created**: 2026-03-30  
**Status**: Ready for UX Testing
