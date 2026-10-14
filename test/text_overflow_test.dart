// 狭い幅（320 / 280dp）× 大きい文字倍率（1 / 2 / 3）で、共有ウィジェットが
// RenderFlex overflow などを起こさないことを確かめる（文字切れ・はみ出しの回帰防止）。
import 'package:app_common_kit/app_common_kit.dart';
import 'package:app_common_kit/hands_free_tts.dart';
import 'package:app_common_kit/parental_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _long = 'とても長い文言のサンプルです。文字が大きくなっても、はみ出したり切れたりしないことを確認します。';

/// 画面サイズ（幅, 高さ）。実機の小さい端末と、さらに狭い分割表示を想定する。
const _sizes = [Size(320, 568), Size(280, 480)];
const _scales = [1.0, 2.0, 3.0];

/// [build] で作ったウィジェットを全条件で表示し、描画中に出たエラーを返す。
Future<List<String>> _errorsFor(
  WidgetTester tester,
  Widget Function() build, {
  Future<void> Function(WidgetTester)? act,
  List<Override> overrides = const [],
}) async {
  final errors = <String>[];
  final prev = FlutterError.onError;
  FlutterError.onError = (d) {
    final lines = d.toString().split('\n');
    final i = lines.indexWhere((l) => l.contains('error-causing widget'));
    final where = i >= 0 && i + 1 < lines.length ? lines[i + 1].trim() : '';
    errors.add('${d.exceptionAsString().split('\n').first} $where');
  };
  try {
    for (final size in _sizes) {
      for (final scale in _scales) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        final before = errors.length;
        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: MaterialApp(
              builder: (c, child) => MediaQuery(
                data: MediaQuery.of(
                  c,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: SafeArea(child: SingleChildScrollView(child: build())),
              ),
            ),
          ),
        );
        await tester.pump();
        if (act != null) await act(tester);
        for (var i = before; i < errors.length; i++) {
          errors[i] = '${size.width.toInt()}dp x$scale: ${errors[i]}';
        }
        // 次の条件の前に画面を空にして、ダイアログ等を片付ける。
        await tester.pumpWidget(const SizedBox());
      }
    }
  } finally {
    FlutterError.onError = prev;
    addTearDown(tester.view.reset);
  }
  return errors;
}

