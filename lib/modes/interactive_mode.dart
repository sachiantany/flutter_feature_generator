import 'dart:io';
import '../models/generation_config.dart';
import '../utils/validators.dart';

/// Interactive mode for feature generation
class InteractiveMode {
  /// Run interactive mode and return configuration
  static Future<GenerationConfig> run() async {
    print('╔═══════════════════════════════════════════════════════════╗');
    print('║   🚀 Interactive Flutter Feature Generator v2.0         ║');
    print('╚═══════════════════════════════════════════════════════════╝');
    print('');

    // Step 1: Detect or ask for package name
    final packageName = await _getPackageName();
    print('');

    // Step 2: Check and install dependencies
    await _checkDependencies();
    print('');

    // Step 3: Ask for feature details
    final featureName = _askQuestion(
      'Feature name (snake_case)',
      example: 'product_reviews',
      validator: Validators.isValidFeatureName,
    );

    final parentEntity = _askQuestion(
      'Parent entity name (snake_case)',
      example: 'product',
      validator: Validators.isValidEntityName,
    );

    print('');
    print('📋 Column Definition:');
    print('   Format: name:type (comma-separated)');
    print('   Types: int, string, DateTime, double, bool');
    print('   Nullable: Add ? suffix (e.g., comment:string?)');
    print('');
    print('   Example: rating:int,title:string,review:string?,date:DateTime');
    print('   Or press ENTER for default columns');
    print('');

    stdout.write('Columns (optional): ');
    final columnsInput = stdin.readLineSync()?.trim() ?? '';
    final columnsStr = columnsInput.isEmpty ? null : columnsInput;

    // Validate columns if provided
    if (columnsStr != null) {
      final validation = Validators.validateColumnsString(columnsStr);
      if (!validation.isValid) {
        print('   ❌ ${validation.errorMessage}');
        exit(1);
      }
    }

    print('');

    return GenerationConfig.fromString(
      packageName: packageName,
      featureName: featureName,
      parentEntity: parentEntity,
      columnsStr: columnsStr,
    );
  }

  static Future<String> _getPackageName() async {
    print('🔍 Detecting package name from pubspec.yaml...');

    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      print('   ⚠️  pubspec.yaml not found!');
      return _askQuestion(
        'Package name',
        example: 'my_app',
        validator: Validators.isValidPackageName,
      );
    }

    final content = await pubspecFile.readAsString();
    final lines = content.split('\n');

    for (final line in lines) {
      if (line.trim().startsWith('name:')) {
        final packageName = line.split(':')[1].trim();
        print('   ✅ Found: $packageName');

        stdout.write('   Use this package name? (Y/n): ');
        final confirm = stdin.readLineSync()?.trim().toLowerCase() ?? 'y';

        if (confirm == 'y' || confirm == 'yes' || confirm.isEmpty) {
          return packageName;
        }
      }
    }

    return _askQuestion(
      'Package name',
      example: 'my_app',
      validator: Validators.isValidPackageName,
    );
  }

  static Future<void> _checkDependencies() async {
    print('📦 Checking dependencies...');

    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      print('   ⚠️  pubspec.yaml not found - skipping dependency check');
      return;
    }

    final content = await pubspecFile.readAsString();

    final required = {
      'drift': '^2.0.0',
      'flutter_bloc': '^8.0.0',
      'injectable': '^2.0.0',
      'dartz': '^0.10.0',
      'equatable': '^2.0.0',
      'connectivity_plus': '^5.0.0',
      'shared_preferences': '^2.0.0',
    };

    final requiredDev = {
      'build_runner': '^2.0.0',
      'drift_dev': '^2.0.0',
      'injectable_generator': '^2.0.0',
    };

    final missing = <String>[];
    final missingDev = <String>[];

    for (final dep in required.keys) {
      if (!content.contains('$dep:')) {
        missing.add(dep);
      }
    }

    for (final dep in requiredDev.keys) {
      if (!content.contains('$dep:')) {
        missingDev.add(dep);
      }
    }

    if (missing.isEmpty && missingDev.isEmpty) {
      print('   ✅ All dependencies present');
      return;
    }

    print('');
    print('   ⚠️  Missing dependencies:');
    if (missing.isNotEmpty) {
      print('      Dependencies: ${missing.join(", ")}');
    }
    if (missingDev.isNotEmpty) {
      print('      Dev Dependencies: ${missingDev.join(", ")}');
    }
    print('');

    stdout.write('   Install missing dependencies? (Y/n): ');
    final install = stdin.readLineSync()?.trim().toLowerCase() ?? 'y';

    if (install == 'y' || install == 'yes' || install.isEmpty) {
      print('');
      print('   📥 Installing dependencies...');

      for (final dep in missing) {
        print('      Adding $dep...');
        await Process.run('flutter', ['pub', 'add', dep]);
      }

      for (final dep in missingDev) {
        print('      Adding $dep (dev)...');
        await Process.run('flutter', ['pub', 'add', '--dev', dep]);
      }

      print('   ✅ Dependencies installed');
    } else {
      print('   ⚠️  Skipped - you may need to add these manually');
    }
  }

  static String _askQuestion(
    String question, {
    String? example,
    bool Function(String)? validator,
  }) {
    while (true) {
      if (example != null) {
        stdout.write('$question (e.g., $example): ');
      } else {
        stdout.write('$question: ');
      }

      final answer = stdin.readLineSync()?.trim() ?? '';

      if (answer.isEmpty) {
        print('   ❌ This field is required');
        continue;
      }

      if (validator != null && !validator(answer)) {
        print(
            '   ❌ Invalid format - use snake_case (lowercase with underscores)');
        continue;
      }

      return answer;
    }
  }
}
