import 'dart:io';

import 'cli_log.dart';
import 'path_resolver.dart';

class Files {

  static Future<String> readFile(String filePath) async {
    final pathUri = await PathResolver.relativeToAbsolute(filePath);
    return File(pathUri.path).readAsString();
  }

  static Future<File> createFile(String filePath, String contents) async {
    final pathUri = await PathResolver.relativeToAbsolute(filePath);
    final file = await File(pathUri.path).create(recursive: true);
    return file.writeAsString(contents);
  }

  static Future<void> createDirs(List<String> dirs) async {
    for (final dir in dirs) {
      await createDir(Directory(dir));
    }
  }

  static Future<void> createDir(Directory dir) async {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      CliLog.success("Created directory '${dir.path}'");
    }
  }

  static Future<void> copyFiles(
      Map<String, String> files,
      [bool replace = false]
  ) async {
    for (final file in files.entries) {
      await copyFile(file.key, file.value, replace);
    }
  }

  static Future<void> copyFile(
      String src,
      String dst,
      [bool replace = false]
  ) async {
    try {
      final srcPath = await PathResolver.relativeToAbsolute(src);
      final srcFile = File(srcPath.path);
      if (await srcFile.exists()) {
        final dstPath = await PathResolver.relativeToAbsolute(dst);
        final dstFile = File(dstPath.path);
        if (replace || !await dstFile.exists()) {
          await createDir(dstFile.parent);
          await srcFile.copy(dstPath.path);
          CliLog.success("Copied '$src' to '$dst'");
        } else {
          CliLog.warn("File '$dst' already exists");
        }
      } else {
        CliLog.error("File $srcPath does not exist.");
      }
    } catch (e) {
      CliLog.error("Error while copying file: $e");
    }
  }
}