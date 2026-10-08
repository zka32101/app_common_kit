import 'package:flutter/material.dart';

/// 起動時画面の下部に出す、組織（Your Wish）のロゴ。全アプリ共通。
///
/// 起動中の読み込み画面（[Scaffold] の body など）の一番下に置く。
/// 画像はキットに同梱（`assets/branding/yourwish_logo.png`）。
class OrgBrandingFooter extends StatelessWidget {
  const OrgBrandingFooter({super.key, this.logoHeight = 72});

  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Semantics(
          label: 'Your Wish',
          child: Image.asset(
            'assets/branding/yourwish_logo.png',
            package: 'app_common_kit',
            height: logoHeight,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/// 起動中の読み込み画面（中央に進行表示、下部に組織ロゴ）。
///
/// [appIconAsset] を渡すと、中央にアプリのアイコン（角丸）と小さい進行表示を出す。
/// 端末側の起動画面を「アイコンなし・背景色だけ」にして [backgroundColor] を同じ色にすると、
/// アイコンと組織ロゴが一枚の画面として見える。どちらも省略すれば従来どおりの見た目。
class StartupSplash extends StatelessWidget {
  const StartupSplash({
    super.key,
    this.center,
    this.appIconAsset,
    this.backgroundColor,
    this.appIconSize = 112,
  });

  /// 中央に出すもの。省略時は進行表示（[appIconAsset] があればアイコン+進行表示）。
  final Widget? center;

  /// 呼び出し側アプリのアイコン画像のアセットパス（例: `assets/branding/app_icon.png`）。
  /// null なら従来表示。
  final String? appIconAsset;

  /// 背景色。null ならテーマの Scaffold 背景。
  final Color? backgroundColor;

  /// [appIconAsset] の一辺の大きさ。
  final double appIconSize;

  @override
  Widget build(BuildContext context) {
    final icon = appIconAsset;
    final Widget middle = center ??
        (icon == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(appIconSize * 0.21),
                    child: Image.asset(icon, width: appIconSize, height: appIconSize),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ],
              ));
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          Expanded(child: Center(child: middle)),
          const OrgBrandingFooter(),
        ],
      ),
    );
  }
}
