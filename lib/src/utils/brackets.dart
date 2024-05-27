import 'package:flutter/material.dart';

import 'model.dart';

/// A simple utility for retrieving data using dot/bracket notation. As long as
/// your data follows a simple convention you can use a simplified dot/bracket
/// notation to locate any piece of data in your hierarchy. Searches return null
/// if no data is found or if the path string is invalid.
///
/// 1. Objects must be represented as <String, dynamic> maps.
/// 2. Array data must use <dynamic> lists.
/// 3. Map keys may only contain upper/lower case letters, numbers and the
///    underscore.
/// 4. Array indexes must be int parsable numbers.

extension MapBrackets on Map<String, dynamic> {
  dynamic getValue(String? path) {
    return PathResolution.resolvePath(path, false, this).getValue(true);
  }

  void setValue(String? path, dynamic value) {
    PathResolution.resolvePath(path, true, this).setValue(value, true);
  }

  dynamic removeValue(String? path) {
    return PathResolution.resolvePath(path, false, this).removeValue();
  }

  ValueNotifier listenForChanges(
      String path,
      dynamic initialValue,
      dynamic defaultValue
  ) {
    final resolved = PathResolution.resolvePath(path, true, this);
    return resolved.listenForChanges(initialValue, defaultValue);
  }
}

extension ListBrackets on List<dynamic> {
  dynamic getValue(String? path) {
    return PathResolution.resolvePath(path, false, this).getValue(true);
  }

  void setValue(String? path, dynamic value) {
    PathResolution.resolvePath(path, true, this).setValue(value, true);
  }

  ValueNotifier listenForChanges(
      String path,
      dynamic initialValue,
      dynamic defaultValue
  ) {
    return PathResolution
        .resolvePath(path, true, this)
        .listenForChanges(initialValue, defaultValue);
  }

  void setValueAt(int index, dynamic value, [dynamic fill]) {
    if (index < length) {
      this[index] = value;
    } else {
      try {
        for (var i = length; i <= index; i++) {
          // this will throw an exception if we need to add null items and
          // the list does not allow nulls
          add(i == index ? value : fill);
        }
      } catch (e) {
        throw Exception("Problem setting item value at index $index. "
            "Unable to add filler value '$fill' to $runtimeType,");
      }
    }
  }
}

class PathResolution {
  final dynamic path;
  final dynamic data;
  final PathResolution? parent;

  PathResolution(this.path, this.data, this.parent);

  static PathResolution resolvePath(
      String? path,
      bool createPath,
      dynamic data
  ) {
    return _resolve(path, createPath, data, null);
  }

  dynamic get _dataValue {
    return data is ModelValueNotifier ? data.value : data;
  }

  dynamic getValue(bool readValueNotifier) {
    dynamic value;
    final collection = _dataValue;
    if (collection is Map) {
      value = collection[path];
    } else if (collection is List) {
      final index = path;
      if (index is int && index < collection.length) {
        value = collection[index];
      }
    }
    return value is ModelValueNotifier && readValueNotifier
        ? value.value : value;
  }

  void setValue(dynamic newValue, bool writeToValueNotifier) {
    bool written = false;
    final oldValue = getValue(false);
    final changed =
      (oldValue is ModelValueNotifier ? oldValue.value : oldValue) !=
      (newValue is ModelValueNotifier ? newValue.value : newValue);

    if (oldValue is ModelValueNotifier &&
        newValue is! ModelValueNotifier &&
        writeToValueNotifier) {
      oldValue.value = newValue;
      written = true;
    } else {
      final collection = _dataValue;
      if (collection is Map) {
        collection[path] = newValue;
        written = true;
      } else if (collection is List) {
        final index = path;
        if (index is int) {
          collection.setValueAt(index, newValue);
          written = true;
        }
      }
    }
    if (changed && written) {
      // aw, we're telling on you!!
      _notifyParents();
    }
  }

