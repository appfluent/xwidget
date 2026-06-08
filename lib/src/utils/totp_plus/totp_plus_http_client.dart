import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'totp_plus_client.dart';

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
    final material = totp.tokenForRequest();
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
}
