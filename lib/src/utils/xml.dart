import 'dart:convert';

import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';

/// Expando that stores a named record (line, column) per XmlNode.
final Expando<XmlNodePosition> _nodePosition = Expando('(XmlNode.position)');

/// Position metadata for a node.
class XmlNodePosition {
  final String? filePath;
  final SourceRange? openTag;
  final SourceRange? closeTag;

  XmlNodePosition({this.filePath, this.openTag, this.closeTag});

  @override
  String toString() => "[${filePath ?? 'no-file'}] open:$openTag, close:$closeTag";
}

/// Extension to read/write position on any XmlNode.
extension XmlNodeExtension on XmlNode {
  XmlNodePosition? get position => _nodePosition[this];
  set position(XmlNodePosition? loc) => _nodePosition[this] = loc;

  String get positionString => position?.toString() ?? '[no-position]';
}

class XmlParser {
  static XmlDocument parse(SourceCode source) {
    final nodes = <XmlNode>[];
    final sink = XmlNodeDecoderSink(
      source: source,
      sink: ConversionSink<List<XmlNode>>(nodes.addAll),
    );
    final events = parseEvents(
      source.input,
      validateNesting: true,
      validateDocument: true,
      withLocation: source.withPosition,
    );
    events.forEach(sink.visit);
    return XmlDocument(nodes);
  }
}

class ConversionSink<T> implements Sink<T> {
  ConversionSink(this.callback);

  void Function(T data) callback;

  @override
  void add(T data) => callback(data);

  @override
  void close() {}
}

class XmlNodeDecoderSink with XmlEventVisitor implements ChunkedConversionSink<List<XmlEvent>> {
  final SourceCode source;
  final Sink<List<XmlNode>> sink;
  XmlElement? parent;

  XmlNodeDecoderSink({required this.source, required this.sink});

  @override
  void add(List<XmlEvent> chunk) => chunk.forEach(visit);

  @override
  void visitCDATAEvent(XmlCDATAEvent event) {
    final element = XmlCDATA(event.value);
    setStartTagPosition(element, event);
    commit(element, event);
  }

  @override
  void visitCommentEvent(XmlCommentEvent event) {
    final element = XmlComment(event.value);
    setStartTagPosition(element, event);
    commit(element, event);
  }

  @override
  void visitDeclarationEvent(XmlDeclarationEvent event) {
    final element = XmlDeclaration(convertAttributes(event.attributes));
    setStartTagPosition(element, event);
    commit(element, event);
  }

  @override
  void visitDoctypeEvent(XmlDoctypeEvent event) {
    final element = XmlDoctype(event.name, event.externalId, event.internalSubset);
    setStartTagPosition(element, event);
    commit(element, event);
  }

  @override
  void visitEndElementEvent(XmlEndElementEvent event) {
    if (parent == null) {
      throw XmlTagException.unexpectedClosingTag(
        event.name,
        buffer: event.buffer,
        position: event.start,
      );
    }
    final element = parent!;
    XmlTagException.checkClosingTag(
      element.name.qualified,
      event.name,
      buffer: event.buffer,
      position: event.start,
    );
    element.isSelfClosing = element.children.isNotEmpty;
    parent = element.parentElement;
    setEndTagPosition(element, event);

    if (parent == null) {
      commit(element, event.parent);
    }
  }

  @override
  void visitProcessingEvent(XmlProcessingEvent event) {
    final element = XmlProcessing(event.target, event.value);
    setStartTagPosition(element, event);
    commit(element, event);
  }

  @override
  void visitStartElementEvent(XmlStartElementEvent event) {
    final attributes = convertAttributes(event.attributes);
    final element = XmlElement.tag(event.name, attributes: attributes);
    setStartTagPosition(element, event);

    if (event.isSelfClosing) {
      commit(element, event);
    } else {
      if (parent != null) {
        parent!.children.add(element);
      }
      parent = element;
    }
  }

  @override
  void visitTextEvent(XmlTextEvent event) {
    final element = XmlText(event.value);
    setStartTagPosition(element, event);
    commit(element, event);
  }

  @override
  void close() {
    if (parent != null) {
      throw XmlTagException.missingClosingTag(parent!.name.qualified);
    }
    sink.close();
  }

