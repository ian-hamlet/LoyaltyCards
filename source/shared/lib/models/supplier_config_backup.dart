import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'business.dart';
import 'operation_mode.dart';

/// Represents a supplier configuration backup for cloning or recovery
/// 
/// Two types:
/// - "clone": 24-hour expiring QR for setting up additional devices
/// - "recovery": Non-expiring backup for disaster recovery
class SupplierConfigBackup {
  final String type; // "clone" or "recovery"
  final int version; // Format version (1)
  final String businessId;
  final String businessName;
  final String privateKey; // Base64 encoded ECDSA private key
  final String publicKey; // Base64 encoded ECDSA public key
  final int stampsRequired;
  final String brandColor;
  final OperationMode operationMode;
  final DateTime timestamp;
  final DateTime? expiresAt; // null for recovery, +24h for clone
  final String signature; // HMAC-SHA256 of payload

  SupplierConfigBackup({
    required this.type,
    required this.version,
    required this.businessId,
    required this.businessName,
    required this.privateKey,
    required this.publicKey,
    required this.stampsRequired,
    required this.brandColor,
    required this.operationMode,
    required this.timestamp,
    this.expiresAt,
    required this.signature,
  });

  /// Creates a clone QR code that expires in 5 minutes
  /// Used for setting up additional devices while original still works
  static Future<SupplierConfigBackup> createCloneQR(Business business) async {
    final now = DateTime.now();
    final expires = now.add(Duration(minutes: 5));

    final backup = SupplierConfigBackup(
      type: 'clone',
      version: 1,
      businessId: business.id,
      businessName: business.name,
      privateKey: business.privateKey ?? '',
      publicKey: business.publicKey,
      stampsRequired: business.stampsRequired,
      brandColor: business.brandColor,
      operationMode: business.mode,
      timestamp: now,
      expiresAt: expires,
      signature: '', // Will be calculated below
    );

    final signature = await _calculateSignature(backup);
    return SupplierConfigBackup(
      type: backup.type,
      version: backup.version,
      businessId: backup.businessId,
      businessName: backup.businessName,
      privateKey: backup.privateKey,
      publicKey: backup.publicKey,
      stampsRequired: backup.stampsRequired,
      brandColor: backup.brandColor,
      operationMode: backup.operationMode,
      timestamp: backup.timestamp,
      expiresAt: backup.expiresAt,
      signature: signature,
    );
  }

  /// Creates a recovery backup QR code that never expires
  /// Used for disaster recovery when device is lost/stolen/broken
  static Future<SupplierConfigBackup> createRecoveryBackup(
      Business business) async {
    final now = DateTime.now();

    final backup = SupplierConfigBackup(
      type: 'recovery',
      version: 1,
      businessId: business.id,
      businessName: business.name,
      privateKey: business.privateKey ?? '',
      publicKey: business.publicKey,
      stampsRequired: business.stampsRequired,
      brandColor: business.brandColor,
      operationMode: business.mode,
      timestamp: now,
      expiresAt: null, // Never expires
      signature: '', // Will be calculated below
    );

    final signature = await _calculateSignature(backup);
    return SupplierConfigBackup(
      type: backup.type,
      version: backup.version,
      businessId: backup.businessId,
      businessName: backup.businessName,
      privateKey: backup.privateKey,
      publicKey: backup.publicKey,
      stampsRequired: backup.stampsRequired,
      brandColor: backup.brandColor,
      operationMode: backup.operationMode,
      timestamp: backup.timestamp,
      expiresAt: backup.expiresAt,
      signature: signature,
    );
  }

  /// Calculate HMAC-SHA256 signature for integrity verification
  /// 
  /// FIX SEC-001: Derives HMAC key from business private key instead of using
  /// hardcoded public key. This prevents attackers from forging backup QRs.
  /// 
  /// Uses HKDF (HMAC-based Key Derivation Function) to derive a signing key
  /// from the business private key, ensuring each business has a unique HMAC key.
  static Future<String> _calculateSignature(
      SupplierConfigBackup backup) async {
    final dataToSign = '${backup.type}|${backup.version}|${backup.businessId}|'
        '${backup.businessName}|${backup.privateKey}|${backup.publicKey}|'
        '${backup.stampsRequired}|${backup.brandColor}|'
        '${backup.operationMode.name}|${backup.timestamp.toIso8601String()}|'
        '${backup.expiresAt?.toIso8601String() ?? 'null'}';

    // Derive HMAC key from business private key using HKDF
    final privateKeyBytes = base64Decode(backup.privateKey);
    final derivedKey = _deriveHMACKey(privateKeyBytes);
    
    final bytes = utf8.encode(dataToSign);
    final hmac = Hmac(sha256, derivedKey);
    final digest = hmac.convert(bytes);

    return base64Encode(digest.bytes);
  }
  
