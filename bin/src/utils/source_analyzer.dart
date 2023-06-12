import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart';

import 'cli_log.dart';
import 'path_resolver.dart';


class SourceAnalyzer {

  Future<Map<String, LibraryElement>> getLibraryElements(Iterable<String> sources) async {
    final libraryElements = <String, LibraryElement>{};
    final manifest = await getSourceManifest(sources);
    final collection = AnalysisContextCollection(
        includedPaths: manifest.paths.toList(),
        resourceProvider: PhysicalResourceProvider.INSTANCE);

    for (final path in manifest.paths) {
      final currentSession = collection.contextFor(path).currentSession;
      libraryElements[path] = await currentSession
          .getLibraryByUri("file://$path")
          .then((libraryResult) => (libraryResult as LibraryElementResult).element);
      CliLog.success("Analyzed source '${basename(path)}'");
    }
    return libraryElements;
  }

  Future<SourceManifest> getSourceManifest(Iterable<String> sources, [List<String> noFilesOk = const []]) async {
    final files = <File>[];
    final paths = <String>{};
    for (final source in sources) {
      final absolutePath = (await PathResolver.relativeToAbsolute(source)).path;
      final absoluteGlob = Glob(absolutePath);
      final entities = absoluteGlob.listSync();
      if (entities.isNotEmpty) {
        for (final entity in entities) {
          final entityPath = entity.path;
          if (entity is File) {
            if (!paths.contains(entityPath)) {
              files.add(entity as File);
              paths.add(entityPath);
            }
          } else if (basename(absolutePath) == basename(entityPath) ){
            CliLog.warn("Glob '$source' matches a directory. "
                "Add a file name or use globs (**.dart) to match specific files or file patterns.");
          }
        }
      } else if (!noFilesOk.contains(source)) {
        CliLog.warn("No files found for glob '$source'.");
      }
    }
    return SourceManifest(files, paths);
  }
}

class SourceManifest {
  final List<File> files;
  final Set<String> paths;

  SourceManifest(this.files, this.paths);
}