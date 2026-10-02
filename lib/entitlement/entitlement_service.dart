import 'entitlement_state.dart';

/// 購入前に呼ばれるフック。false を返すと購入を中止する。
/// 子ども向けアプリは保護者ゲートをここに差し込む。
typedef BeforePurchase = Future<bool> Function(String productId);

/// 権利管理の抽象。アプリ側はこれにだけ依存する。
abstract class EntitlementService {
  /// 現在の状態。
  EntitlementState get state;

  /// 状態の変化。購読直後に現在値は流れない（[state] で取得）。
  Stream<EntitlementState> get stateStream;

  /// 購入。[BeforePurchase] が false なら [PurchaseOutcome.blockedByGate]。
  Future<PurchaseOutcome> purchase(String productId);

  /// 購入の復元。
  Future<EntitlementState> restore();

  /// 匿名→Google/Apple 連携時に appUserId を引き継ぐ。
  Future<EntitlementState> logIn(String appUserId);

  Future<EntitlementState> logOut();

  void dispose();
}
