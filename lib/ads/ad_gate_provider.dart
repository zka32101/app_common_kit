import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_gate.dart';

/// アプリ起動時に ProviderScope.overrides で実体を差し込む
/// （`AdGate.init()` は非同期のため、`main()` で await してから渡す）。
final adGateProvider = Provider<AdGate>(
  (ref) => throw UnimplementedError(
    'adGateProvider を ProviderScope.overrides で上書きしてください',
  ),
);