  void commit(XmlNode node, XmlEvent? event) {
    if (parent == null) {
      // If we have information about a parent event, create hidden
      // [XmlElement] nodes to make sure namespace resolution works
      // as expected.
      for (
        var outerElement = node, outerEvent = event?.parent;
        outerEvent != null;
        outerEvent = outerEvent.parent
      ) {
        outerElement = XmlElement.tag(
          outerEvent.name,
          attributes: convertAttributes(outerEvent.attributes),
          children: [outerElement],
          isSelfClosing: outerEvent.isSelfClosing,
        );
      }
      sink.add(<XmlNode>[node]);
    } else {
      parent!.children.add(node);
    }
  }

  Iterable<XmlAttribute> convertAttributes(Iterable<XmlEventAttribute> attributes) {
    return attributes.map(
      (attribute) => XmlAttribute(
        XmlName.fromString(attribute.name),
        attribute.value,
        attribute.attributeType,
      ),
    );
  }

  T setStartTagPosition<T extends XmlNode>(T node, XmlEvent event) {
    final start = source.findLineAndColumn(event.start);
    final stop = source.findLineAndColumn(event.stop);
    if (start.isNotEmpty) {
      node.position = XmlNodePosition(
        filePath: source.filePath,
        openTag: SourceRange(SourcePosition(start[0], start[1]), SourcePosition(stop[0], stop[1])),
        closeTag: node.position?.closeTag,
      );
    }
    return node;
  }

  T setEndTagPosition<T extends XmlNode>(T node, XmlEvent event) {
    final start = source.findLineAndColumn(event.start);
    final stop = source.findLineAndColumn(event.stop);
    if (start.isNotEmpty && stop.isNotEmpty) {
      node.position = XmlNodePosition(
        filePath: source.filePath,
        openTag: node.position?.openTag,
        closeTag: SourceRange(SourcePosition(start[0], start[1]), SourcePosition(stop[0], stop[1])),
      );
    }
    return node;
  }
}

class SourceCode {
  final String input;
  final String? filePath;
  final bool withPosition;
  final List<int> _lineStarts;

  SourceCode(this.input, {this.filePath, this.withPosition = false})
    : _lineStarts = withPosition ? buildLineStarts(input) : [];

  /// Build 0-based start offsets for each line in [buffer].
  /// Each entry is the index of the first character of that line.
  static List<int> buildLineStarts(String buffer) {
    final starts = <int>[0];
    final len = buffer.length;
    for (var i = 0; i < len; i++) {
      final ch = buffer.codeUnitAt(i);
      if (ch == 0x0A) {
        // LF
        starts.add(i + 1);
      } else if (ch == 0x0D) {
        // CR or CRLF
        if (i + 1 < len && buffer.codeUnitAt(i + 1) == 0x0A) {
          // CRLF: next line starts after LF
          starts.add(i + 2 <= len ? i + 2 : len);
          i++; // skip LF
        } else {
          starts.add(i + 1);
        }
      } else if (ch == 0x0B || ch == 0x0C || ch == 0x85 || ch == 0x2028 || ch == 0x2029) {
        // VT, FF, NEL, LS, PS
        starts.add(i + 1);
      }
    }
    return starts;
  }

  /// Convert a 0-based [offset] into a 1-based [line, column] using precomputed [lineStarts].
  /// [bufferLength] is required so we clamp against the actual buffer length (not lineStarts.last).
  List<int> findLineAndColumn(int? offset) {
    if (offset == null || !withPosition) return [];
    if (_lineStarts.isEmpty) return [1, offset + 1];

    // clamp start into [0, bufferLength]
    final pos = offset < 0 ? 0 : (offset > input.length ? input.length : offset);

    // binary search for greatest start <= pos
    var lo = 0, hi = _lineStarts.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (_lineStarts[mid] <= pos) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    final lineIndex = hi.clamp(0, _lineStarts.length - 1);
    final line = lineIndex + 1; // 1-based
    final column = pos - _lineStarts[lineIndex] + 1; // 1-based
    return [line, column];
  }
}

class SourcePosition {
  final int line;
  final int column;

  const SourcePosition(this.line, this.column);

  @override
  String toString() {
    return '$line:$column';
  }
}

class SourceRange {
  final SourcePosition start;
  final SourcePosition end;

  const SourceRange(this.start, this.end);

  @override
  String toString() {
    return '$start,$end';
  }
}
