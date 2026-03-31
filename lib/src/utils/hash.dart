import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const _base62Alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

const _base64Alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_-';

/// Encodes a [Uint8List] as a base62 string.
///
/// This implementation matches the TypeScript version used server-side
/// to ensure consistent hashing across platforms.
String toBase62(Uint8List bytes) {
  var num = BigInt.zero;
  for (final byte in bytes) {
    num = (num << 8) | BigInt.from(byte);
  }

  if (num == BigInt.zero) return '0';

  final buffer = StringBuffer();
  final base = BigInt.from(62);
  while (num > BigInt.zero) {
    buffer.write(_base62Alphabet[(num % base).toInt()]);
    num = num ~/ base;
  }

  // Reverse since we built the string from least significant digit
  return String.fromCharCodes(buffer.toString().codeUnits.reversed);
}

/// Hashes a [storageKey] using SHA-256 and encodes the result as base62.
///
/// Used to construct the content path segment from the raw storage key,
/// preventing the key from being exposed in URLs.
String hashStorageKey(String storageKey) {
  final bytes = utf8.encode(storageKey);
  final digest = sha256.convert(bytes);
  return toBase62(Uint8List.fromList(digest.bytes));
}

String nanoid([int length = 21]) {
  final random = Random.secure();
  return String.fromCharCodes(
    List.generate(length, (_) => _base64Alphabet.codeUnitAt(random.nextInt(64))),
  );
}
