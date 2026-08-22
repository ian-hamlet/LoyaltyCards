/// QR Token Models for P2P Communication
/// 
/// These models define the data structures exchanged between supplier
/// and customer devices via QR codes.

import 'dart:convert';
import 'operation_mode.dart';
import '../utils/signature_format.dart';

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
    final stampNumber = json['stampNumber'] as int;
    final timestamp = json['timestamp'] as int;
    
    // Validation: stamp number must be positive
    if (stampNumber < 1) {
      throw FormatException('Invalid stamp number: $stampNumber (must be >= 1)');
    }
    
    // Validation: timestamp should not be in the far future (allow 5 min clock skew)
    final now = DateTime.now().millisecondsSinceEpoch;
    final maxFutureMs = 5 * 60 * 1000; // 5 minutes
    if (timestamp > now + maxFutureMs) {
      throw FormatException(
        'Timestamp in future: $timestamp (current: $now, max allowed: ${now + maxFutureMs})'
      );
    }
    
    return InitialStamp(
      stampNumber: stampNumber,
      signature: json['signature'] as String,
      timestamp: timestamp,
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
  /// DECISION-017: the single source of truth for the supported
  /// stampsRequired range, so the onboarding slider (supplier_onboarding.dart),
  /// this token's own validation below, and the supplier-side
  /// out-of-range detection (business_repository.dart /
  /// supplier_home.dart / supplier_issue_card.dart / supplier_settings.dart)
  /// can never drift apart the way they did across TEST-016/017/019 -
  /// each of those bugs was a bound defined in one place not matching a
  /// check defined in another.
  static const int minStampsRequired = 3;
  static const int maxStampsRequired = 12;

  static bool isStampsRequiredSupported(int stampsRequired) =>
      stampsRequired >= minStampsRequired && stampsRequired <= maxStampsRequired;

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
  ///
  /// Always includes cardId (empty string if null) for consistency.
  /// Format: businessId:businessName:publicKey:stampsRequired:brandColor:cardId:timestamp:mode
  ///
  /// V-011 fix: mode is now part of the signed data. Previously it was
  /// excluded, so a Secure Mode issuance token could have its mode field
  /// edited to "simple" after signing (signature still verified) and
  /// permanently downgrade the resulting card to skip all future
  /// signature/hash-chain checks.
  String getSignatureData() {
    final cardIdValue = cardId ?? '';
    return '$businessId:$businessName:$publicKey:$stampsRequired:$brandColor:$cardIdValue:$timestamp:${mode.toStorageString()}';
  }

  /// Validate token structure
  bool isValid() => validationError() == null;

  /// TEST-019: like [isValid], but reports *why* when invalid, instead of
  /// just true/false. A generic "invalid token" message is fine for a
  /// genuinely malformed/corrupt scan (retrying makes sense), but the
  /// stampsRequired-out-of-range case is different: it means the business's
  /// own stored configuration is incompatible with this app version, which
  /// no amount of retrying fixes - the customer needs to know that so they
  /// don't keep re-scanning a QR that will always fail the same way.
  String? validationError() {
    if (businessId.isEmpty || businessName.isEmpty || publicKey.isEmpty) {
      return 'This QR code is missing required information.';
    }
    // TEST-016: must match the onboarding slider's minimum (min: 3 in
    // supplier_onboarding.dart) - this was previously 5, silently rejecting
    // every card issued by a business configured for 3 or 4 stamps.
    //
    // TEST-017: upper bound originally lowered from 20 to 10 - a Secure
    // Mode redemption QR bundles one signature per stamp, and at 20
    // stamps the encoded payload sat at ~99.5% of the plain-JSON/byte-mode
    // QR capacity even with zero overflow-relocated stamps.
    //
    // TEST-020: raised from 10 to 12 now that RedemptionQrCodec
    // (gzip + Base45 + QR alphanumeric mode, see AlphanumericQr) is used
    // for the actual redemption QR instead of plain JSON/byte mode - a
    // 12-stamp card stays within capacity even at 100% overflow-relocated
    // stamps (the worst case), measured against the real qr package. See
    // DEFECT_TRACKER.md TEST-020 for the full size comparison.
    // CustomerCardDetail's _qrTooLargeToRender fallback remains as a
    // safety net for an already-issued pre-TEST-020 card, or any payload
    // that still doesn't fit for some other reason.
    //
    // TEST-019: a business created before this bound was tightened still
    // has its old, now-out-of-range stampsRequired stored, and issues
    // tokens with it forever (it can't be changed after setup without a
    // full reset that wipes customer data) - this is a real, permanent
    // backward-compatibility gap, not a hypothetical one. Reported here
    // with a specific, identifiable message (see ErrorMessageMapper) so
    // the customer isn't just told to keep retrying a scan that can never
    // succeed.
    if (!isStampsRequiredSupported(stampsRequired)) {
      return "This business's card is set up for $stampsRequired stamps, which this app version doesn't support (supported range: $minStampsRequired-$maxStampsRequired). This won't be fixed by scanning again - let the business know, they may need to update or reconfigure.";
    }
    if (!brandColor.startsWith('#') || brandColor.length != 7) {
      return 'This QR code has invalid formatting.';
    }
    if (signature.isEmpty) {
      return "This QR code couldn't be verified.";
    }
    // If there are initial stamps, cardId must be present
    if (initialStamps.isNotEmpty && (cardId == null || cardId!.isEmpty)) {
      return 'This QR code is missing required information.';
    }
    return null;
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
  
  // REQ-022: Enhanced Simple Mode fields
  final int stampCount; // Number of stamps this token grants (1-N)
  final int? expiryDate; // Optional expiry timestamp (null = no expiry)
  final int? scanInterval; // Supplier's configured rate limit in ms (null = use default)

  // Business profile snapshot fields (Requirements/DISCUSSION_Business_Field_Editing.md
  // §4). Populated by the supplier app at token-generation time as a
  // snapshot of the CURRENT Business record - deliberately outside
  // getSignatureData() below, since these are informational/display-only,
  // not trust-bearing (stamp-chain integrity doesn't depend on them). All
  // nullable: an older supplier app that never sends them, or an
  // already-in-circulation older-format token, decodes fine with these
  // simply absent - no crash, no behavior change from before this field
  // existed.
  final String? businessName;
  final String? brandColor;
  final int? logoIndex;
  final int? stampsRequired;

  StampToken({
    required this.id,
    required this.cardId,
    required this.businessId,
    required this.stampNumber,
    required this.previousHash,
    required this.signature,
    required int timestamp,
    this.additionalStamps = const [],
    this.stampCount = 1, // Default: 1 stamp (backward compatible)
    this.expiryDate, // Optional expiry
    this.scanInterval, // Optional rate limit override
    this.businessName,
    this.brandColor,
    this.logoIndex,
    this.stampsRequired,
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
      stampCount: json['stampCount'] as int? ?? 1, // REQ-022: Default 1 for backward compatibility
      expiryDate: json['expiryDate'] as int?, // REQ-022: Optional expiry
      scanInterval: json['scanInterval'] as int?, // REQ-022: Optional rate limit
      businessName: json['businessName'] as String?,
      brandColor: json['brandColor'] as String?,
      logoIndex: json['logoIndex'] as int?,
      stampsRequired: json['stampsRequired'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = {
      'type': type,
      'id': id,
      'cardId': cardId,
      'businessId': businessId,
      'stampNumber': stampNumber,
      'timestamp': timestamp,
      'previousHash': previousHash,
      'signature': signature,
      'additionalStamps': additionalStamps.map((s) => s.toJson()).toList(),
      'stampCount': stampCount, // REQ-022
    };

    // Only include optional fields if they have values
    // Use local variables to allow null-safety promotion
    final expiry = expiryDate;
    if (expiry != null) {
      json['expiryDate'] = expiry;
    }
    final interval = scanInterval;
    if (interval != null) {
      json['scanInterval'] = interval;
    }
    final name = businessName;
    if (name != null) {
      json['businessName'] = name;
    }
    final color = brandColor;
    if (color != null) {
      json['brandColor'] = color;
    }
    final logo = logoIndex;
    if (logo != null) {
      json['logoIndex'] = logo;
    }
    final required = stampsRequired;
    if (required != null) {
      json['stampsRequired'] = required;
    }

    return json;
  }

  /// Data string used for signature verification
  ///
  /// V-010 fix: stampCount, expiryDate, and scanInterval are now part of the
  /// signed data. Previously these were excluded, so tampering with
  /// stampCount after signing (e.g. changing 1 -> stampsRequired) did not
  /// invalidate the signature, letting one legitimate scan mint many
  /// unverified stamp rows. Must match the signing side exactly - see
  /// QRTokenGenerator.generateStampToken in supplier_app.
  String getSignatureData() {
    return SignatureFormat.stampChainData(
      cardId: cardId,
      stampNumber: stampNumber,
      timestampMs: timestamp,
      previousHash: previousHash,
      stampCount: stampCount,
      expiryDate: expiryDate,
      scanInterval: scanInterval,
    );
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

/// A single stamp's signature plus the timestamp it was originally signed
/// with (V-012 fix). The bare signature alone isn't enough for the supplier
/// to reconstruct what was signed - `timestamp` is required to rebuild
/// `cardId:stampNumber:timestamp:previousHash:...` for verification at
/// redemption time.
class RedemptionStampProof {
  final String signature;
  final int timestamp;

  // Set only when this stamp was relocated from another card by the
  // overflow-splitting logic - see Stamp's matching fields. When present,
  // the supplier must verify this proof's signature against this original
  // context instead of its position in this proof list, since that's what
  // the signature actually covers.
  final String? originalCardId;
  final int? originalStampNumber;
  final String? originalPreviousHash;

  RedemptionStampProof({
    required this.signature,
    required this.timestamp,
    this.originalCardId,
    this.originalStampNumber,
    this.originalPreviousHash,
  });

  factory RedemptionStampProof.fromJson(Map<String, dynamic> json) {
    return RedemptionStampProof(
      signature: json['signature'] as String,
      timestamp: json['timestamp'] as int,
      originalCardId: json['originalCardId'] as String?,
      originalStampNumber: json['originalStampNumber'] as int?,
      originalPreviousHash: json['originalPreviousHash'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'signature': signature,
      'timestamp': timestamp,
    };
    if (originalCardId != null) {
      map['originalCardId'] = originalCardId!;
    }
    if (originalStampNumber != null) {
      map['originalStampNumber'] = originalStampNumber!;
    }
    if (originalPreviousHash != null) {
      map['originalPreviousHash'] = originalPreviousHash!;
    }
    return map;
  }
}

/// Token for customer to request redemption from supplier
class RedemptionRequestToken extends QRToken {
  final String cardId;
  final String businessId;
  final int stampsCollected;
  final List<RedemptionStampProof> stampProofs;
  final String? cardDeviceId; // V-005: Device where card was created
  final String? currentDeviceId; // V-005: Device showing redemption QR

  RedemptionRequestToken({
    required this.cardId,
    required this.businessId,
    required this.stampsCollected,
    required this.stampProofs,
    required int timestamp,
    this.cardDeviceId,
    this.currentDeviceId,
  }) : super(type: 'redemption_request', timestamp: timestamp);

  factory RedemptionRequestToken.fromJson(Map<String, dynamic> json) {
    // V-012: accept legacy 'stampSignatures' (bare strings, no timestamp)
    // for backward compatibility with pre-fix tokens, but these can never
    // pass verification since timestamp is required to reconstruct the
    // signed data - they'll be rejected at the verification step, not here.
    final proofsJson = json['stampProofs'] as List<dynamic>?;
    final List<RedemptionStampProof> proofs;
    if (proofsJson != null) {
      proofs = proofsJson
          .map((e) => RedemptionStampProof.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      final legacySignatures = json['stampSignatures'] as List<dynamic>? ?? [];
      proofs = legacySignatures
          .map((e) => RedemptionStampProof(signature: e as String, timestamp: 0))
          .toList();
    }
    return RedemptionRequestToken(
      cardId: json['cardId'] as String,
      businessId: json['businessId'] as String,
      stampsCollected: json['stampsCollected'] as int,
      stampProofs: proofs,
      timestamp: json['timestamp'] as int,
      cardDeviceId: json['cardDeviceId'] as String?,
      currentDeviceId: json['currentDeviceId'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'cardId': cardId,
      'businessId': businessId,
      'stampsCollected': stampsCollected,
      'stampProofs': stampProofs.map((p) => p.toJson()).toList(),
      'timestamp': timestamp,
      'cardDeviceId': cardDeviceId,
      'currentDeviceId': currentDeviceId,
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
    if (stampProofs.length != stampsCollected) {
      return false;
    }
    return true;
  }
  
  /// Check if there's a device mismatch (V-005)
  /// Returns true if device IDs are present but don't match
  bool hasDeviceMismatch() {
    // If either ID is null, we can't determine mismatch (old cards)
    if (cardDeviceId == null || currentDeviceId == null) {
      return false;
    }
    // If both present, check if they differ
    return cardDeviceId != currentDeviceId;
  }
}

/// Token for supplier to confirm redemption to customer (prevents double redemption)
class RedemptionToken extends QRToken {
  final String cardId;
  final String businessId;
  final int stampsRedeemed;
  final String signature; // Supplier signs: cardId:stampsRedeemed:timestamp
  final String? cardDeviceId; // V-005: Device where card was created (null for old cards)
  final String? currentDeviceId; // V-005: Device showing redemption QR

  RedemptionToken({
    required this.cardId,
    required this.businessId,
    required this.stampsRedeemed,
    required this.signature,
    required int timestamp,
    this.cardDeviceId,
    this.currentDeviceId,
  }) : super(type: 'redemption_token', timestamp: timestamp);

  factory RedemptionToken.fromJson(Map<String, dynamic> json) {
    return RedemptionToken(
      cardId: json['cardId'] as String,
      businessId: json['businessId'] as String,
      stampsRedeemed: json['stampsRedeemed'] as int,
      signature: json['signature'] as String,
      timestamp: json['timestamp'] as int,
      cardDeviceId: json['cardDeviceId'] as String?,
      currentDeviceId: json['currentDeviceId'] as String?,
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
      'cardDeviceId': cardDeviceId,
      'currentDeviceId': currentDeviceId,
    };
  }

  /// Data string used for signature verification
  String getSignatureData() {
    return SignatureFormat.redemptionTokenData(
      cardId: cardId,
      stampsRedeemed: stampsRedeemed,
      timestampMs: timestamp,
    );
  }

  /// Validate token structure
  bool isValid() {
    if (cardId.isEmpty || businessId.isEmpty || signature.isEmpty) {
      return false;
    }
    // Stamps redeemed must be positive (> 0, not >= 1 for clarity)
    if (stampsRedeemed <= 0) {
      return false;
    }
    return true;
  }
}
