import 'dart:async';

import 'package:flutter/widgets.dart';

/// 選択肢の「出た直後の誤タップ」を防ぐ設定。
///
/// 「次へ」を連打すると、2回目のタップが次の問題の選択肢に当たって勝手に答えてしまう。
/// これを防ぐため、問題が切り替わった（label/text が変わった）直後は [duration] だけ
/// 選択肢のタップを無視する。[ChoiceTile]・[HandsFreeChoiceTile] が使う。
class KitTapGuard {
  KitTapGuard._();

  /// 無視する時間。[Duration.zero] でガードを無効にする（アプリのテストの setUp 用）。
  static Duration duration = const Duration(milliseconds: 450);

  /// true なら、初回表示（マウント直後）もガードする。既定は false
  /// （画面を開いてすぐのタップは誤操作ではないため）。
  static bool guardOnFirstShow = false;
}

/// 選択肢ウィジェットの State に混ぜて使う。問題の切替（[identity] の変化）で一定時間ガードする。
mixin TapGuardStateMixin<T extends StatefulWidget> on State<T> {
  Timer? _guardTimer;
  bool _guarding = false;

  /// 問題の同一性を表す値（label と text など）。変わると再ガードする。
  Object get tapGuardIdentity;

  /// ガード中なら true。
  bool get isTapGuarded => _guarding;

  @override
  void initState() {
    super.initState();
    if (KitTapGuard.guardOnFirstShow) _startGuard();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    // identity は新旧比較のため、build 前に保存した値と比べる。
    if (_lastIdentity != tapGuardIdentity) _startGuard();
    _lastIdentity = tapGuardIdentity;
  }

  Object? _lastIdentity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lastIdentity ??= tapGuardIdentity;
  }

  void _startGuard() {
    final d = KitTapGuard.duration;
    _guardTimer?.cancel();
    if (d <= Duration.zero) {
      _guarding = false;
      return;
    }
    _guarding = true;
    _guardTimer = Timer(d, () {
      _guarding = false;
      _guardTimer = null;
    });
  }

  /// [onTap] をガード付きにして返す。null はそのまま null（無効表示を保つ）。
  VoidCallback? guardedTap(VoidCallback? onTap) {
    if (onTap == null) return null;
    return () {
      if (_guarding) return;
      onTap();
    };
  }

  @override
  void dispose() {
    _guardTimer?.cancel();
    super.dispose();
  }
}
