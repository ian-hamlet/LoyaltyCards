import 'package:flutter/material.dart';
import 'supplier_onboarding.dart';
import 'supplier_issue_card.dart';
import 'supplier_stamp_card.dart';
import 'supplier_redeem_card.dart';

class SupplierHome extends StatefulWidget {
  const SupplierHome({super.key});

  @override
  State<SupplierHome> createState() => _SupplierHomeState();
}

class _SupplierHomeState extends State<SupplierHome> {
  bool _isOnboarded = false;
  String _businessName = 'My Coffee Shop';
  int _stampsRequired = 7;

  void _completeOnboarding(String businessName, int stamps) {
    setState(() {
      _isOnboarded = true;
      _businessName = businessName;
      _stampsRequired = stamps;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOnboarded) {
      return SupplierOnboarding(onComplete: _completeOnboarding);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_businessName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              setState(() {
                _isOnboarded = false;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.store, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _businessName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Buy $_stampsRequired, Get ${_stampsRequired + 1}th FREE',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Action Buttons
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _ActionCard(
                    icon: Icons.qr_code,
                    title: 'Issue Card',
                    subtitle: 'Give card to customer',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SupplierIssueCard(
                            businessName: _businessName,
                            stampsRequired: _stampsRequired,
                          ),
                        ),
                      );
                    },
                  ),
                  _ActionCard(
                    icon: Icons.add_circle,
                    title: 'Stamp Card',
                    subtitle: 'Add stamp to card',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SupplierStampCard(),
                        ),
                      );
                    },
                  ),
                  _ActionCard(
                    icon: Icons.card_giftcard,
                    title: 'Redeem Card',
                    subtitle: 'Complete reward',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SupplierRedeemCard(),
                        ),
                      );
                    },
                  ),
                  _ActionCard(
                    icon: Icons.bar_chart,
                    title: 'Statistics',
                    subtitle: 'View activity',
                    color: Colors.teal,
                    onTap: () {
                      _showStatistics(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatistics(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatRow('Stamps Issued Today', '23'),
            _StatRow('Redemptions Today', '3'),
            _StatRow('Active Cards', '156'),
            _StatRow('Total Cards Issued', '287'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
