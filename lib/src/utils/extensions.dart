import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';


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
      .map((e)=>'${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
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
      // An exception here means the asset was not found. This is allowed
      // so just return null.
    }
    return jsonString.isNotEmpty ? json.decode(jsonString) : null;
  }
}
