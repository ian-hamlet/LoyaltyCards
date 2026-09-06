import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:customer_app/services/device_service.dart';

/// Regression coverage for the Android device-identifier fix: `getDeviceId()`
/// used to hash `AndroidDeviceInfo.id` (Build.ID), which is a per-OS-build
/// tag shared by every device on the same firmware image, not a per-device
/// value - silently breaking the V-005 multi-device mismatch check for any
/// two Android devices on identical firmware. Fixed by generating and
/// persisting a random UUID on first run instead.
///
/// `getOrCreateAndroidInstallId()` is tested directly (not through
/// `getDeviceId()`) because it's deliberately not gated on
/// `Platform.isAndroid` - `flutter test` always runs as the host platform,
/// so there's no way to make `Platform.isAndroid` true in this suite.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const uuidV4Pattern =
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('generates a UUID v4 on first call', () async {
    final id = await DeviceService.getOrCreateAndroidInstallId();
    expect(id, matches(RegExp(uuidV4Pattern)));
  });

  test('persists the generated id across calls', () async {
    final first = await DeviceService.getOrCreateAndroidInstallId();
    final second = await DeviceService.getOrCreateAndroidInstallId();
    expect(second, equals(first));
  });

  test('returns a pre-existing persisted id unchanged, without regenerating it', () async {
    SharedPreferences.setMockInitialValues({
      'device_service_android_install_id': 'existing-install-id',
    });

    final id = await DeviceService.getOrCreateAndroidInstallId();

    expect(id, equals('existing-install-id'));
  });

  test('two installs (empty SharedPreferences each) get different ids', () async {
    final first = await DeviceService.getOrCreateAndroidInstallId();

    SharedPreferences.setMockInitialValues({});
    final second = await DeviceService.getOrCreateAndroidInstallId();

    expect(second, isNot(equals(first)));
  });
}
