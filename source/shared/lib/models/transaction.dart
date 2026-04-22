/// Represents a transaction in the loyalty card system
enum TransactionType {
  pickup, // Customer picked up a new card
  stamp, // Customer received a stamp
  redemption, // Customer redeemed a completed card
}

class Transaction {
  final String id;
  final String cardId;
  final TransactionType type;
  final DateTime timestamp;
  final String businessName;
  final String? details; // Optional additional information

  Transaction({
    required this.id,
    required this.cardId,
    required this.type,
    required this.timestamp,
    required this.businessName,
    this.details,
  });

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'card_id': cardId,
      'type': type.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'business_name': businessName,
      'details': details,
    };
  }

  /// Create from JSON (from database)
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      cardId: json['card_id'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      businessName: json['business_name'] as String,
      details: json['details'] as String?,
    );
  }

  /// Create a copy with updated fields
  Transaction copyWith({
    String? id,
    String? cardId,
    TransactionType? type,
    DateTime? timestamp,
    String? businessName,
    String? details,
  }) {
    return Transaction(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      businessName: businessName ?? this.businessName,
      details: details ?? this.details,
    );
  }

  /// Get a human-readable description of the transaction
  String get description {
    switch (type) {
      case TransactionType.pickup:
        return 'Card picked up from $businessName';
      case TransactionType.stamp:
        return 'Stamp received at $businessName';
      case TransactionType.redemption:
        return 'Card redeemed at $businessName';
    }
  }

  @override
  String toString() {
    return 'Transaction(id: $id, type: ${type.name}, businessName: $businessName)';
  }
}
