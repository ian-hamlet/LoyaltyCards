import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'screens/supplier/supplier_home.dart';

void main() {
  runApp(const SupplierApp());
}

class SupplierApp extends StatelessWidget {
  const SupplierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.supplierAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: BrandColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: AppConstants.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: BrandColors.primary,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SupplierHome(),
    );
  }
}
