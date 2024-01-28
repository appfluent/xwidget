import 'dart:collection';

import 'package:flutter/material.dart';

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

  ValueNotifier listenForChanges(String path, dynamic initialValue, dynamic defaultValue) {
    return PathResolution.resolvePath(path, true, this).listenForChanges(initialValue, defaultValue);
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
  final dynamic collection;

  PathResolution(this.path, this.collection);

  static PathResolution resolvePath(String? path, bool createPath, dynamic data) {
    return _resolve(path, createPath, data);
  }

  dynamic getValue(bool readValueNotifier) {
    dynamic value;
    final data = collection;
    if (data is Map) {
      value = data[path];
    } else if (data is List) {
      final index = path;
      if (index is int && index < data.length) {
        value = data[index];
      }
    }
    return value is DataValueNotifier && readValueNotifier
        ? value.value : value;
  }

  void setValue(dynamic newValue, bool writeToValueNotifier) {
    final value = getValue(false);
    if (value is DataValueNotifier &&
        newValue is! DataValueNotifier &&
        writeToValueNotifier)
    {
      value.value = newValue;
    } else {
      final data = collection;
      if (data is Map) {
        data[path] = newValue;
      } else if (data is List) {
        final index = path;
        if (index is int) {
          data.setValueAt(index, newValue);
        }
      }
    }
  }

  dynamic removeValue() {
    final data = collection;
    if (data is Map) {
      return data.remove(path);
    } else if (data is List) {
      final index = path;
      if (index is int && index < data.length) {
        return data.removeAt(index);
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

  static _resolve(String? path, bool createPath, dynamic data) {
    if (path != null && path.isNotEmpty && data != null) {
      final pathInfo = PathInfo.parsePath(path);
      dynamic currPath = pathInfo.currPath;
      dynamic value;

      if (data is List) {
        // data is a List; therefore, currPath must be an index, so convert it
        // to an int and get the value that it points to.
        currPath = int.parse(currPath);
        if (currPath > -1 && currPath < data.length) {
          value = data[currPath];
        }
      } else {
        // data is some sort of map, so use currPath as it to get the value.
        value = data[currPath];
      }

      if (value == null) {
        if (createPath && pathInfo.nextPath.isNotEmpty) {
          if (pathInfo.isList) {
            value = [];
            data.setValue(currPath, value);
          } else {
            value = data[currPath] = <String, dynamic>{};
          }
        } else if (!pathInfo.isNullable) {
          throw Exception("Value at path '$path' is null. Use the '?' "
              "null-safety operator to access '${pathInfo.currPath}'");
        }
      }
      if (pathInfo.nextPath.isEmpty) {
        return PathResolution(currPath, data);
      }
      if (value is DataValueNotifier) {
        value = value.value;
      }
      return _resolve(pathInfo.nextPath, createPath, value);
    }
    return PathResolution(path, null);
  }
}

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
    _assertMutable();
    data.setValue(key, value);
  }

  @override
  void clear() {
    _assertMutable();
    data.clear();
  }

  @override
  dynamic remove(Object? key) {
    _assertMutable();
    data.remove(key);
  }

  void _assertMutable() {
    if (immutable) {
      throw UnimplementedError("Cannot change immutable data");
    }
  }
}

/// A [ValueNotifier] that holds a single value.
///
/// The main purpose of this class is to allow Brackets distinguish it's own
/// ValueNotifiers from others so that it doesn't access the wrapped value
/// unintentionally.
///
/// Additionaly, instances can keep track of ownership and if there are any
/// attached listeners. This is used by [ValueListener] widget to determine
/// if and when to cleanup resources.
class DataValueNotifier extends ValueNotifier {
  Key? _ownerKey;
  bool _hasNoListeners = false;

  DataValueNotifier(super.value);

  bool get hasNoListeners => _hasNoListeners;

  /// Register a closure to be called when the object changes.
  ///
  /// See [ChangeNotifier] for details
  @override
  void addListener(VoidCallback listener) {
    _hasNoListeners = false;
    super.addListener(listener);
  }

  /// Remove a previously registered closure from the list of closures that are
  /// notified when the object changes.
  ///
  /// See [ChangeNotifier] for details
  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    _hasNoListeners = !hasListeners;
  }

  bool isOwner(Key? key) {
    return key != null && key == _ownerKey;
  }

  Key? takeOwnership() {
    return _ownerKey == null ? _ownerKey = UniqueKey() : null;
  }
}