  dynamic removeValue() {
    final collection = _dataValue;
    if (collection is Map) {
      return collection.remove(path);
    } else if (collection is List) {
      final index = path;
      if (index is int && index < collection.length) {
        return collection.removeAt(index);
      }
    }
  }

  ValueNotifier listenForChanges(dynamic initialValue, dynamic defaultValue) {
    var value = getValue(false);
    if (value is! ValueNotifier) {
      value = ModelValueNotifier(initialValue ?? value ?? defaultValue);
      setValue(value, false);
    }
    return value;
  }

  //===================================
  // private methods
  //===================================

  static PathResolution _resolve(
      String? path,
      bool createPath,
      dynamic data,
      PathResolution? parent
  ) {
    if (path != null && path.isNotEmpty && data != null) {
      final pathInfo = PathInfo.parsePath(path);
      dynamic collection = data is ModelValueNotifier ? data.value : data;
      dynamic currPath = pathInfo.currPath;
      dynamic value;

      if (collection == null && createPath && data is ModelValueNotifier) {
        // interesting use case where we have a ModelValueNotifier whose value
        // is null and we're trying write a property to it. The collection
        // doesn't exist, so we need to create it first.
        data.pauseNotifications();
        collection = data.value = pathInfo.isList ? [] : <String, dynamic>{};
        data.resumeNotifications();
      }
      if (collection is List) {
        // data is a List; therefore, currPath must be an index, so convert it
        // to an int and get the value that it points to.
        currPath = int.parse(currPath);
        if (currPath > -1 && currPath < collection.length) {
          value = collection[currPath];
        }
      } else {
        // data is some sort of map, so use currPath as it to get the value.
        value = collection[currPath];
      }

      if (value == null) {
        if (createPath && pathInfo.nextPath.isNotEmpty) {
          if (pathInfo.isList) {
            value = [];
            collection.setValue(currPath, value);
          } else {
            value = collection[currPath] = <String, dynamic>{};
          }
        } else if (!pathInfo.isNullable) {
          throw Exception("Value at path '$path' is null. Use the '?' "
              "null-safety operator to access '${pathInfo.currPath}'");
        }
      }
      final resolution = PathResolution(currPath, data, parent);
      return pathInfo.nextPath.isNotEmpty
        ? _resolve(pathInfo.nextPath, createPath, value, resolution)
        : resolution;
    }
    return PathResolution(path, null, null);
  }

  _notifyParents() {
    PathResolution? currResolution = this;
    while (currResolution != null) {
      final currData = currResolution.data;
      if (currData is ModelValueNotifier) {
        currData.notifyListeners();
      }
      currResolution = currResolution.parent;
    }
  }
}

/// A simple dot/bracket notation path parser.
class PathInfo {
  final String currPath;
  final String nextPath;
  final bool isNullable;
  final bool isList;

  PathInfo(this.currPath, this.nextPath, this.isNullable, this.isList);

  factory PathInfo.parsePath(String path) {
    String currPath = "";
    String nextPath = "";
    bool isNullable = false;
    bool done = false;

    for (int pos = 0; pos < path.length && !done; pos++) {
      final char = path[pos];
      if (char == "[") {
        if (pos > 0) {
          nextPath = path.substring(pos, path.length);
          done = true;
        }
      } else if (char == ".") {
        nextPath = path.substring(pos + 1, path.length);
        done = true;
      } else if (char != "]" && char != " ") {
        currPath += char;
      }
    }

    if (currPath.endsWith("?")) {
      isNullable = true;
      currPath = currPath.substring(0, currPath.length - 1);
    } else if (currPath.endsWith("!")) {
      currPath = currPath.substring(0, currPath.length - 1);
    } else if (nextPath.isEmpty) {
      isNullable = true;
    }

    final isList = nextPath.isNotEmpty && nextPath.startsWith("[");
    return PathInfo(currPath, nextPath, isNullable, isList);
  }
}