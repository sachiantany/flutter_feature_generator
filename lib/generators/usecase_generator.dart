import 'base_generator.dart';
import '../utils/naming_converter.dart';

/// Generator for use cases
class UseCaseGenerator extends BaseGenerator {
  const UseCaseGenerator(super.config);

  @override
  Future<void> generate() async {
    await generateUseCases();
  }

  /// Generate all use cases
  Future<void> generateUseCases() async {
    final useCases = [
      _UseCaseDef('create', 'Create new $entitySingular',
          '${entityPascal}Entity', 'int'),
      _UseCaseDef('update', 'Update existing $entitySingular',
          '${entityPascal}Entity', 'void'),
      _UseCaseDef('delete', 'Delete $entitySingular by ID', 'int', 'void'),
      _UseCaseDef('get_all', 'Get all $featureName', 'NoParams',
          'List<${entityPascal}Entity>'),
      _UseCaseDef(
          'get_by_${parentEntity}_id',
          'Get $featureName by $parentEntity ID',
          'int',
          'List<${entityPascal}Entity>'),
      _UseCaseDef('get_by_id', 'Get $entitySingular by ID', 'int',
          '${entityPascal}Entity?'),
      _UseCaseDef('search', 'Search $featureName', 'String',
          'List<${entityPascal}Entity>'),
      _UseCaseDef(
          'sync_pending', 'Sync pending $featureName', 'NoParams', 'void'),
    ];

    for (final uc in useCases) {
      await _generateUseCase(uc);
    }

    // Generate NoParams class
    await _generateNoParams();
  }

  /// Generate individual use case
  Future<void> _generateUseCase(_UseCaseDef def) async {
    final ucPascal = NamingConverter.toPascal(def.name);
    final methodName = _getRepositoryMethodName(def.name);

    final content = '''
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:$packageName/core/errors/failures.dart';
import 'package:$packageName/features/$featureName/domain/entities/$entitySingular.dart';
import 'package:$packageName/features/$featureName/domain/repositories/${entitySingular}_repository.dart';

/// ${def.description}
@injectable
class $ucPascal${entityPascal}UseCase {
  final ${entityPascal}Repository repository;

  $ucPascal${entityPascal}UseCase(this.repository);

  Future<Either<Failure, ${def.returnType}>> call(${def.paramType} params) async {
    ${_generateUseCaseBody(def.name, methodName)}
  }
}
''';

    await writeToFile(
      'lib/features/$featureName/domain/usecases/${def.name}_${entitySingular}_usecase.dart',
      content,
    );
  }

  /// Get repository method name for use case
  String _getRepositoryMethodName(String useCaseName) {
    if (useCaseName == 'create') {
      return 'create$entityPascal';
    } else if (useCaseName == 'update') {
      return 'update$entityPascal';
    } else if (useCaseName == 'delete') {
      return 'delete$entityPascal';
    } else if (useCaseName == 'get_all') {
      return 'getAll$featurePascal';
    } else if (useCaseName == 'get_by_${parentEntity}_id') {
      return 'get${featurePascal}By${parentPascal}Id';
    } else if (useCaseName == 'get_by_id') {
      return 'get${entityPascal}ById';
    } else if (useCaseName == 'search') {
      return 'search$featurePascal';
    } else if (useCaseName == 'sync_pending') {
      return 'syncPending$featurePascal';
    } else {
      return useCaseName;
    }
  }

  /// Generate use case body
  String _generateUseCaseBody(String useCaseName, String methodName) {
    if (useCaseName == 'get_all' || useCaseName == 'sync_pending') {
      return 'return await repository.$methodName();';
    } else if (useCaseName == 'create' || useCaseName == 'update') {
      return 'return await repository.$methodName(params);';
    } else if (useCaseName == 'delete' ||
               useCaseName == 'get_by_id' ||
               useCaseName == 'search') {
      return 'return await repository.$methodName(params);';
    } else if (useCaseName == 'get_by_${parentEntity}_id') {
      return 'return await repository.$methodName(params);';
    } else {
      return 'return await repository.$methodName(params);';
    }
  }

  /// Generate NoParams class
  Future<void> _generateNoParams() async {
    final content = '''
import 'package:equatable/equatable.dart';

/// Represents no parameters for use cases
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
''';

    await writeToFile(
      'lib/features/$featureName/domain/usecases/no_params.dart',
      content,
    );
  }
}

/// Use case definition
class _UseCaseDef {
  final String name;
  final String description;
  final String paramType;
  final String returnType;

  const _UseCaseDef(
      this.name, this.description, this.paramType, this.returnType);
}
