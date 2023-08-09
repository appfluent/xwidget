import 'dart:collection';

import 'package:flutter/material.dart';

/// A simple utility for retrieving data using dot/bracket notation. As long as your
/// data follows a simple convention you can use a simplified dot/bracket notation
/// to locate any piece of data in your hierarchy. Searches return null if no data is found
/// or if the path string is invalid.
///
/// 1. Objects must be represented as <String, dynamic> maps.
/// 2. Array data must use <dynamic> lists.
/// 3. Map keys may only contain upper/lower case letters, numbers and the underscore.
/// 4. Array indexes must be int parsable numbers.


extension MapBrackets on Map<String, dynamic> {

  dynamic getValue(String? path) {
    return PathResolution.resolvePath(path, false, this).getValue(true);
  }

  void setValue(String? path, dynamic value) {
    PathResolution.resolvePath(path, true, this).setValue(value, true);
  }

  ValueNotifier listenForChanges(String path, dynamic initialValue, dynamic defaultValue) {
    return PathResolution.resolvePath(path, true, this).listenForChanges(initialValue, defaultValue);
  }
}

extension ListBrackets on List<dynamic>  {

  dynamic getValue(String? path) {
    return PathResolution.resolvePath(path, false, this).getValue(true);
  }

  void setValue(String? path, dynamic value) {
    PathResolution.resolvePath(path, true, this).setValue(value, true);
  }

  ValueNotifier listenForChanges(String path, dynamic initialValue, dynamic defaultValue) {
    return PathResolution.resolvePath(path, true, this).listenForChanges(initialValue, defaultValue);
  }

  void setValueAt(int index, dynamic value) {
    if (index < length) {
      this[index] = value;
    } else {
      for (var i = length; i <= index; i++) {
        add(i == index ? value : null);
      }
    }
  }
}

class PathResolution {
  final dynamic path;
  final dynamic collection;

  static final _mapPathRegExp = RegExp(r"^([a-zA-Z0-9_]+[?!]?)(?:\.?)(.*)");
  static final _listPathRegExp = RegExp(r"^\[([0-9]+)\](?:\.?)(.*)");
  static final _nullSafetyRegExp = RegExp("[?!]");

  PathResolution(this.path, this.collection);

  static PathResolution resolvePath(String? path, bool createPath, dynamic data) {
    return data is List ? _resolveListPath(path, createPath, data) : _resolveMapPath(path, createPath, data);
  }

  dynamic getValue(bool readValueNotifier) {
    if (collection == null) return null;
    final value = collection[path];
    return value is DataValueNotifier && readValueNotifier ? value.value : value;
  }

  void setValue(dynamic newValue, bool writeToValueNotifier) {
    if (collection != null) {
      final value = collection[path];
      if (value is DataValueNotifier && newValue is! DataValueNotifier && writeToValueNotifier) {
        value.value = newValue;
      } else {
        collection[path] = newValue;
      }
    }
  }

  ValueNotifier listenForChanges(dynamic initialValue, dynamic defaultValue) {
    var value = getValue(false);
    if (value is! ValueNotifier) {
      value = DataValueNotifier(initialValue ?? value ?? defaultValue);
      setValue(value, false);
    }
    return value;
  }

  //===================================
  // private methods
  //===================================

  static PathResolution _resolveMapPath(String? path, bool createPath, dynamic data) {
    if (path != null) {
      final matches = _mapPathRegExp.firstMatch(path);
      if (matches != null) {
        final nextPath = matches.group(2);
        final nextPathIsList = nextPath?.startsWith("[") ?? false;
        final nextPathIsEmpty = nextPath == null || nextPath.isEmpty;
        final group1 = matches.group(1)!;
        final currPath = group1.replaceAll(_nullSafetyRegExp, "");
        final valueIsNullable = group1.endsWith("?") || (nextPathIsEmpty && !group1.endsWith("!"));
        var value = data[currPath];

        if (value == null) {
          if (createPath && !nextPathIsEmpty) {
            value = data[currPath] = nextPathIsList ? <dynamic>[] : <String, dynamic>{};
          } else if (valueIsNullable) {
            return PathResolution(currPath, data);
          } else {
            throw Exception("Value at path '$path' is null. Use the '?' null-safety operator to access '$currPath'");
          }
        } else if (nextPathIsEmpty) {
          return PathResolution(currPath, data);
        }

        if (value is DataValueNotifier) {
          // unwrap notifier value
          value = value.value;
        }
        return _continuePathResolution(path, nextPath, nextPathIsList, value, createPath);
      }
    }
    return PathResolution(path ,null);
  }

  static PathResolution _resolveListPath(String? path, bool createPath, List data) {
    if (path != null) {
      final matches = _listPathRegExp.firstMatch(path);
      if (matches != null) {
        final index = int.tryParse(matches.group(1) ?? "");
        if (index != null && index > -1) {
          final nextPath = matches.group(2);
          final nextPathIsList = nextPath?.startsWith("[") ?? false;
          var value = index < data.length ? data[index] : null;

          if (nextPath == null || nextPath.isEmpty) {
            return PathResolution(index, data);
          } else if (value == null && createPath) {
            value = nextPath.startsWith("[") ? [] : <String, dynamic>{};
            data.setValueAt(index, value);
          }

          if (value is DataValueNotifier) {
            // unwrap notifier value
            value = value.value;
          }
          return _continuePathResolution(path, nextPath, nextPathIsList, value, createPath);
        }
      }
    }
    return PathResolution(path ,null);
  }

  static _continuePathResolution(String path, String nextPath, bool nextPathIsList, dynamic value, bool createPath) {
    if (nextPathIsList) {
      if (value is List<dynamic>) return PathResolution._resolveListPath(nextPath, createPath, value);
      throw Exception("Path '$path' implies a [List], but found a [${value.runtimeType}] at '$nextPath' instead.");
    } else if (value is Map<String, dynamic> || value is Keyed) {
      return PathResolution.resolvePath(nextPath, createPath, value);
    } else if (value is Data) {
      return PathResolution.resolvePath(nextPath, createPath, value.data);
    }
    throw Exception("Path '$path' implies a keyed or indexed value such as [Data], [Map], [List] or [Keyed],"
        " but found a [${value.runtimeType}] at '$nextPath' instead.");
  }
}

class Data extends MapBase<String, dynamic> {
  final Map<String, dynamic> data;
  final bool immutable;

  Data(this.data, [this.immutable = true]);

  @override
  Iterable<String> get keys => data.keys;

  @override
  dynamic operator [](Object? key) {
    return data.getValue(key?.toString());
  }

  @override
  void operator []=(String key, value) {
    if (immutable) throw UnimplementedError("Cannot change immutable data: key=$key");
    data.setValue(key, value);
  }

  @override
  void clear() {
    if (immutable) throw UnimplementedError("Cannot change immutable data");
    data.clear();
  }

  @override
  dynamic remove(Object? key) {
    if (immutable) throw UnimplementedError("Cannot change immutable data: key=$key");
    data.remove(key);
  }
}

/// A [ValueNotifier] that holds a single value.
///
/// The sole purpose of this class is to allow Brackets distinguish it's own ValueNotifiers from
/// others so that it doesn't access the wrapped value by unintentionally.
class DataValueNotifier extends ValueNotifier {
  DataValueNotifier(super.value);
}

class Keyed {

  dynamic operator [](String key) {
    throw UnimplementedError("[] operator not implement.");
  }

  void operator []=(String key, value) {
    throw UnimplementedError("[] operator not implement.");
  }
}
