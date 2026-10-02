import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'entitlement_service.dart';
import 'entitlement_state.dart';

/// アプリ起動時に ProviderScope.overrides で実体を差し込む。
final entitlementServiceProvider = Provider<EntitlementService>(
  (ref) => throw UnimplementedError(
    'entitlementServiceProvider を ProviderScope.overrides で上書きしてください',
  ),
);

/// 権利の状態。UI はこれを watch する。
final entitlementStateProvider = StreamProvider<EntitlementState>((ref) async* {
  final service = ref.watch(entitlementServiceProvider);
  yield service.state;
  yield* service.stateStream;
});

/// 広告を出さない状態か（noads または premium）。
final adsHiddenProvider = Provider<bool>((ref) {
  final service = ref.watch(entitlementServiceProvider);
  return ref.watch(entitlementStateProvider).valueOrNull?.adsHidden ??
      service.state.adsHidden;
});
