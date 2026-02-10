import 'base_generator.dart';
import '../models/column.dart';

/// Generator for database tables
class DatabaseGenerator extends BaseGenerator {
  const DatabaseGenerator(super.config);

  @override
  Future<void> generate() async {
    await generateTable();
  }

  /// Generate Drift table definition
  Future<void> generateTable() async {
    final columnsCode =
        config.tableColumns.map(_buildColumnDefinition).join('\n');

    final content = '''
import 'package:drift/drift.dart';

class $featurePascal extends Table {
$columnsCode
}
''';

    await writeToFile(
      'lib/core/database/tables/${featureName}_table.dart',
      content,
    );
  }

  /// Build column definition for Drift table
  String _buildColumnDefinition(Column col) {
    if (col.name == 'id') {
      return '  IntColumn get id => integer().autoIncrement()();';
    } else if (col.name == 'syncStatus') {
      return '  TextColumn get syncStatus => text().withDefault(const Constant(\'pending\'))();';
    } else {
      final nullable = col.isNullable ? '.nullable()' : '';
      final typeMethod = col.driftType;
      return '  ${col.driftColumnType} get ${col.name} => $typeMethod$nullable();';
    }
  }
}
