import '../models/generation_config.dart';
import '../utils/file_writer.dart';

/// Base class for all feature generators
abstract class BaseGenerator {
  final GenerationConfig config;

  const BaseGenerator(this.config);

  /// Get package name
  String get packageName => config.packageName;

  /// Get naming variants
  String get featureName => config.naming.featureName;
  String get featurePascal => config.naming.featurePascal;
  String get featureCamel => config.naming.featureCamel;
  String get entitySingular => config.naming.entitySingular;
  String get entityPascal => config.naming.entityPascal;
  String get entityCamel => config.naming.entityCamel;
  String get parentEntity => config.naming.parentEntity;
  String get parentPascal => config.naming.parentPascal;
  String get parentCamel => config.naming.parentCamel;

  /// Write file with automatic directory creation
  Future<void> writeToFile(String path, String content) async {
    await FileWriter.writeFile(path, content);
  }

  /// Main generation method - to be implemented by subclasses
  Future<void> generate();
}
