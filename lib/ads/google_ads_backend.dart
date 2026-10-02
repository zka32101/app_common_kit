// ignore_for_file: deprecated_member_use  // 4.x〜9.x 共通で動かすため旧API（児童向けタグ・適応バナー）を使用
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_rules.dart';
import 'ads_backend.dart';

/// google_mobile_ads 実装。同意は UMP（iOS の ATT 文言は同意フォーム側で扱う）。
class GoogleAdsBackend implements AdsBackend {
  late AdConfig _config;
  InterstitialAd? _interstitial;

  @override
  Future<bool> initialize(AdConfig config) async {
    _config = config;
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        tagForChildDirectedTreatment: config.childDirected
            ? TagForChildDirectedTreatment.yes
            : TagForChildDirectedTreatment.unspecified,
        tagForUnderAgeOfConsent: config.childDirected
            ? TagForUnderAgeOfConsent.yes
            : TagForUnderAgeOfConsent.unspecified,
      ),
    );

    final consentDone = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(tagForUnderAgeOfConsent: config.childDirected),
      () async {
        ConsentForm.loadAndShowConsentFormIfRequired((_) {
          if (!consentDone.isCompleted) consentDone.complete();
        });
      },
      (_) {
        if (!consentDone.isCompleted) consentDone.complete();
      },
    );
    await consentDone.future;

    if (!await ConsentInformation.instance.canRequestAds()) return false;
    await MobileAds.instance.initialize();
    return true;
  }

  @override
  Future<void> preloadInterstitial() async {
    if (_interstitial != null) return;
    final done = Completer<void>();
    await InterstitialAd.load(
      adUnitId: _config.unitIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          done.complete();
        },
        onAdFailedToLoad: (_) => done.complete(),
      ),
    );
    await done.future;
  }

  @override
  bool get isInterstitialReady => _interstitial != null;

  @override
  Future<bool> showInterstitial() async {
    final ad = _interstitial;
    if (ad == null) return false;
    _interstitial = null;
    final done = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        done.complete(true);
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        done.complete(false);
      },
    );
    await ad.show();
    return done.future;
  }

  @override
  Future<bool> showRewarded() async {
    final loaded = Completer<RewardedAd?>();
    await RewardedAd.load(
      adUnitId: _config.unitIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: loaded.complete,
        onAdFailedToLoad: (_) => loaded.complete(null),
      ),
    );
    final ad = await loaded.future;
    if (ad == null) return false;
    final result = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        result.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        result.complete(false);
      },
    );
    await ad.show(onUserEarnedReward: (_, __) => earned = true);
    return result.future;
  }

  @override
  Widget buildBanner(BannerPlacement placement) =>
      _AdaptiveBanner(adUnitId: _config.unitIds.banner);
}

class _AdaptiveBanner extends StatefulWidget {
  const _AdaptiveBanner({required this.adUnitId});

  final String adUnitId;

  @override
  State<_AdaptiveBanner> createState() => _AdaptiveBannerState();
}

class _AdaptiveBannerState extends State<_AdaptiveBanner> {
  BannerAd? _ad;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load(MediaQuery.sizeOf(context).width.truncate());
  }

  Future<void> _load(int width) async {
    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;
    final ad = BannerAd(
      adUnitId: widget.adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (a) {
          if (mounted) {
            setState(() => _ad = a as BannerAd);
          } else {
            a.dispose();
          }
        },
        onAdFailedToLoad: (a, _) => a.dispose(),
      ),
    );
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
