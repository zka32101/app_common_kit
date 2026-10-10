import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('https の URL だけ受け付ける', () {
    expect(LegalLinks.isValidUrl('https://example.com/p'), isTrue);
    expect(LegalLinks.isValidUrl('http://example.com'), isFalse);
    expect(LegalLinks.isValidUrl('javascript:alert(1)'), isFalse);
    expect(LegalLinks.isValidUrl('https://'), isFalse);
    expect(LegalLinks.isValidUrl(''), isFalse);
    expect(LegalLinks.isValidUrl(null), isFalse);
  });

  test('有効な項目だけを、決まった順で返す', () {
    const l = LegalLinks(
      contactUrl: 'https://example.com/c',
      termsUrl: 'http://bad',
      privacyPolicyUrl: 'https://example.com/p',
    );
    expect(l.entries.map((e) => e.kind), [LegalKind.privacyPolicy, LegalKind.contact]);
    expect(const LegalLinks().isEmpty, isTrue);
  });

  test('文言: 5言語が空でない', () {
    for (final c in ['ja', 'en', 'zh', 'zh-Hant', 'ko', 'xx']) {
      final s = LegalStrings.forCode(c);
      for (final k in LegalKind.values) {
        expect(s.of(k), isNotEmpty);
      }
    }
    expect(LegalStrings.forCode('en').privacyPolicy, 'Privacy Policy');
  });

  testWidgets('欄をタップすると URL を渡す', (tester) async {
    Uri? opened;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LegalSection(
          links: const LegalLinks(privacyPolicyUrl: 'https://example.com/p'),
          strings: LegalStrings.ja,
          onOpen: (u) => opened = u,
        ),
      ),
    ));
    await tester.tap(find.text('プライバシーポリシー'));
    expect(opened, Uri.parse('https://example.com/p'));
  });
}
