import 'package:flutter/material.dart';
import 'customer_card_detail.dart';
import 'customer_add_card.dart';

// Mock data models (will be replaced with proper models later)
class LoyaltyCard {
  final String id;
  final String businessName;
  final int stampsRequired;
  final int stampsCollected;
  final Color brandColor;

  LoyaltyCard({
    required this.id,
    required this.businessName,
    required this.stampsRequired,
    required this.stampsCollected,
    required this.brandColor,
  });

  bool get isComplete => stampsCollected >= stampsRequired;
  int get stampsRemaining => stampsRequired - stampsCollected;
}

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  final List<LoyaltyCard> _cards = [
    LoyaltyCard(
      id: '1',
      businessName: "Joe's Coffee Shop",
      stampsRequired: 7,
      stampsCollected: 4,
      brandColor: Colors.brown,
    ),
    LoyaltyCard(
      id: '2',
      businessName: 'Pizza Palace',
      stampsRequired: 10,
      stampsCollected: 10,
      brandColor: Colors.red,
    ),
    LoyaltyCard(
      id: '3',
      businessName: 'Smoothie Bar',
      stampsRequired: 5,
      stampsCollected: 2,
      brandColor: Colors.green,
    ),
  ];

  void _addCard(LoyaltyCard card) {
    setState(() {
      _cards.add(card);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Loyalty Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Settings
            },
          ),
        ],
      ),
      body: _cards.isEmpty
          ? _buildEmptyState(context)
          : _buildCardList(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newCard = await Navigator.push<LoyaltyCard>(
            context,
            MaterialPageRoute(
              builder: (context) => const CustomerAddCard(),
            ),
          );
          if (newCard != null) {
            _addCard(newCard);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Card'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_membership_outlined,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'No Loyalty Cards Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Visit a participating business and scan their QR code to add your first loyalty card!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        return _LoyaltyCardWidget(
          card: card,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerCardDetail(card: card),
              ),
            );
          },
        );
      },
    );
  }
}

class _LoyaltyCardWidget extends StatelessWidget {
  final LoyaltyCard card;
  final VoidCallback onTap;

  const _LoyaltyCardWidget({
    required this.card,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                card.brandColor.withOpacity(0.1),
                card.brandColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: card.brandColor,
                    child: const Icon(Icons.store, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.businessName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          card.isComplete
                              ? 'Ready to redeem!'
                              : '${card.stampsRemaining} more to go',
                          style: TextStyle(
                            fontSize: 14,
                            color: card.isComplete ? Colors.green : Colors.grey[600],
                            fontWeight: card.isComplete ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (card.isComplete)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'COMPLETE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(card.stampsRequired, (index) {
                  final isCollected = index < card.stampsCollected;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _StampCircle(
                      isCollected: isCollected,
                      color: card.brandColor,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              
              // Counter
              Text(
                '${card.stampsCollected} / ${card.stampsRequired} stamps',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StampCircle extends StatelessWidget {
  final bool isCollected;
  final Color color;

  const _StampCircle({
    required this.isCollected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isCollected ? color : Colors.grey[200],
        shape: BoxShape.circle,
        border: Border.all(
          color: isCollected ? color : Colors.grey[400]!,
          width: 2,
        ),
      ),
      child: isCollected
          ? const Icon(Icons.check, color: Colors.white, size: 18)
          : null,
    );
  }
}
