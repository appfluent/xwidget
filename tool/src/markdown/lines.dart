class Lines {
  var _data = <String>[];
  final _buffer = <String>[];

  void add(String line) => _buffer.add(line);
  void addAll(List<String> line) => _buffer.addAll(line);
  void accept() {
    _data.addAll(_buffer);
    _buffer.clear();
  }

  List<String> data() {
    accept();
    return _data;
  }

  void discard() {
    _buffer.clear();
  }

  void removeIndention(int indent) {
    accept();
    if (indent > 0) {
      _data = _data.map((line) {
        if (line.length > indent) {
          return line.substring(indent);
        } else {
          return line;
        }
      }).toList();
    }
  }
}