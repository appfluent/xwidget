import 'utils.dart';


class Path {
  static const _separator = "/";

  final List<String> _path;
  final String _fileName;

  Path(this._path, this._fileName);

  static Path parse(String? path) {
    if (isBlank(path)) return Path([], "");

    String fileName = "";
    final parsedPath = <String>[];
    final segments = path!.split(_separator);

    for (int index = 0; index < segments.length; index++) {
      final segment = segments[index];
      if (isNotBlank(segment) && segment != ".") {
        if (segment == "..") {
          if (parsedPath.isNotEmpty) {
            parsedPath.removeLast();
          } else {
            throw Exception("Unable resolve relative path '$path'. Try Using 'parseRelativeTo' instead.");
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

  static parseRelativeTo(String? path, String? relativeTo) {
    if (path == null) return Path.parse("");
    final relativePath = Path.parse(relativeTo).pathToString();
    final separator = isNotBlank(relativePath) && isNotBlank(path) ? _separator : "";
    return Path.parse("$relativePath$separator$path");
  }

  String pathToString() {
    return _path.join(_separator);
  }

  @override
  toString() {
    final pathStr = pathToString();
    final separator = isNotBlank(pathStr) && isNotBlank(_fileName) ? _separator : "";
    return "$pathStr$separator$_fileName";
  }
}