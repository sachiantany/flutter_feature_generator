import '../utils/naming_converter.dart';
import 'column.dart';

/// Configuration for feature generation
class GenerationConfig {
  final String packageName;
  final String featureName;
  final String parentEntity;
  final List<Column> columns;
  final NamingVariants naming;

  GenerationConfig({
    required this.packageName,
    required this.featureName,
    required this.parentEntity,
    required this.columns,
  }) : naming = NamingConverter.getVariants(featureName, parentEntity);

  /// Create config with parsed columns from string
  factory GenerationConfig.fromString({
    required String packageName,
    required String featureName,
    required String parentEntity,
    String? columnsStr,
  }) {
    final columns = _buildColumns(featureName, parentEntity, columnsStr);

    return GenerationConfig(
      packageName: packageName,
      featureName: featureName,
      parentEntity: parentEntity,
      columns: columns,
    );
  }

  /// Build complete column list including auto-generated columns
  static List<Column> _buildColumns(
    String featureName,
    String parentEntity,
    String? columnsStr,
  ) {
    final customColumns = <Column>[];

    // Parse user-defined columns or use defaults
    if (columnsStr != null && columnsStr.isNotEmpty) {
      customColumns.addAll(Column.parseList(columnsStr));
    } else {
      // Default columns for a generic feature
      customColumns.addAll([
        const Column('remarkType', 'string', true),
        const Column('comment', 'string', true),
        const Column('timestamp', 'DateTime', false),
        const Column('status', 'string', true),
      ]);
    }

    // Build complete column list with auto-generated columns
    final parentCamel = NamingConverter.toCamel(parentEntity);

    return [
      const Column('id', 'int', false),
      Column('${parentCamel}Id', 'int', false),
      ...customColumns,
      const Column('syncStatus', 'string', false),
      const Column('createdAt', 'DateTime', false),
      const Column('updatedAt', 'DateTime', true),
    ];
  }

  /// Get only user-defined columns (excluding auto-generated)
  List<Column> get userColumns {
    return columns.where((col) => col.isUserField).toList();
  }

  /// Get columns for database table definition
  List<Column> get tableColumns => columns;

  /// Get columns for entity constructor (excluding id which has default)
  List<Column> get constructorColumns {
    return columns.where((col) => col.name != 'id').toList();
  }

  /// Get columns for copyWith method (excluding id)
  List<Column> get copyWithColumns {
    return columns.where((col) => col.name != 'id').toList();
  }

  @override
  String toString() {
    return '''
GenerationConfig(
  packageName: $packageName,
  featureName: $featureName,
  parentEntity: $parentEntity,
  columns: ${columns.length} columns
)''';
  }
}
