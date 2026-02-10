import 'base_generator.dart';

/// Generator for domain layer (entities and repositories)
class DomainGenerator extends BaseGenerator {
  const DomainGenerator(super.config);

  @override
  Future<void> generate() async {
    await generateEntity();
    await generateRepository();
  }

  /// Generate domain entity
  Future<void> generateEntity() async {
    final fields = config.tableColumns
        .map((col) => '  final ${col.dartType} ${col.name};')
        .join('\n');

    final constructorParams = config.tableColumns.map((col) {
      if (col.name == 'id') {
        return '    required this.id,';
      } else if (col.name == 'syncStatus') {
        return '    this.syncStatus = \'pending\',';
      }
      final required = !col.isNullable ? 'required ' : '';
      return '    ${required}this.${col.name},';
    }).join('\n');

    final copyWithParams = config.copyWithColumns.map((col) {
      // If type is already nullable, don't add another ?
      final type = col.dartType.endsWith('?') ? col.dartType : '${col.dartType}?';
      return '    $type ${col.name},';
    }).join('\n');

    final copyWithAssignments = config.tableColumns.map((col) {
      if (col.name == 'id') {
        return '      id: id,';
      }
      return '      ${col.name}: ${col.name} ?? this.${col.name},';
    }).join('\n');

    final props =
        config.tableColumns.map((col) => '        ${col.name},').join('\n');

    final content = '''
import 'package:equatable/equatable.dart';

class ${entityPascal}Entity extends Equatable {
$fields

  const ${entityPascal}Entity({
$constructorParams
  });

  ${entityPascal}Entity copyWith({
$copyWithParams
  }) {
    return ${entityPascal}Entity(
$copyWithAssignments
    );
  }

  @override
  List<Object?> get props => [
$props
      ];
}
''';

    await writeToFile(
      'lib/features/$featureName/domain/entities/$entitySingular.dart',
      content,
    );
  }

  /// Generate repository interface
  Future<void> generateRepository() async {
    final content = '''
import 'package:dartz/dartz.dart';
import 'package:$packageName/core/errors/failures.dart';
import 'package:$packageName/features/$featureName/domain/entities/$entitySingular.dart';

abstract class ${entityPascal}Repository {
  /// Get all $featureName
  Future<Either<Failure, List<${entityPascal}Entity>>> getAll$featurePascal();
  
  /// Get $featureName by $parentEntity ID
  Future<Either<Failure, List<${entityPascal}Entity>>> get${featurePascal}By${parentPascal}Id(int ${parentCamel}Id);
  
  /// Get single $entitySingular by ID
  Future<Either<Failure, ${entityPascal}Entity?>> get${entityPascal}ById(int id);
  
  /// Search $featureName
  Future<Either<Failure, List<${entityPascal}Entity>>> search$featurePascal(String query);
  
  /// Create new $entitySingular
  Future<Either<Failure, int>> create$entityPascal(${entityPascal}Entity entity);
  
  /// Update existing $entitySingular
  Future<Either<Failure, void>> update$entityPascal(${entityPascal}Entity entity);
  
  /// Delete $entitySingular by ID
  Future<Either<Failure, void>> delete$entityPascal(int id);
  
  /// Sync pending $featureName to server
  Future<Either<Failure, void>> syncPending$featurePascal();
}
''';

    await writeToFile(
      'lib/features/$featureName/domain/repositories/${entitySingular}_repository.dart',
      content,
    );
  }
}
