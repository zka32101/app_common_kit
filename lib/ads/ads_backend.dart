import 'package:flutter/widgets.dart';

import 'ad_rules.dart';

/// 広告SDKの差し替え点。本番は [GoogleAdsBackend]、テストはフェイク。
abstract class AdsBackend {
  /// 同意取得（UMP。iOS の ATT 文言は UMP の同意フォームで扱う）と SDK 初期化。
  /// 広告をリクエストしてよい状態なら true。
  Future<bool> initialize(AdConfig config);

  /// インタースティシャルを事前ロードする。
  Future<void> preloadInterstitial();

  bool get isInterstitialReady;

  /// 表示し、閉じられたら完了する。実際に表示できたら true。
  Future<bool> showInterstitial();

  /// リワードを表示する。報酬を得たら true。
  Future<bool> showRewarded();

  /// 画面下部固定の適応型バナー。
  Widget buildBanner(BannerPlacement placement);
}
