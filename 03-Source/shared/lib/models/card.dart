/// Represents a loyalty card held by a customer
class Card {
  final String id;
  final String businessId;
  final String businessName;
  final String businessPublicKey;
  final int stampsRequired;
  final int stampsCollected;
  final String brandColor; // Hex color string
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRedeemed; // Track if card has been redeemed (prevents double redemption)

  Card({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.businessPublicKey,
    required this.stampsRequired,
    required this.stampsCollected,
    required this.brandColor,
    required this.createdAt,
    required this.updatedAt,
    this.isRedeemed = false,
  });

  /// Check if card is complete (all stamps collected)
  bool get isComplete => stampsCollected >= stampsRequired;

  /// Calculate progress percentage (0.0 to 1.0)
  double get progress => stampsCollected / stampsRequired;

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'business_name': businessName,
      'business_public_key': businessPublicKey,
      'stamps_required': stampsRequired,
      'stamps_collected': stampsCollected,
      'brand_color': brandColor,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_redeemed': isRedeemed ? 1 : 0,
    };
  }

  /// Create from JSON (from database)
  factory Card.fromJson(Map<String, dynamic> json) {
    return Card(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      businessName: json['business_name'] as String,
      businessPublicKey: json['business_public_key'] as String,
      stampsRequired: json['stamps_required'] as int,
      stampsCollected: json['stamps_collected'] as int,
      brandColor: json['brand_color'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int),
      isRedeemed: (json['is_redeemed'] as int?) == 1,
    );
  }

  /// Create a copy with updated fields
  Card copyWith({
    String? id,
    String? businessId,
    String? businessName,
    String? businessPublicKey,
    int? stampsRequired,
    int? stampsCollected,
    String? brandColor,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRedeemed,
  }) {
    return Card(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      businessPublicKey: businessPublicKey ?? this.businessPublicKey,
      stampsRequired: stampsRequired ?? this.stampsRequired,
      stampsCollected: stampsCollected ?? this.stampsCollected,
      brandColor: brandColor ?? this.brandColor,
      isRedeemed: isRedeemed ?? this.isRedeemed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Card(id: $id, businessName: $businessName, stamps: $stampsCollected/$stampsRequired)';
  }
}
