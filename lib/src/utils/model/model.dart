library model;

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:type_plus/type_plus.dart';

import '../../../xwidget.dart';

part 'transform.dart';

_registerType<T>() {
  TypePlus.add<T>();
  TypePlus.addFactory(<T>(f) => f<List<T>>());
  TypePlus.addFactory(<T>(f) => f<Set<T>>());
}

_autoRegisterType<T>() {
  if (T.id.isEmpty) {
    if (!T.toString().contains("<")) {
      _registerType<T>();
    } else {
      throw Exception("Unable to auto register type '$T', because it contains "
          "generic type arguments. Each generic type must be registered "
          "individually. Please register a transform function for each "
          "generic type by calling XWidget.registerTransformFunction(). Note: "
          "basic types such as String, int, bool, etc are registered by "
          "default. You only need to register custom types. Call "
          "XWidget.registerModel() to register model types.");
    }
  }
}

typedef ModelFactory<T extends Model> = T Function(
  Map<String, dynamic> data, {
  PropertyTranslation? translation,
  bool? immutable
});

const xwidgetModel = XWidgetModel();

class XWidgetModel {
  const XWidgetModel();
}

class Models {

  static final _factories = <String, ModelFactory>{};
  static final _transformers = <String, List<PropertyTransformer>>{};
  static final _keyTransformers = <String, List<PropertyTransformer>>{};

  static ModelFactory<T> factoryOf<T extends Model>() {
    final key = nonNullType(T);
    final factory = _factories[key];
    if (factory != null) {
      return factory as ModelFactory<T>;
    }
    throw Exception("ModelFactory not registered for type '$key'. You can "
        "register a ModelFactory by calling XWidget.registerModel().");
  }

  static List<PropertyTransformer> keyTransformersOf<T extends Model>() {
    final key = nonNullType(T);
    final transformers = _keyTransformers[key];
    if (transformers != null) {
      return transformers;
    }
    throw Exception("Key PropertyTransformers not registered for type '$key'. "
        "You can register your model's PropertyTransformers by calling "
        "XWidget.registerModel().");
  }

  static List<PropertyTransformer>? getTransformers(Type type) {
    return _transformers[nonNullType(type)];
  }

  static List<PropertyTransformer>? getKeyTransformers(Type type) {
    return _keyTransformers[nonNullType(type)];
  }

  static register<T extends Model>(
    ModelFactory<T> factory,
    List<PropertyTransformer>? transformers
  ) {
    final key = nonNullType(T);
    _factories[key] = factory;
    if (transformers != null && transformers.isNotEmpty) {
      _transformers[key] = transformers;
      _keyTransformers[key] = transformers.where((t) => t.isKey).toList();
    }
    _registerType<T>();
  }
}

class Model extends MapBase<String, dynamic> {

  // A static map to hold instances of subclasses, keyed by type and string value.
  static final Map<String, Map<String?, dynamic>> _instances = {};

  late final Map<String, dynamic> _data;
  final Map<String, ModelErrors> _localErrors = {};
  final bool immutable;

  Map<String, ModelErrors> get errors => _getErrors(this);

  Model(
    Map<String, dynamic> data, {
    PropertyTranslation? translation,
    bool? immutable,
  }): immutable = immutable ?? false {
    if (data.isEmpty) {
      _data = {};
    } else {
      final transformers = Models.getTransformers(runtimeType);
      if (transformers == null) {
        _data = {...data};
      } else {
        _data = {};
        for (final transformer in transformers) {
          final value = transformer.transform(
            data: data,
            translation: translation,
            immutable: immutable
          );
          if (value != null) {
            _data.setValue(transformer.property, value);
          } else if (!transformer.type.isNullable) {
            _localErrors[transformer.property] = ModelErrors.required;
          }
        }
      }
    }
  }

