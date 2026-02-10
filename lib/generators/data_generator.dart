import 'base_generator.dart';

/// Generator for data layer (models, data sources, repository implementation)
class DataGenerator extends BaseGenerator {
  const DataGenerator(super.config);

  @override
  Future<void> generate() async {
    await generateModel();
    await generateLocalDataSource();
    await generateRemoteDataSource();
    await generateRepositoryImpl();
  }

  /// Generate data model
  Future<void> generateModel() async {
    final constructorParams = config.tableColumns.map((col) {
      if (col.name == 'id') {
        return '    required super.id,';
      } else if (col.name == 'syncStatus') {
        return '    super.syncStatus = \'pending\',';
      }
      final required = !col.isNullable ? 'required ' : '';
      return '    ${required}super.${col.name},';
    }).join('\n');

    final fromDbFields = config.tableColumns
        .map((col) => '      ${col.name}: entity.${col.name},')
        .join('\n');

    final toJsonFields = config.tableColumns
        .map((col) => '      \'${col.name}\': ${col.jsonSerializer()},')
        .join('\n');

    final fromJsonFields = config.tableColumns.map((col) {
      if (col.type.toLowerCase() == 'datetime') {
        return col.isNullable
            ? '      ${col.name}: json[\'${col.name}\'] != null ? DateTime.parse(json[\'${col.name}\']) : null,'
            : '      ${col.name}: DateTime.parse(json[\'${col.name}\']),';
      }
      return '      ${col.name}: json[\'${col.name}\']${col.isNullable ? '' : ' as ${col.dartType}'},';
    }).join('\n');

    final content = '''
import 'package:$packageName/core/database/app_database.dart';
import 'package:$packageName/features/$featureName/domain/entities/$entitySingular.dart';

class ${entityPascal}Model extends ${entityPascal}Entity {
  const ${entityPascal}Model({
$constructorParams
  });

  /// Create model from database entity
  factory ${entityPascal}Model.fromDatabase($entityPascal entity) {
    return ${entityPascal}Model(
$fromDbFields
    );
  }

  /// Create model from JSON
  factory ${entityPascal}Model.fromJson(Map<String, dynamic> json) {
    return ${entityPascal}Model(
$fromJsonFields
    );
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
$toJsonFields
    };
  }

  /// Convert to database companion for insert
  ${featurePascal}Companion toCompanion() {
    return ${featurePascal}Companion.insert(
${config.constructorColumns.map((col) {
      if (col.isNullable) {
        return '      ${col.name}: drift.Value(${col.name}),';
      }
      return '      ${col.name}: ${col.name},';
    }).join('\n')}
    );
  }
}
''';

    await writeToFile(
      'lib/features/$featureName/data/models/${entitySingular}_model.dart',
      content,
    );
  }

