import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  bool _en = false;

  @override
  Widget build(BuildContext context) {
    final strings = _en ? KitStrings.en : KitStrings.ja;
    return MaterialApp(
      title: 'app_common_kit example',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: KitStringsScope(
        strings: strings,
        child: Scaffold(
          appBar: AppBar(title: const Text('app_common_kit example')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                const Text('English'),
                Switch(key: const Key('lang-switch'), value: _en, onChanged: (v) => setState(() => _en = v)),
              ]),
              const SizedBox(height: 16),
              const StreakBadge(days: 3),
              const SizedBox(height: 8),
              const StreakBadge(days: 0),
              const SizedBox(height: 16),
              CoinBreakdownCard(grants: [
                CoinGrant(CoinEvent.newQuestion('q1'), 5),
                CoinGrant(CoinEvent.newQuestion('q2'), 5),
                CoinGrant(CoinEvent.mockPass('m1'), 50),
              ]),
              const SizedBox(height: 16),
              ResultSummary(correct: 8, total: 10, passRatio: 0.7, onRetry: () {}, onClose: () {}),
              SizedBox(height: 200, child: ErrorState(onRetry: () {})),
            ],
          ),
        ),
      ),
    );
  }
}
