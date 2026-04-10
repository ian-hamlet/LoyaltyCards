import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'screens/customer/customer_home.dart';

void main() {
  print('='.padRight(60, '='));
  print('CUSTOMER APP STARTING - ${DateTime.now().toIso8601String()}');
  print('Version: $appVersion');
  print('This is the NEW CODE with deployment verification');
  print('='.padRight(60, '='));
  runApp(const CustomerApp());
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.customerAppName,
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
      home: const CustomerHome(),
    );
  }
}
