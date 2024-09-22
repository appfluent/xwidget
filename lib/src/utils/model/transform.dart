part of 'model.dart';

typedef TypeConverter<T> = T? Function(dynamic value);

class TypeConverters {
  static final _functions = _predefinedFunctions();

  static register<T>(TypeConverter<T> function) {
    _registerType<T>();
    _functions[nonNullType(T)] = function;
  }

  static T? convert<T>(dynamic value) {
    if (value != null) {
      final key = nonNullType(T);
      final function = _functions[key];
      if (function != null) {
        return function(value);
      } else if (value is T) {
        return value;
      } else {
        throw Exception("Type converter function not registered for type "
            "'$key'. You can register a function that converts the value to "
            "the appropriate type by calling XWidget.registerTypeConverter(). "
            "Typically, this is done inside main(). Alternatively, you can "
            "ensure that the data has the appropriate type before attempting "
            "to import it into your model.");
      }
    }
    return null;
  }

  static Map<String, TypeConverter> _predefinedFunctions() {
    _registerType<Color>();
    _registerType<DateTime>();
    _registerType<Duration>();
    return {
      "bool": toBool,
      "Color": toColor,
      "DateTime": toDateTime,
      "Duration": toDuration,
      "double": toDouble,
      "int": toInt,
      "String": toString,
      "dynamic": (v) => v,
    };
  }
}

class PropertyTranslation {

  // nested model parent
  final String? _destPrefix;

  // nested model parent w/index - used to build the srcPath translation when
  // not provided by user
  final String? _srcPrefix;

  // source to destination property translation
  final Map<String, String> _srcToDest;

  // destination to source property translation
  final Map<String, List<String>> _destToSrc;

  final bool _srcPrefixSet;

  const PropertyTranslation._(
      this._srcToDest,
      this._destToSrc, [
      this._destPrefix,
      this._srcPrefix,
      this._srcPrefixSet = false
  ]);

  factory PropertyTranslation(
      Map<String, String> srcToDest, [
      String? destPrefix,
      String? srcPrefix,
      bool? srcPrefixSet,
  ]) {
    Map<String, List<String>> destToSrc = {};
    for (final entry in srcToDest.entries) {
      var src = destToSrc[entry.value];
      if (src == null) {
        src = <String>[];
        destToSrc[entry.value] = src;
      }
      src.add(entry.key);
    }
    return PropertyTranslation._(
        srcToDest,
        destToSrc,
        destPrefix,
        srcPrefix,
        srcPrefixSet ?? false,
    );
  }

  TranslatedProperty translate(String dest) {
    final destPath = _addPathPrefix(dest, _destPrefix);
    final srcPath = _destToSrc[destPath] ?? [_addPathPrefix(dest, _srcPrefix)];
    return TranslatedProperty(destPath, srcPath);
  }

  PropertyTranslation setParent(String dest) {
    final destPrefix = _addPathPrefix(dest, _destPrefix);
    final srcPrefix = _srcPrefixSet ? _srcPrefix : _addPathPrefix(dest, _srcPrefix);
    return PropertyTranslation._(_srcToDest, _destToSrc, destPrefix, srcPrefix);
  }

  PropertyTranslation setSrcIndex(String src, int index) {
    final srcToDest = _srcToDest.map((key, value) {
      if (key.startsWith("$src[]")) {
        return MapEntry("$src[$index]${key.substring(src.length + 2)}", value);
      } else if (key.startsWith("$src.")) {
        return MapEntry("$src[$index]${key.substring(src.length)}", value);
      } else {
        return MapEntry(key, value);
      }
    });
    final srcPrefix = "$src[$index]";
    return PropertyTranslation(srcToDest, _destPrefix, srcPrefix, true);
  }

  /// Filters out other srcPaths for a given destPath.
  ///
  /// Since a destPath can be associated with multiple srcPaths, i.e. when
  /// populating a list from multiple objects not contained in a List,
  /// we need a way to target only the srcPath were currently interested in.
  PropertyTranslation filterSrcDest(String src, String dest) {
    final srcToDest = Map.fromEntries(_srcToDest.entries.where((e) {
      return e.key == src || e.value != dest;
    }));
    return PropertyTranslation(srcToDest, _destPrefix, _srcPrefix);
  }

