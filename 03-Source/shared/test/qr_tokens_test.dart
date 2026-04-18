import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'dart:convert';

void main() {
  group('QR Token Models - Parsing', () {
    test('CardIssueToken - to and from JSON', () {
      final token = CardIssueToken(
        businessId: 'business-123',
        businessName: 'Test Coffee',
        publicKey: 'test-public-key',
        stampsRequired: 10,
        brandColor: '#FF5733',
        signature: 'test-signature',
        timestamp: 1234567890000,
      );

      final json = token.toJson();
      expect(json['type'], 'card_issue');
      expect(json['businessId'], 'business-123');
      expect(json['businessName'], 'Test Coffee');

      final decoded = CardIssueToken.fromJson(json);
      expect(decoded.businessId, token.businessId);
      expect(decoded.businessName, token.businessName);
      expect(decoded.publicKey, token.publicKey);
    });

    test('CardIssueToken - toQRString and fromQRString', () {
      final token = CardIssueToken(
        businessId: 'business-123',
        businessName: 'Test Coffee',
        publicKey: 'test-public-key',
        stampsRequired: 10,
        brandColor: '#FF5733',
        signature: 'test-signature',
        timestamp: 1234567890000,
      );

      final qrString = token.toQRString();
      expect(qrString, isA<String>());
      expect(qrString.isNotEmpty, true);

      final decoded = QRToken.fromQRString(qrString);
      expect(decoded, isA<CardIssueToken>());
      expect((decoded as CardIssueToken).businessId, token.businessId);
    });

    test('StampToken - to and from JSON', () {
      final token = StampToken(
        id: 'stamp-1',
        cardId: 'card-123',
        businessId: 'business-123',
        stampNumber: 1,
        previousHash: '',
        signature: 'test-signature',
        timestamp: 1234567890000,
      );

      final json = token.toJson();
      expect(json['type'], 'stamp_token');
      expect(json['stampNumber'], 1);

      final decoded = StampToken.fromJson(json);
      expect(decoded.cardId, token.cardId);
      expect(decoded.stampNumber, token.stampNumber);
    });

    test('CardStampRequestToken - to and from JSON', () {
      final token = CardStampRequestToken(
        cardId: 'card-123',
        businessId: 'business-123',
        currentStamps: 3,
        publicKey: 'test-public-key',
        lastStampHash: '',
        timestamp: 1234567890000,
      );

      final json = token.toJson();
      expect(json['type'], 'card_stamp_request');  
      expect(json['currentStamps'], 3);

      final decoded = CardStampRequestToken.fromJson(json);
      expect(decoded.cardId, token.cardId);
      expect(decoded.currentStamps, token.currentStamps);
    });

    test('RedemptionRequestToken - to and from JSON', () {
      final token = RedemptionRequestToken(
        cardId: 'card-123',
        businessId: 'business-123',
        stampsCollected: 10,
        stampSignatures: ['sig1', 'sig2', 'sig3'],
        timestamp: 1234567890000,
      );

      final json = token.toJson();
      expect(json['type'], 'redemption_request');
      expect(json['stampsCollected'], 10);
      expect(json['stampSignatures'], hasLength(3));

      final decoded = RedemptionRequestToken.fromJson(json);
      expect(decoded.cardId, token.cardId);
      expect(decoded.stampsCollected, token.stampsCollected);
      expect(decoded.stampSignatures, hasLength(3));
    });

    test('QRToken.fromQRString - returns null for invalid JSON', () {
      final invalidJson = 'not-valid-json';
      final result = QRToken.fromQRString(invalidJson);
      expect(result, isNull);
    });

    test('QRToken.fromQRString - returns null for unknown type', () {
      final json = jsonEncode({'type': 'unknown_type', 'data': 'test'});
      final result = QRToken.fromQRString(json);
      expect(result, isNull);
    });
  });

  group('QR Token Models - Validation', () {
    test('CardIssueToken - validates correct structure', () {
      final validToken = CardIssueToken(
        businessId: 'business-123',
        businessName: 'Test Coffee',
        publicKey: 'test-public-key',
        stampsRequired: 10,
        brandColor: '#FF5733',
        signature: 'test-signature',
        timestamp: 1234567890000,
      );

      expect(validToken.isValid(), true);
    });

    test('CardIssueToken - rejects empty businessId', () {
      final invalidToken = CardIssueToken(
        businessId: '',
        businessName: 'Test Coffee',
        publicKey: 'test-public-key',
        stampsRequired: 10,
        brandColor: '#FF5733',
        signature: 'test-signature',
        timestamp: 1234567890000,
      );

      expect(invalidToken.isValid(), false);
    });

    test('CardIssueToken - rejects invalid stamp requirements', () {
      final tooFew = CardIssueToken(
        businessId: 'business-123',
        businessName: 'Test Coffee',
        publicKey: 'test-public-key',
        stampsRequired: 3,
        brandColor: '#FF5733',
        signature: 'test-signature',
        timestamp: 1234567890000,
      );

      expect(tooFew.isValid(), false);

      final tooMany = CardIssueToken(
        businessId: 'business-123',
        businessName: 'Test Coffee',
        publicKey: 'test-public-key',
        stampsRequired: 25,
        brandColor: '#FF5733',
        signature: 'test-signature',
        timestamp: 1234567890000,
      );

      expect(tooMany.isValid(), false);
    });

    test('CardIssueToken - rejects invalid brand color', () {
      final invalidColor = CardIssueToken(
        businessId: 'business-123',
        businessName: 'Test Coffee',
        publicKey: 'test-public-key',
        stampsRequired: 10,
        brandColor: 'FF5733', // Missing #
        signature: 'test-signature',
        timestamp: 1234567890000,
      );

      expect(invalidColor.isValid(), false);
    });

    test('StampToken - validates correct structure', () {
      final validToken = StampToken(
        id: 'stamp-1',
        cardId: 'card-123',
        businessId: 'business-123',
        stampNumber: 1,
        previousHash: '',
        signature: 'test-signature',
        timestamp: 1234567890000,
      );

      expect(validToken.isValid(), true);
    });

    test('StampToken - rejects invalid stamp number', () {
      final invalidToken = StampToken(
        id: 'stamp-1',
        cardId: 'card-123',
        businessId: 'business-123',
        stampNumber: 0,
        previousHash: '',
        signature: 'test-signature',
        timestamp: 1234567890000,
      );

      expect(invalidToken.isValid(), false);
    });

    test('RedemptionRequestToken - validates correct structure', () {
      final validToken = RedemptionRequestToken(
        cardId: 'card-123',
        businessId: 'business-123',
        stampsCollected: 3,
        stampSignatures: ['sig1', 'sig2', 'sig3'],
        timestamp: 1234567890000,
      );

      expect(validToken.isValid(), true);
    });

    test('RedemptionRequestToken - rejects mismatched signature count', () {
      final invalidToken = RedemptionRequestToken(
        cardId: 'card-123',
        businessId: 'business-123',
        stampsCollected: 5,
        stampSignatures: ['sig1', 'sig2', 'sig3'], // Only 3 signatures
        timestamp: 1234567890000,
      );

      expect(invalidToken.isValid(), false);
    });
  });

  group('QR Token Models - Signature Data', () {
    test('CardIssueToken - generates correct signature data', () {
      final token = CardIssueToken(
        businessId: 'business-123',
        businessName: 'Test Coffee',
        publicKey: 'test-public-key',
        stampsRequired: 10,
        brandColor: '#FF5733',
        signature: 'test-signature',
        timestamp: 1234567890000,
      );

      final signatureData = token.getSignatureData();
      expect(signatureData, contains('business-123'));
      expect(signatureData, contains('Test Coffee'));
      expect(signatureData, contains('test-public-key'));
      expect(signatureData, contains('10'));
      expect(signatureData, contains('#FF5733'));
      expect(signatureData, contains('1234567890000'));
    });

    test('StampToken - generates correct signature data', () {
      final token = StampToken(
        id: 'stamp-1',
        cardId: 'card-123',
        businessId: 'business-123',
        stampNumber: 5,
        previousHash: 'prev-hash-123',
        signature: 'test-signature',
        timestamp: 1234567890000,
      );

      final signatureData = token.getSignatureData();
      expect(signatureData, contains('card-123'));
      expect(signatureData, contains('5'));
      expect(signatureData, contains('1234567890000'));
      expect(signatureData, contains('prev-hash-123'));
    });
  });
}
