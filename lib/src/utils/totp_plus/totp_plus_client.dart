import 'dart:convert';
import 'dart:math';

import '../hash.dart';

import 'totp_plus_core.dart';

/// Client-side TotpPlus token producer.
///
/// Holds an in-memory clock-skew offset (server time minus device time) so that
/// tokens are derived against server-corrected UTC, not the device's possibly
/// wrong clock. The offset is NOT persisted: on a cold start the client derives
/// against its own clock, and switches to corrected time after the first server
/// response. A badly-skewed first request is handled by the SDK's existing retry
/// (which re-derives once the offset is known).
///
/// Everything is UTC. The offset is a UTC-vs-UTC delta.
///
/// Typical use:
/// ```dart
/// final client = TotpPlusClient(key: projectKey);
/// // ... build a request:
/// final material = client.tokenForRequest(context: sessionId);
/// // attach material.token, material.nonce, material.claimedTimestamp to the request
/// // ... on every response, feed the server's UTC time back:
/// client.updateOffsetFromServer(serverUtc: serverTime);
/// ```
class TotpPlusClient {
  final String _key;
  final String _keyHash;
  final TotpPlusConfig config;

  /// Injectable clock, for testing. Returns the device's current UTC time.
  final DateTime Function() _deviceNowUtc;

  /// Injectable nonce generator, for testing. Defaults to a 16-byte random,
  /// base64url-encoded value. Replace with a nanoid generator if preferred —
  /// the only requirement is per-request uniqueness.
  final String Function() _nonceGenerator;

  /// Server-minus-device offset. Null until the first server response is seen.
  /// In-memory only — reset to null on each new client instance / cold start.
  Duration? _offset;

  TotpPlusClient({
    required String key,
    this.config = const TotpPlusConfig(),
    DateTime Function()? deviceNowUtc,
    String Function()? nonceGenerator,
  }) : _key = key,
       _keyHash = hashKey(key),
       _deviceNowUtc = deviceNowUtc ?? (() => DateTime.now().toUtc()),
       _nonceGenerator = nonceGenerator ?? _defaultNonce;

  /// Whether a server offset has been established yet this session.
  bool get isSynced => _offset != null;

  /// The current offset (server minus device), or [Duration.zero] if not yet
  /// synced. Exposed mainly for diagnostics/telemetry.
  Duration get offset => _offset ?? Duration.zero;

  /// The UTC time the client should derive tokens against:
  /// device clock plus the server offset. Before the first sync, this is just
  /// the device clock.
  DateTime correctedNowUtc() {
    final device = _deviceNowUtc();
    return _offset == null ? device : device.add(_offset!);
  }

  /// Updates the in-memory offset from a server-provided UTC timestamp.
  ///
  /// Call on every server response. [serverUtc] is the server's clock at the
  /// time it generated the response. The offset is recomputed against the
  /// device clock now; small request/response latency is absorbed by the
  /// server's skew tolerance and is not corrected for here.
  ///
  /// Throws [ArgumentError] if [serverUtc] is not UTC.
  void updateOffsetFromServer({required DateTime serverUtc}) {
    if (!serverUtc.isUtc) {
      throw ArgumentError.value(serverUtc, 'serverUtc', 'Server timestamp must be UTC.');
    }
    _offset = serverUtc.difference(_deviceNowUtc());
  }

  /// Clears the offset (e.g. on a new session). Next derivation falls back to
  /// device time until the next [updateOffsetFromServer].
  void resetSync() => _offset = null;

  /// Produces the token material for a single request.
  ///
  /// Returns a [TotpPlusMaterial] carrying the token, the nonce used (sent so
  /// the server can recompute), and the corrected-UTC claimed timestamp (sent
  /// so the server can pick the window and early-reject out-of-range requests).
  /// The network layer is responsible for attaching these to the outgoing
  /// request.
  ///
  /// [context] is an optional opaque binding string (e.g. a session id). When
  /// omitted it defaults to the empty string, meaning the token is not bound to
  /// any context (replay protection still applies via the nonce). If supplied,
  /// it must match the value the server uses to verify.
  ///
  /// [bodyHash] is the SHA-256 of the request body (see `hashBody`). When
  /// supplied the token is bound to that exact body, so a tampered body fails
  /// verification. It is not transmitted — the server recomputes it from the
  /// body it receives. Omit it (the default) for requests with no body.
  TotpPlusMaterial tokenForRequest({String context = '', String? bodyHash}) {
    final now = correctedNowUtc();
    final window = windowFor(now, config);
    final nonce = _nonceGenerator();
    final token = deriveToken(
      key: _key,
      window: window,
      context: context,
      nonce: nonce,
      bodyHash: bodyHash,
    );
    return TotpPlusMaterial(
      keyHash: _keyHash,
      token: token,
      nonce: nonce,
      claimedTimestamp: now,
      context: context,
    );
  }

  static String _defaultNonce() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}

/// The material produced for a single request. [keyHash], [token], [nonce] and
/// [claimedTimestamp] are all transmitted as `X-TP-*` headers; [context] is
/// included for the caller's convenience (it is typically already known to the
/// network layer). Note [keyHash] is constant per client — the project
/// identifier — while the rest vary per request.
class TotpPlusMaterial {
  final String keyHash;
  final String token;
  final String nonce;
  final DateTime claimedTimestamp;
  final String context;

  const TotpPlusMaterial({
    required this.keyHash,
    required this.token,
    required this.nonce,
    required this.claimedTimestamp,
    required this.context,
  });
}