  /// Generate local data source (Drift)
  Future<void> generateLocalDataSource() async {
    // Generate companion fields for create
    final companionFields = config.constructorColumns.map((col) {
      return '          ${col.name}: drift.Value(model.${col.name}),';
    }).join('\n');

    // Generate entity fields for update
    final entityFields = config.tableColumns.map((col) {
      return '          ${col.name}: model.${col.name},';
    }).join('\n');

    final content = '''
import 'package:injectable/injectable.dart';
import 'package:$packageName/core/database/app_database.dart';
import 'package:$packageName/features/$featureName/data/models/${entitySingular}_model.dart';
import 'package:drift/drift.dart' as drift;

abstract class ${entityPascal}LocalDataSource {
  Future<List<${entityPascal}Model>> getAll$featurePascal();
  Future<List<${entityPascal}Model>> get${featurePascal}By${parentPascal}Id(int ${parentCamel}Id);
  Future<${entityPascal}Model?> get${entityPascal}ById(int id);
  Future<List<${entityPascal}Model>> search$featurePascal(String query);
  Future<int> create$entityPascal(${entityPascal}Model model);
  Future<void> update$entityPascal(${entityPascal}Model model);
  Future<void> delete$entityPascal(int id);
  Future<List<${entityPascal}Model>> getPending$featurePascal();
  Future<void> markAsSynced(int id);
}

@Injectable(as: ${entityPascal}LocalDataSource)
class ${entityPascal}LocalDataSourceImpl implements ${entityPascal}LocalDataSource {
  final AppDatabase database;

  ${entityPascal}LocalDataSourceImpl(this.database);

  @override
  Future<List<${entityPascal}Model>> getAll$featurePascal() async {
    try {
      final results = await database.getAll$featurePascal();
      return results.map((r) => ${entityPascal}Model.fromDatabase(r)).toList();
    } catch (e) {
      throw Exception('Failed to fetch $featureName: \$e');
    }
  }

  @override
  Future<List<${entityPascal}Model>> get${featurePascal}By${parentPascal}Id(int ${parentCamel}Id) async {
    try {
      final results = await database.get${featurePascal}By${parentPascal}Id(${parentCamel}Id);
      return results.map((r) => ${entityPascal}Model.fromDatabase(r)).toList();
    } catch (e) {
      throw Exception('Failed to fetch $featureName by ${parentEntity}: \$e');
    }
  }

  @override
  Future<${entityPascal}Model?> get${entityPascal}ById(int id) async {
    try {
      final result = await database.get${entityPascal}ById(id);
      if (result == null) return null;
      return ${entityPascal}Model.fromDatabase(result);
    } catch (e) {
      throw Exception('Failed to fetch ${entitySingular}: \$e');
    }
  }

  @override
  Future<List<${entityPascal}Model>> search$featurePascal(String query) async {
    try {
      final results = await database.search$featurePascal(query);
      return results.map((r) => ${entityPascal}Model.fromDatabase(r)).toList();
    } catch (e) {
      throw Exception('Failed to search $featureName: \$e');
    }
  }

  @override
  Future<int> create$entityPascal(${entityPascal}Model model) async {
    try {
      return await database.insert$entityPascal(
        ${featurePascal}Companion(
$companionFields
        ),
      );
    } catch (e) {
      throw Exception('Failed to create ${entitySingular}: \$e');
    }
  }

  @override
  Future<void> update$entityPascal(${entityPascal}Model model) async {
    try {
      await database.update$entityPascal(
        $entityPascal(
$entityFields
        ),
      );
    } catch (e) {
      throw Exception('Failed to update ${entitySingular}: \$e');
    }
  }

  @override
  Future<void> delete$entityPascal(int id) async {
    try {
      await database.delete$entityPascal(id);
    } catch (e) {
      throw Exception('Failed to delete ${entitySingular}: \$e');
    }
  }

  @override
  Future<List<${entityPascal}Model>> getPending$featurePascal() async {
    try {
      final results = await database.getPending$featurePascal();
      return results.map((r) => ${entityPascal}Model.fromDatabase(r)).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending $featureName: \$e');
    }
  }

  @override
  Future<void> markAsSynced(int id) async {
    try {
      await database.markAs${entityPascal}Synced(id);
    } catch (e) {
      throw Exception('Failed to mark ${entitySingular} as synced: \$e');
    }
  }
}
''';

    await writeToFile(
      'lib/features/$featureName/data/datasources/${entitySingular}_local_data_source.dart',
      content,
    );
  }

  /// Generate remote data source (API placeholder)
  Future<void> generateRemoteDataSource() async {
    final content = '''
import 'package:injectable/injectable.dart';
import 'package:$packageName/features/$featureName/data/models/${entitySingular}_model.dart';

abstract class ${entityPascal}RemoteDataSource {
  Future<List<${entityPascal}Model>> get${featurePascal}FromApi(int ${parentCamel}Id);
  Future<${entityPascal}Model> create${entityPascal}OnApi(${entityPascal}Model model);
  Future<void> update${entityPascal}OnApi(${entityPascal}Model model);
  Future<void> delete${entityPascal}OnApi(int id);
  Future<void> sync${entityPascal}ToApi(${entityPascal}Model model);
}

@Injectable(as: ${entityPascal}RemoteDataSource)
class ${entityPascal}RemoteDataSourceImpl implements ${entityPascal}RemoteDataSource {
  // TODO: Add API client dependency
  // final ApiClient apiClient;
  
  // ${entityPascal}RemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<${entityPascal}Model>> get${featurePascal}FromApi(int ${parentCamel}Id) async {
    // TODO: Implement API call
    // final response = await apiClient.get('/api/$featureName?${parentCamel}Id=\$${parentCamel}Id');
    // return (response.data as List).map((json) => ${entityPascal}Model.fromJson(json)).toList();
    throw UnimplementedError('API not implemented');
  }

  @override
  Future<${entityPascal}Model> create${entityPascal}OnApi(${entityPascal}Model model) async {
    // TODO: Implement API call
    // final response = await apiClient.post('/api/$featureName', data: model.toJson());
    // return ${entityPascal}Model.fromJson(response.data);
    throw UnimplementedError('API not implemented');
  }

  @override
  Future<void> update${entityPascal}OnApi(${entityPascal}Model model) async {
    // TODO: Implement API call
    // await apiClient.put('/api/$featureName/\${model.id}', data: model.toJson());
    throw UnimplementedError('API not implemented');
  }

  @override
  Future<void> delete${entityPascal}OnApi(int id) async {
    // TODO: Implement API call
    // await apiClient.delete('/api/$featureName/\$id');
    throw UnimplementedError('API not implemented');
  }

  @override
  Future<void> sync${entityPascal}ToApi(${entityPascal}Model model) async {
    // TODO: Implement sync logic
    // Check syncStatus and perform appropriate API call
    throw UnimplementedError('API not implemented');
  }
}
''';

    await writeToFile(
      'lib/features/$featureName/data/datasources/${entitySingular}_remote_data_source.dart',
      content,
    );
  }

