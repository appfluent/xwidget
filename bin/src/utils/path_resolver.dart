import 'dart:io';
import 'dart:isolate';

class PathResolver {

  static Future<Uri> get packageRoot async {
    final package = await Isolate.packageConfig;
    return package != null ? package.resolve("../") : Directory.current.uri;
  }

  /// Resolves relative package path to an absolute file path.
  ///
  /// Accepted formats:
  /// - "package:<package_name>/<file_path>": package lib/ relative
  /// - "<package_name>|<file_path>": package root relative
  /// - "<file_path>": current project root relative
  ///
  /// Throws an [Exception] if the specified package can't be found, presumably
  /// because it wasn't added as a dependency.
  static Future<Uri> relativeToAbsolute(String path) async {
    String uriPath = path;
    bool fromRoot = false;

    if (path.contains("|")) {
      final parts = path.split("|");
      uriPath = "package:${parts[0]}/${parts[1]}";
      fromRoot = true;
    }
    if (uriPath.startsWith("package:")) {
      final packageUri = Uri.parse(uriPath);
      final resolvedUri = await Isolate.resolvePackageUri(packageUri);
      if (resolvedUri != null) {
        return Uri.parse((fromRoot)
            ? resolvedUri.toString().replaceFirst("/lib/", "/")
            : resolvedUri.toString()
        );
      }
      throw Exception("Invalid package path: '$path'");
    }

    final root = await packageRoot;
    return root.resolve(path);
  }
}