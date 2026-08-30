import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:supplier_app/models/biometric_auth_result.dart';
import 'package:supplier_app/services/biometric_auth_service.dart';

/// Regression coverage for the Build 37 fix: `local_auth_android` 2.0.9 (and
/// `local_auth_darwin` 2.0.3, confirmed the same) throw `LocalAuthException`
/// for structured auth failures, not `PlatformException` - so
/// BiometricAuthService's specific error-code handling was dead code before
/// this fix, and every real failure fell through to a generic
/// "Unexpected error" message.
///
/// This substitutes `LocalAuthPlatform.instance` directly (the actual seam
/// `LocalAuthentication` delegates to) rather than mocking the
/// 'plugins.flutter.io/local_auth' MethodChannel used elsewhere in this test
/// suite: under `flutter test`, no platform-specific plugin is registered,
/// so the channel falls back to `DefaultLocalAuthPlatform`, which never
/// throws `LocalAuthException` at all - a channel-based mock could only ever
/// exercise the old `PlatformException` path, not the one this fix adds.
class _FakeLocalAuthPlatform extends LocalAuthPlatform {
  _FakeLocalAuthPlatform({
    this.authenticateResult = true,
    this.authenticateError,
    this.deviceSupportsBiometricsResult = true,
    this.isDeviceSupportedResult = true,
  });

  final bool authenticateResult;
  final Object? authenticateError;
  final bool deviceSupportsBiometricsResult;
  final bool isDeviceSupportedResult;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    required Iterable<AuthMessages> authMessages,
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    if (authenticateError != null) {
      throw authenticateError!;
    }
    return authenticateResult;
  }

  @override
  Future<bool> deviceSupportsBiometrics() async => deviceSupportsBiometricsResult;

  @override
  Future<bool> isDeviceSupported() async => isDeviceSupportedResult;

  @override
  Future<List<BiometricType>> getEnrolledBiometrics() async => <BiometricType>[];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BiometricAuthService service;

  setUp(() {
    service = BiometricAuthService();
  });

  group('BiometricAuthService.authenticate', () {
    test('success returns BiometricAuthResult.success', () async {
      LocalAuthPlatform.instance = _FakeLocalAuthPlatform(authenticateResult: true);
      final result = await service.authenticate(reason: 'test');
      expect(result.status, BiometricAuthStatus.success);
    });

    test('a false result (failed challenge, no exception) returns cancelled', () async {
      LocalAuthPlatform.instance = _FakeLocalAuthPlatform(authenticateResult: false);
      final result = await service.authenticate(reason: 'test');
      expect(result.status, BiometricAuthStatus.userCancelled);
    });

    test('not available on device (before ever calling authenticate)', () async {
      LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
        deviceSupportsBiometricsResult: false,
        isDeviceSupportedResult: false,
      );
      final result = await service.authenticate(reason: 'test');
      expect(result.status, BiometricAuthStatus.notAvailable);
    });

    group('LocalAuthException mapping (the actual exception type thrown in production)', () {
      test('noCredentialsSet maps to notEnrolled', () async {
        LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
          authenticateError: const LocalAuthException(code: LocalAuthExceptionCode.noCredentialsSet),
        );
        final result = await service.authenticate(reason: 'test');
        expect(result.status, BiometricAuthStatus.notEnrolled);
      });

      test('noBiometricsEnrolled maps to notEnrolled', () async {
        LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
          authenticateError: const LocalAuthException(code: LocalAuthExceptionCode.noBiometricsEnrolled),
        );
        final result = await service.authenticate(reason: 'test');
        expect(result.status, BiometricAuthStatus.notEnrolled);
      });

      test('noBiometricHardware maps to notAvailable', () async {
        LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
          authenticateError: const LocalAuthException(code: LocalAuthExceptionCode.noBiometricHardware),
        );
        final result = await service.authenticate(reason: 'test');
        expect(result.status, BiometricAuthStatus.notAvailable);
      });

      test('biometricHardwareTemporarilyUnavailable maps to notAvailable', () async {
        LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
          authenticateError: const LocalAuthException(
            code: LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable,
          ),
        );
        final result = await service.authenticate(reason: 'test');
        expect(result.status, BiometricAuthStatus.notAvailable);
      });

      test('biometricLockout maps to platformError with a too-many-attempts message', () async {
        LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
          authenticateError: const LocalAuthException(code: LocalAuthExceptionCode.biometricLockout),
        );
        final result = await service.authenticate(reason: 'test');
        expect(result.status, BiometricAuthStatus.platformError);
        expect(result.errorMessage, contains('Too many failed attempts'));
      });

      test('temporaryLockout maps to platformError with a temporarily-locked message', () async {
        LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
          authenticateError: const LocalAuthException(code: LocalAuthExceptionCode.temporaryLockout),
        );
        final result = await service.authenticate(reason: 'test');
        expect(result.status, BiometricAuthStatus.platformError);
        expect(result.errorMessage, contains('Temporarily locked'));
      });

      test('userCanceled maps to cancelled', () async {
        LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
          authenticateError: const LocalAuthException(code: LocalAuthExceptionCode.userCanceled),
        );
        final result = await service.authenticate(reason: 'test');
        expect(result.status, BiometricAuthStatus.userCancelled);
      });

      test('systemCanceled maps to cancelled', () async {
        LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
          authenticateError: const LocalAuthException(code: LocalAuthExceptionCode.systemCanceled),
        );
        final result = await service.authenticate(reason: 'test');
        expect(result.status, BiometricAuthStatus.userCancelled);
      });

      test('an unmapped code (e.g. deviceError) falls through to platformError, not a crash', () async {
        LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
          authenticateError: const LocalAuthException(
            code: LocalAuthExceptionCode.deviceError,
            description: 'simulated device error',
          ),
        );
        final result = await service.authenticate(reason: 'test');
        expect(result.status, BiometricAuthStatus.platformError);
        expect(result.errorMessage, contains('simulated device error'));
      });
    });

    test('PlatformException is still handled (defensive fallback path)', () async {
      LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
        authenticateError: PlatformException(code: 'NotEnrolled'),
      );
      final result = await service.authenticate(reason: 'test');
      expect(result.status, BiometricAuthStatus.notEnrolled);
    });

    test('a genuinely unexpected exception does not crash the caller', () async {
      LocalAuthPlatform.instance = _FakeLocalAuthPlatform(authenticateError: StateError('boom'));
      final result = await service.authenticate(reason: 'test');
      expect(result.status, BiometricAuthStatus.platformError);
      expect(result.errorMessage, 'Unexpected error during authentication');
    });
  });
}