  /// Generate repository implementation
  Future<void> generateRepositoryImpl() async {
    final content = '''
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:$packageName/core/errors/failures.dart';
import 'package:$packageName/core/network/network_info.dart';
import 'package:$packageName/features/$featureName/data/datasources/${entitySingular}_local_data_source.dart';
import 'package:$packageName/features/$featureName/data/datasources/${entitySingular}_remote_data_source.dart';
import 'package:$packageName/features/$featureName/data/models/${entitySingular}_model.dart';
import 'package:$packageName/features/$featureName/domain/entities/$entitySingular.dart';
import 'package:$packageName/features/$featureName/domain/repositories/${entitySingular}_repository.dart';

@Injectable(as: ${entityPascal}Repository)
class ${entityPascal}RepositoryImpl implements ${entityPascal}Repository {
  final ${entityPascal}LocalDataSource localDataSource;
  final ${entityPascal}RemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ${entityPascal}RepositoryImpl(
    this.localDataSource,
    this.remoteDataSource,
    this.networkInfo,
  );

  @override
  Future<Either<Failure, List<${entityPascal}Entity>>> getAll$featurePascal() async {
    try {
      final results = await localDataSource.getAll$featurePascal();
      return Right(results);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<${entityPascal}Entity>>> get${featurePascal}By${parentPascal}Id(int ${parentCamel}Id) async {
    try {
      // Try to get from local first
      final results = await localDataSource.get${featurePascal}By${parentPascal}Id(${parentCamel}Id);
      
      // If connected, try to sync from API in background
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        _syncFromApi${parentCamel}Id(${parentCamel}Id);
      }
      
      return Right(results);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ${entityPascal}Entity?>> get${entityPascal}ById(int id) async {
    try {
      final result = await localDataSource.get${entityPascal}ById(id);
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<${entityPascal}Entity>>> search$featurePascal(String query) async {
    try {
      final results = await localDataSource.search$featurePascal(query);
      return Right(results);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> create$entityPascal(${entityPascal}Entity entity) async {
    try {
      final model = ${entityPascal}Model(
${config.constructorColumns.map((col) => '        ${col.name}: entity.${col.name},').join('\n')}
      );
      
      final id = await localDataSource.create$entityPascal(model);
      
      // Try to sync to API if connected
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        _syncToApi(model.copyWith(id: id) as ${entityPascal}Model);
      }
      
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> update$entityPascal(${entityPascal}Entity entity) async {
    try {
      final model = ${entityPascal}Model(
${config.tableColumns.map((col) => '        ${col.name}: entity.${col.name},').join('\n')}
      );
      
      await localDataSource.update$entityPascal(model);
      
      // Try to sync to API if connected
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        _syncToApi(model);
      }
      
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete$entityPascal(int id) async {
    try {
      await localDataSource.delete$entityPascal(id);
      
      // Try to sync deletion to API if connected
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          await remoteDataSource.delete${entityPascal}OnApi(id);
        } catch (e) {
          // Ignore API errors for now
        }
      }
      
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncPending$featurePascal() async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        return const Left(NetworkFailure('No internet connection'));
      }

      final pending = await localDataSource.getPending$featurePascal();
      
      for (final model in pending) {
        try {
          await remoteDataSource.sync${entityPascal}ToApi(model);
          await localDataSource.markAsSynced(model.id);
        } catch (e) {
          // Continue with next item if one fails
          continue;
        }
      }
      
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  // Helper methods
  Future<void> _syncToApi(${entityPascal}Model model) async {
    try {
      await remoteDataSource.sync${entityPascal}ToApi(model);
      await localDataSource.markAsSynced(model.id);
    } catch (e) {
      // Silently fail - will be synced later
    }
  }

  Future<void> _syncFromApi${parentCamel}Id(int ${parentCamel}Id) async {
    try {
      await remoteDataSource.get${featurePascal}FromApi(${parentCamel}Id);
      // TODO: Merge with local data
    } catch (e) {
      // Silently fail
    }
  }
}
''';

    await writeToFile(
      'lib/features/$featureName/data/repositories/${entitySingular}_repository_impl.dart',
      content,
    );
  }
}
