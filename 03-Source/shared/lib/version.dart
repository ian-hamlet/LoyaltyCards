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
/// Recent Changes (Builds 80-84):
/// - Build 84: Custom app icons for both apps
/// - Build 83: 5-minute clone QR expiry (security improvement)
/// - Build 82: Clone device feature complete
/// - Build 81: QR scanning frame and rotation controls
/// - Build 80: Fixed backup/restore private key encoding

const String appVersion = '0.2.0+6';
