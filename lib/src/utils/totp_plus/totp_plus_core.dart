import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Shared TotpPlus derivation core.
///
/// This file is the single source of truth for how a token is computed. Both
/// the client (which produces tokens) and the server (which verifies them) MUST
/// call into this same code so their output is byte-identical. Do not
/// re-implement the derivation on either side — copy this file and call it.
///
/// A token is `HMAC-SHA256(key, message)`, base64url-encoded, where
/// `message` is an unambiguous, length-prefixed encoding of:
///   (window, context, nonce, [bodyHash])
///
/// `bodyHash` (optional) binds the token to the request body — see [hashBody].
/// When omitted, `message` is the original 3-part form, so tokens minted before
/// body-binding still verify. During rollout the server tries the body-bound
/// form first, then falls back to the legacy form; once every client binds the
/// body, the legacy fallback can be turned off (see the verifier).
///
/// The token never reveals the key: it is a one-way derivation. The
/// server verifies by recomputing the token from its own copy of the key and
/// comparing. The key itself is never transmitted in any form.
///
/// All time handling is UTC. Callers pass UTC `DateTime`s; this core rejects
/// non-UTC input rather than silently producing a skewed window.

/// Configuration for token derivation. The same config must be used on both
/// sides — a mismatch in [windowSeconds] alone will cause every token to fail.
class TotpPlusConfig {
  /// Length of a single time window in seconds. The derived token is stable
  /// for this many seconds, then changes. Default 60s.
  final int windowSeconds;

  /// Number of adjacent windows the server tolerates on each side of the
  /// window selected from the client's claimed timestamp. `1` means the
  /// server accepts windows N-1, N, N+1 — a total acceptance span of
  /// `(2 * skewWindows + 1) * windowSeconds`. With the defaults that is
  /// 3 windows = 180 seconds.
  ///
  /// This absorbs the window-boundary race (a token derived at the tail of one
  /// window arriving in the next) and minor clock disagreement. Widening it
  /// directly widens the replay-acceptance span, so the nonce TTL is derived
  /// from it (see [nonceTtl]).
  final int skewWindows;

  /// Extra margin added on top of the acceptance span when computing the
  /// nonce retention TTL, so eviction never races the acceptance window.
  final Duration nonceTtlMargin;

  const TotpPlusConfig({
    this.windowSeconds = 60,
    this.skewWindows = 1,
    this.nonceTtlMargin = const Duration(minutes: 2),
  }) : assert(windowSeconds > 0),
       assert(skewWindows >= 0);

  /// The full span over which a token may be accepted, in seconds:
  /// `(2 * skewWindows + 1) * windowSeconds`.
  int get acceptanceSpanSeconds => (2 * skewWindows + 1) * windowSeconds;

  /// How long a nonce must be retained to guarantee replay protection across
  /// the entire window in which its token can be accepted, plus margin.
  ///
  /// Auto-derived from [skewWindows] and [windowSeconds] so that widening the
  /// skew tolerance cannot silently leave the nonce store too short-lived.
  Duration get nonceTtl => Duration(seconds: acceptanceSpanSeconds) + nonceTtlMargin;
}

/// Computes the window index for a UTC instant: `floor(epochSeconds / windowSeconds)`.
///
/// Throws [ArgumentError] if [utc] is not in UTC, to prevent a caller from
/// accidentally bucketing local time (which would shift the window by the
/// local offset and break verification).
int windowFor(DateTime utc, TotpPlusConfig config) {
  if (!utc.isUtc) {
    throw ArgumentError.value(utc, 'utc', 'DateTime must be UTC; call .toUtc() before deriving.');
  }
  final epochSeconds = utc.millisecondsSinceEpoch ~/ 1000;
  return epochSeconds ~/ config.windowSeconds;
}

/// Builds the unambiguous HMAC message from the parts.
///
/// Each part is encoded as: 4-byte big-endian length, then the UTF-8 bytes of
/// the part. Length-prefixing makes the encoding injective — no two distinct
/// part tuples can ever produce the same message — which plain concatenation
/// does not guarantee (e.g. ("12","345") and ("123","45") both concatenate to
/// "12345").
///
/// [bodyHash], when non-null, is appended as a fourth part to bind the token to
/// the request body. When null the message is the original 3-part form, so
/// tokens minted before body-binding still verify byte-for-byte.
Uint8List buildMessage(int window, String context, String nonce, {String? bodyHash}) {
  final parts = <List<int>>[
    utf8.encode(window.toString()),
    utf8.encode(context),
    utf8.encode(nonce),
    if (bodyHash != null) utf8.encode(bodyHash),
  ];
  final builder = BytesBuilder();
  for (final part in parts) {
    final len = ByteData(4)..setUint32(0, part.length, Endian.big);
    builder.add(len.buffer.asUint8List());
    builder.add(part);
  }
  return builder.toBytes();
}

/// Derives the TotpPlus token for an explicit [window].
///
/// `token = base64url( HMAC-SHA256(key, buildMessage(window, context, nonce, bodyHash)) )`
///
/// - [key]: the shared secret. Never transmitted; only used to sign.
/// - [window]: the time-window index (see [windowFor]).
/// - [context]: an opaque string both sides agree on (e.g. a session id). It is
///   not interpreted here — it only binds the token to that context so a token
///   minted for one context cannot be reused for another.
/// - [nonce]: a per-request unique value that makes each request's token
///   distinct even within the same window/context, enabling replay detection
///   and avoiding false replay rejections when multiple requests fall in one
///   window.
/// - [bodyHash]: optional SHA-256 of the request body (see [hashBody]). When
///   provided it binds the token to that exact body; when omitted the token is
///   the legacy body-agnostic form.
///
/// The output is base64url without padding.
String deriveToken({
  required String key,
  required int window,
  required String context,
  required String nonce,
  String? bodyHash,
}) {
  final hmac = Hmac(sha256, utf8.encode(key));
  final digest = hmac.convert(buildMessage(window, context, nonce, bodyHash: bodyHash));
  return base64Url.encode(digest.bytes).replaceAll('=', '');
}

/// SHA-256 of the raw request-body bytes, base64url (no padding).
///
/// Client and server compute this from the *same* bytes and pass it to
/// [deriveToken] as `bodyHash`, binding the token to the exact body so a
/// tampered body fails verification. It is **never transmitted** — each side
/// derives it from the body it holds.
String hashBody(List<int> bodyBytes) =>
    base64Url.encode(sha256.convert(bodyBytes).bytes).replaceAll('=', '');

/// Constant-time comparison of two strings.
///
/// Always inspects every byte (XOR-accumulate) so the time taken does not
/// reveal how many leading bytes matched. Use this for the token comparison
/// rather than `==`, which short-circuits on the first mismatch and can leak
/// timing information.
///
/// Returns false immediately only on length mismatch (length is not secret).
bool constantTimeEquals(String a, String b) {
  final ab = utf8.encode(a);
  final bb = utf8.encode(b);
  if (ab.length != bb.length) return false;
  var diff = 0;
  for (var i = 0; i < ab.length; i++) {
    diff |= ab[i] ^ bb[i];
  }
  return diff == 0;
}
