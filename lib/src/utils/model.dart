import 'dart:collection';

import 'package:flutter/material.dart';


class Model extends MapBase<String, dynamic> {

  // A static map to hold instances of subclasses, keyed by type and string value.
  static final Map<Type, Map<String?, dynamic>> _instances = {};

  final Map<String, dynamic> _data = {};
  final bool immutable;

  Model([Map<String, dynamic>? data, this.immutable = true]) {
    if (data != null) {
      _data.addAll(data);
    }
  }

  // An internal static method to manage instance creation.
  static T _getInstance<T extends Model>(Type type, String? key, T Function() create) {
    // Ensure the cache for the specific subclass exists.
    _instances[type] ??= {};

    // Return an existing instance if one exists, otherwise create a new one.
    return _instances[type]![key] ??= create();
  }

  /// Helper method to streamline instance creation for subclasses.
  ///
  /// Keyed instances always returns the same instance when given the same key.
  static T keyedInstance<T extends Model>(String key, T Function() create) {
    return Model._getInstance(T, key, create);
  }

  /// Helper method to streamline instance creation for subclasses.
  ///
  /// Always returns the same instance (singleton)
  static T singleInstance<T extends Model>(T Function() create) {
    return Model._getInstance(T, null, create);
  }

  static clearInstances(Type type, [String? key]) {
    final typed = _instances[type];
    if (typed != null) {
      if (key != null) {
        typed.remove(key);
      } else {
        typed.clear();
      }
    }
  }

  static bool hasInstance(Type type, [String? key]) {
    final typed = _instances[type];
    if (typed != null) {
      final keyed = typed[key];
      if (keyed != null) {
        return true;
      }
    }
    return false;
  }

  @override
  Iterable<String> get keys => _data.keys;

  @override
  dynamic operator [](Object? key) {
    return _data[key?.toString()];
  }

  @override
  void operator []=(String key, value) {
    _assertMutable();
    _data[key] = value;
  }

  @override
  void clear() {
    _assertMutable();
    _data.clear();
  }

  @override
  dynamic remove(Object? key) {
    _assertMutable();
    _data.remove(key);
  }

  void _assertMutable() {
    if (immutable) {
      throw UnimplementedError("Model '$runtimeType' is immutable.");
    }
  }
}

/// A [ValueNotifier] that holds a single value.
///
/// The main purpose of this class is to allow Brackets distinguish it's own
/// ValueNotifiers from others so that it doesn't access the wrapped value
/// unintentionally.
///
/// Additionally, instances can keep track of ownership and if there are any
/// attached listeners. This is used by [ValueListener] widget to determine
/// if and when to cleanup resources.
class ModelValueNotifier extends ValueNotifier {
  Key? _ownerKey;
  bool _hasNoListeners = false;

  ModelValueNotifier(super.value);

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