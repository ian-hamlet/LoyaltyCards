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
      // Generate business ID
      final businessId = _uuid.v4();

      // Generate key pair
      final keyPair = await _keyManager.generateKeyPair();

      // Store keys securely (cast to EC types)
      await _keyManager.storePrivateKey(businessId, keyPair.privateKey as ECPrivateKey);
      await _keyManager.storePublicKey(businessId, keyPair.publicKey as ECPublicKey);

      // Get public key for storage
      final publicKey = await _keyManager.getPublicKey(businessId);
      if (publicKey == null) {
        throw Exception('Failed to retrieve generated public key');
      }

      // Create business model (without private key in DB)
      final business = Business(
        id: businessId,
        name: _businessNameController.text.trim(),
        publicKey: 'stored_in_keychain', // Placeholder, actual key in secure storage
        privateKey: '', // Not stored in database
        stampsRequired: _stampsRequired,
        brandColor: _selectedColor,
        createdAt: DateTime.now(),
      );

      // Save to database
      await _businessRepo.insertBusiness(business);

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
                  'Set up your loyalty card program',
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
}
