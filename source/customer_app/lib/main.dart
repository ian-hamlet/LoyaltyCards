import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/customer/customer_home.dart';
import 'services/biometric_auth_service.dart';

void main() {
  AppLogger.version(appVersion);
  AppLogger.info('Customer App starting at ${DateTime.now().toIso8601String()}');
  runApp(const CustomerApp());
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.customerAppName,
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

/// Wrapper widget that handles biometric authentication before showing app content
class AppLockWrapper extends StatefulWidget {
  const AppLockWrapper({super.key});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper> {
  bool _isAuthenticated = false;
  bool _isAuthenticating = true;
  final BiometricAuthService _biometricAuth = BiometricAuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthRequirement();
  }

  Future<void> _checkAuthRequirement() async {
    try {
      // Check if app lock is enabled
      final prefs = await SharedPreferences.getInstance();
      final bool requireAuth = prefs.getBool('require_app_lock') ?? false;

      if (!requireAuth) {
        // App lock disabled, proceed normally
        setState(() {
          _isAuthenticated = true;
          _isAuthenticating = false;
        });
        return;
      }

      // App lock enabled, require authentication
      AppLogger.info('App lock enabled, requesting authentication', 'Security');
      final authenticated = await _biometricAuth.authenticate(
        reason: 'Unlock LoyaltyCards to view your cards',
      );

      setState(() {
        _isAuthenticated = authenticated;
        _isAuthenticating = false;
      });

      if (!authenticated) {
        AppLogger.warning('Authentication failed, app locked', 'Security');
      }
    } catch (e) {
      AppLogger.error('Error checking auth requirement: $e', tag: 'Security');
      setState(() {
        _isAuthenticated = true; // Fail open for better UX
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticating) {
      // Show loading while checking authentication
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAuthenticated) {
      // Show locked screen
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

    // Authenticated, show home
    return const CustomerHome();
  }
}
