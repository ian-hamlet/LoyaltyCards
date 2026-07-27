import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/supplier/supplier_home.dart';
import 'services/biometric_auth_service.dart';

void main() {
  AppLogger.version(appVersion);
  AppLogger.info('Supplier App starting at ${DateTime.now().toIso8601String()}');
  runApp(const SupplierApp());
}

class SupplierApp extends StatelessWidget {
  const SupplierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.supplierAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: BrandColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: AppConstants.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: BrandColors.primary,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AppLockWrapper(),
    );
  }
}

/// Wrapper widget that handles biometric authentication before showing app
/// content - mirrors customer_app's AppLockWrapper (main.dart). The
/// supplier app already gates individual sensitive actions (viewing backup/
/// clone QR codes) behind biometrics, but had no optional app-wide lock at
/// all, unlike the customer app - this closes that gap. Arguably more
/// important here, since this app holds the business's private keys.
class AppLockWrapper extends StatefulWidget {
  const AppLockWrapper({super.key});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper> with WidgetsBindingObserver {
  bool _isAuthenticated = false;
  bool _isAuthenticating = true;
  bool _requireAppLock = false; // Cached from prefs, used by didChangeAppLifecycleState
  final BiometricAuthService _biometricAuth = BiometricAuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAuthRequirement();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      _handleAppPaused();
    } else if (state == AppLifecycleState.resumed && !_isAuthenticated && !_isAuthenticating) {
      _checkAuthRequirement();
    }
  }

  // Re-reads the preference fresh instead of trusting the cached
  // _requireAppLock - that cache is only otherwise refreshed at cold
  // launch or while already locked, so toggling app lock ON in Settings
  // mid-session (while still authenticated) would never re-lock on the
  // next background/foreground until the app was fully killed and
  // relaunched. SharedPreferences caches in memory after first load, so
  // this is effectively instant, not a real async round-trip.
  Future<void> _handleAppPaused() async {
    final prefs = await SharedPreferences.getInstance();
    _requireAppLock = prefs.getBool('require_app_lock') ?? false;
    if (!mounted) return;
    if (_requireAppLock && _isAuthenticated) {
      setState(() {
        _isAuthenticated = false;
      });
    }
  }

  Future<void> _checkAuthRequirement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool requireAuth = prefs.getBool('require_app_lock') ?? false;
      if (!mounted) return;
      _requireAppLock = requireAuth;

      if (!requireAuth) {
        setState(() {
          _isAuthenticated = true;
          _isAuthenticating = false;
        });
        return;
      }

      AppLogger.info('App lock enabled, requesting authentication', 'Security');
      final result = await _biometricAuth.authenticate(
        reason: 'Unlock LoyaltyCards Business to access your business',
      );
      if (!mounted) return;

      setState(() {
        _isAuthenticated = result.isSuccess;
        _isAuthenticating = false;
      });

      if (!result.isSuccess) {
        AppLogger.warning('Authentication failed, app locked', 'Security');
      }
    } catch (e) {
      // Fail closed, not open - matches customer_app's V-014 fix. A prefs
      // read failure or local_auth platform-channel error shouldn't bypass
      // authentication entirely.
      AppLogger.error('Error checking auth requirement: $e', tag: 'Security');
      if (!mounted) return;
      setState(() {
        _isAuthenticated = false;
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticating) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'App Locked',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Authentication required',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _checkAuthRequirement,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Authenticate'),
              ),
            ],
          ),
        ),
      );
    }

    return const SupplierHome();
  }
}
