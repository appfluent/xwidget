import 'package:yaml/yaml.dart';

import 'cli_log.dart';

class ConfigLoader {
  static String loadToString(dynamic doc, String key, String defaultValue) {
    final value = getValue(doc, key);
    if (value != null) {
      if (value is String) return value;
      CliLog.stepWarn("'$key' is invalid");
    }
    return defaultValue;
  }

  static void loadToSet(dynamic doc, String key, Set set) {
    final value = getValue(doc, key);
    if (value != null) {
      if (value is YamlList) {
        for (final item in value) {
          if (item is String) {
            set.add(item);
          } else {
            CliLog.stepWarn("'$key' has invalid item '$value'. Must be of type String.");
          }
        }
      } else if (value is List<String>) {
        set.addAll(value);
      } else if (value is String) {
        set.add(value);
      } else {
        CliLog.stepWarn("'$key' is of type ${value.runtimeType}. Must be of type YamlList, List<String>, or String.");
      }
    }
  }

  static void loadToMap(dynamic doc, String key, Map map) {
    final value = getValue(doc, key);
    if (value != null) {
      if (value is YamlMap) {
        for (final entry in value.entries) {
          if (entry.value is String) {
            map[entry.key] = entry.value;
          } else {
            CliLog.stepWarn("'$key' has invalid item '$value'");
          }
        }
      } else if (value is Map<String, String>) {
        map.addAll(value);
      } else {
        CliLog.stepWarn("'$key' is of type ${value.runtimeType}. Must be of type YamlMap or Map<String, String>.");
      }
    }
  }

  static dynamic getValue(dynamic doc, String key) {
    if (doc == null) return null;
    final first = key.indexOf(".");
    if (first > -1) {
      final currentKey = key.substring(0, first);
      final nextKey = key.substring(first + 1);
      final nextDoc = doc[currentKey];
      return getValue(nextDoc, nextKey);
    } else {
      return doc[key];
    }
  }
}