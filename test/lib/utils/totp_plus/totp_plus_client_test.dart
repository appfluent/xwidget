import 'package:flutter_test/flutter_test.dart';
import 'package:xwidget/src/utils/hash.dart';
import 'package:xwidget/src/utils/totp_plus/totp_plus_client.dart';
import 'package:xwidget/src/utils/totp_plus/totp_plus_core.dart';

void main() {
  const config = TotpPlusConfig();
  final fixedNow = DateTime.utc(2021); // 2021-01-01T00:00:00Z -> window 26824320

  TotpPlusClient newClient({DateTime Function()? clock, String Function()? nonce}) {
    return TotpPlusClient(
      key: 'abc',
      deviceNowUtc: clock ?? (() => fixedNow),
      nonceGenerator: nonce ?? (() => 'n1'),
    );
  }

  group('tokenForRequest', () {
    test('produces material wired to the shared core', () {
      final m = newClient().tokenForRequest();
      expect(m.nonce, 'n1');
      expect(m.context, '');
      expect(m.claimedTimestamp, fixedNow);
      expect(m.keyHash, hashKey('abc'));
      // The token must equal a fresh derivation against the claimed window —
      // exactly the center-window check the server verifier performs.
      expect(
        m.token,
        deriveToken(key: 'abc', window: windowFor(fixedNow, config), context: '', nonce: 'n1'),
      );
    });

    test('binds an explicit context', () {
      final m = newClient().tokenForRequest(context: 'sess');
      expect(m.context, 'sess');
      expect(
        m.token,
        deriveToken(key: 'abc', window: windowFor(fixedNow, config), context: 'sess', nonce: 'n1'),
      );
      // A bound token differs from the unbound (empty-context) default.
      expect(m.token, isNot(newClient().tokenForRequest().token));
    });

    test('keyHash is the project-key hash and is stable across requests', () {
      final c = newClient(nonce: () => 'whatever');
      expect(c.tokenForRequest().keyHash, hashKey('abc'));
      expect(c.tokenForRequest().keyHash, c.tokenForRequest().keyHash);
    });

    test('binds the body hash into the token', () {
      final material = newClient().tokenForRequest(bodyHash: 'bh');
      expect(
        material.token,
        deriveToken(
          key: 'abc',
          window: windowFor(fixedNow, config),
          context: '',
          nonce: 'n1',
          bodyHash: 'bh',
        ),
      );
      // A body-bound token differs from the unbound default.
      expect(material.token, isNot(newClient().tokenForRequest().token));
    });

    test('a different body hash yields a different token (tamper)', () {
      expect(
        newClient().tokenForRequest(bodyHash: 'bh1').token,
        isNot(newClient().tokenForRequest(bodyHash: 'bh2').token),
      );
    });
  });

  group('clock-skew offset', () {
    test('starts unsynced with zero offset, deriving against the device clock', () {
      final c = newClient();
      expect(c.isSynced, isFalse);
      expect(c.offset, Duration.zero);
      expect(c.correctedNowUtc(), fixedNow);
    });

    test('updateOffsetFromServer establishes the offset and corrects time', () {
      final c = newClient();
      final serverNow = fixedNow.add(const Duration(seconds: 100));
      c.updateOffsetFromServer(serverUtc: serverNow);
      expect(c.isSynced, isTrue);
      expect(c.offset, const Duration(seconds: 100));
      // Device clock is fixed, so corrected time lands exactly on server time.
      expect(c.correctedNowUtc(), serverNow);
    });

    test('rejects a non-UTC server timestamp', () {
      expect(
        () => newClient().updateOffsetFromServer(serverUtc: DateTime(2021)),
        throwsArgumentError,
      );
    });

    test('resetSync clears the offset', () {
      final c = newClient();
      c.updateOffsetFromServer(serverUtc: fixedNow.add(const Duration(seconds: 100)));
      c.resetSync();
      expect(c.isSynced, isFalse);
      expect(c.offset, Duration.zero);
      expect(c.correctedNowUtc(), fixedNow);
    });

    test('a synced offset shifts the derivation window', () {
      // Device clock fixed mid-window; a +60s server offset pushes corrected
      // time into the next window.
      final boundary = DateTime.utc(2021, 1, 1, 0, 0, 30);
      final c = TotpPlusClient(
        key: 'abc',
        deviceNowUtc: () => boundary,
        nonceGenerator: () => 'n1',
      );
      final before = windowFor(c.correctedNowUtc(), config);
      c.updateOffsetFromServer(serverUtc: boundary.add(const Duration(seconds: 60)));
      expect(windowFor(c.correctedNowUtc(), config), before + 1);
    });
  });

  test('default nonce generator yields unique values', () {
    final c = TotpPlusClient(key: 'abc', deviceNowUtc: () => fixedNow);
    final nonces = {for (var i = 0; i < 100; i++) c.tokenForRequest().nonce};
    expect(nonces.length, 100);
  });
}