  PropertyTranslation removeSrcPaths(List<String> srcPaths) {
    final srcToDest = Map.fromEntries(_srcToDest.entries.where((e) {
      for (final srcPath in srcPaths) {
        if (e.key == srcPath ||
            e.key.startsWith("$srcPath.") ||
            e.key.startsWith("$srcPath[")) return false;
      }
      return true;
    }));
    return PropertyTranslation(srcToDest, _destPrefix, _srcPrefix);
  }

  @override
  String toString() {
    return "PropertyTranslation{srcPrefix=$_srcPrefix, "
        "destPrefix=$_destPrefix, destToSrc=$_destToSrc}";
  }

  //===================================
  // private methods
  //===================================

  String _addPathPrefix(String path, String? prefix) {
    if (isNotEmpty(prefix)) {
      if (path.startsWith("[")) {
        return "$prefix$path";
      } else {
        return "$prefix.$path";
      }
    }
    return path;
  }
}

class TranslatedProperty {
  final String destPath;
  final List<String> srcPaths;

  TranslatedProperty(this.destPath, this.srcPaths);

  @override
  String toString() {
    return "TranslatedProperty: destPath=$destPath, srcPaths=$srcPaths";
  }
}

class PropertyTransformer<T> {
  final String property;
  final Type type;
  final bool isKey;
  final T? defaultValue;
  final TypeConverter<T>? converter;

  const PropertyTransformer(
    this.property, {
    this.isKey = false,
    this.defaultValue,
    this.converter,
  }): type = T;

  T? transform({
    required Map<String, dynamic> data,
    PropertyTranslation? translation,
    Map<String, TypeConverter>? functions,
    bool? immutable
  }) {
    // set default values, if null
    translation ??= const PropertyTranslation._({}, {});
    immutable ??= false;

    // try to auto register the type. If we don't do this and the type is
    // unregistered and there's a downstream converter error, we won't know
    // which type failed.
    _autoRegisterType<T>();

    final value = _transform.callWith(
      typeArguments: [T],
      parameters: [property, data, translation, immutable, T]
    );
    return (converter != null ? converter!(value) : value) ?? defaultValue;
  }

  @override
  toString() {
    return "PropertyTransformer<$T>: property=$property, "
       "transformFunction=$converter, defaultValue=$defaultValue";
  }

  //===================================
  // private methods
  //===================================

  V? _transform<V>(
    String property,
    Map<String, dynamic> data,
    PropertyTranslation translation,
    bool immutable, [
    Type? realType,
  ]) {
    final type = <V>[];
    if (type is List<Model?>) {
      // V is a Model
      return _toModel.callWith(
          typeArguments: [V],
          parameters: [data, translation, immutable]
      );
    } else if (type is List<List?>) {
      // V is a List
      return _toList.callWith(
          typeArguments: V.args,
          parameters: [property, data, translation, immutable]
      );
    } else if (type is List<Set?>) {
      // V is a Set
      return _toSet.callWith(
          typeArguments: V.args,
          parameters: [property, data, translation, immutable]
      );
    } else if (type is List<Map?>) {
      // V is a Map
      return _toMap.callWith(
          typeArguments: V.args,
          parameters: [property, data, translation, immutable]
      );
    } else {
      return _toObject.callWith(
          typeArguments: [V],
          parameters: [property, data, translation]
      );
    }
  }

  Model? _toModel<V extends Model?>(
    Map<String, dynamic> data,
    PropertyTranslation translation,
    bool immutable
  ) {
    final ModelFactory factory = Models.factoryOf.callWith(typeArguments: [V.nonNull]);
    final nested = translation.setParent(property);
    final model = factory(data, translation: nested, immutable: immutable);
    return model._data.isNotEmpty == true ? model : null;
  }

  List<V> _toList<V>(
    String property,
    Map<String, dynamic> data,
    PropertyTranslation translation,
    bool immutable
  ) {
    final list = <V>[];
    final translated = translation.translate(property);
    addItem(item) { if (item != null) list.add(item); }

    for (final srcPath in translated.srcPaths) {
      final resolution = PathResolution(srcPath, false, data);
      final value = resolution.getValue(true);
      if (value is Iterable) {
        for (int i = 0; i < value.length; i++) {
          // todo stop is prev translation == curr
          final indexed = translation.setSrcIndex(srcPath, i);
          final item = _transform<V>("", data, indexed, immutable);
          addItem(item);
        }
      } else if (value != null) {
        // add src object to list
        final filtered = translation.filterSrcDest(srcPath, property);
        final item = _transform<V>(property, data, filtered, immutable);
        addItem(item);
      }
    }

    // attempt to transform unindexed model groups
    final removed = translation.removeSrcPaths(translated.srcPaths);
    _fromModelGroup<V>(property, data, removed, immutable, addItem);

    return immutable ? List.unmodifiable(list) : list;
  }