  /// Helper method to streamline instance creation for subclasses.
  ///
  /// Always returns the same instance when given the same key.
  static T keyedInstance<T extends Model>({
    required ModelFactory<T> factory,
    Map<String, dynamic>? data,
    PropertyTranslation? translation,
    bool? immutable
  }) {
    if (data == null || data.isEmpty) {
      return factory({});
    } else {
      final key = _getModelKey(T, data, translation);
      if (key != null) {
        return _getInstance(
          key: key,
          factory: factory,
          data: data,
          translation: translation,
          immutable: immutable
        );
      } else {
        return factory(
          data,
          translation: translation,
          immutable: immutable
        );
      }
    }
  }

  /// Helper method to streamline instance creation for subclasses.
  ///
  /// Always returns the same instance (singleton)
  static T singleInstance<T extends Model>({
    required ModelFactory<T> factory,
    Map<String, dynamic>? data,
    PropertyTranslation? translation,
    bool? immutable
  }) {
    return _getInstance(
      data: data,
      factory: factory,
      translation: translation,
      immutable: immutable
    );
  }

  static clearInstances<T>([String? key]) {
    final typed = _instances[nonNullType(T)];
    if (typed != null) {
      if (key != null) {
        typed.remove(key);
      } else {
        typed.clear();
      }
    }
  }

  static bool hasInstance<T>([String? key]) {
    final typed = _instances[nonNullType(T)];
    if (typed != null) {
      final keyed = typed[key];
      if (keyed != null) {
        return true;
      }
    }
    return false;
  }

  // An internal static method to manage instance creation.
  static T _getInstance<T extends Model>({
    required ModelFactory<T> factory,
    String? key,
    Map<String, dynamic>? data,
    PropertyTranslation? translation,
    Map<String, TypeConverter>? functions,
    bool? immutable
  }) {
    final type = nonNullType(T);

    // Ensure the cache for the specific subclass exists.
    _instances[type] ??= {};

    // Return an existing instance if one exists, otherwise create a new one.
    return _instances[type]![key] ??= factory(
      data ?? {},
      translation: translation,
      immutable: immutable
    );
  }

  static String? _getModelKey(
    Type type,
    Map<String, dynamic> data, [
    PropertyTranslation? translation
  ]) {
    final keys = [];
    final transformers = Models.getKeyTransformers(type);
    if (transformers != null) {
      for (final transformer in transformers) {
        keys.add(transformer.transform(data: data));
      }
    }
    final key = keys.join(":");
    return isNotBlank(key) ? key : null;
  }

  String? get modelKey => _getModelKey(runtimeType, _data);

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

  @override
  bool operator ==(Object other) => other is Model && deepEquals(_data, other._data);

  @override
  int get hashCode => deepHashCode(_data);

  void _assertMutable() {
    if (immutable) {
      throw UnimplementedError("Model '$runtimeType' is immutable.");
    }
  }

  Map<String, ModelErrors> _getErrors(dynamic object, [String prefix = ""]) {
    final errors = <String, ModelErrors>{};
    if (object is Model) {
      errors.addAll(object._localErrors);
      errors.addAll(_getErrors(object._data));
    } else if (object is Map) {
      for (final entry in object.entries) {
        errors.addAll(_getErrors(entry.value, "${entry.key}"));
      }
    } else if (object is List) {
      for (var i = 0; i < object.length; i++) {
        errors.addAll(_getErrors(object[i], "[$i]"));
      }
    } else if (object is Set) {
      for (var i = 0; i < object.length; i++) {
        errors.addAll(_getErrors(object.elementAt(i), "{$i}"));
      }
    }
    return prefix.isNotEmpty
        ? errors.map((key, value) {
            final separator =
              (key.startsWith("[") || key.startsWith("{")) &&
              (prefix.endsWith("]") || prefix.endsWith("}")) ? "" : ".";
            return MapEntry("$prefix$separator$key", value);
          })
        : errors;
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
  bool _paused = false;

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

  void pauseNotifications() {
    _paused = true;
  }

  void resumeNotifications() {
    _paused = false;
  }

  @override
  void notifyListeners() {
    // we're overriding this method to make it available to users of this class
    // i.e. brackets.
    if (!_paused) {
      super.notifyListeners();
    }
  }
}

enum ModelErrors {
  required;
}