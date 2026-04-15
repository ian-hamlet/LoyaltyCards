/// Shared app version information for both Customer and Supplier apps
/// 
/// Update this version string each time you make changes to verify
/// that the new code has been deployed to the device.
/// 
/// Format: v{major}.{minor}.{patch} (Build {build})
/// Example: v1.0.0 (Build 1)
///
/// Version 0.2.0 - Pilot Testing Release
/// 
/// Ready for TestFlight deployment and initial pilot testing.
/// 
/// Key Features:
/// - Dual operation modes (Simple & Secure)
/// - P2P architecture with cryptographic security
/// - QR-based stamp issuance and redemption
/// - Multi-device supplier support (backup & clone)
/// - Privacy-first design (zero data collection)
/// - Custom branded app icons
/// - Offline-capable with local storage
/// 
/// Build 9 Changes:
/// - Fix customer QR scanner rotation buttons (TEST-004)
/// - Add camera flip button to all QR scanners
/// - Fix rotation calculation to use _manualRotationOffset variable
/// - Add flip camera (front/back switch) functionality
/// - Apply fixes to customer_app/qr_scanner_screen.dart
/// - Apply fixes to supplier_app/import_business_screen.dart
/// - Add camera controls to supplier_stamp_card.dart and supplier_redeem_card.dart

const String appVersion = '0.2.0+9';
