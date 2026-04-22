/// Represents a single stamp on a loyalty card
class Stamp {
  final String id;
  final String cardId;
  final int stampNumber; // 1-indexed (1, 2, 3...)
  final DateTime timestamp;
  final String signature; // Cryptographic signature from supplier
  final String? previousHash; // Hash of previous stamp for blockchain-like verification
  final String? deviceId; // Device ID where stamp was collected (V-005 multi-device detection)

  Stamp({
    required this.id,
    required this.cardId,
    required this.stampNumber,
    required this.timestamp,
    required this.signature,
    this.previousHash,
    this.deviceId,
  });

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'card_id': cardId,
      'stamp_number': stampNumber,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'signature': signature,
      'previous_hash': previousHash,
      'device_id': deviceId,
    };
  }

  /// Create from JSON (from database)
  factory Stamp.fromJson(Map<String, dynamic> json) {
    return Stamp(
      id: json['id'] as String,
      cardId: json['card_id'] as String,
      stampNumber: json['stamp_number'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      signature: json['signature'] as String,
      previousHash: json['previous_hash'] as String?,
      deviceId: json['device_id'] as String?,
    );
  }

  /// Create a copy with updated fields
  Stamp copyWith({
    String? id,
    String? cardId,
    int? stampNumber,
    DateTime? timestamp,
    String? signature,
    String? previousHash,
    String? deviceId,
  }) {
    return Stamp(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      stampNumber: stampNumber ?? this.stampNumber,
      timestamp: timestamp ?? this.timestamp,
      signature: signature ?? this.signature,
      previousHash: previousHash ?? this.previousHash,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  @override
  String toString() {
    return 'Stamp(id: $id, cardId: $cardId, number: $stampNumber, timestamp: $timestamp)';
  }
}
