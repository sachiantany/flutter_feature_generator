import 'dart:async';

import '../lib/modes/interactive_mode.dart';
import '../lib/modes/command_line_mode.dart';
import '../lib/orchestrator.dart';

/// Main entry point for Flutter Feature Generator
///
/// Supports two modes:
/// - Interactive: dart run tools/bin/feature_gen.dart
/// - Command-line: dart run tools/bin/feature_gen.dart <feature> <parent> [columns]
Future<void> main(List<String> args) async {
  try {
    // Determine mode based on arguments
    final config = args.length >= 2
        ? await CommandLineMode.parse(args)
        : await InteractiveMode.run();

    // Generate feature
    final orchestrator = FeatureOrchestrator(config);
    await orchestrator.generate();

    // Print success message
    _printSuccessMessage(config);
  } catch (e) {
    print('\n❌ Error: $e');
    return;
  }
}

void _printSuccessMessage(config) {
  final naming = config.naming;

  print('\n╔═══════════════════════════════════════════════════════════╗');
  print('║  ✨ Success! Your feature is ready to use!              ║');
  print('╚═══════════════════════════════════════════════════════════╝');
  print('');
  print('📂 Location: lib/features/${naming.featureName}/');
  print('');
  print('🎯 What was generated:');
  print('   • Database table with ${config.columns.length} columns');
  print('   • Domain entities and repository interface');
  print('   • 8 use cases (CRUD + Search + Sync)');
  print('   • Data sources (local + remote)');
  print('   • BLoC with events and states');
  print('   • 3 UI pages (List, Detail, Form)');
  print('');
  print('📋 Next steps:');
  print('');
  print('1️⃣  Add table to @DriftDatabase in lib/core/database/app_database.dart:');
  print('   import \'tables/${naming.featureName}_table.dart\';');
  print('');
  print('   @DriftDatabase(');
  print('     tables: [');
  print('       // ... existing tables');
  print('       ${naming.featurePascal},  // ← Add this');
  print('     ],');
  print('   )');
  print('');
  print('2️⃣  Add DAO methods in AppDatabase class:');
  print('');
  _printDaoMethods(naming, config);
  print('');
  print('3️⃣  Update database version & add migration:');
  print('   static const int databaseVersion = X;  // Increment version');
  print('');
  print('   @override');
  print('   MigrationStrategy get migration {');
  print('     return MigrationStrategy(');
  print('       onUpgrade: (Migrator m, int from, int to) async {');
  print('         if (from < X) {');
  print('           await m.createTable(${naming.featureCamel});');
  print('         }');
  print('       },');
  print('     );');
  print('   }');
  print('');
  print('4️⃣  Run build runner:');
  print('   dart run build_runner build --delete-conflicting-outputs');
  print('');
}

void _printDaoMethods(naming, config) {
  final tableName = naming.featureCamel;
  final entityPascal = naming.entityPascal;
  final parentCamel = naming.parentCamel;
  final parentPascal = naming.parentPascal;
  final featurePascal = naming.featurePascal;

  // Get user columns for search example
  final userColumns = config.userColumns;
  final searchColumns = userColumns.where((col) =>
    col.dartType == 'String' || col.dartType == 'String?'
  ).take(2).toList();

  final searchConditions = searchColumns.isEmpty
    ? 'tbl.id.equals(query)'
    : searchColumns.map((col) => 'tbl.${col.name}.contains(query)').join(' |\n                ');

  print('   // $featurePascal DAO Methods');
  print('   Future<List<$entityPascal>> getAll$featurePascal() =>');
  print('       select($tableName).get();');
  print('');
  print('   Future<List<$entityPascal>> get${featurePascal}By${parentPascal}Id(int ${parentCamel}Id) =>');
  print('       (select($tableName)');
  print('         ..where((tbl) => tbl.${parentCamel}Id.equals(${parentCamel}Id)))');
  print('           .get();');
  print('');
  print('   Future<$entityPascal?> get${entityPascal}ById(int id) =>');
  print('       (select($tableName)');
  print('         ..where((tbl) => tbl.id.equals(id)))');
  print('           .getSingleOrNull();');
  print('');
  print('   Future<List<$entityPascal>> search$featurePascal(String query) =>');
  print('       (select($tableName)');
  print('         ..where((tbl) =>');
  print('               $searchConditions))');
  print('           .get();');
  print('');
  print('   Future<int> insert$entityPascal(${featurePascal}Companion entity) =>');
  print('       into($tableName).insert(entity);');
  print('');
  print('   Future<bool> update$entityPascal($entityPascal entity) =>');
  print('       update($tableName).replace(entity);');
  print('');
  print('   Future<int> delete$entityPascal(int id) =>');
  print('       (delete($tableName)..where((tbl) => tbl.id.equals(id))).go();');
  print('');
  print('   Future<List<$entityPascal>> getPending$featurePascal() =>');
  print('       (select($tableName)');
  print('         ..where((tbl) =>');
  print('               tbl.syncStatus.equals(\'pending\') |');
  print('               tbl.syncStatus.equals(\'failed\')))');
  print('           .get();');
  print('');
  print('   Future<int> getPending${featurePascal}Count() async {');
  print('     final query = selectOnly($tableName)');
  print('       ..addColumns([$tableName.id.count()])');
  print('       ..where(');
  print('         $tableName.syncStatus.equals(\'pending\') |');
  print('         $tableName.syncStatus.equals(\'failed\'),');
  print('       );');
  print('     final result = await query.getSingle();');
  print('     return result.read($tableName.id.count()) ?? 0;');
  print('   }');
  print('');
  print('   Future<int> markAs${entityPascal}Synced(int id) =>');
  print('       (update($tableName)..where((tbl) => tbl.id.equals(id)))');
  print('         .write(const ${featurePascal}Companion(syncStatus: Value(\'synced\')));');
}
