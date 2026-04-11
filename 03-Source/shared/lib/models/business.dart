/// Represents a business/supplier configuration
class Business {
  final String id;
  final String name;
  final String publicKey;
  final String privateKey;
  final int stampsRequired;
  final String brandColor; // Hex color string
  final int logoIndex; // Business icon/logo index (0-99)
  final DateTime createdAt;

  Business({
    required this.id,
    required this.name,
    required this.publicKey,
    required this.privateKey,
    required this.stampsRequired,
    required this.brandColor,
    this.logoIndex = 0,
    required this.createdAt,
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
      'created_at': createdAt.millisecondsSinceEpoch,
    };
    
    if (includePrivateKey) {
      json['private_key'] = privateKey;
    }
    
    return json;
  }

  /// Create from JSON (from database)
  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      name: json['name'] as String,
      publicKey: json['public_key'] as String,
      privateKey: json['private_key'] as String? ?? '',
      stampsRequired: json['stamps_required'] as int,
      brandColor: json['brand_color'] as String,
      logoIndex: json['logo_index'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
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
    DateTime? createdAt,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      publicKey: publicKey ?? this.publicKey,
      privateKey: privateKey ?? this.privateKey,
      stampsRequired: stampsRequired ?? this.stampsRequired,
      brandColor: brandColor ?? this.brandColor,
      logoIndex: logoIndex ?? this.logoIndex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Business(id: $id, name: $name, stampsRequired: $stampsRequired)';
  }
}
