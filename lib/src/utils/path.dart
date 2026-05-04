import 'package:xwidget_el/xwidget_el.dart';

class Path {
  static const _separator = "/";

  final List<String> _path;
  final String _fileName;

  Path(this._path, this._fileName);

  static Path parse(String? path) {
    if (isEmpty(path)) return Path([], "");

    String fileName = "";
    final parsedPath = <String>[];
    final segments = path!.split(_separator);

    for (int index = 0; index < segments.length; index++) {
      final segment = segments[index];
      if (isNotEmpty(segment) && segment != ".") {
        if (segment == "..") {
          if (parsedPath.isNotEmpty) {
            parsedPath.removeLast();
          } else {
            throw Exception(
              "Unable resolve relative path '$path'. Try Using "
              "'parseRelativeTo' instead.",
            );
          }
        } else if (index == segments.length - 1 && segment.contains(".")) {
          fileName = segment;
        } else {
          parsedPath.add(segment);
        }
      }
    }
    return Path(parsedPath, fileName);
  }

  static Path parseRelativeTo(String? path, String? relativeTo) {
    if (path == null) return Path.parse("");
    final relativePath = Path.parse(relativeTo).pathToString();
    final separator = isNotEmpty(relativePath) && isNotEmpty(path) ? _separator : "";
    return Path.parse("$relativePath$separator$path");
  }

  String pathToString() {
    return _path.join(_separator);
  }

  @override
  toString() {
    final pathStr = pathToString();
    final separator = isNotEmpty(pathStr) && isNotEmpty(_fileName) ? _separator : "";
    return "$pathStr$separator$_fileName";
  }
}

/// Splits a relative file path into its directory path, file name, and
/// extension components.
///
/// For example, `subdir/my_file.xml` returns
/// `(path: "subdir/", name: "my_file", ext: "xml")`.
PathParts? splitPath(String relativePath) {
  final lastSlash = relativePath.lastIndexOf('/');
  final lastDot = relativePath.lastIndexOf('.');

  if (lastDot < 0) return null; // no extension

  final path = lastSlash >= 0 ? relativePath.substring(0, lastSlash + 1) : '';
  final name = relativePath.substring(lastSlash + 1, lastDot);
  final ext = relativePath.substring(lastDot + 1);

  if (name.isEmpty || ext.isEmpty) return null;

  return PathParts(path: path, name: name, ext: ext);
}

class PathParts {
  final String path;
  final String name;
  final String ext;

  PathParts({required this.path, required this.name, required this.ext});
}
