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
    final resolved = PathResolution.resolvePath(path, false, this);
    final collection = resolved.collection;
    if (collection is Map) {
      return collection.remove(resolved.path);
    }
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

  PathResolution(this.path, this.collection);

  static PathResolution resolvePath(String? path, bool createPath, dynamic data) {
    return data is List
        ? _resolveListPath(path, createPath, data)
        : _resolveMapPath(path, createPath, data);
  }

  dynamic getValue(bool readValueNotifier) {
    if (collection == null) return null;
    final value = collection[path];
    return value is DataValueNotifier && readValueNotifier
        ? value.value
        : value;
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
      final pathInfo = PathInfo.parsePath(path);
      var value = data[pathInfo.currPath];
      if (value == null) {
        if (createPath && pathInfo.nextPath.isNotEmpty) {
          value = data[pathInfo.currPath] = pathInfo.isNextPathList
              ? <dynamic>[]
              : <String, dynamic>{};
        } else if (pathInfo.isValueNullable) {
          return PathResolution(pathInfo.currPath, data);
        } else {
          throw Exception("Value at path '$path' is null. Use the '?' "
              "null-safety operator to access '${pathInfo.currPath}'");
        }
      } else if (pathInfo.nextPath.isEmpty) {
        return PathResolution(pathInfo.currPath, data);
      }
      if (value is DataValueNotifier) {
        // unwrap notifier value
        value = value.value;
      }
      return _continuePathResolution(path, pathInfo.nextPath, pathInfo.isNextPathList, value, createPath);
    }
    return PathResolution(path, null);
  }

  static PathResolution _resolveListPath(String? path, bool createPath, List data) {
    if (path != null) {
      final pathInfo = PathInfo.parsePath(path);
      final index = pathInfo.currPathListIndex;
      if (index != null && index > -1) {
        var value = index < data.length ? data[index] : null;
        if (pathInfo.nextPath.isEmpty) {
          return PathResolution(index, data);
        } else if (value == null && createPath) {
          value = pathInfo.isNextPathList ? [] : <String, dynamic>{};
          data.setValueAt(index, value);
        }
        if (value is DataValueNotifier) {
          // unwrap notifier value
          value = value.value;
        }
        return _continuePathResolution(path, pathInfo.nextPath, pathInfo.isNextPathList, value, createPath);
      }
    }
    return PathResolution(path, null);
  }

  static _continuePathResolution(String path, String nextPath, bool isNextPathList, dynamic value, bool createPath) {
    if (isNextPathList) {
      if (value is List<dynamic>) {
        return PathResolution._resolveListPath(nextPath, createPath, value);
      }
      throw Exception("Path '$path' implies a [List], but found a "
          "[${value.runtimeType}] at '$nextPath' instead.");
    } else if (value is Map<String, dynamic> || value is Keyed) {
      return PathResolution.resolvePath(nextPath, createPath, value);
    } else if (value is Data) {
      return PathResolution.resolvePath(nextPath, createPath, value.data);
    }
    throw Exception("Path '$path' implies a keyed or indexed value such as "
        "[Data], [Map], [List] or [Keyed], but found a [${value.runtimeType}] "
        "at '$nextPath' instead.");
  }
}

class PathInfo {
  final String currPath;
  final String nextPath;
  final int? currPathListIndex;
  final bool isNextPathList;
  final bool isValueNullable;

  PathInfo(this.currPath, this.nextPath, this.isNextPathList, this.currPathListIndex, this.isValueNullable);

  factory PathInfo.parsePath(String path) {
    String currPath = "";
    String nextPath = "";
    int? currPathListIndex;
    bool isValueNullable = false;

    final splitIndex = path.indexOf(".");
    if (splitIndex > -1) {
      currPath = path.substring(0, splitIndex);
      nextPath = path.substring(splitIndex + 1, path.length);
    } else {
      currPath = path;
    }

    if (currPath.startsWith("[")) {
      currPathListIndex = int.parse(currPath.substring(1, currPath.length - 1));
    }

    if (currPath.endsWith("?")) {
      isValueNullable = true;
      currPath = currPath.substring(0, currPath.length - 1);
    } else if (currPath.endsWith("!")) {
      currPath = currPath.substring(0, currPath.length - 1);
    } else if (nextPath.isEmpty) {
      isValueNullable = true;
    }

    final isNextPathList = nextPath.isNotEmpty && nextPath.startsWith("[");
    return PathInfo(currPath, nextPath, isNextPathList, currPathListIndex, isValueNullable);
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

class Keyed {
  dynamic operator [](String key) {
    throw UnimplementedError("[] operator not implement.");
  }

  void operator []=(String key, value) {
    throw UnimplementedError("[] operator not implement.");
  }
}
