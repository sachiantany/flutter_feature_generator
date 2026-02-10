import 'models/generation_config.dart';
import 'generators/infrastructure_generator.dart';
import 'generators/database_generator.dart';
import 'generators/domain_generator.dart';
import 'generators/usecase_generator.dart';
import 'generators/data_generator.dart';
import 'generators/presentation_generator.dart';

/// Orchestrates the feature generation process
class FeatureOrchestrator {
  final GenerationConfig config;

  const FeatureOrchestrator(this.config);

  /// Generate complete feature
  Future<void> generate() async {
    print('   [1/10] Creating directories...');
    final infrastructure = InfrastructureGenerator(config);
    await infrastructure.createDirectoryStructure();

    print('   [2/10] Ensuring core files exist...');
    await infrastructure.ensureCoreFiles();

    print('   [3/10] Generating database table...');
    await DatabaseGenerator(config).generate();

    print('   [4/10] Generating domain layer...');
    await DomainGenerator(config).generate();

    print('   [5/10] Generating use cases...');
    await UseCaseGenerator(config).generate();

    print('   [6/10] Generating data layer...');
    await DataGenerator(config).generate();

    print('   [7/10] Generating BLoC...');
    await PresentationGenerator(config).generate();

    print('   [8/10] Feature generation complete!');
    print('   [9/10] Running build_runner...');
    await infrastructure.runBuildRunner();

    print('   [10/10] Done!');
  }

  /// Generate feature without build_runner
  Future<void> generateWithoutBuildRunner() async {
    print('   [1/9] Creating directories...');
    final infrastructure = InfrastructureGenerator(config);
    await infrastructure.createDirectoryStructure();

    print('   [2/9] Ensuring core files exist...');
    await infrastructure.ensureCoreFiles();

    print('   [3/9] Generating database table...');
    await DatabaseGenerator(config).generate();

    print('   [4/9] Generating domain layer...');
    await DomainGenerator(config).generate();

    print('   [5/9] Generating use cases...');
    await UseCaseGenerator(config).generate();

    print('   [6/9] Generating data layer...');
    await DataGenerator(config).generate();

    print('   [7/9] Generating BLoC...');
    await PresentationGenerator(config).generate();

    print('   [8/9] Feature generation complete!');
    print('   [9/9] Skipping build_runner (run manually if needed)');
  }
}
