import 'operation_mode.dart';

/// Represents a business/supplier configuration
class Business {
  final String id;
  final String name;
  final String publicKey;
  final String privateKey;
  final int stampsRequired;
  final String brandColor; // Hex color string
  final int logoIndex; // Business icon/logo index (0-99)
  final OperationMode mode; // Operation mode (simple or secure)
  final DateTime createdAt;
  final int scanInterval; // REQ-022: Customer scan rate limit in ms (default: 30000 = 30s)

  Business({
    required this.id,
    required this.name,
    required this.publicKey,
    required this.privateKey,
    required this.stampsRequired,
    required this.brandColor,
    this.logoIndex = 0,
    this.mode = OperationMode.secure, // Default to secure for backward compatibility
    required this.createdAt,
    this.scanInterval = 30000, // REQ-022: Default 30 seconds for simple mode
  });

  /// Convert to JSON for persistence (EXCLUDES private key for safety)
  Map<String, dynamic> toJson({bool includePrivateKey = false}) {
    final json = {
      'id': id,
      'name': name,
      'public_key': publicKey,
      'stamps_required': stampsRequired,
      'brand_color': brandColor,
      'logo_index': logoIndex,
      'mode': mode.toStorageString(),
      'created_at': createdAt.millisecondsSinceEpoch,
      'scan_interval_seconds': (scanInterval / 1000).round(), // REQ-022: Store as seconds
    };
    
    if (includePrivateKey) {
      json['private_key'] = privateKey;
    }
    
    return json;
  }

  /// Create from JSON (from database)
  factory Business.fromJson(Map<String, dynamic> json) {
    // REQ-022: Read scan_interval_seconds from DB, convert to ms
    final scanIntervalSeconds = json['scan_interval_seconds'] as int? ?? 30; // Default 30s
    final scanIntervalMs = scanIntervalSeconds * 1000;
    
    return Business(
      id: json['id'] as String,
      name: json['name'] as String,
      publicKey: json['public_key'] as String,
      privateKey: json['private_key'] as String? ?? '',
      stampsRequired: json['stamps_required'] as int,
      brandColor: json['brand_color'] as String,
      logoIndex: json['logo_index'] as int? ?? 0,
      mode: OperationModeExtension.fromString(json['mode'] as String? ?? 'secure'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      scanInterval: scanIntervalMs,
    );
  }

  /// Create a copy with updated fields
  Business copyWith({
    String? id,
    String? name,
    String? publicKey,
    String? privateKey,
    int? stampsRequired,
    String? brandColor,
    int? logoIndex,
    OperationMode? mode,
    DateTime? createdAt,
    int? scanInterval,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      publicKey: publicKey ?? this.publicKey,
      privateKey: privateKey ?? this.privateKey,
      stampsRequired: stampsRequired ?? this.stampsRequired,
      brandColor: brandColor ?? this.brandColor,
      logoIndex: logoIndex ?? this.logoIndex,
      mode: mode ?? this.mode,
      createdAt: createdAt ?? this.createdAt,
      scanInterval: scanInterval ?? this.scanInterval,
    );
  }

  @override
  String toString() {
    return 'Business(id: $id, name: $name, stampsRequired: $stampsRequired)';
  }
}
