import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'totp_plus_client.dart';
import 'totp_plus_core.dart';

/// Issues TotpPlus-authenticated POSTs.
///
/// On each [post] it derives fresh auth material from [totp] (the project-key
/// hash, a token, a nonce, and a claimed UTC timestamp), attaches them as the
/// `X-API-Key` and `X-TP-*` headers, sends via the top-level `http.post` (a
/// fresh client per call), then feeds the server's returned timestamp back into
/// the skew offset so later requests derive against server-corrected time.
///
/// This is not an `http` [Client] — it exposes only [post], which is all the
/// analytics flush needs. The caller supplies any remaining headers (e.g.
/// `Content-Type`); this class adds the authentication headers.
///
/// Header names must match the server's verifier (both sides must agree).
class TotpPlusHttpClient {
  /// Header carrying the project-key hash (the non-secret identifier).
  static const keyHashHeader = 'X-TP-Hash';

  /// Header carrying the derived token.
  static const tokenHeader = 'X-TP-Token';

  /// Header carrying the per-request nonce.
  static const nonceHeader = 'X-TP-Nonce';

  /// Header carrying the client's claimed UTC timestamp (ISO-8601, UTC).
  static const timestampHeader = 'X-TP-Ts';

  /// Response header (from the server) carrying server UTC time (ISO-8601, UTC),
  /// used to update the skew offset.
  static const serverTimeHeader = 'X-TP-Server-Ts';

  final TotpPlusClient totp;

  TotpPlusHttpClient({required this.totp});

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    // Bind the token to the body. We hash the same bytes `http.post` will send,
    // so the server's recomputation (over the bytes it reads) matches. The hash
    // is not transmitted — both sides derive it from the body.
    final material = totp.tokenForRequest(bodyHash: hashBody(_bodyBytes(body)));
    final response = await http.post(
      url,
      headers: {
        ...?headers,
        keyHashHeader: material.keyHash,
        tokenHeader: material.token,
        nonceHeader: material.nonce,
        timestampHeader: material.claimedTimestamp.toUtc().toIso8601String(),
      },
      body: body,
      encoding: encoding,
    );

    // Update skew offset from the server's clock, if provided.
    final serverTs =
        response.headers[serverTimeHeader.toLowerCase()] ?? response.headers[serverTimeHeader];

    if (serverTs != null) {
      final parsed = DateTime.tryParse(serverTs);
      if (parsed != null) {
        totp.updateOffsetFromServer(serverUtc: parsed.toUtc());
      }
    }

    return response;
  }

  /// The bytes that will go on the wire for [body], so the hash matches what the
  /// server reads back. A `String` is UTF-8 encoded (the analytics flush sends a
  /// JSON string); raw bytes pass through; a null body hashes to empty. Maps are
  /// not used here — if one is ever passed, it is stringified, which would *not*
  /// match `http`'s form-encoding, so callers must send a String or bytes.
  List<int> _bodyBytes(Object? body) {
    if (body == null) return const [];
    if (body is String) return utf8.encode(body);
    if (body is List<int>) return body;
    return utf8.encode(body.toString());
  }
}