  Set<V> _toSet<V>(
    String property,
    Map<String, dynamic> data,
    PropertyTranslation translation,
    bool immutable
  ) {
    final set = <V>{};
    final translated = translation.translate(property);
    addItem(item) { if (item != null) set.add(item); }

    for (final srcPath in translated.srcPaths) {
      final resolution = PathResolution(srcPath, false, data);
      final value = resolution.getValue(true);
      if (value is Iterable || value is Map) {
        for (int i = 0; i < value.length; i++) {
          // todo stop is prev translation == curr
          final indexed = translation.setSrcIndex(srcPath, i);
          final item = _transform<V>("", data, indexed, immutable);
          addItem(item);
        }
      } else if (value != null) {
        // add src object to set
        final filtered = translation.filterSrcDest(srcPath, property);
        final item = _transform<V>(property, data, filtered, immutable);
        addItem(item);
      }
    }

    // attempt to transform unindexed model groups
    final removed = translation.removeSrcPaths(translated.srcPaths);
    _fromModelGroup<V>(property, data, removed, immutable, addItem);

    return immutable ? Set.unmodifiable(set) : set;
  }

  Map<K,V> _toMap<K,V>(
    String property,
    Map<String, dynamic> data,
    PropertyTranslation translation,
    bool immutable,
  ) {
    final map = <K,V>{};
    final translated = translation.translate(property);
    for (final srcPath in translated.srcPaths) {
      final resolution = PathResolution(srcPath, false, data);
      final value = resolution.getValue(true);
      if (value is Map) {
        for (int i = 0; i < value.length; i++) {
          final indexed = translation.setSrcIndex(srcPath, i);
          final key = _transform<K>("_key", data, indexed, immutable);
          if (key != null) {
            final value = _transform<V>("_value", data, indexed, immutable);
            if (value != null) {
              map[key] = value;
            }
          }
        }
      } else if (value is Iterable) {
        // we have a List or Set of items
        for (int i = 0; i < value.length; i++) {
          final indexed = translation.setSrcIndex(srcPath, i);
          final value = _transform<V>("", data, indexed, immutable);
          if (value != null) {
            final key = value is Model ? value.modelKey ?? i : i;
            map[TypeConverters.convert<K>(key)!] = value;
          }
        }
      }
    }
    return immutable ? Map.unmodifiable(map) : map;
  }

  V? _toObject<V>(
    String property,
    Map<String, dynamic> data,
    PropertyTranslation translation,
  ) {
    V? object;
    final translated = translation.translate(property);
    for (final srcPath in translated.srcPaths) {
      final resolution = PathResolution(srcPath, false, data);
      final value = resolution.getValue(true);
      object = TypeConverters.convert<V>(value);
      // todo pick the first non-null value
    }
    return object;
  }

  void _fromModelGroup<V>(
    String property,
    Map<String, dynamic> data,
    PropertyTranslation translation,
    bool immutable,
    Function(V?) callback
  ) {
    Map<String, String>? currDests;
    final otherDests = <String, String>{};
    final destGroups = <Map<String, String>>[];
    for (final srcToDestEntry in translation._srcToDest.entries) {
      // divide srcToDest entries into groups with each group representing
      // data for a potential model object. Irrelevant (for this context)
      // entries are stored in otherDests to be merged back in later.
      final src = srcToDestEntry.key;
      final dest = srcToDestEntry.value;
      if (dest.startsWith("$property.")) {
        if (currDests == null || currDests.containsValue(dest)) {
          destGroups.add(currDests = {});
        }
        currDests[src] = dest;
      } else {
        otherDests[src] = dest;
      }
    }

    for (final destGroup in destGroups) {
      final merged = PropertyTranslation({}..addAll(otherDests)..addAll(destGroup));
      callback(_transform<V>(property, data, merged, immutable));
    }
  }
}