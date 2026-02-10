import 'dart:io';

/// Utility for writing files with error handling and directory creation
class FileWriter {
  /// Write content to a file, creating parent directories if needed
  static Future<void> writeFile(
    String path,
    String content, {
    bool createDirs = true,
  }) async {
    try {
      final file = File(path);

      // Create parent directories if needed
      if (createDirs) {
        final dir = file.parent;
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      }

      // Write the file
      await file.writeAsString(content);
    } catch (e) {
      throw FileWriteException('Failed to write file: $path', e);
    }
  }

  /// Create directories recursively
  static Future<void> createDirectories(List<String> paths) async {
    for (final path in paths) {
      try {
        await Directory(path).create(recursive: true);
      } catch (e) {
        throw FileWriteException('Failed to create directory: $path', e);
      }
    }
  }

  /// Ensure a file exists, create from template if it doesn't
  static Future<void> ensureFileExists(
    String path,
    String content,
  ) async {
    final file = File(path);
    if (!await file.exists()) {
      await writeFile(path, content);
    }
  }

  /// Check if a file exists
  static Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  /// Read file content
  static Future<String> readFile(String path) async {
    try {
      return await File(path).readAsString();
    } catch (e) {
      throw FileWriteException('Failed to read file: $path', e);
    }
  }

  /// Delete a file
  static Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw FileWriteException('Failed to delete file: $path', e);
    }
  }

  /// Copy a file
  static Future<void> copyFile(String source, String destination) async {
    try {
      final sourceFile = File(source);
      await sourceFile.copy(destination);
    } catch (e) {
      throw FileWriteException(
          'Failed to copy file: $source -> $destination', e);
    }
  }
}

/// Exception thrown when file operations fail
class FileWriteException implements Exception {
  final String message;
  final dynamic cause;

  FileWriteException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return '$message\nCause: $cause';
    }
    return message;
  }
}
