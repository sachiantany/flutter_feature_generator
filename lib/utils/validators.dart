/// Validation utilities for user input
class Validators {
  /// Validates that a string is in snake_case format
  /// Example: valid: product_review, invalid: ProductReview, product-review
  static bool isSnakeCase(String value) {
    if (value.isEmpty) return false;
    return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(value);
  }

  /// Validates package name format
  static bool isValidPackageName(String value) {
    if (value.isEmpty) return false;
    // Package names must be lowercase, can contain underscores and numbers
    // Must start with a letter
    return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(value);
  }

  /// Validates feature name
  static bool isValidFeatureName(String value) {
    return isSnakeCase(value);
  }

  /// Validates entity name
  static bool isValidEntityName(String value) {
    return isSnakeCase(value);
  }

  /// Validates column definition string
  /// Format: name:type or name:type?
  static ValidationResult validateColumnDefinition(String definition) {
    final trimmed = definition.trim();

    if (trimmed.isEmpty) {
      return ValidationResult.error('Column definition cannot be empty');
    }

    final parts = trimmed.split(':');
    if (parts.length != 2) {
      return ValidationResult.error(
        'Invalid format. Expected: name:type (e.g., title:string)',
      );
    }

    final name = parts[0].trim();
    final typeStr = parts[1].trim();

    // Validate column name is a valid identifier (allow camelCase, snake_case, etc.)
    if (name.isEmpty || !RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(name)) {
      return ValidationResult.error(
        'Column name must be a valid identifier: $name',
      );
    }

    // Check if nullable
    final isNullable = typeStr.endsWith('?');
    final type =
        isNullable ? typeStr.substring(0, typeStr.length - 1) : typeStr;

    // Import TypeMapper for validation
    final validTypes = [
      'string',
      'int',
      'integer',
      'datetime',
      'date',
      'double',
      'float',
      'bool',
      'boolean'
    ];
    if (!validTypes.contains(type.toLowerCase())) {
      return ValidationResult.error(
        'Invalid type: $type. Valid types: ${validTypes.join(", ")}',
      );
    }

    return ValidationResult.success();
  }

  /// Validates multiple column definitions (comma-separated)
  static ValidationResult validateColumnsString(String columnsStr) {
    if (columnsStr.trim().isEmpty) {
      return ValidationResult.success(); // Empty is okay, will use defaults
    }

    final definitions = columnsStr.split(',');
    for (final def in definitions) {
      final result = validateColumnDefinition(def);
      if (!result.isValid) {
        return result;
      }
    }

    return ValidationResult.success();
  }
}

/// Result of a validation operation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult.success()
      : isValid = true,
        errorMessage = null;

  const ValidationResult.error(this.errorMessage) : isValid = false;

  @override
  String toString() {
    return isValid ? 'Valid' : 'Invalid: $errorMessage';
  }
}
