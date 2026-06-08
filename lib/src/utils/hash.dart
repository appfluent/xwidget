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

/// SHA-256 of [value], base62-encoded. One-way; safe to transmit/log.
String hashKey(String value) {
  final digest = sha256.convert(utf8.encode(value));
  return toBase62(Uint8List.fromList(digest.bytes));
}

String nanoid([int length = 21]) {
  final random = Random.secure();
  return String.fromCharCodes(
    List.generate(length, (_) => _base64Alphabet.codeUnitAt(random.nextInt(64))),
  );
}
