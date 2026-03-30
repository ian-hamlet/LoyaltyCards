import 'package:flutter/material.dart';

class SupplierOnboarding extends StatefulWidget {
  final Function(String businessName, int stamps) onComplete;

  const SupplierOnboarding({super.key, required this.onComplete});

  @override
  State<SupplierOnboarding> createState() => _SupplierOnboardingState();
}

class _SupplierOnboardingState extends State<SupplierOnboarding> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  int _selectedStamps = 7;
  final List<int> _stampOptions = [5, 7, 10, 12, 15];

  @override
  void dispose() {
    _businessNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Setup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Header
              const Icon(
                Icons.store,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to LoyaltyCards',
                style: Theme.of(context).textTheme.headlineSmall,
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
              const SizedBox(height: 40),

              // Business Name
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  hintText: 'Joe\'s Coffee Shop',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your business name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Stamps Required
              Text(
                'Stamps Required for Reward',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Buy $_selectedStamps, Get ${_selectedStamps + 1}th FREE',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _stampOptions.map((stamps) {
                  final isSelected = stamps == _selectedStamps;
                  return ChoiceChip(
                    label: Text('$stamps stamps'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStamps = stamps;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              // Complete Button
              FilledButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onComplete(
                      _businessNameController.text,
                      _selectedStamps,
                    );
                  }
                },
                icon: const Icon(Icons.check),
                label: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Complete Setup',
                    style: TextStyle(fontSize: 16),
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
