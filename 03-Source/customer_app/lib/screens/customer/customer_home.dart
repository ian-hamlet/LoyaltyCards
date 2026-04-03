import 'package:flutter/material.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:shared/models/card.dart' as models;
import 'package:shared/models/transaction.dart' as models;
import 'package:uuid/uuid.dart';
import '../../services/card_repository.dart';
import '../../services/transaction_repository.dart';
import '../../services/database_helper.dart';
import 'customer_card_detail.dart';
import 'qr_scanner_screen.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  final CardRepository _cardRepo = CardRepository(DatabaseHelper());
  final TransactionRepository _transactionRepo = TransactionRepository(DatabaseHelper());
  List<models.Card> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    try {
      final cards = await _cardRepo.getAllCards();
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cards: $e')),
        );
      }
    }
  }

  Future<void> _addTestCard() async {
    final uuid = const Uuid();
    final testCard = models.Card(
      id: uuid.v4(),
      businessId: uuid.v4(),
      businessName: 'Test Coffee Shop',
      businessPublicKey: 'test-public-key',
      stampsRequired: 7,
      stampsCollected: 3,
      brandColor: '#8B4513',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _cardRepo.insertCard(testCard);
    
    // Add transaction
    final transaction = models.Transaction(
      id: uuid.v4(),
      cardId: testCard.id,
      type: TransactionType.pickup,
      timestamp: DateTime.now(),
      businessName: testCard.businessName,
    );
    await _transactionRepo.insertTransaction(transaction);

    await _loadCards();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test card added!')),
      );
    }
  }

  Future<void> _deleteCard(models.Card card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: Text('Delete "${card.businessName}" card?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cardRepo.deleteCard(card.id);
      await _loadCards();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${card.businessName} deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Loyalty Cards'),
        actions: [
          // Debug: Add test card button
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _addTestCard,
            tooltip: 'Add Test Card',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Settings - future
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? _buildEmptyState(context)
              : _buildCardList(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QRScannerScreen(
                mode: QRScanMode.addCard,
              ),
            ),
          );
          
          if (result != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result)),
            );
          }
          
          _loadCards(); // Reload after returning
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan Card'),
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
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.customerNoCards,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.customerNoCardsHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addTestCard,
              icon: const Icon(Icons.science),
              label: const Text('Add Test Card'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardList(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadCards,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          final card = _cards[index];
          return Dismissible(
            key: Key(card.id),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Card?'),
                  content: Text('Delete "${card.businessName}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (direction) async {
              await _cardRepo.deleteCard(card.id);
              await _loadCards();
            },
            child: _LoyaltyCardWidget(
              card: card,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerCardDetail(cardId: card.id),
                  ),
                );
                _loadCards(); // Reload in case card was updated
              },
            ),
          );
        },
      ),
    );
  }
}

class _LoyaltyCardWidget extends StatelessWidget {
  final models.Card card;
  final VoidCallback onTap;

  const _LoyaltyCardWidget({
    required this.card,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brandColor = BrandColors.fromHex(card.brandColor);
    
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
                brandColor.withValues(alpha: 0.1),
                brandColor.withValues(alpha: 0.05),
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
                    backgroundColor: brandColor,
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
                              ? AppStrings.stampReadyToRedeem
                              : '${card.stampsRequired - card.stampsCollected} more to go',
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
                        color: BrandColors.success,
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
                      color: brandColor,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              
              // Count
              Center(
                child: Text(
                  '${card.stampsCollected} / ${card.stampsRequired} ${AppStrings.stampsCollected}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCollected ? color : Colors.transparent,
        border: Border.all(
          color: isCollected ? color : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: isCollected
          ? const Icon(
              Icons.check,
              size: 16,
              color: Colors.white,
            )
          : null,
    );
  }
}
