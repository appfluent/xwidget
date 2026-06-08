import 'package:flutter_test/flutter_test.dart';
import 'package:xwidget/src/utils/totp_plus/totp_plus_core.dart';

void main() {
  const config = TotpPlusConfig();

  group('windowFor', () {
    test('computes floor(epochSeconds / windowSeconds) for a known instant', () {
      // 2021-01-01T00:00:00Z = 1609459200s; / 60 = 26824320.
      expect(windowFor(DateTime.utc(2021), config), 26824320);
    });

    test('is stable within a window and increments at the boundary', () {
      final start = DateTime.utc(2021);
      expect(windowFor(start, config), 26824320);
      expect(windowFor(start.add(const Duration(seconds: 59)), config), 26824320);
      expect(windowFor(start.add(const Duration(seconds: 60)), config), 26824321);
    });

    test('rejects non-UTC input', () {
      expect(() => windowFor(DateTime(2021), config), throwsArgumentError);
    });
  });

  group('deriveToken', () {
    // Independent known-answer vectors: computed offline (HMAC-SHA256 over the
    // length-prefixed message, base64url, padding stripped), NOT from this code.
    // These lock the shared core's behavior — if the derivation ever drifts on
    // either the client or the (copy-pasted) server side, this fails. Mirror
    // these same vectors in the server's test suite to keep both in lockstep.
    test('matches the known-answer vector (empty context)', () {
      expect(
        deriveToken(key: 'test-key', window: 26824320, context: '', nonce: 'fixed-nonce'),
        '766AkVcOlmsdYJL2Sz9anl0JAKZcmhzdg0lAZ0GHmtw',
      );
    });

    test('binds the context (matches its own vector)', () {
      expect(
        deriveToken(key: 'test-key', window: 26824320, context: 'sess', nonce: 'fixed-nonce'),
        'WpJ_0jcPTJYtHssg0KdG-1rt6gNJYE_Mg9udy2XJqvk',
      );
    });

    test('is deterministic for identical inputs', () {
      expect(
        deriveToken(key: 'k', window: 1, context: 'c', nonce: 'n'),
        deriveToken(key: 'k', window: 1, context: 'c', nonce: 'n'),
      );
    });

    test('changes when any single input changes', () {
      final base = deriveToken(key: 'k', window: 1, context: 'c', nonce: 'n');
      expect(deriveToken(key: 'k2', window: 1, context: 'c', nonce: 'n'), isNot(base));
      expect(deriveToken(key: 'k', window: 2, context: 'c', nonce: 'n'), isNot(base));
      expect(deriveToken(key: 'k', window: 1, context: 'c2', nonce: 'n'), isNot(base));
      expect(deriveToken(key: 'k', window: 1, context: 'c', nonce: 'n2'), isNot(base));
    });

    test('output is base64url without padding', () {
      final token = deriveToken(key: 'k', window: 1, context: 'c', nonce: 'n');
      expect(token.contains('='), isFalse);
      expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(token), isTrue);
    });
  });

  group('buildMessage', () {
    test('is injective via length-prefixing', () {
      // ("12","345") and ("123","45") collide under plain concatenation but must
      // not here, because each part is length-prefixed.
      expect(buildMessage(1, '12', '345'), isNot(equals(buildMessage(1, '123', '45'))));
    });

    test('is stable for identical parts', () {
      expect(buildMessage(1, 'a', 'b'), equals(buildMessage(1, 'a', 'b')));
    });
  });

  group('constantTimeEquals', () {
    test('true for equal strings', () => expect(constantTimeEquals('abc', 'abc'), isTrue));
    test(
      'false for a same-length difference',
      () => expect(constantTimeEquals('abc', 'abd'), isFalse),
    );
    test('false for a length mismatch', () => expect(constantTimeEquals('abc', 'abcd'), isFalse));
    test('true for empty strings', () => expect(constantTimeEquals('', ''), isTrue));
  });

  group('TotpPlusConfig', () {
    test('derives acceptance span and nonce TTL from window/skew', () {
      const c = TotpPlusConfig(windowSeconds: 60, skewWindows: 1);
      expect(c.acceptanceSpanSeconds, 180); // (2*1 + 1) * 60
      expect(c.nonceTtl, const Duration(seconds: 300)); // 180s + 2m margin
    });
  });
}