/// ボタンを押してダイアログを開く版。
Future<List<String>> _dialogErrors(
  WidgetTester tester,
  Future<void> Function(BuildContext) open,
) => _errorsFor(
  tester,
  () => Builder(
    builder: (c) => TextButton(
      key: const Key('open'),
      onPressed: () => open(c),
      child: const Text('open'),
    ),
  ),
  act: (t) async {
    await t.tap(find.byKey(const Key('open')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
  },
);

void main() {
  _emptyErrorStateTests();
  testWidgets('MinutesBadge: ListTile の trailing で溢れない', (t) async {
    final e = await _errorsFor(
      t,
      () => const ListTile(
        title: Text(_long),
        trailing: MinutesBadge(minutes: 15),
      ),
    );
    if (e.isNotEmpty) fail(e.join('\n'));
  });

  testWidgets('ChoiceTile / HandsFreeChoiceTile: 長い選択肢と判定ラベル', (t) async {
    final e = await _errorsFor(
      t,
      () => Column(
        children: [
          for (final s in ChoiceState.values)
            ChoiceTile(
              label: 'ア',
              text: _long,
              state: s,
              correctText: _long,
              incorrectText: _long,
            ),
          for (final s in ChoiceState.values)
            HandsFreeChoiceTile(
              label: 'ア',
              text: _long,
              state: s,
              correctText: _long,
              incorrectText: _long,
            ),
        ],
      ),
    );
    if (e.isNotEmpty) fail(e.join('\n'));
  });

  testWidgets('StreakBadge / ProgressRing / ResultSummary', (t) async {
    final e = await _errorsFor(
      t,
      () => Column(
        children: [
          const StreakBadge(days: 123),
          const StreakBadge(days: 0, zeroText: _long),
          const ProgressRing(value: 0.5, label: _long),
          ResultSummary(
            correct: 7,
            total: 10,
            passRatio: 0.6,
            passedText: _long,
            notPassedText: _long,
            onRetry: () {},
            retryLabel: _long,
            onClose: () {},
            closeLabel: _long,
          ),
        ],
      ),
    );
    if (e.isNotEmpty) fail(e.join('\n'));
  });

  testWidgets(
    'EmptyState / ErrorState / QuestionCard / ExplanationPanel / KitSectionHeader',
    (t) async {
      final e = await _errorsFor(
        t,
        () => Column(
          children: [
            EmptyState(message: _long, actionLabel: _long, onAction: () {}),
            ErrorState(message: _long, retryLabel: _long, onRetry: () {}),
            const QuestionCard(text: _long, index: 12, total: 100),
            const ExplanationPanel(
              title: _long,
              body: _long,
              sourceRef: _long,
              checkedAt: '2026-10-14',
            ),
            const KitSectionHeader(title: _long),
            ExamDateTile(date: DateTime(2026, 12, 31), onChanged: (_) {}),
          ],
        ),
      );
      if (e.isNotEmpty) fail(e.join('\n'));
    },
  );

  testWidgets('TextScaleSetting: 3 つの選択肢が収まる', (t) async {
    final e = await _errorsFor(t, () => const TextScaleSetting());
    if (e.isNotEmpty) fail(e.join('\n'));
  });

  testWidgets('SettingsScreen: 表示モード・文字サイズ・言語・各セクション', (t) async {
    final e = await _settingsErrors(t);
    if (e.isNotEmpty) fail(e.join('\n'));
  });

  testWidgets('ParentalGateDialog / 同意 / データ削除 / 通知のダイアログ', (t) async {
    final cases = <String, Future<void> Function(BuildContext)>{
      'parentalGate': (c) => requireParentalGate(c),
      'consentPrompt': (c) =>
          showConsentPrompt(c, ConsentController(), strings: ConsentStrings.ja),
      'consentSettings': (c) => showConsentSettings(
        c,
        ConsentController(),
        strings: ConsentStrings.ja,
      ),
      'dataDeletion': (c) => showDataDeletionFlow(
        c,
        DataDeletion(const []),
        strings: DataDeletionStrings.ja,
      ),
    };
    final all = <String>[];
    for (final entry in cases.entries) {
      final e = await _dialogErrors(t, entry.value);
      all.addAll(e.map((m) => '${entry.key}: $m'));
    }
    if (all.isNotEmpty) fail(all.join('\n'));
  });

  testWidgets('更新内容・レビュー依頼・購入・法務リンクなど', (t) async {
    final all = <String>[];
    final store = InMemoryWhatsNewStore();
    await store.saveSeenVersion('1.0.0');
    final wn = WhatsNew(
      store: store,
      currentVersion: '2.0.0',
      entries: [
        WhatsNewEntry(version: '2.0.0', items: const [_long, _long]),
      ],
    );
    all.addAll(
      (await _dialogErrors(
        t,
        (c) => showWhatsNewIfNeeded(c, wn),
      )).map((m) => 'whatsNew: $m'),
    );

    final svc = ReviewPromptService(
      store: InMemoryReviewStore(),
      backend: FakeReviewBackend(),
      rules: const ReviewPromptRules(
        minDaysSinceFirstLaunch: 0,
        minPositiveMoments: 0,
        minDaysBetweenAsks: 0,
      ),
    );
    await svc.load();
    all.addAll(
      (await _dialogErrors(
        t,
        (c) => showReviewPrePrompt(c, svc),
      )).map((m) => 'reviewPrePrompt: $m'),
    );

    all.addAll(
      (await _errorsFor(
        t,
        () => LegalSection(
          links: const LegalLinks(
            privacyPolicyUrl: 'https://example.com/p',
            termsUrl: 'https://example.com/t',
            commercialDisclosureUrl: 'https://example.com/c',
            contactUrl: 'https://example.com/m',
          ),
          strings: LegalStrings.forCode('ja'),
          onOpen: (_) {},
        ),
      )).map((m) => 'legal: $m'),
    );

    all.addAll(
      (await _errorsFor(
        t,
        () => const PurchaseSection(),
        overrides: [
          entitlementServiceProvider.overrideWithValue(
            FakeEntitlementService(
              availableOffers: const [
                EntitlementOffer(
                  id: 'a',
                  productId: 'p',
                  title: _long,
                  priceString: '¥1,480 / 年',
                ),
              ],
            ),
          ),
        ],
      )).map((m) => 'purchase: $m'),
    );
    if (all.isNotEmpty) fail(all.join('\n'));
  });

  testWidgets('ながら学習の画面（NagaraSessionView）と選択肢本文', (t) async {
    final fake = FakeSpeechBackend();
    final all = (await _errorsFor(
      t,
      () => SizedBox(
        height: 460,
        child: NagaraSessionView(
          questions: [
            const NagaraQuestion(
              id: 'q1',
              prompt: _long,
              choices: [_long, _long, _long],
              correctIndex: 0,
              explanation: _long,
            ),
          ],
        ),
      ),
      overrides: [
        speechBackendProvider.overrideWithValue(fake),
        handsFreeStoreProvider.overrideWithValue(InMemoryHandsFreeStore()),
      ],
    )).toList();
    if (all.isNotEmpty) fail(all.join('\n'));
  });

  testWidgets('FeedbackFormPage / HandsFreeChoiceBody / OrgBrandingFooter', (
    t,
  ) async {
    final all = <String>[];
    final overrides = [
      handsFreeStoreProvider.overrideWithValue(InMemoryHandsFreeStore()),
      speechBackendProvider.overrideWithValue(FakeSpeechBackend()),
    ];
    all.addAll(
      (await _errorsFor(
        t,
        () => SizedBox(
          height: 1400,
          child: FeedbackFormPage(appName: _long, appVersion: '1.0.0'),
        ),
        overrides: overrides,
      )).map((m) => 'feedback: $m'),
    );
    all.addAll(
      (await _errorsFor(
        t,
        () => SizedBox(
          height: 700,
          child: HandsFreeChoiceBody(
            qid: 'q1',
            prompt: _long,
            choices: const [_long, _long, _long],
            index: 11,
            total: 100,
            onSelect: (_) {},
          ),
        ),
        overrides: overrides,
      )).map((m) => 'handsFreeBody: $m'),
    );
    all.addAll(
      (await _errorsFor(
        t,
        () => const OrgBrandingFooter(),
      )).map((m) => 'branding: $m'),
    );
    if (all.isNotEmpty) fail(all.join('\n'));
  });
}

Future<List<String>> _settingsErrors(WidgetTester t) => _errorsFor(
  t,
  () => SizedBox(
    height: 3000,
    child: SettingsScreen(
      appName: _long,
      appVersion: '1.2.3',
      showTextScale: true,
      languages: const [SettingsLanguage('ja', _long)],
      languageCode: 'ja',
      disclaimer: _long,
    ),
  ),
  overrides: [
    handsFreeStoreProvider.overrideWithValue(InMemoryHandsFreeStore()),
    entitlementServiceProvider.overrideWithValue(
      FakeEntitlementService(
        availableOffers: const [
          EntitlementOffer(
            id: 'noads',
            productId: 'p',
            title: _long,
            priceString: '¥480',
          ),
        ],
      ),
    ),
  ],
);

void _emptyErrorStateTests() {
  for (final size in _sizes) {
    for (final scale in _scales) {
      for (final err in [false, true]) {
        testWidgets('${err ? 'ErrorState' : 'EmptyState'} 縦固定の領域でもはみ出さない ${size.width.toInt()}dp x$scale', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(MaterialApp(
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: SafeArea(
                child: err
                    ? ErrorState(message: _long * 3, onRetry: () {}, retryLabel: _long)
                    : EmptyState(message: _long * 3, actionLabel: _long, onAction: () {}),
              ),
            ),
          ));
          await tester.pump();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
