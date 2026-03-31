// platform_utils_web.dart
import 'dart:js_interop';
import 'package:logging/logging.dart';
import 'package:web/web.dart' as web;

final _log = Logger('Platform Web');

String getPlatformName() => 'web';

Future<bool> requestStoragePersistence() async {
  final result = await web.window.navigator.storage.persist().toDart;
  final granted = result.toDart;
  _log.info('Storage persistence granted: $granted');
  return granted;
}
