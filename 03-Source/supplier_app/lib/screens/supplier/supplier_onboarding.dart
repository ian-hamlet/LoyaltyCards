import 'package:flutter/material.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:uuid/uuid.dart';
import 'package:pointycastle/ecc/api.dart';
import '../../services/key_manager.dart';
import '../../services/business_repository.dart';
import 'supplier_home.dart';

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
  bool _isCreating = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _createBusiness() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      print('='.padRight(60, '='));
      print('SUPPLIER APP: SETTING UP NEW BUSINESS - ${DateTime.now().toIso8601String()}');
      
      // Generate business ID
      final businessId = _uuid.v4();
      print('Generated business ID: $businessId');
      print('Business name: ${_businessNameController.text.trim()}');
      print('Stamps required: $_stampsRequired');
      print('Brand color: $_selectedColor');
      print('Logo index: $_selectedLogoIndex');

      // Generate key pair
      print('Generating cryptographic key pair...');
      final keyPair = await _keyManager.generateKeyPair();
      print('Key pair generated successfully');

      // Store keys securely (cast to EC types)
      print('Storing private key in secure storage...');
      await _keyManager.storePrivateKey(businessId, keyPair.privateKey as ECPrivateKey);
      print('Storing public key in secure storage...');
      await _keyManager.storePublicKey(businessId, keyPair.publicKey as ECPublicKey);

      // Get public key as encoded string for database storage
      print('Retrieving public key for database storage...');
      final publicKeyString = await _keyManager.getPublicKeyString(businessId);
      if (publicKeyString == null) {
        throw Exception('Failed to retrieve generated public key');
      }
      print('Public key encoded (length: ${publicKeyString.length} chars)');

      // Create business model (without private key in DB)
      final business = Business(
        id: businessId,
        name: _businessNameController.text.trim(),
        publicKey: publicKeyString, // Actual encoded public key for QR codes
        privateKey: '', // Not stored in database
        stampsRequired: _stampsRequired,
        brandColor: _selectedColor,
        logoIndex: _selectedLogoIndex,
        createdAt: DateTime.now(),
      );

      // Save to database
      print('Saving business configuration to database...');
      await _businessRepo.insertBusiness(business);
      
      print('BUSINESS SETUP COMPLETE');
      print('='.padRight(60, '='));

      if (mounted) {
        // Navigate to home screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SupplierHome()),
        );
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting up business: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                
                // Logo/Icon
                Icon(
                  Icons.storefront,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                
                const SizedBox(height: 24),
                
                // Title
                Text(
                  AppConstants.supplierAppName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Set and configure your loyalty card program for your customers',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stamps Required',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'How many stamps to earn a reward?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: _stampsRequired > 3
                                  ? () => setState(() => _stampsRequired--)
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
                                  ? () => setState(() => _stampsRequired++)
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
                      ],
                    ),
                  ),
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
                      onTap: () => setState(() => _selectedColor = color),
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
                const SizedBox(height: 8),
                Text(
                  'Choose an icon to represent your business',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
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
                  const SizedBox(height: 32),
                ],
                
                // Create Button
                FilledButton(
                  onPressed: _isCreating ? null : _createBusiness,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: BrandColors.fromHex(_selectedColor),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Business Profile',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                
                const SizedBox(height: 16),
                
                // Info text
                Text(
                  'Your cryptographic keys will be generated and stored securely on this device.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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
      onTap: () => setState(() => _selectedLogoIndex = index),
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
