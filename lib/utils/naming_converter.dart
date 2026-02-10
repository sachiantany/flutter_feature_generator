/// Utility class for converting between naming conventions
class NamingConverter {
  /// Converts snake_case to PascalCase
  /// Example: product_review -> ProductReview
  static String toPascal(String str) {
    if (str.isEmpty) return str;
    return str
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join('');
  }

  /// Converts snake_case to camelCase
  /// Example: product_review -> productReview
  static String toCamel(String str) {
    if (str.isEmpty) return str;
    final words = str.split('_');
    return words.first +
        words.skip(1).map((w) => w[0].toUpperCase() + w.substring(1)).join('');
  }

  /// Converts PascalCase or camelCase to snake_case
  /// Example: ProductReview -> product_review
  static String toSnake(String str) {
    if (str.isEmpty) return str;
    return str
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => '_${match.group(1)!.toLowerCase()}',
        )
        .replaceFirst('_', '');
  }

  /// Converts plural to singular (simple version)
  /// Example: products -> product, reviews -> review
  static String toSingular(String str) {
    if (str.isEmpty) return str;

    // Handle common patterns
    if (str.endsWith('ies')) {
      return str.substring(0, str.length - 3) + 'y';
    }
    if (str.endsWith('ses') || str.endsWith('zes') || str.endsWith('xes')) {
      return str.substring(0, str.length - 2);
    }
    if (str.endsWith('s')) {
      return str.substring(0, str.length - 1);
    }

    return str;
  }

  /// Get all naming variations for a feature name
  static NamingVariants getVariants(String featureName, String parentEntity) {
    final entitySingular = toSingular(featureName);

    return NamingVariants(
      featureName: featureName,
      featurePascal: toPascal(featureName),
      featureCamel: toCamel(featureName),
      entitySingular: entitySingular,
      entityPascal: toPascal(entitySingular),
      entityCamel: toCamel(entitySingular),
      parentEntity: parentEntity,
      parentPascal: toPascal(parentEntity),
      parentCamel: toCamel(parentEntity),
    );
  }
}

/// Container for all naming variations
class NamingVariants {
  final String featureName;
  final String featurePascal;
  final String featureCamel;
  final String entitySingular;
  final String entityPascal;
  final String entityCamel;
  final String parentEntity;
  final String parentPascal;
  final String parentCamel;

  const NamingVariants({
    required this.featureName,
    required this.featurePascal,
    required this.featureCamel,
    required this.entitySingular,
    required this.entityPascal,
    required this.entityCamel,
    required this.parentEntity,
    required this.parentPascal,
    required this.parentCamel,
  });
}
