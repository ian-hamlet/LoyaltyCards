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
/// Build 8 Changes:
/// - Complete print() → AppLogger migration (NEW-001)
/// - Add missing AppLogger.database() method (NEW-002)
/// - Standardize logging strategy across all screens (NEW-003)
/// - Document AppLogger.qr() method (NEW-004)
/// - Finish CR-002: Remove all remaining debug print statements

const String appVersion = '0.2.0+8';