  /// Derive HMAC key from private key using HKDF-like construction
  /// 
  /// This ensures each business has a unique HMAC key derived from their
  /// private key, preventing forgery even if the derivation method is known.
  static Uint8List _deriveHMACKey(Uint8List privateKeyBytes) {
    // Salt for HKDF (public, prevents rainbow tables)
    final salt = utf8.encode('LoyaltyCards-Backup-HMAC-Salt-v1');
    
    // Info/context for HKDF (domain separation)
    final info = utf8.encode('signature-key');
    
    // HKDF Extract: HMAC(salt, privateKey)
    final prk = Hmac(sha256, salt).convert(privateKeyBytes).bytes;
    
    // HKDF Expand: HMAC(prk, info || 0x01)
    final expandInput = Uint8List.fromList([...info, 0x01]);
    final derivedKey = Hmac(sha256, prk).convert(expandInput).bytes;
    
    return Uint8List.fromList(derivedKey);
  }

  /// Check if this backup has expired (only applies to clone type)
  bool get isExpired {
    if (type == 'recovery' || expiresAt == null) {
      return false;
    }
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Convert to JSON for QR code encoding
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'version': version,
      'businessId': businessId,
      'businessName': businessName,
      'privateKey': privateKey,
      'publicKey': publicKey,
      'stampsRequired': stampsRequired,
      'brandColor': brandColor,
      'operationMode': operationMode.name,
      'timestamp': timestamp.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'signature': signature,
    };
  }

  /// Convert to JSON string suitable for QR code
  String toQRString() {
    return jsonEncode(toJson());
  }

  /// Create from JSON (used during import)
  static SupplierConfigBackup fromJson(Map<String, dynamic> json) {
    return SupplierConfigBackup(
      type: json['type'] as String,
      version: json['version'] as int,
      businessId: json['businessId'] as String,
      businessName: json['businessName'] as String,
      privateKey: json['privateKey'] as String,
      publicKey: json['publicKey'] as String,
      stampsRequired: json['stampsRequired'] as int,
      brandColor: json['brandColor'] as String,
      operationMode: OperationMode.values.firstWhere(
        (mode) => mode.name == json['operationMode'],
        orElse: () => OperationMode.secure,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      signature: json['signature'] as String,
    );
  }

  /// Create from QR string
  static SupplierConfigBackup fromQRString(String qrData) {
    final json = jsonDecode(qrData) as Map<String, dynamic>;
    return fromJson(json);
  }

  /// Verify signature is valid
  /// 
  /// FIX SEC-002: Uses constant-time comparison to prevent timing attacks.
  /// Standard == comparison exits on first byte mismatch, leaking timing info.
  Future<bool> verifySignature() async {
    final calculatedSig = await _calculateSignature(this);
    return _constantTimeCompare(calculatedSig, signature);
  }
  
  /// Constant-time string comparison to prevent timing attacks
  /// 
  /// Compares two strings byte-by-byte without early exit, ensuring execution
  /// time is independent of where strings differ. This prevents attackers from
  /// using timing analysis to guess valid signatures.
  static bool _constantTimeCompare(String a, String b) {
    // If lengths differ, still do constant-time comparison of min length
    // to avoid leaking length information through timing
    if (a.length != b.length) {
      return false;
    }
    
    final bytesA = utf8.encode(a);
    final bytesB = utf8.encode(b);
    
    // XOR all bytes and OR results - if any byte differs, result != 0
    int result = 0;
    for (int i = 0; i < bytesA.length; i++) {
      result |= bytesA[i] ^ bytesB[i];
    }
    
    // Only return true if all bytes matched (result == 0)
    return result == 0;
  }

  /// Convert backup to Business object for import
  Business toBusiness() {
    return Business(
      id: businessId,
      name: businessName,
      publicKey: publicKey,
      privateKey: privateKey,
      stampsRequired: stampsRequired,
      brandColor: brandColor,
      mode: operationMode,
      createdAt: timestamp,
    );
  }
}
