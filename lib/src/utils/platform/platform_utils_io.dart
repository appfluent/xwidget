// platform_utils_io.dart
import 'dart:io';

String getPlatformName() => Platform.operatingSystem;
Future<bool> requestStoragePersistence() async => true;
