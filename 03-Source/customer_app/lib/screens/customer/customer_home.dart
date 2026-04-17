import 'package:flutter/material.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:shared/models/card.dart' as models;
import 'package:shared/models/transaction.dart' as models;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../services/card_repository.dart';
import '../../services/transaction_repository.dart';
import '../../services/database_helper.dart';
import 'customer_card_detail.dart';
import 'customer_settings.dart';
import 'qr_scanner_screen.dart';
import 'how_it_works.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  final CardRepository _cardRepo = CardRepository(DatabaseHelper());
  final TransactionRepository _transactionRepo = TransactionRepository(DatabaseHelper());
  List<models.Card> _cards = [];
  List<models.Card> _filteredCards = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Filter preference
  bool _hideRedeemed = true; // Default: hide redeemed cards
  static const String _hideRedeemedKey = 'hide_redeemed_cards';

  @override
  void initState() {
    super.initState();
    _loadFilterPreference();
    _loadCards();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFilterPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hideRedeemed = prefs.getBool(_hideRedeemedKey) ?? true; // Default: hide redeemed
    });
  }

  Future<void> _setHideRedeemed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideRedeemedKey, value);
    setState(() {
      _hideRedeemed = value;
      _filterCards();
    });
    AppLogger.debug('Hide redeemed cards: $value', 'Filter');
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    try {
      final cards = await _cardRepo.getAllCards();
      setState(() {
        _cards = cards;
        _filterCards();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppFeedback.error(context, 'Error loading cards: $e');
      }
    }
  }

  void _filterCards() {
    var filtered = _cards;
    
    // Apply redeemed filter first
    if (_hideRedeemed) {
      filtered = filtered.where((card) => !card.isRedeemed).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((card) {
        return card.businessName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    _filteredCards = filtered;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterCards();
    });
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
      Haptics.medium();
      await _cardRepo.deleteCard(card.id);
      await _loadCards();
      if (mounted) {
        AppFeedback.success(context, '${card.businessName} deleted');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Loyalty Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'How It Works',
            onPressed: () {
              Haptics.light();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HowItWorks()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Haptics.light();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerSettings(),
                ),
              ).then((_) => _loadCards());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          if (_cards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search cards...',
                  hintStyle: const TextStyle(fontSize: AppTypography.bodyLarge),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            Haptics.light();
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          
          // Filter chips
          if (_cards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md)
                  .copyWith(bottom: AppSpacing.sm),
              child: Wrap(
                spacing: AppSpacing.sm,
                children: [
                  FilterChip(
                    label: Text(_hideRedeemed ? 'Hiding Redeemed Cards' : 'Showing Redeemed Cards'),
                    selected: _hideRedeemed,
                    onSelected: (value) {
                      Haptics.light();
                      _setHideRedeemed(value);
                    },
                    avatar: Icon(
                      _hideRedeemed ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          
          // Content
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: 3,
                    itemBuilder: (context, index) => const SkeletonCard(),
                  )
                : _filteredCards.isEmpty
                    ? _buildEmptyState(context)
                    : _buildCardList(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          Haptics.medium();
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QRScannerScreen(
                mode: QRScanMode.addCard,
              ),
            ),
          );
          
          if (result != null && mounted) {
            AppFeedback.success(context, result);
          }
          
          _loadCards(); // Reload after returning
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan your shop\'s QR code'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isEmpty = _cards.isEmpty;
    final message = isEmpty 
        ? AppStrings.customerNoCards 
        : 'No matching cards';
    final hint = isEmpty
        ? AppStrings.customerNoCardsHint
        : 'Try a different search term';
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEmpty ? Icons.card_membership_outlined : Icons.search_off,
              size: 100,
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
                fontSize: AppTypography.displaySmall,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: AppTypography.titleMedium,
              ),
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
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _filteredCards.length,
        itemBuilder: (context, index) {
          final card = _filteredCards[index];
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
              Haptics.medium();
              await _cardRepo.deleteCard(card.id);
              await _loadCards();
              if (mounted) {
                AppFeedback.success(context, '${card.businessName} deleted');
              }
            },
            child: _LoyaltyCardWidget(
              card: card,
              onTap: () async {
                Haptics.selection();
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
                    child: Icon(BusinessIcons.getIcon(card.logoIndex), color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                card.businessName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Mode indicator icon
                            Icon(
                              card.mode == OperationMode.simple 
                                  ? Icons.all_inclusive 
                                  : Icons.security_outlined,
                              size: 14,
                              color: card.mode == OperationMode.simple 
                                  ? Colors.blue[600] 
                                  : Colors.orange[700],
                            ),
                          ],
                        ),
                        Text(
                          card.isRedeemed
                              ? 'Reward claimed - you can delete this card'
                              : card.isComplete
                                  ? AppStrings.stampReadyToRedeem
                                  : '${card.stampsRequired - card.stampsCollected} more to go',
                          style: TextStyle(
                            fontSize: 14,
                            color: card.isRedeemed 
                                ? Colors.grey[600]
                                : card.isComplete 
                                    ? Colors.green 
                                    : Colors.grey[600],
                            fontWeight: card.isComplete && !card.isRedeemed ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (card.isRedeemed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'REDEEMED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (card.isComplete)
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
