import 'package:flutter/material.dart';

import 'model/model.dart';
import 'functions/validators.dart';

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
  bool hasPath(String? path) {
    return PathResolution(path, false, this).hasPath();
  }

  dynamic getValue(String? path) {
    return PathResolution(path, false, this).getValue(true);
  }

  void setValue(String? path, dynamic value) {
    PathResolution(path, true, this).setValue(value, true);
  }

  dynamic removeValue(String? path) {
    return PathResolution(path, false, this).removeValue();
  }

  ValueNotifier listenForChanges(
      String path,
      dynamic initialValue,
      dynamic defaultValue
  ) {
    final resolved = PathResolution(path, true, this);
    return resolved.listenForChanges(initialValue, defaultValue);
  }
}

extension ListBrackets on List<dynamic> {
  dynamic getValue(String? path) {
    return PathResolution(path, false, this).getValue(true);
  }

  void setValue(String? path, dynamic value) {
    PathResolution(path, true, this).setValue(value, true);
  }

  ValueNotifier listenForChanges(
      String path,
      dynamic initialValue,
      dynamic defaultValue
  ) {
    return PathResolution(path, true, this)
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

  dynamic get _dataValue => data is ModelValueNotifier ? data.value : data;

  PathResolution._(this.path, this.data, this.parent);

  factory PathResolution(
      String? path,
      bool createPath,
      dynamic data
  ) {
    return _resolve(path, createPath, data, null);
  }

  bool hasPath() {
    if (data is Map) {
      return data.containsKey(path);
    } else if (data is List) {
      final index = path;
      return index is int && index < data.length;
    }
    throw Exception("Invalid data collection type ${data.runtimeType}");
  }

  dynamic getValue(bool readValueNotifier) {
    dynamic value = _readValue(path, _dataValue);
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

      if (collection == null && createPath && data is ModelValueNotifier) {
        // interesting case where we have a ModelValueNotifier whose value
        // is null and we're trying write a property to it. The collection
        // doesn't exist, so we need to create it first.
        data.pauseNotifications();
        collection = data.value = pathInfo.isList ? [] : <String, dynamic>{};
        data.resumeNotifications();
      }

      dynamic currPath = pathInfo.isIndex
          ? int.parse(pathInfo.currPath) : pathInfo.currPath;
      dynamic value = _readValue(currPath, collection);

      if (value == null) {
        if (createPath && pathInfo.nextPath.isNotEmpty) {
          // nextPath is not empty, so the value must a collection
          if (pathInfo.isList) {
            value = [];
            collection.setValue(currPath, value);
          } else if (!pathInfo.isIndex) {
            value = collection[currPath] = <String, dynamic>{};
          } else {
            throw Exception("Cannot use Iterable style index reference "
                "{${pathInfo.currPath}} to set values. If the collection is a "
                "List, then use bracket ([]) notation. If the collection is a "
                "Map, then use dot (.) notation with the left-hand side being "
                "the collection and the right-hand side being the key.");
          }
        } else if (!pathInfo.isNullable) {
          throw Exception("Value at path '$path' is null. Use the '?' "
              "null-safety operator to access '${pathInfo.currPath}'");
        }
      }
      final resolution = PathResolution._(currPath, data, parent);
      return pathInfo.nextPath.isNotEmpty
        ? _resolve(pathInfo.nextPath, createPath, value, resolution)
        : resolution;
    }
    return PathResolution._(path, null, null);
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

  static dynamic _readValue(dynamic currPath, dynamic collection) {
    if (isEmpty(collection)) {
      return null;
    } else if (collection is MapEntry) {
      if (currPath == "_key") {
        return collection.key;
      } else if (currPath == "_value") {
        return collection.value;
      } else {
        return _readValue(currPath, collection.value);
      }
    } else if (currPath is int) {
      // currPath is an index value, get the item at that index location.
      if (currPath < 0 || currPath >= collection.length) {
        // index is out of range, so just return null
        return null;
      } else {
        if (collection is Iterable) {
          return collection.elementAt(currPath);
        } else if (collection is Map) {
          return collection.entries.elementAt(currPath);
        }
      }
    } else if (collection is Map) {
      return collection[currPath];
    } else if (collection is Iterable) {
      throw Exception("Unable to read value at index '$currPath' from "
          "Iterable collection of type '${collection.runtimeType}'. The "
          "index provided is not an int. Check your property paths.");
    }
    throw Exception("Path '$currPath' references an unsupported collection of "
      "type '${collection.runtimeType}'. Supported collections are List, Set, "
      "and Map.");
  }
}

/// A simple dot/bracket notation path parser.
class PathInfo {
  final String currPath;
  final String nextPath;
  final bool isNullable;
  final bool isList;
  final bool isIndex;

  PathInfo(
      this.currPath,
      this.nextPath,
      this.isNullable,
      this.isList,
      this.isIndex
  );

  factory PathInfo.parsePath(String path) {
    String currPath = "";
    String nextPath = "";
    bool done = false;
    bool isIndex = false;

    for (int pos = 0; pos < path.length && !done; pos++) {
      final char = path[pos];
      if (char == "[") {
        if (pos > 0) {
          nextPath = path.substring(pos, path.length);
          done = true;
        } else {
          isIndex = true;
        }
      } else if (char == ".") {
        nextPath = path.substring(pos + 1, path.length);
        done = true;
      } else if (char != "]" && char != " ") {
        currPath += char;
      }
    }

    bool isNullable = true;
    if (currPath.endsWith("!")) {
      currPath = currPath.substring(0, currPath.length - 1);
      isNullable = false;
    } else if (currPath.endsWith("?")) {
      currPath = currPath.substring(0, currPath.length - 1);
    }

    bool isList = nextPath.startsWith("[");
    return PathInfo(currPath, nextPath, isNullable, isList, isIndex);
  }
}