import 'package:flutter/material.dart';

/// Business logo/icon options for visual differentiation
class BusinessIcons {
  BusinessIcons._(); // Private constructor to prevent instantiation

  /// List of available business icons
  /// Index 0 is the default (storefront) - used as fallback
  static const List<IconData> icons = [
    Icons.storefront,           // 0 - Default/Generic store
    Icons.local_cafe,           // 1 - Coffee shop
    Icons.restaurant,           // 2 - Restaurant
    Icons.local_pizza,          // 3 - Pizza
    Icons.local_bar,            // 4 - Bar/Drinks
    Icons.bakery_dining,        // 5 - Bakery
    Icons.icecream,             // 6 - Ice cream
    Icons.local_dining,         // 7 - Fine dining
    Icons.fastfood,             // 8 - Fast food
    Icons.ramen_dining,         // 9 - Asian food
    Icons.local_grocery_store,  // 10 - Grocery
    Icons.shopping_bag,         // 11 - Shopping/Retail
    Icons.local_florist,        // 12 - Flowers
    Icons.spa,                  // 13 - Spa/Wellness
    Icons.fitness_center,       // 14 - Gym/Fitness
    Icons.dry_cleaning,         // 15 - Laundry/Cleaning
    Icons.build,                // 16 - Hardware/Tools
    Icons.palette,              // 17 - Art/Creative
    Icons.headphones,           // 18 - Electronics/Music
    Icons.pets,                 // 19 - Pet store
  ];

  /// Get icon by index with fallback to default
  static IconData getIcon(int index) {
    if (index >= 0 && index < icons.length) {
      return icons[index];
    }
    return icons[0]; // Default fallback
  }

  /// Get icon name for UI display
  static String getIconName(int index) {
    const names = [
      'Store',
      'Coffee Shop',
      'Restaurant',
      'Pizza',
      'Bar',
      'Bakery',
      'Ice Cream',
      'Fine Dining',
      'Fast Food',
      'Asian Food',
      'Grocery',
      'Shopping',
      'Florist',
      'Spa',
      'Gym',
      'Laundry',
      'Hardware',
      'Art & Creative',
      'Electronics',
      'Pet Store',
    ];
    
    if (index >= 0 && index < names.length) {
      return names[index];
    }
    return 'Store';
  }
}
