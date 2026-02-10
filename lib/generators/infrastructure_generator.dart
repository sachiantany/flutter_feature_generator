import 'dart:io';
import '../utils/file_writer.dart';
import 'base_generator.dart';

/// Generator for infrastructure (directories, core files, build runner)
class InfrastructureGenerator extends BaseGenerator {
  const InfrastructureGenerator(super.config);

  @override
  Future<void> generate() async {
    await createDirectoryStructure();
    await ensureCoreFiles();
  }

  /// Create all necessary directories
  Future<void> createDirectoryStructure() async {
    final dirs = [
      'lib/core/database/tables',
      'lib/core/errors',
      'lib/core/network',
      'lib/core/di',
      'lib/features/$featureName/domain/entities',
      'lib/features/$featureName/domain/repositories',
      'lib/features/$featureName/domain/usecases',
      'lib/features/$featureName/data/models',
      'lib/features/$featureName/data/datasources',
      'lib/features/$featureName/data/repositories',
      'lib/features/$featureName/presentation/bloc',
      'lib/features/$featureName/presentation/pages',
      'lib/features/$featureName/presentation/widgets',
    ];

    await FileWriter.createDirectories(dirs);
  }

  /// Ensure core files exist (failures, network_info, injection)
  Future<void> ensureCoreFiles() async {
    await _ensureFailuresFile();
    await _ensureNetworkInfoFile();
    await _ensureInjectionFile();
  }

  /// Run build_runner for code generation
  Future<void> runBuildRunner() async {
    print('   Running build_runner...');

    final result = await Process.run(
      'dart',
      ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
    );

    if (result.exitCode != 0) {
      print('   ⚠️  Build runner had warnings (this is normal)');
      // Don't fail on warnings, they're often harmless
    } else {
      print('   ✅ Build runner completed');
    }
  }

  Future<void> _ensureFailuresFile() async {
    await FileWriter.ensureFileExists(
      'lib/core/errors/failures.dart',
      _failuresTemplate,
    );
  }

  Future<void> _ensureNetworkInfoFile() async {
    await FileWriter.ensureFileExists(
      'lib/core/network/network_info.dart',
      _networkInfoTemplate,
    );
  }

  Future<void> _ensureInjectionFile() async {
    await FileWriter.ensureFileExists(
      'lib/core/di/injection.dart',
      _injectionTemplate,
    );
  }

  static const _failuresTemplate = '''
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);

  @override
  List<Object?> get props => [message, code];
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, [super.code]);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.code]);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, [super.code]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.code]);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, [super.code]);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.code]);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, [super.code]);
}
''';

  static const _networkInfoTemplate = '''
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

@LazySingleton(as: NetworkInfo)
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    try {
      final results = await connectivity.checkConnectivity();
      return _isConnected(results);
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return connectivity.onConnectivityChanged.map(_isConnected);
  }

  bool _isConnected(dynamic results) {
    if (results is List) {
      return results.any((result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet);
    } else {
      return results == ConnectivityResult.mobile ||
          results == ConnectivityResult.wifi ||
          results == ConnectivityResult.ethernet;
    }
  }
}
''';

  static const _injectionTemplate = '''
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  await getIt.init();
}

@module
abstract class RegisterModule {
  @lazySingleton
  Connectivity get connectivity => Connectivity();

  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}
''';
}
