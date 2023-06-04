
class Stack<E> {
  final _list = <E>[];

  void push(E value) => _list.add(value);

  E? pop() => _list.isNotEmpty ? _list.removeLast() : null;

  E? get peek => _list.isNotEmpty ? _list.last : null;

  bool get isEmpty => _list.isEmpty;
  bool get isNotEmpty => _list.isNotEmpty;

  @override
  String toString() => _list.toString();
}