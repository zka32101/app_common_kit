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
class StartupSplash extends StatelessWidget {
  const StartupSplash({super.key, this.center});

  /// 中央に出すもの。省略時は進行表示。
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: Center(child: center ?? const CircularProgressIndicator())),
          const OrgBrandingFooter(),
        ],
      ),
    );
  }
}
