import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../widgets/feedback.dart';
import 'app_logger.dart';

/// Centralized error handling for consistent user feedback and logging
/// 
/// This class provides a unified approach to error handling across the app:
/// 1. All errors are logged for debugging
/// 2. User-friendly messages are shown to users
/// 3. Consistent UI feedback using AppFeedback
/// 
/// Usage:
/// ```dart
/// try {
///   await repository.updateCard(card);
/// } catch (e, stack) {
///   ErrorHandler.handle(
///     context,
///     'Update card',
///     e,
///     stack: stack,
///     userMessage: 'Could not save changes',
///   );
/// }
/// ```
class ErrorHandler {
  ErrorHandler._(); // Private constructor to prevent instantiation

  /// Handle an error with consistent logging and user feedback
  /// 
  /// Parameters:
  /// - [context]: BuildContext for showing user feedback
  /// - [operation]: Short description of what failed (e.g., "Update card")
  /// - [error]: The error object
  /// - [stack]: Optional stack trace for debugging
  /// - [showUser]: Whether to show error to user (default: true)
  /// - [userMessage]: Custom user-facing message (default: generated from error)
  static void handle(
    BuildContext context,
    String operation,
    dynamic error, {
    StackTrace? stack,
    bool showUser = true,
    String? userMessage,
  }) {
    // Always log the error for debugging
    AppLogger.error('$operation failed: $error', stackTrace: stack);
    
    // Conditionally show user feedback
    if (showUser) {
      final message = userMessage ?? _getUserFriendlyMessage(error, operation);
      AppFeedback.error(context, message);
    }
  }

  /// Handle an error without BuildContext (logging only)
  /// 
  /// Use this variant in services or non-UI code where you can't show feedback
  static void logOnly(
    String operation,
    dynamic error, {
    StackTrace? stack,
  }) {
    AppLogger.error('$operation failed: $error', stackTrace: stack);
  }

  /// Generate user-friendly error message from exception type
  static String _getUserFriendlyMessage(dynamic error, String operation) {
    // TimeoutException - operation took too long
    if (error is TimeoutException) {
      return 'Operation timed out. Please check your connection and try again.';
    }
    
    // FormatException - data parsing/validation failed
    if (error is FormatException) {
      return 'Invalid data format. ${error.message}';
    }
    
    // Database errors - check by error message since we can't import sqflite here
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('database') || errorString.contains('sqlite')) {
      if (errorString.contains('unique')) {
        return 'This record already exists.';
      }
      if (errorString.contains('foreign key')) {
        return 'Cannot complete operation - related data not found.';
      }
      return 'Database error. Please try again or contact support.';
    }
    
    // ArgumentError - invalid parameters
    if (error is ArgumentError) {
      return error.message?.toString() ?? 'Invalid input provided.';
    }
    
    // StateError - invalid operation state
    if (error is StateError) {
      return 'Operation not available in current state.';
    }
    
    // Generic fallback
    return '$operation failed. Please try again.';
  }

  /// Handle error with custom action button
  /// 
  /// Shows error message with a custom action button (e.g., "Retry", "Contact Support")
  static void handleWithAction(
    BuildContext context,
    String operation,
    dynamic error, {
    StackTrace? stack,
    required String actionLabel,
    required VoidCallback onAction,
    String? userMessage,
  }) {
    // Log the error
    AppLogger.error('$operation failed: $error', stackTrace: stack);
    
    // Show error with action button
    final message = userMessage ?? _getUserFriendlyMessage(error, operation);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BrandColors.error,
        action: SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: onAction,
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }
}
