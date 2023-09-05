/// A very simple stack implementation using an array
class Stack<E> {
  final _list = <E>[];

  /// Pushes a new item onto the stack
  void push(E value) => _list.add(value);

  /// Pops last item pushed off the stack.
  ///
  /// Returns the popped item.
  E? pop() => _list.isNotEmpty ? _list.removeLast() : null;

  /// Returns the last item pushed to the stack without popping it.
  E? get peek => _list.isNotEmpty ? _list.last : null;

  /// Checks to see if the stack is empty
  bool get isEmpty => _list.isEmpty;

  /// Checks to see if the stack is not empty
  bool get isNotEmpty => _list.isNotEmpty;

  @override
  String toString() => _list.toString();
}
