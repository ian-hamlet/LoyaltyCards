import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/card_repository.dart';
import '../../services/stamp_repository.dart';
import '../../services/transaction_repository.dart';
import '../../services/database_helper.dart';
import '../../services/biometric_auth_service.dart';
import '../../utils/error_message_mapper.dart';

/// Feature flag: Show dangerous delete button during testing phase
/// Set to false before production App Store release
const bool _enableDeleteInRelease = true;

class CustomerSettings extends StatefulWidget {
  const CustomerSettings({super.key});

  @override
  State<CustomerSettings> createState() => _CustomerSettingsState();
}

class _CustomerSettingsState extends State<CustomerSettings> {
  final CardRepository _cardRepo = CardRepository(DatabaseHelper());
  final StampRepository _stampRepo = StampRepository(DatabaseHelper());
  final TransactionRepository _transactionRepo = TransactionRepository(DatabaseHelper());
  final BiometricAuthService _biometricAuth = BiometricAuthService();
  
  /// Check if dangerous delete button should be shown
  /// True in debug mode OR if explicitly enabled for TestFlight testing
  bool get _showDeleteButton => kDebugMode || _enableDeleteInRelease;
  
  int _cardCount = 0;
  int _stampCount = 0;
  int _completeCardsCount = 0;
  int _cardsAddedCount = 0;
  int _stampsEarnedCount = 0;
  int _redeemedCount = 0;
  bool _isLoading = true;
  bool _requireAppLock = false;
  bool _biometricAvailable = false;
  String _authMethodName = 'Biometric';

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final available = await _biometricAuth.isAvailable();
      final authName = await _biometricAuth.getAuthMethodName();
      
