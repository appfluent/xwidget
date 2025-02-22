import '../../xwidget.dart';


class ListInflater extends Inflater {
  @override
  String get type => 'List';

  @override
  bool get inflatesOwnChildren => false;

  @override
  bool get inflatesCustomWidget => false;

  @override
  List? inflate(
      Map<String, dynamic> attributes,
      List<dynamic> children,
      List<String> text
  ) {
    final items = [];
    final innerLists = attributes["innerLists"];
    for (final child in children) {
      if (innerLists == "spread" && child is List) {
        items.addAll(child);
      } else {
        items.add(child);
      }
    }
    return items;
  }

  @override
  dynamic parseAttribute(String name, String value) {
    return value;
  }
}

class ItemInflater extends Inflater {
  @override
  String get type => 'Item';

  @override
  bool get inflatesOwnChildren => false;

  @override
  bool get inflatesCustomWidget => false;

  @override
  dynamic inflate(
      Map<String, dynamic> attributes,
      List<dynamic> children,
      List<String> text
  ) {
    return attributes["value"];
  }

  @override
  dynamic parseAttribute(String name, String value) {
    return value;
  }
}

class MapInflater extends Inflater {
  @override
  String get type => 'Map';

  @override
  bool get inflatesOwnChildren => false;

  @override
  bool get inflatesCustomWidget => false;

  @override
  Map inflate(
      Map<String, dynamic> attributes,
      List<dynamic> children,
      List<String> text
  ) {
    final Map map = {};
    for (final child in children) {
      if (child is MapEntry) {
        map[child.key] = child.value;
      }
    }
    return map;
  }

  @override
  dynamic parseAttribute(String name, String value) {
    return value;
  }
}

class MapEntryInflater extends Inflater {
  @override
  String get type => 'Entry';

  @override
  bool get inflatesOwnChildren => false;

  @override
  bool get inflatesCustomWidget => false;

  @override
  MapEntry? inflate(
      Map<String, dynamic> attributes,
      List<dynamic> children,
      List<String> text
  ) {
    var value = XWidgetUtils.getOnlyChild("param", children);
    if (value == null) {
      value = attributes["value"];
      if (value == null && text.isNotEmpty) {
        value = XWidgetUtils.joinStrings(text);
      }
    }
    return MapEntry(attributes["key"], value);
  }

  @override
  dynamic parseAttribute(String name, String value) {
    return value;
  }
}

class ParamInflater extends Inflater {
  @override
  String get type => 'param';

  @override
  bool get inflatesOwnChildren => false;

  @override
  bool get inflatesCustomWidget => false;

  @override
  MapEntry? inflate(
      Map<String, dynamic> attributes,
      List<dynamic> children,
      List<String> text
  ) {
    var value = XWidgetUtils.getOnlyChild("param", children);
    if (value == null) {
      value = attributes["value"];
      if (value == null && text.isNotEmpty) {
        value = XWidgetUtils.joinStrings(text);
      }
    }
    return MapEntry(attributes["name"], value);
  }

  @override
  dynamic parseAttribute(String name, String value) {
    return value;
  }
}