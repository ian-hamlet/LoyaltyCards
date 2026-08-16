/// Represents a single stamp on a loyalty card
class Stamp {
  final String id;
  final String cardId;
  final int stampNumber; // 1-indexed (1, 2, 3...)
  final DateTime timestamp;
  final String signature; // Cryptographic signature from supplier
  final String? previousHash; // Hash of previous stamp for blockchain-like verification
  final String? deviceId; // Device ID where stamp was collected (V-005 multi-device detection)

  // Set only when this stamp was relocated from another card by the
  // overflow-splitting logic (a card completed with stamps left over,
  // spilling onto a new/existing card). The stamp's signature is a fixed
  // cryptographic commitment to the exact (cardId, stampNumber,
  // previousHash) it was originally signed with - it can't be recomputed
  // for a new position without the supplier's private key, so these fields
  // preserve that original context for redemption verification to check
  // the signature against, instead of the stamp's current (post-move)
  // position. Populated only by the app's own internal move logic, never
  // from anything a scanned QR token or user action controls - trusting
  // these fields is safe only because there's no path for the current
  // card to claim an arbitrary origin the app didn't itself record.
  final String? originalCardId;
  final int? originalStampNumber;
  final String? originalPreviousHash;

  Stamp({
    required this.id,
    required this.cardId,
    required this.stampNumber,
    required this.timestamp,
    required this.signature,
    this.previousHash,
    this.deviceId,
    this.originalCardId,
    this.originalStampNumber,
    this.originalPreviousHash,
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
      'original_card_id': originalCardId,
      'original_stamp_number': originalStampNumber,
      'original_previous_hash': originalPreviousHash,
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
      originalCardId: json['original_card_id'] as String?,
      originalStampNumber: json['original_stamp_number'] as int?,
      originalPreviousHash: json['original_previous_hash'] as String?,
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
    String? originalCardId,
    int? originalStampNumber,
    String? originalPreviousHash,
  }) {
    return Stamp(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      stampNumber: stampNumber ?? this.stampNumber,
      timestamp: timestamp ?? this.timestamp,
      signature: signature ?? this.signature,
      previousHash: previousHash ?? this.previousHash,
      deviceId: deviceId ?? this.deviceId,
      originalCardId: originalCardId ?? this.originalCardId,
      originalStampNumber: originalStampNumber ?? this.originalStampNumber,
      originalPreviousHash: originalPreviousHash ?? this.originalPreviousHash,
    );
  }

  /// TEST-018: builds a copy of this stamp for a new card/position, as
  /// created by the overflow-relocation logic when a completed card has
  /// stamps left over. Preserves the *original* signing context
  /// (originalCardId/originalStampNumber/originalPreviousHash) - the true
  /// first card/position this stamp was ever signed for, not whatever
  /// intermediate card it's currently on - so a stamp relocated more than
  /// once still resolves back to where its signature was actually issued.
  ///
  /// Centralizing the whole construction here (not just the original*
  /// fields) is deliberate: a hand-written `Stamp(...)` at each overflow
  /// call site previously let one of three call sites omit these fields
  /// entirely, silently dropping provenance and breaking signature
  /// verification for those stamps at redemption.
  Stamp relocateTo({
    required String id,
    required String cardId,
    required int stampNumber,
    String? previousHash,
  }) {
    return Stamp(
      id: id,
      cardId: cardId,
      stampNumber: stampNumber,
      timestamp: timestamp,
      signature: signature,
      previousHash: previousHash,
      deviceId: deviceId,
      originalCardId: originalCardId ?? this.cardId,
      originalStampNumber: originalStampNumber ?? this.stampNumber,
      originalPreviousHash: originalPreviousHash ?? this.previousHash,
    );
  }

  @override
  String toString() {
    return 'Stamp(id: $id, cardId: $cardId, number: $stampNumber, timestamp: $timestamp)';
  }
}
