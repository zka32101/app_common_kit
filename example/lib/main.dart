import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 実データの保存先はアプリごとに違うので、example はメモリ上のものを渡す。
  final coin = CoinService(
    store: InMemoryCoinStore(),
    shop: OutfitCatalog.shopItems([UkalabCert.bikeLicense]),
  );
  await coin.load();
  await coin.grant(CoinEvent.passReport(UkalabCert.bikeLicense.id)); // 衣装を買える残高
  final outfit = OutfitService(store: InMemoryOutfitStore());
  await outfit.load();
  // 購入欄の確認用。実際の課金は使わず、購入するとすぐ反映されるモック。
  final entitlement = FakeEntitlementService(
    availableOffers: const [
      EntitlementOffer(id: 'noads', productId: 'ex_noads', title: '広告非表示', priceString: '¥480'),
    ],
    grantOnPurchase: const {'ex_noads': EntitlementState(hasNoAds: true)},
  );
  runApp(ProviderScope(
    overrides: [
      entitlementServiceProvider.overrideWithValue(entitlement),
      coinServiceProvider.overrideWithValue(coin),
      outfitServiceProvider.overrideWithValue(outfit),
    ],
    child: const ExampleApp(),
  ));
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  bool _en = false;

  @override
  void initState() {
    super.initState();
    // フィードバックの送信先（本番は Firestore 等）。example は何もしない。
    ProviderScope.containerOf(context, listen: false)
        .read(feedbackProvider.notifier)
        .setSubmitHandler((report) async {});
  }

  @override
  Widget build(BuildContext context) {
    final strings = _en ? KitStrings.en : KitStrings.ja;
    return MaterialApp(
      title: 'app_common_kit example',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      // Navigator より上に置くと、積まれた画面やダイアログにも文言が届く。
      builder: (context, child) =>
          KitStringsScope(strings: strings, child: child!),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('app_common_kit example'),
          // 一覧をスクロールしても常に押せるよう、アプリバーに置く。
          actions: [
            const Center(child: Text('English')),
            Switch(
              key: const Key('lang-switch'),
              value: _en,
              onChanged: (v) => setState(() => _en = v),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const StreakBadge(days: 3),
            const SizedBox(height: 8),
            const StreakBadge(days: 0),
            const SizedBox(height: 16),
            CoinBreakdownCard(
              grants: [
                CoinGrant(CoinEvent.newQuestion('q1'), 5),
                CoinGrant(CoinEvent.newQuestion('q2'), 5),
                CoinGrant(CoinEvent.mockPass('m1'), 50),
              ],
            ),
            const SizedBox(height: 16),
            ResultSummary(
              correct: 8,
              total: 10,
              passRatio: 0.7,
              onRetry: () {},
              onClose: () {},
            ),
            SizedBox(height: 200, child: ErrorState(onRetry: () {})),
            const SizedBox(height: 16),
            UkalabOshiCard(
              cert: UkalabCert.bikeLicense,
              stage: MascotStage.lv1,
              appId: 'example',
            ),
            const SizedBox(height: 16),
            // 積んだ画面（Navigator の上の Scope から文言が届くかの確認）。
            const _NavButtons(),
          ],
        ),
      ),
    );
  }
}

class _NavButtons extends StatelessWidget {
  const _NavButtons();

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) => Column(
        children: [
          FilledButton(
            onPressed: () => _push(context, const FeedbackFormPage(appName: 'example')),
            child: const Text('Open feedback'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => _push(context, const WardrobeScreen(cert: UkalabCert.bikeLicense)),
            child: const Text('Open wardrobe'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => _push(context, const _HandsFreeDemo()),
            child: const Text('Open hands-free'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => _push(context, const _SettingsDemo()),
            child: const Text('Open settings'),
          ),
        ],
      );
}

class _HandsFreeDemo extends StatefulWidget {
  const _HandsFreeDemo();

  @override
  State<_HandsFreeDemo> createState() => _HandsFreeDemoState();
}

class _HandsFreeDemoState extends State<_HandsFreeDemo> {
  int? _picked;
  static const _answer = 0;

  ChoiceState _state(int i) {
    if (_picked == null) return ChoiceState.idle;
    if (i == _answer) return ChoiceState.correct;
    return i == _picked ? ChoiceState.incorrect : ChoiceState.idle;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('hands-free')),
        body: HandsFreeQuestionLayout(
          question: const Text('1 + 1 = ?', style: TextStyle(fontSize: 22)),
          trailing: ReadAloudButton(onPressed: () {}),
          choices: [
            for (final (i, t) in ['2', '3'].indexed)
              HandsFreeChoiceTile(
                label: 'AB'[i],
                text: t,
                state: _state(i),
                onTap: _picked == null ? () => setState(() => _picked = i) : null,
              ),
          ],
        ),
      );
}

/// 設定タブ相当。購入欄（PurchaseSection）と受験日の入力欄（ExamDateTile）の確認用。
class _SettingsDemo extends StatefulWidget {
  const _SettingsDemo();

  @override
  State<_SettingsDemo> createState() => _SettingsDemoState();
}

class _SettingsDemoState extends State<_SettingsDemo> {
  DateTime? _examDate;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('settings')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const PurchaseSection(),
            const Divider(height: 32),
            ExamDateTile(
              date: _examDate,
              onChanged: (d) => setState(() => _examDate = d),
            ),
          ],
        ),
      );
}
