import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class HowItWorks extends StatelessWidget {
  const HowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How It Works'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section
              Center(
                child: Icon(
                  Icons.info_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              
              Text(
                'Digital Loyalty Cards Made Simple',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Step 1
              _buildStep(
                context,
                stepNumber: 1,
                icon: Icons.storefront,
                color: BrandColors.primary,
                title: 'Set Up Your Business',
                description: 'Configure your loyalty card program with your business name, brand colors, and rewards requirements. Choose how many stamps customers need to earn a reward.',
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Step 2
              _buildStep(
                context,
                stepNumber: 2,
                icon: Icons.qr_code_2,
                color: BrandColors.secondary,
                title: 'Add Cards to Customer Wallets',
                description: 'Customers can scan your business QR code to add your card to their wallet. Or, you can issue cards directly to customers—optionally pre-loaded with stamps for first-time bonuses or bulk purchases.',
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Step 3
              _buildStep(
                context,
                stepNumber: 3,
                icon: Icons.add_circle,
                color: BrandColors.accent,
                title: 'Issue Stamps',
                description: 'Scan a customer\'s QR code to add stamps to their card. You can add multiple stamps in a single operation—perfect for larger purchases or special promotions. It\'s fast and requires no personal data.',
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Step 4
              _buildStep(
                context,
                stepNumber: 4,
                icon: Icons.card_giftcard,
                color: BrandColors.success,
                title: 'Redeem Rewards',
                description: 'When a card is full, scan the customer\'s QR code to verify and redeem their reward. The card automatically resets for the next one.',
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Security Section
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: BrandColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: BrandColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Secure & Private',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Your cryptographic keys are generated and stored securely on this device. Each stamp is digitally signed to prevent fraud. No customer personal data is required or collected.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // QR Code Expiration Section
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: BrandColors.warningContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: BrandColors.warning,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Dynamic QR Codes',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'For security, QR codes are time-limited and regenerate automatically. If a QR code expires during use, simply refresh it by tapping the refresh button on the screen.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Offline Section
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: BrandColors.successContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cloud_off,
                          color: BrandColors.success,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Works Offline',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No internet connection required. The entire system works peer-to-peer using QR codes and digital signatures.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required int stepNumber,
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step number circle
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: AppSpacing.md),
        
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
