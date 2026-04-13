/// QR Token Models for P2P Communication
/// 
/// These models define the data structures exchanged between supplier
/// and customer devices via QR codes.

import 'dart:convert';
import 'operation_mode.dart';

/// Base class for all QR token types
abstract class QRToken {
  final String type;
  final int timestamp;

  QRToken({
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toJson();

  String toQRString() {
    return jsonEncode(toJson());
  }

  static QRToken? fromQRString(String qrData) {
    try {
      final json = jsonDecode(qrData) as Map<String, dynamic>;
      final type = json['type'] as String?;

      switch (type) {
        case 'card_issue':
          return CardIssueToken.fromJson(json);
        case 'card_stamp_request':
          return CardStampRequestToken.fromJson(json);
        case 'stamp_token':
          return StampToken.fromJson(json);
        case 'redemption_request':
          return RedemptionRequestToken.fromJson(json);
        case 'redemption_token':
          return RedemptionToken.fromJson(json);
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }
}

/// Initial stamp data included in card issuance
class InitialStamp {
  final int stampNumber;
  final String signature;
  final int timestamp;

  InitialStamp({
    required this.stampNumber,
    required this.signature,
    required this.timestamp,
  });

  factory InitialStamp.fromJson(Map<String, dynamic> json) {
    return InitialStamp(
      stampNumber: json['stampNumber'] as int,
      signature: json['signature'] as String,
      timestamp: json['timestamp'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stampNumber': stampNumber,
      'signature': signature,
      'timestamp': timestamp,
    };
  }
}

/// Token for supplier to issue a new card to customer
class CardIssueToken extends QRToken {
  final String businessId;
  final String businessName;
  final String publicKey;
  final int stampsRequired;
  final String brandColor;
  final int logoIndex; // Business icon index (0-99)
  final OperationMode mode; // Operation mode for this card
  final String signature;
  final String? cardId; // Pre-generated card ID for signature consistency (optional for backward compatibility)
  final List<InitialStamp> initialStamps; // Pre-applied stamps at issuance

  CardIssueToken({
    required this.businessId,
    required this.businessName,
    required this.publicKey,
    required this.stampsRequired,
    required this.brandColor,
    this.logoIndex = 0,
    this.mode = OperationMode.secure,
    required this.signature,
    this.cardId,
    required int timestamp,
    this.initialStamps = const [],
  }) : super(type: 'card_issue', timestamp: timestamp);

  factory CardIssueToken.fromJson(Map<String, dynamic> json) {
    final initialStampsJson = json['initialStamps'] as List<dynamic>? ?? [];
    return CardIssueToken(
      businessId: json['businessId'] as String,
      businessName: json['businessName'] as String,
      publicKey: json['publicKey'] as String,
      stampsRequired: json['stampsRequired'] as int,
      brandColor: json['brandColor'] as String,
      logoIndex: json['logoIndex'] as int? ?? 0,
      mode: OperationModeExtension.fromString(json['mode'] as String? ?? 'secure'),
      signature: json['signature'] as String,
      cardId: json['cardId'] as String?,
      timestamp: json['timestamp'] as int,
      initialStamps: initialStampsJson
          .map((s) => InitialStamp.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = {
      'type': type,
      'businessId': businessId,
      'businessName': businessName,
      'publicKey': publicKey,
      'stampsRequired': stampsRequired,
      'brandColor': brandColor,
      'logoIndex': logoIndex,
      'mode': mode.toStorageString(),
      'timestamp': timestamp,
      'signature': signature,
      'initialStamps': initialStamps.map((s) => s.toJson()).toList(),
    };
    if (cardId != null) {
      map['cardId'] = cardId!;
    }
    return map;
  }

  /// Data string used for signature verification
  String getSignatureData() {
    // Include cardId only if present (backward compatibility)
    if (cardId != null) {
      return '$businessId:$businessName:$publicKey:$stampsRequired:$brandColor:$cardId:$timestamp';
    }
    return '$businessId:$businessName:$publicKey:$stampsRequired:$brandColor:$timestamp';
  }

  /// Validate token structure
  bool isValid() {
    if (businessId.isEmpty || businessName.isEmpty || publicKey.isEmpty) {
      return false;
    }
    if (stampsRequired < 5 || stampsRequired > 20) {
      return false;
    }
    if (!brandColor.startsWith('#') || brandColor.length != 7) {
      return false;
    }
    if (signature.isEmpty) {
      return false;
    }
    // If there are initial stamps, cardId must be present
    if (initialStamps.isNotEmpty && (cardId == null || cardId!.isEmpty)) {
      return false;
    }
    return true;
  }
}

/// Token for customer to request a stamp from supplier
class CardStampRequestToken extends QRToken {
  final String cardId;
  final String businessId;
  final int currentStamps;
  final String publicKey;
  final String lastStampHash; // Hash of previous stamp for chain validation

  CardStampRequestToken({
    required this.cardId,
    required this.businessId,
    required this.currentStamps,
    required this.publicKey,
    required this.lastStampHash,
    required int timestamp,
  }) : super(type: 'card_stamp_request', timestamp: timestamp);

  factory CardStampRequestToken.fromJson(Map<String, dynamic> json) {
    return CardStampRequestToken(
      cardId: json['cardId'] as String,
      businessId: json['businessId'] as String,
      currentStamps: json['currentStamps'] as int,
      publicKey: json['publicKey'] as String,
      lastStampHash: json['lastStampHash'] as String? ?? '',
      timestamp: json['timestamp'] as int,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'cardId': cardId,
      'businessId': businessId,
      'currentStamps': currentStamps,
      'publicKey': publicKey,
      'lastStampHash': lastStampHash,
      'timestamp': timestamp,
    };
  }

  /// Validate token structure
  bool isValid() {
    if (cardId.isEmpty || businessId.isEmpty || publicKey.isEmpty) {
      return false;
    }
    if (currentStamps < 0) {
      return false;
    }
    return true;
  }
}

/// Additional stamp in a multi-stamp operation
class AdditionalStamp {
  final int stampNumber;
  final String signature;
  final int timestamp;

  AdditionalStamp({
    required this.stampNumber,
    required this.signature,
    required this.timestamp,
  });

  factory AdditionalStamp.fromJson(Map<String, dynamic> json) {
    return AdditionalStamp(
      stampNumber: json['stampNumber'] as int,
      signature: json['signature'] as String,
      timestamp: json['timestamp'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stampNumber': stampNumber,
      'signature': signature,
      'timestamp': timestamp,
    };
  }
}

/// Token for supplier to issue a stamp to customer
class StampToken extends QRToken {
  final String id;
  final String cardId;
  final String businessId; // Added for simple mode card lookup
  final int stampNumber;
  final String previousHash;
  final String signature;
  final List<AdditionalStamp> additionalStamps; // For multi-stamp operations

  StampToken({
    required this.id,
    required this.cardId,
    required this.businessId,
    required this.stampNumber,
    required this.previousHash,
    required this.signature,
    required int timestamp,
    this.additionalStamps = const [],
  }) : super(type: 'stamp_token', timestamp: timestamp);

  factory StampToken.fromJson(Map<String, dynamic> json) {
    final additionalStampsJson = json['additionalStamps'] as List<dynamic>? ?? [];
    return StampToken(
      id: json['id'] as String,
      cardId: json['cardId'] as String,
      businessId: json['businessId'] as String? ?? '', // Backward compatibility
      stampNumber: json['stampNumber'] as int,
      previousHash: json['previousHash'] as String? ?? '',
      signature: json['signature'] as String,
      timestamp: json['timestamp'] as int,
      additionalStamps: additionalStampsJson
          .map((s) => AdditionalStamp.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'cardId': cardId,
      'businessId': businessId,
      'stampNumber': stampNumber,
      'timestamp': timestamp,
      'previousHash': previousHash,
      'signature': signature,
      'additionalStamps': additionalStamps.map((s) => s.toJson()).toList(),
    };
  }

  /// Data string used for signature verification
  String getSignatureData() {
    return '$cardId:$stampNumber:$timestamp:$previousHash';
  }

  /// Validate token structure
  bool isValid() {
    if (id.isEmpty || cardId.isEmpty || signature.isEmpty) {
      return false;
    }
    if (stampNumber < 1) {
      return false;
    }
    return true;
  }
}

/// Token for customer to request redemption from supplier
class RedemptionRequestToken extends QRToken {
  final String cardId;
  final String businessId;
  final int stampsCollected;
  final List<String> stampSignatures;

  RedemptionRequestToken({
    required this.cardId,
    required this.businessId,
    required this.stampsCollected,
    required this.stampSignatures,
    required int timestamp,
  }) : super(type: 'redemption_request', timestamp: timestamp);

  factory RedemptionRequestToken.fromJson(Map<String, dynamic> json) {
    return RedemptionRequestToken(
      cardId: json['cardId'] as String,
      businessId: json['businessId'] as String,
      stampsCollected: json['stampsCollected'] as int,
      stampSignatures: (json['stampSignatures'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      timestamp: json['timestamp'] as int,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'cardId': cardId,
      'businessId': businessId,
      'stampsCollected': stampsCollected,
      'stampSignatures': stampSignatures,
      'timestamp': timestamp,
    };
  }

  /// Validate token structure
  bool isValid() {
    if (cardId.isEmpty || businessId.isEmpty) {
      return false;
    }
    if (stampsCollected < 1) {
      return false;
    }
    if (stampSignatures.length != stampsCollected) {
      return false;
    }
    return true;
  }
}

/// Token for supplier to confirm redemption to customer (prevents double redemption)
class RedemptionToken extends QRToken {
  final String cardId;
  final String businessId;
  final int stampsRedeemed;
  final String signature; // Supplier signs: cardId:stampsRedeemed:timestamp

  RedemptionToken({
    required this.cardId,
    required this.businessId,
    required this.stampsRedeemed,
    required this.signature,
    required int timestamp,
  }) : super(type: 'redemption_token', timestamp: timestamp);

  factory RedemptionToken.fromJson(Map<String, dynamic> json) {
    return RedemptionToken(
      cardId: json['cardId'] as String,
      businessId: json['businessId'] as String,
      stampsRedeemed: json['stampsRedeemed'] as int,
      signature: json['signature'] as String,
      timestamp: json['timestamp'] as int,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'cardId': cardId,
      'businessId': businessId,
      'stampsRedeemed': stampsRedeemed,
      'signature': signature,
      'timestamp': timestamp,
    };
  }

  /// Data string used for signature verification
  String getSignatureData() {
    return '$cardId:$stampsRedeemed:$timestamp';
  }

  /// Validate token structure
  bool isValid() {
    if (cardId.isEmpty || businessId.isEmpty || signature.isEmpty) {
      return false;
    }
    if (stampsRedeemed < 1) {
      return false;
    }
    return true;
  }
}