      setState(() {
        _requireAppLock = prefs.getBool('require_app_lock') ?? false;
        _biometricAvailable = available;
        _authMethodName = authName;
      });
    } catch (e) {
      AppLogger.error('Error loading security settings', error: e, tag: 'Settings');
      // Use defaults but log the error
      setState(() {
        _requireAppLock = false; // Safe default
        _biometricAvailable = false;
        _authMethodName = 'Passcode';
      });
    }
  }

  Future<void> _toggleAppLock(bool value) async {
    if (value) {
      // Enabling app lock - verify biometrics are available
      if (!_biometricAvailable) {
        if (mounted) {
          AppFeedback.error(
            context,
            'Biometric authentication is not available on this device',
          );
        }
        return;
      }

      // Test authentication before enabling
      final authenticated = await _biometricAuth.authenticate(
        reason: 'Verify authentication to enable app lock',
      );

      if (!authenticated) {
        if (mounted) {
          AppFeedback.error(context, 'Authentication failed');
        }
        return;
      }
    }

    // Save preference
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('require_app_lock', value);
      
      setState(() {
        _requireAppLock = value;
      });

      if (mounted) {
        AppFeedback.success(
          context,
          value ? 'App lock enabled' : 'App lock disabled',
        );
      }

      AppLogger.info('App lock ${value ? 'enabled' : 'disabled'}', 'Security');
    } catch (e) {
      AppLogger.error('Error toggling app lock', error: e, tag: 'Settings');
      
      // Revert UI state since save failed
      setState(() {
        _requireAppLock = !value;
      });
      
      if (mounted) {
        AppFeedback.error(
          context,
          'Could not save app lock setting. Please try again.',
        );
      }
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final cards = await _cardRepo.getAllCards();
      final stamps = await _stampRepo.getAllStamps();
      final transactions = await _transactionRepo.getAllTransactions();
      
      // Count transaction types
      final pickupTransactions = transactions.where((t) => t.type == TransactionType.pickup).toList();
      final stampTransactions = transactions.where((t) => t.type == TransactionType.stamp).toList();
      final redemptionTransactions = transactions.where((t) => t.type == TransactionType.redemption).toList();
      
      // Count complete cards (ready to redeem)
      final completeCards = cards.where((card) => 
        card.stampsCollected >= card.stampsRequired && !card.isRedeemed
      ).toList();
      
      setState(() {
        _cardCount = cards.length;
        _stampCount = stamps.length;
        _completeCardsCount = completeCards.length;
        _cardsAddedCount = pickupTransactions.length;
        _stampsEarnedCount = stampTransactions.length;
        _redeemedCount = redemptionTransactions.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmAndDeleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This will permanently delete:\n\n'
          '• All loyalty cards\n'
          '• All collected stamps\n'
          '• All transaction history\n\n'
          'This action cannot be undone.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Haptics.light();
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Haptics.error();
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Delete all data
        await _deleteAllData();

        if (mounted) {
          // Pop loading dialog
          Navigator.pop(context);

          // Show success message
          AppFeedback.success(context, 'All data deleted successfully');

          // Refresh stats
          await _loadStats();

          // Pop settings screen to return to (now empty) home
          Navigator.pop(context);
        }
      } catch (e) {
        AppLogger.error('Error deleting data', error: e, tag: 'Settings');
        if (mounted) {
          // Pop loading dialog
          Navigator.pop(context);

          AppFeedback.error(context, ErrorMessageMapper.forOperation(e, 'delete all data'));
        }
      }
    }
  }

  Future<void> _deleteAllData() async {
    AppLogger.database('Deleting all customer data');
    // Delete all cards (stamps and transactions will CASCADE delete)
    final cards = await _cardRepo.getAllCards();
    AppLogger.debug('Found ${cards.length} cards to delete', 'Data');
    for (final card in cards) {
      AppLogger.debug('Deleting card: ${card.id} (${card.businessName})', 'Data');
      await _cardRepo.deleteCard(card.id);
    }
    AppLogger.database('All data deleted successfully');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF673AB7),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Wallet Status Section
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Your Wallet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.card_membership),
                  title: const Text('Loyalty Cards'),
                  subtitle: const Text('Cards in your wallet'),
                  trailing: Text(
                    '$_cardCount',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF673AB7),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.auto_awesome),
                  title: const Text('Stamps Collected'),
                  subtitle: const Text('Total stamps on all cards'),
                  trailing: Text(
                    '$_stampCount',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF673AB7),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.celebration),
                  title: const Text('Ready to Redeem'),
                  subtitle: const Text('Complete cards awaiting redemption'),
                  trailing: Text(
                    '$_completeCardsCount',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF673AB7),
                    ),
                  ),
                ),

                const Divider(height: 32),

                // Activity History Section
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Activity History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.add_card),
                  title: const Text('Cards Added'),
                  subtitle: const Text('New cards you\'ve received'),
                  trailing: Text(
                    '$_cardsAddedCount',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF673AB7),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.star),
                  title: const Text('Stamps Earned'),
                  subtitle: const Text('Times you\'ve received stamps'),
                  trailing: Text(
                    '$_stampsEarnedCount',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF673AB7),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.card_giftcard),
                  title: const Text('Rewards Redeemed'),
                  subtitle: const Text('Completed cards you\'ve redeemed'),
                  trailing: Text(
                    '$_redeemedCount',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF673AB7),
                    ),
                  ),
                ),

                const Divider(height: 32),

                // App Information Section
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'App Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Version'),
                  subtitle: Text(appVersion),
                ),

                const Divider(height: 32),

                // Security Section
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Security',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: Text('Lock App with $_authMethodName'),
                  subtitle: Text(
                    _biometricAvailable
                        ? 'Require authentication to open app'
                        : 'Biometric authentication not available',
                  ),
                  value: _requireAppLock,
                  onChanged: _biometricAvailable ? _toggleAppLock : null,
                ),
                if (_requireAppLock)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Authentication will be required each time you open the app',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                const Divider(height: 32),

                // About Section
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'About',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.security),
                  title: Text('Data Storage'),
                  subtitle: Text('All data stored locally on your device'),
                ),
                const ListTile(
                  leading: Icon(Icons.lock),
                  title: Text('Privacy'),
                  subtitle: Text('No data is sent to external servers'),
                ),

                const Divider(height: 32),

                // Danger Zone - TestFlight/Debug only (controlled by feature flag)
                if (_showDeleteButton) ...[                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Danger Zone',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.warning, color: Colors.red),
                    title: const Text(
                      'Delete All Data',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text(
                      'Remove all cards, stamps, and transaction history',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Haptics.medium();
                      _confirmAndDeleteAllData();
                    },
                  ),
                  const SizedBox(height: 32),
                ],

                const Divider(height: 32),
                // App Version Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'App Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Version'),
                        subtitle: Text(appVersion),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),

                const Divider(height: 32),
                // Tips Section
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Tips',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• Pull down on home screen to refresh cards\n'
                        '• Tap a card to view details and stamps\n'
                        '• Delete single cards by long-pressing them\n'
                        '• Rate limit: 1 second between stamps\n'
                        '• All data is stored securely on your device',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
