/// インタースティシャルを出してよい契機。出題中・解説表示中の契機は存在しない。
enum InterstitialTrigger { sessionEnd, mockExamResult }

/// バナーを出してよい場所。出題中・解説表示中の場所は存在しない。
enum BannerPlacement { home, result, weakDrill }

/// 配信する広告の最大コンテンツレーティング。
enum AdContentRating { g, pg, t, ma }

/// 表示ルール。既定値は暫定で、Remote Config（v0.2）で上書きする想定。
class AdRules {
  const AdRules({
    this.interstitialMinInterval = const Duration(minutes: 3),
    this.interstitialDailyCap = 5,
  });

  final Duration interstitialMinInterval;
  final int interstitialDailyCap;

  AdRules copyWith({Duration? interstitialMinInterval, int? interstitialDailyCap}) =>
      AdRules(
        interstitialMinInterval:
            interstitialMinInterval ?? this.interstitialMinInterval,
        interstitialDailyCap: interstitialDailyCap ?? this.interstitialDailyCap,
      );
}

/// 広告ユニットID。本番IDは引数で渡す（コミットしない）。
class AdUnitIds {
  const AdUnitIds({
    required this.banner,
    required this.interstitial,
    required this.rewarded,
  });

  /// Google 公式のテスト広告ユニットのパブリッシャーID。
  static const testPublisherPrefix = 'ca-app-pub-3940256099942544/';

  final String banner;
  final String interstitial;
  final String rewarded;

  bool get usesTestIds => [banner, interstitial, rewarded]
      .any((id) => id.startsWith(testPublisherPrefix));

  /// リリースビルドでテストIDが使われていたら例外にする（取り違え防止）。
  void assertNoTestIdsInRelease({required bool isRelease}) {
    if (isRelease && usesTestIds) {
      throw StateError('リリースビルドでテスト広告ユニットIDが使われています。');
    }
  }
}

/// 広告全体の設定。
class AdConfig {
  const AdConfig({
    required this.unitIds,
    this.rules = const AdRules(),
    this.childDirected = false,
    this.maxAdContentRating,
    this.nonPersonalizedAds = false,
  });

  final AdUnitIds unitIds;
  final AdRules rules;

  /// 子ども向けアプリ。児童向けタグと under-age-of-consent を設定する。
  final bool childDirected;

  /// 配信する広告の最大レーティング。null なら制限しない（児童向けは g を推奨）。
  final AdContentRating? maxAdContentRating;

  /// 非パーソナライズ広告のみをリクエストする。
  final bool nonPersonalizedAds;
}
