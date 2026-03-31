import 'package:logging/logging.dart';

typedef EventListenerCallback<T extends Enum> = void Function(T event, dynamic payload);

void registerXWidgetEvents(List<Enum> events) {
  for (final event in events) {
    EventNotifier._events["$event"] = event;
  }
}

Enum parseEvent(String value) {
  final event = EventNotifier._events[value];
  if (event != null) {
    return event;
  }
  throw Exception(
    "Event '$value' was not registered'. Call "
    "'registerXWidgetEvents()' to register your application's events.",
  );
}

mixin EventNotifier<T extends Enum> {
  static final _events = <String, Enum>{};
  static final _listeners = <Enum, Set<EventListenerCallback>>{};
  final _log = Logger("EventNotifier");

  void addListener(T event, EventListenerCallback<T> listener) {
    _log.fine("Adding event listener: event=$event");
    Set<EventListenerCallback<T>>? listeners = _listeners[event];
    listeners ??= _listeners[event] = {};
    listeners.add(listener);
  }

  void removeListener(T event, EventListenerCallback<T> listener) {
    _log.fine("Removing event listener: event=$event");
    Set<EventListenerCallback<T>>? listeners = _listeners[event];
    if (listeners != null) {
      listeners.remove(listener);
    }
  }

  void postEvent(T event, [dynamic payload]) {
    _log.fine("Posting event: event=$event, payload=$payload");
    Set<EventListenerCallback<T>>? listeners = _listeners[event];
    if (listeners != null) {
      for (final listener in listeners) {
        listener(event, payload);
      }
    }
  }
}
