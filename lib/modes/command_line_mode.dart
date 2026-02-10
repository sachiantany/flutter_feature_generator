import 'dart:io';
import '../models/generation_config.dart';
import '../utils/validators.dart';

/// Command-line mode for feature generation
class CommandLineMode {
  /// Parse command-line arguments and return configuration
  static Future<GenerationConfig> parse(List<String> args) async {
    print('╔═══════════════════════════════════════════════════════════╗');
    print('║   🚀 Flutter Feature Generator (Command-Line Mode)      ║');
    print('╚═══════════════════════════════════════════════════════════╝');
    print('');

    if (args.length < 2) {
      _printUsage();
      exit(1);
    }

    try {
      final featureName = args[0];
      final parentEntity = args[1];
      final columnsStr = args.length > 2 ? args[2] : null;

      // Validate inputs
      if (!Validators.isValidFeatureName(featureName)) {
        print(
            '❌ Error: Feature name must be in snake_case (lowercase with underscores)');
        print('   Example: product_reviews, order_notes');
        exit(1);
      }

      if (!Validators.isValidEntityName(parentEntity)) {
        print(
            '❌ Error: Parent entity must be in snake_case (lowercase with underscores)');
        print('   Example: product, order, customer');
        exit(1);
      }

      // Validate columns if provided
      if (columnsStr != null) {
        final validation = Validators.validateColumnsString(columnsStr);
        if (!validation.isValid) {
          print('❌ Error: ${validation.errorMessage}');
          exit(1);
        }
      }

      // Detect package name
      final packageName = await _getPackageName();
      print('');

      print('📦 Generating feature...');
      print('   Package: $packageName');
      print('   Feature: $featureName');
      print('   Parent: $parentEntity');
      if (columnsStr != null) {
        print('   Columns: $columnsStr');
      } else {
        print('   Columns: Using defaults');
      }
      print('');

      return GenerationConfig.fromString(
        packageName: packageName,
        featureName: featureName,
        parentEntity: parentEntity,
        columnsStr: columnsStr,
      );
    } catch (e) {
      print('\n❌ Error: $e');
      _printUsage();
      exit(1);
    }
  }

  static Future<String> _getPackageName() async {
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      print('❌ Error: pubspec.yaml not found in current directory');
      print('   Make sure you\'re running this from your Flutter project root');
      exit(1);
    }

    final content = await pubspecFile.readAsString();
    final lines = content.split('\n');

    for (final line in lines) {
      if (line.trim().startsWith('name:')) {
        return line.split(':')[1].trim();
      }
    }

    print('❌ Error: Could not find package name in pubspec.yaml');
    exit(1);
  }

  static void _printUsage() {
    print('');
    print(
        'Usage: dart run tools/feature_gen.dart <feature_name> <parent_entity> [columns]');
    print('');
    print('Arguments:');
    print(
        '  feature_name    - Name of the feature in snake_case (e.g., product_reviews)');
    print(
        '  parent_entity   - Parent entity name in snake_case (e.g., product)');
    print('  columns        - Optional comma-separated column definitions');
    print('                   Format: name:type or name:type?');
    print('                   Types: int, string, DateTime, double, bool');
    print('');
    print('Examples:');
    print('  dart run tools/feature_gen.dart product_reviews product');
    print(
        '  dart run tools/feature_gen.dart order_notes order "note:string,priority:int"');
    print(
        '  dart run tools/feature_gen.dart customer_feedback customer "rating:int,comment:string?,date:DateTime"');
    print('');
  }
}
