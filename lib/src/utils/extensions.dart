import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';


extension StringExt on String {

  List<String> chunk(int chunkSize) {
    var chunks = <String>[];
    var startIndex = 0;
    while (startIndex < length) {
      var endIndex = min(startIndex + chunkSize, length);
      chunks.add(substring(startIndex, endIndex));
      startIndex = endIndex;
    }
    return chunks;
  }

  bool parseBool() {
    switch (toLowerCase()) {
      case "true": return true;
      case "false": return false;
      default: throw Exception("Invalid bool value: $this");
    }
  }
}

extension UriExt on Uri {

  static String encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  static Uri emailUri({required String to, String? subject, String? body}) {
    return Uri(
      scheme: "mailto",
      path: to,
      query: encodeQueryParameters(<String, String>{
        'subject': subject ?? "",
        "body": body ?? "",
      }),
    );
  }
}

extension AssetBundleExt on AssetBundle {
  Future<Map<String, dynamic>?> loadJson(String key) async {
    var jsonString = "";
    try {
      jsonString = await loadString(key);
    } catch (e) {
      // An exception here means the asset was not found. This is allowed so just return null.
    }
    return jsonString.isNotEmpty ? json.decode(jsonString) : null;
  }
}

extension MapExt<K, V> on Map<K, V> {
  String asString(String key, [String defaultValue = ""]) {
    return this[key]?.toString() ?? defaultValue;
  }

  void subtract(Map<K, V> map) {
    removeWhere((key, value) => map.containsKey(key));
  }

  Map<K, V> immutable() {
    final map = {};
    for (final entry in entries) {
      final value = entry.value;
      map[entry.key] = (value is Map) ? value.immutable() : ((value is List) ? value.immutable() : value);
    }
    return Map.unmodifiable(map);
  }

  MapEntry<K, V>? firstOrNull() {
    for (final entry in entries) {
      return entry;
    }
    return null;
  }

  MapEntry<K, V> first() {
    final entry = firstOrNull();
    if (entry != null) return entry;
    throw Exception("Cannot get first item because the map is empty");
  }

  MapEntry<K, V>? lastOrNull() {
    MapEntry<K, V>? entry;
    for (entry in entries) {}
    return entry;
  }

  MapEntry<K, V> last() {
    final entry = lastOrNull();
    if (entry != null) return entry;
    throw Exception("Cannot get last item because the map is empty");
  }

  void removeKeys(Map<K, dynamic> referenceMap) {
    for (final key in referenceMap.keys) {
      remove(key);
    }
  }
}

extension ListExt<E> on List<E> {
  addIfNotNull(E? value) {
    if (value != null) {
      add(value);
    }
  }

  E? firstOrNull() {
    return (isNotEmpty) ? first : null;
  }

  E? lastOrNull() {
    return (isNotEmpty) ? last : null;
  }

  void subtract(List<E> list) {
    removeWhere((element) => list.contains(element));
  }

  List<E> immutable() {
    final list = [];
    for (final value in this) {
      list.add((value is Map) ? value.immutable() : ((value is List) ? value.immutable() : value));
    }
    return List.unmodifiable(list);
  }
}

extension ColorExt on Color {
  static RegExp colorPrefixRegExp = RegExp("^(#|0x)*");

  static Color parse(String value) {
    var argb = value.replaceAll(colorPrefixRegExp, "");
    if (argb.length == 6) {
      argb = "FF$argb";
    }
    if (argb.length == 8) {
      final colorInt = int.parse(argb, radix: 16);
      return Color(colorInt);
    }
    throw Exception("Invalid color value: $value");
  }

  String asString() {
    return "0x${value.toRadixString(16).padLeft(8, '0')}";
  }
}