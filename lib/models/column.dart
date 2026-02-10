import '../utils/type_mapper.dart';

/// Represents a database column definition
class Column {
  final String name;
  final String type;
  final bool isNullable;

  const Column(this.name, this.type, this.isNullable);

  /// Get Dart type representation
  String get dartType => TypeMapper.toDartType(type, isNullable: isNullable);

  /// Get Drift column type method
  String get driftType => TypeMapper.toDriftType(type);

  /// Get Drift column class name
  String get driftColumnType => TypeMapper.toDriftColumnType(type);

  /// Get JSON serialization code
  String jsonSerializer() => TypeMapper.toJsonSerializer(name, type);

  /// Get JSON deserialization code
  String fromJsonDeserializer(String jsonKey) =>
      TypeMapper.fromJsonDeserializer(jsonKey, type);

  /// Check if this is a special field (id, foreign keys, sync status, timestamps)
  bool get isSpecialField {
    return name == 'id' ||
        name == 'syncStatus' ||
        name == 'createdAt' ||
        name == 'updatedAt' ||
        name.endsWith('Id');
  }

  /// Check if this is a user-defined field
  bool get isUserField => !isSpecialField;

  /// Create a copy with modifications
  Column copyWith({
    String? name,
    String? type,
    bool? isNullable,
  }) {
    return Column(
      name ?? this.name,
      type ?? this.type,
      isNullable ?? this.isNullable,
    );
  }

  @override
  String toString() {
    return 'Column(name: $name, type: $type, nullable: $isNullable)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Column &&
        other.name == name &&
        other.type == type &&
        other.isNullable == isNullable;
  }

  @override
  int get hashCode => Object.hash(name, type, isNullable);

  /// Parse column from string definition
  /// Format: "name:type" or "name:type?"
  static Column parse(String definition) {
    final parts = definition.trim().split(':');
    if (parts.length != 2) {
      throw ArgumentError('Invalid column definition: $definition');
    }

    final name = parts[0].trim();
    final typeStr = parts[1].trim();
    final isNullable = typeStr.endsWith('?');
    final type =
        isNullable ? typeStr.substring(0, typeStr.length - 1) : typeStr;

    return Column(name, type, isNullable);
  }

  /// Parse multiple columns from comma-separated string
  static List<Column> parseList(String definitions) {
    if (definitions.trim().isEmpty) {
      return [];
    }

    return definitions.split(',').map((def) => parse(def)).toList();
  }
}
