import 'package:flutter_test/flutter_test.dart';
import 'package:we_monitor/shared/utils/deep_link.dart';

void main() {
  DeepLink p(String s) => parseDeepLink(Uri.parse(s));

  test('cleanup and hotspot links', () {
    expect(
      (p('https://app.ascoa-cm.org/cleanup/abc_123-X') as CleanupLink).id,
      'abc_123-X',
    );
    expect((p('https://app.ascoa-cm.org/hotspot/h1/') as HotspotLink).id, 'h1');
    expect(p(cleanupShareUrl('a1')), isA<CleanupLink>());
    expect(p(hotspotShareUrl('a1')), isA<HotspotLink>());
  });

  test('reset password link', () {
    final l = p(
      'https://app.ascoa-cm.org/action?mode=resetPassword&oobCode=xyz',
    );
    expect((l as ResetPasswordLink).oobCode, 'xyz');
    expect(
      p('https://app.ascoa-cm.org/action?mode=resetPassword'),
      isA<UnknownLink>(),
    );
  });

  test('rejects wrong host, bad ids, extra paths', () {
    expect(p('https://evil.com/cleanup/abc'), isA<UnknownLink>());
    expect(p('https://app.ascoa-cm.org/cleanup/'), isA<UnknownLink>());
    expect(p('https://app.ascoa-cm.org/cleanup/a%20b'), isA<UnknownLink>());
    expect(p('https://app.ascoa-cm.org/cleanup/a.b'), isA<UnknownLink>());
    expect(
      p('https://app.ascoa-cm.org/cleanup/${'a' * 129}'),
      isA<UnknownLink>(),
    );
    expect(
      p('https://app.ascoa-cm.org/cleanup/${'a' * 128}'),
      isA<CleanupLink>(),
    );
    expect(p('https://app.ascoa-cm.org/cleanup/a/b'), isA<UnknownLink>());
    expect(p('https://app.ascoa-cm.org/get'), isA<UnknownLink>());
  });
}
