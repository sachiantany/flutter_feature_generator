/// Utility class for mapping between different type systems
class TypeMapper {
  /// Map custom type to Dart type
  /// Example: string -> String, int -> int, DateTime -> DateTime
  static String toDartType(String type, {bool isNullable = false}) {
    final baseType = _mapToDartType(type);
    return isNullable ? '$baseType?' : baseType;
  }

  static String _mapToDartType(String type) {
    switch (type.toLowerCase()) {
      case 'string':
        return 'String';
      case 'int':
      case 'integer':
        return 'int';
      case 'datetime':
      case 'date':
        return 'DateTime';
      case 'double':
      case 'float':
        return 'double';
      case 'bool':
      case 'boolean':
        return 'bool';
      default:
        return 'String'; // Default to String for unknown types
    }
  }

  /// Map custom type to Drift column type method
  /// Example: int -> integer(), string -> text(), DateTime -> dateTime()
  static String toDriftType(String type) {
    switch (type.toLowerCase()) {
      case 'int':
      case 'integer':
        return 'integer()';
      case 'string':
        return 'text()';
      case 'datetime':
      case 'date':
        return 'dateTime()';
      case 'double':
      case 'float':
        return 'real()';
      case 'bool':
      case 'boolean':
        return 'boolean()';
      default:
        return 'text()';
    }
  }

  /// Map custom type to Drift column class name
  /// Example: int -> IntColumn, string -> TextColumn
  static String toDriftColumnType(String type) {
    switch (type.toLowerCase()) {
      case 'int':
      case 'integer':
        return 'IntColumn';
      case 'string':
        return 'TextColumn';
      case 'datetime':
      case 'date':
        return 'DateTimeColumn';
      case 'double':
      case 'float':
        return 'RealColumn';
      case 'bool':
      case 'boolean':
        return 'BoolColumn';
      default:
        return 'TextColumn';
    }
  }

  /// Get JSON serialization code for a type
  static String toJsonSerializer(String fieldName, String type) {
    switch (type.toLowerCase()) {
      case 'datetime':
      case 'date':
        return '$fieldName?.toIso8601String()';
      default:
        return fieldName;
    }
  }

  /// Get JSON deserialization code for a type
  static String fromJsonDeserializer(String jsonKey, String type) {
    switch (type.toLowerCase()) {
      case 'datetime':
      case 'date':
        return 'json[\'$jsonKey\'] != null ? DateTime.parse(json[\'$jsonKey\']) : null';
      case 'int':
      case 'integer':
        return 'json[\'$jsonKey\'] as int?';
      case 'double':
      case 'float':
        return 'json[\'$jsonKey\'] as double?';
      case 'bool':
      case 'boolean':
        return 'json[\'$jsonKey\'] as bool?';
      default:
        return 'json[\'$jsonKey\'] as String?';
    }
  }

  /// Validate if a type is supported
  static bool isValidType(String type) {
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
    return validTypes.contains(type.toLowerCase());
  }

  /// Get default value for a type
  static String getDefaultValue(String type) {
    switch (type.toLowerCase()) {
      case 'int':
      case 'integer':
        return '0';
      case 'double':
      case 'float':
        return '0.0';
      case 'bool':
      case 'boolean':
        return 'false';
      case 'string':
        return '\'\'';
      case 'datetime':
      case 'date':
        return 'DateTime.now()';
      default:
        return '\'\'';
    }
  }
}
