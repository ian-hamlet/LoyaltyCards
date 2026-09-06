/// Repository exception classes for consistent error handling
/// 
/// These exceptions are thrown by repository layers when data validation
/// or database operations fail. They work in ALL build modes (debug/release).
library;

/// Base exception for repository errors
class RepositoryException implements Exception {
  final String message;
  final dynamic cause;
  
  RepositoryException(this.message, {this.cause});
  
  @override
  String toString() => 'RepositoryException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Exception thrown when card data validation fails
class CardValidationException extends RepositoryException {
  CardValidationException(super.message);
  
  @override
  String toString() => 'CardValidationException: $message';
}

/// Exception thrown when stamp data validation fails
class StampValidationException extends RepositoryException {
  StampValidationException(super.message);
  
  @override
  String toString() => 'StampValidationException: $message';
}

/// Exception thrown when transaction data validation fails
class TransactionValidationException extends RepositoryException {
  TransactionValidationException(super.message);
  
  @override
  String toString() => 'TransactionValidationException: $message';
}

/// Exception thrown when business data validation fails
class BusinessValidationException extends RepositoryException {
  BusinessValidationException(super.message);
  
  @override
  String toString() => 'BusinessValidationException: $message';
}

/// Exception thrown when database constraint is violated
class DatabaseConstraintException extends RepositoryException {
  DatabaseConstraintException(super.message, {super.cause});
  
  @override
  String toString() => 'DatabaseConstraintException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}
