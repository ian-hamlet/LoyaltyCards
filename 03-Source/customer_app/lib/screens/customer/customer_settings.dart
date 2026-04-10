import 'package:flutter/material.dart';
import '../../services/card_repository.dart';
import '../../services/stamp_repository.dart';
import '../../services/transaction_repository.dart';
import '../../services/database_helper.dart';

class CustomerSettings extends StatefulWidget {
  const CustomerSettings({super.key});

  @override
  State<CustomerSettings> createState() => _CustomerSettingsState();
}

class _CustomerSettingsState extends State<CustomerSettings> {
  final CardRepository _cardRepo = CardRepository(DatabaseHelper());
  final StampRepository _stampRepo = StampRepository(DatabaseHelper());
  final TransactionRepository _transactionRepo = TransactionRepository(DatabaseHelper());
  
  int _cardCount = 0;
  int _stampCount = 0;
  int _transactionCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final cards = await _cardRepo.getAllCards();
      final stamps = await _stampRepo.getAllStamps();
      final transactions = await _transactionRepo.getAllTransactions();
      
      setState(() {
        _cardCount = cards.length;
        _stampCount = stamps.length;
        _transactionCount = transactions.length;
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All data deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh stats
          await _loadStats();

          // Pop settings screen to return to (now empty) home
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          // Pop loading dialog
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAllData() async {
    // Delete all cards (stamps and transactions will CASCADE delete)
    final cards = await _cardRepo.getAllCards();
    for (final card in cards) {
      await _cardRepo.deleteCard(card.id);
    }
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
                // App Info Section
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
                  leading: const Icon(Icons.card_membership),
                  title: const Text('Loyalty Cards'),
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
                  leading: const Icon(Icons.history),
                  title: const Text('Transactions'),
                  trailing: Text(
                    '$_transactionCount',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF673AB7),
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
                  leading: Icon(Icons.info_outline),
                  title: Text('Version'),
                  subtitle: Text('1.0.0 (Beta)'),
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

                // Danger Zone
                const Padding(
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
                  onTap: _confirmAndDeleteAllData,
                ),

                const SizedBox(height: 32),

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
