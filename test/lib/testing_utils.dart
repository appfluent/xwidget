import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

exceptionStartsWith(String message) {
  return throwsA(isA<Exception>().having((e) => e.toString(), 'message', startsWith(message)));
}

class TestAssetBundle extends CachingAssetBundle {
  late final String rootPath;
  late final List<String> assetPaths;

  TestAssetBundle([List<String>? assets]) {
    rootPath = _getRootPath();
    assetPaths = assets ?? [];
  }

  @override
  Future<ByteData> load(String key) async {
    if (key == "AssetManifest.json") {
      final manifest = json.encode(getAssetManifest());
      return Uint8List.fromList(utf8.encode(manifest)).buffer.asByteData();
    } else {
      final file = _getFile(key);
      return file.readAsBytesSync().buffer.asByteData();
    }
  }

  Map<String, List<String>> getAssetManifest() {
    final Map<String, List<String>> manifest = {};
    final files = _getFilesInPaths(assetPaths);
    for (final file in files) {
      final relativePath = _toRelativePath(file.uri.toString());
      manifest[relativePath] = [relativePath];
    }
    return manifest;
  }

  File _getFile(String path) {
    final absolutePath = _toAbsolutePath(path);
    final file = File(absolutePath);
    if (file.existsSync()) return file;
    throw Exception("File not found: '$path'");
  }

  Set<File> _getFilesInPaths(List<String> paths) {
    Set<File> files = {};
    for (final path in paths) {
      final type = FileSystemEntity.typeSync(path);
      switch (type) {
        case FileSystemEntityType.directory:
          files.addAll(Directory(path).listSync(recursive: true).whereType<File>());
          break;
        case FileSystemEntityType.file:
          files.add(File(path));
          break;
        case FileSystemEntityType.notFound:
          throw Exception("File not found: '$path'");
        default:
          Exception("Invalid file type: '$type'");
      }
    }
    return files;
  }

  String _getRootPath() {
    final dir = Directory.current.path;
    return dir.endsWith('/test') ? dir.replaceAll('/test', '') : dir;
  }
  
  String _toRelativePath(String path) {
    if (!path.startsWith("/")) return path;
    if (path.startsWith(rootPath)) return path.substring(rootPath.length);
    throw Exception("Path '$path' not relative to root '$rootPath'");
  }

  String _toAbsolutePath(String path) {
    if (path.startsWith(rootPath)) return path;
    if (!path.startsWith("/")) return "$rootPath/$path";
    throw Exception("Path '$path' not relative to root '$rootPath'");
  }
}
