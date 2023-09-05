import 'dart:collection';

import '../xwidget.dart';

@InflaterDef(inflaterType: "ListOf", inflatesOwnChildren: false)
class ListOf<T> extends ListBase<T> {
  final List<T> children;

  ListOf(this.children);

  @override
  int get length => children.length;

  @override
  set length(int length) {
    children.length = length;
  }

  @override
  T operator [](int index) {
    return children[index];
  }

  @override
  void operator []=(int index, T value) {
    children[index] = value;
  }
}

class MapOf extends MapBase {
  @override
  operator [](Object? key) {
    // TODO: implement []
    throw UnimplementedError();
  }

  @override
  void operator []=(key, value) {
    // TODO: implement []=
  }

  @override
  void clear() {
    // TODO: implement clear
  }

  @override
  // TODO: implement keys
  Iterable get keys => throw UnimplementedError();

  @override
  remove(Object? key) {
    // TODO: implement remove
    throw UnimplementedError();
  }
}

class ListOfInflater extends Inflater {
  @override
  String get type => 'ListOf';

  @override
  bool get inflatesOwnChildren => false;

  @override
  bool get inflatesCustomWidget => true;

  @override
  List? inflate(Map<String, dynamic> attributes, List<dynamic> children, List<String> text) {
    return ListOf(
      [...children, ...?attributes['children']],
    );
  }

  @override
  dynamic parseAttribute(String name, String value) {
    switch (name) {
      case 'children': break;
    }
  }
}
