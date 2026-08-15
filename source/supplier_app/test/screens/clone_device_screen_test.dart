import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:supplier_app/screens/supplier/clone_device_screen.dart';
import 'package:supplier_app/services/key_manager.dart';

/// Regression test for a first-frame bug found by manual testing: this
/// screen requires biometric authentication before it generates a clone QR
/// (CloneDeviceScreen._authenticateAndGenerate, called from initState) - same
/// local_auth mocking as recovery_backup_screen_test.dart is needed, since
/// under flutter_test no native plugin registration happens and
/// LocalAuthPlatform.instance falls back to a plain MethodChannel
/// ('plugins.flutter.io/local_auth').
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const localAuthChannel = MethodChannel('plugins.flutter.io/local_auth');
  const businessId = 'business-clone-device-test';

  late KeyManager keyManager;

  setUp(() async {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({});
    keyManager = KeyManager();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      localAuthChannel,
      (call) async {
        switch (call.method) {
          case 'getAvailableBiometrics':
            return <String>['fingerprint'];
          case 'isDeviceSupported':
            return true;
          case 'authenticate':
            return true;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(localAuthChannel, null);
  });

  Future<Business> seedBusiness(WidgetTester tester) async {
    final business = await tester.runAsync(() async {
      final keyPair = await keyManager.generateKeyPair();
      await keyManager.storePrivateKey(businessId, keyPair.privateKey as ECPrivateKey);
      await keyManager.storePublicKey(businessId, keyPair.publicKey as ECPublicKey);
      final publicKeyEncoded = (await keyManager.getPublicKeyString(businessId))!;

      return Business(
        id: businessId,
        name: 'Test Coffee Shop',
        publicKey: publicKeyEncoded,
        privateKey: 'unused-plaintext-field',
        stampsRequired: 10,
        brandColor: '#FF5733',
        mode: OperationMode.simple,
        createdAt: DateTime.now(),
      );
    });
    return business!;
  }

  testWidgets(
    'first frame shows the loading indicator, not "Failed to generate clone QR"',
    (tester) async {
      // Deliberately no settle here - this test is specifically about the
      // frame that renders immediately after pumpWidget(), before
      // initState()'s async authenticate-then-generate work has had any
      // chance to resolve. Regression test for a bug where _isGenerating
      // started false: that first frame fell into the "_cloneQR == null"
      // branch and showed "Failed to generate clone QR" - not an actual
      // failure, just the state not having caught up to what was already
      // in flight.
      final business = await seedBusiness(tester);

      await tester.pumpWidget(MaterialApp(home: CloneDeviceScreen(business: business)));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Failed to generate clone QR'), findsNothing);

      // Let the pending auth/generate work and its timer finish cleanly.
      await tester.pumpAndSettle();
    },
  );
}
