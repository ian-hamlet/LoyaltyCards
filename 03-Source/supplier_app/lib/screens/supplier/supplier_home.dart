import 'package:flutter/material.dart';
import 'package:shared/shared.dart' hide Card;
import '../../services/business_repository.dart';
import '../../services/supplier_database_helper.dart';
import 'supplier_onboarding.dart';
import 'supplier_issue_card.dart';
import 'supplier_stamp_card.dart';
import 'supplier_redeem_card.dart';
import 'supplier_settings.dart';

class SupplierHome extends StatefulWidget {
  const SupplierHome({super.key});

  @override
  State<SupplierHome> createState() => _SupplierHomeState();
}

class _SupplierHomeState extends State<SupplierHome> {
  final BusinessRepository _businessRepo = BusinessRepository();
  Business? _business;
  bool _isLoading = true;
  int _issuedCards = 0;
  int _issuedStamps = 0;

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  Future<void> _loadBusinessData() async {
    setState(() => _isLoading = true);
    
    try {
      final business = await _businessRepo.getBusiness();
      
      if (business == null) {
        // No business configured - redirect to onboarding
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SupplierOnboarding()),
          );
        }
        return;
      }

      final cardCount = await _businessRepo.getIssuedCardCount();
      final stampCount = await _businessRepo.getIssuedStampCount();

      setState(() {
        _business = business;
        _issuedCards = cardCount;
        _issuedStamps = stampCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading business: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_business == null) {
      return const Scaffold(
        body: Center(child: Text('Loading...')),
      );
    }

    final brandColor = BrandColors.fromHex(_business!.brandColor);

    return Scaffold(
      appBar: AppBar(
        title: Text(_business!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SupplierSettings(business: _business!),
                ),
              ).then((_) => _loadBusinessData());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBusinessData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Business Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [brandColor, brandColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: brandColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.storefront, size: 60, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      _business!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_business!.stampsRequired} stamps to reward',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat('Stamps Issued', _issuedStamps),
                        Container(width: 1, height: 40, color: Colors.white30),
                        _buildStat('Cards (P2P)', _issuedCards),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),

              // Issue Card Button
              _ActionCard(
                icon: Icons.card_giftcard,
                title: AppStrings.supplierIssueCard,
                subtitle: 'Generate QR for new customer',
                color: BrandColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SupplierIssueCard(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Stamp Card Button
              _ActionCard(
                icon: Icons.qr_code_scanner,
                title: AppStrings.supplierStampCard,
                subtitle: 'Scan customer card to add stamp',
                color: BrandColors.info,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SupplierStampCard(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Redeem Card Button
              _ActionCard(
                icon: Icons.redeem,
                title: AppStrings.supplierRedeemCard,
                subtitle: 'Scan completed card for redemption',
                color: BrandColors.success,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SupplierRedeemCard(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Info Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How it Works',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoItem(
                        '1.',
                        'Issue Card',
                        'Show QR code for customer to scan and add your loyalty card',
                      ),
                      _buildInfoItem(
                        '2.',
                        'Stamp Card',
                        'Scan customer\'s card QR to add a cryptographically signed stamp',
                      ),
                      _buildInfoItem(
                        '3.',
                        'Redeem',
                        'When card is complete, scan to validate and redeem reward',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, int value) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: BrandColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
