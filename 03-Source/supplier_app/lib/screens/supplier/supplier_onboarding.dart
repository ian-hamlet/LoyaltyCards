import 'package:flutter/material.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:uuid/uuid.dart';
import 'package:pointycastle/ecc/api.dart';
import '../../services/key_manager.dart';
import '../../services/business_repository.dart';
import 'supplier_home.dart';
import 'how_it_works.dart';
import 'import_business_screen.dart';

class SupplierOnboarding extends StatefulWidget {
  const SupplierOnboarding({super.key});

  @override
  State<SupplierOnboarding> createState() => _SupplierOnboardingState();
}

class _SupplierOnboardingState extends State<SupplierOnboarding> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final KeyManager _keyManager = KeyManager();
  final BusinessRepository _businessRepo = BusinessRepository();
  final Uuid _uuid = const Uuid();

  int _stampsRequired = AppConstants.defaultStampsRequired;
  String _selectedColor = BrandColors.cardColorOptions.first;
  int _selectedLogoIndex = 0;
  OperationMode _selectedMode = OperationMode.secure; // Default to secure
  bool _isCreating = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _createBusiness() async {
    if (!_formKey.currentState!.validate()) {
      Haptics.error();
      return;
    }

    Haptics.medium();
    setState(() => _isCreating = true);

    try {
      AppLogger.business('Setting up new business');
      
      // Generate business ID
      final businessId = _uuid.v4();
      AppLogger.debug('Generated business ID: $businessId', 'Business');
      AppLogger.debug('Business name: ${_businessNameController.text.trim()}', 'Business');
      AppLogger.debug('Stamps required: $_stampsRequired', 'Business');
      AppLogger.debug('Brand color: $_selectedColor', 'Business');
      AppLogger.debug('Logo index: $_selectedLogoIndex', 'Business');
      AppLogger.debug('Operation mode: ${_selectedMode.displayName}', 'Business');

      // Generate key pair
      AppLogger.crypto('Generating cryptographic key pair');
      final keyPair = await _keyManager.generateKeyPair();
      AppLogger.crypto('Key pair generated successfully');

      // Store keys securely (cast to EC types)
      AppLogger.crypto('Storing private key in secure storage');
      await _keyManager.storePrivateKey(businessId, keyPair.privateKey as ECPrivateKey);
      AppLogger.crypto('Storing public key in secure storage');
      await _keyManager.storePublicKey(businessId, keyPair.publicKey as ECPublicKey);

      // Get public key as encoded string for database storage
      AppLogger.crypto('Retrieving public key for database storage');
      final publicKeyString = await _keyManager.getPublicKeyString(businessId);
      if (publicKeyString == null) {
        throw Exception('Failed to retrieve generated public key');
      }
      AppLogger.debug('Public key encoded (length: ${publicKeyString.length} chars)', 'Crypto');

      // Create business model (without private key in DB)
      final business = Business(
        id: businessId,
        name: _businessNameController.text.trim(),
        publicKey: publicKeyString, // Actual encoded public key for QR codes
        privateKey: '', // Not stored in database
        stampsRequired: _stampsRequired,
        brandColor: _selectedColor,
        logoIndex: _selectedLogoIndex,
        mode: _selectedMode,
        createdAt: DateTime.now(),
      );

      // Save to database
      AppLogger.database('Saving business configuration to database');
      await _businessRepo.insertBusiness(business);
      
      AppLogger.business('Business setup complete');

      if (mounted) {
        Haptics.success();
        // Navigate to home screen and clear all previous routes
        // Prevents back button from returning to onboarding/settings
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SupplierHome()),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        Haptics.error();
        AppFeedback.error(context, 'Error setting up business: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Setup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'How It Works',
            onPressed: () {
              Haptics.light();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HowItWorks()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                
                // Logo/Icon
                Icon(
                  Icons.storefront,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Title
                Text(
                  AppConstants.supplierAppName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Business Name
                TextFormField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(
                    labelText: 'Business Name',
                    hintText: 'e.g., Joe\'s Coffee Shop',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your business name';
                    }
                    if (value.trim().length < 2) {
                      return 'Business name must be at least 2 characters';
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {}),
                ),
                
                const SizedBox(height: 24),
                
                // Stamps Required
                Row(
                  children: [
                    const Text(
                      'Stamps Required',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'How many stamps customers need to earn a reward (3-20)',
                      child: Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _stampsRequired > 3
                          ? () {
                              Haptics.light();
                              setState(() => _stampsRequired--);
                            }
                          : null,
                      icon: const Icon(Icons.remove_circle),
                    ),
                    Text(
                      '$_stampsRequired stamps',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _stampsRequired < 20
                          ? () {
                              Haptics.light();
                              setState(() => _stampsRequired++);
                            }
                          : null,
                      icon: const Icon(Icons.add_circle),
                    ),
                  ],
                ),
                Slider(
                  value: _stampsRequired.toDouble(),
                  min: 3,
                  max: 20,
                  divisions: 17,
                  label: '$_stampsRequired',
                  onChanged: (value) {
                    setState(() => _stampsRequired = value.toInt());
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Operation Mode Selection
                Row(
                  children: [
                    const Text(
                      'Operation Mode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Simple: Fast, trust-based (coffee shops)\nSecure: Crypto validation (high-value)',
                      child: Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RadioListTile<OperationMode>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(OperationMode.simple.displayName),
                  subtitle: Text(
                    OperationMode.simple.description,
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: OperationMode.simple,
                  groupValue: _selectedMode,
                  onChanged: (value) {
                    Haptics.selection();
                    setState(() => _selectedMode = value!);
                  },
                ),
                RadioListTile<OperationMode>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(OperationMode.secure.displayName),
                  subtitle: Text(
                    OperationMode.secure.description,
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: OperationMode.secure,
                  groupValue: _selectedMode,
                  onChanged: (value) {
                    Haptics.selection();
                    setState(() => _selectedMode = value!);
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Brand Color
                const Text(
                  'Brand Color',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: BrandColors.cardColorOptions.map((color) {
                    final isSelected = color == _selectedColor;
                    return GestureDetector(
                      onTap: () {
                        Haptics.selection();
                        setState(() => _selectedColor = color);
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: BrandColors.fromHex(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 24),
                
                // Business Logo/Icon
                const Text(
                  'Business Icon',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildLogoOption(0, 'Store', Icons.storefront),
                    _buildLogoOption(1, 'Coffee', Icons.local_cafe),
                    _buildLogoOption(2, 'Restaurant', Icons.restaurant),
                    _buildLogoOption(3, 'Pizza', Icons.local_pizza),
                    _buildLogoOption(5, 'Bakery', Icons.bakery_dining),
                    _buildLogoOption(6, 'Dessert', Icons.icecream),
                    _buildLogoOption(8, 'Fast Food', Icons.fastfood),
                    _buildLogoOption(10, 'Grocery', Icons.local_grocery_store),
                    _buildLogoOption(11, 'Shopping', Icons.shopping_bag),
                    _buildLogoOption(13, 'Spa', Icons.spa),
                    _buildLogoOption(14, 'Gym', Icons.fitness_center),
                    _buildLogoOption(19, 'Pets', Icons.pets),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Preview
                if (_businessNameController.text.isNotEmpty) ...[
                  const Text(
                    'Preview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          BrandColors.fromHex(_selectedColor),
                          BrandColors.fromHex(_selectedColor).withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          BusinessIcons.getIcon(_selectedLogoIndex),
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _businessNameController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _stampsRequired < 10 ? _stampsRequired : 10,
                            (index) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_stampsRequired > 10)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '+ ${_stampsRequired - 10} more',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: AppSpacing.lg),
                
                // Divider with "OR"
                Row(
                  children: [
                    Expanded(child: Divider(thickness: 1, color: Colors.grey[400])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    Expanded(child: Divider(thickness: 1, color: Colors.grey[400])),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Import options
                Text(
                  'Already Have a Business?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Recover Existing Business button
                OutlinedButton.icon(
                  onPressed: () {
                    Haptics.medium();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ImportBusinessScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.restore, size: 24),
                  label: Text('Recover from Backup'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.all(16),
                    side: BorderSide(color: Colors.blue, width: 2),
                    foregroundColor: Colors.blue,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  'Restore your business if you lost your device',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Clone from Another Device button
                OutlinedButton.icon(
                  onPressed: () {
                    Haptics.medium();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ImportBusinessScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.device_hub, size: 24),
                  label: Text('Clone from Another Device'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.all(16),
                    side: BorderSide(color: Colors.green, width: 2),
                    foregroundColor: Colors.green,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  'Set up this device as an additional location',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FilledButton(
            onPressed: _isCreating ? null : _createBusiness,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(AppSpacing.md),
              backgroundColor: BrandColors.fromHex(_selectedColor),
            ),
            child: _isCreating
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Creating...',
                        style: TextStyle(fontSize: AppTypography.bodyLarge),
                      ),
                    ],
                  )
                : Text(
                    'Create Business Profile',
                    style: TextStyle(fontSize: AppTypography.bodyLarge),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoOption(int index, String label, IconData icon) {
    final isSelected = _selectedLogoIndex == index;
    final color = BrandColors.fromHex(_selectedColor);
    
    return GestureDetector(
      onTap: () {
        Haptics.selection();
        setState(() => _selectedLogoIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : Colors.grey[400]!,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? color : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
