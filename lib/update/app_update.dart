import 'package:flutter/material.dart';

import '../ui_kit/kit_strings.dart';

/// 配信側（Remote Config など）が決める更新の方針。
class UpdatePolicy {
  const UpdatePolicy({this.minVersion, this.latestVersion, this.storeUrl, this.message});

  /// これ未満のバージョンは使えない（強制アップデート）。
  final String? minVersion;

  /// 最新のバージョン。いまより新しければ、任意のアップデートを案内する。
  final String? latestVersion;

  final String? storeUrl;

  /// 画面に添えるお知らせ（任意）。
  final String? message;
}

/// 更新の方針を取ってくる窓口。アプリ側が Firebase Remote Config などで実装して渡す
/// （キットは Remote Config に依存しない）。
abstract class UpdateBackend {
  Future<UpdatePolicy?> fetch();
}

/// テスト・example 用。
class FakeUpdateBackend implements UpdateBackend {
  FakeUpdateBackend(this.policy, {this.fail = false});
  UpdatePolicy? policy;
  bool fail;

  @override
  Future<UpdatePolicy?> fetch() async {
    if (fail) throw StateError('fetch failed');
    return policy;
  }
}

enum UpdateDecision { none, optional, required }

/// `1.2.10` のようなバージョンを数値で比べる（a<b なら負、同じなら0、a>b なら正）。
/// `+ビルド番号`・`-pre` は無視する。数字でない部分は 0 とみなす。
int compareVersions(String a, String b) {
  List<int> parse(String v) => v
      .split(RegExp(r'[+-]'))
      .first
      .split('.')
      .map((p) => int.tryParse(p.trim()) ?? 0)
      .toList();
  final x = parse(a), y = parse(b);
  final n = x.length > y.length ? x.length : y.length;
  for (var i = 0; i < n; i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d;
  }
  return 0;
}

UpdateDecision decideUpdate(String currentVersion, UpdatePolicy? policy) {
  if (policy == null) return UpdateDecision.none;
  final min = policy.minVersion;
  if (min != null && min.isNotEmpty && compareVersions(currentVersion, min) < 0) {
    return UpdateDecision.required;
  }
  final latest = policy.latestVersion;
  if (latest != null && latest.isNotEmpty && compareVersions(currentVersion, latest) < 0) {
    return UpdateDecision.optional;
  }
  return UpdateDecision.none;
}

/// 方針を取って判定する。取得に失敗しても例外は出さず `none`（更新確認のせいでアプリが使えなくならない）。
Future<({UpdateDecision decision, UpdatePolicy? policy})> checkForUpdate(
  UpdateBackend backend,
  String currentVersion,
) async {
  try {
    final policy = await backend.fetch();
    return (decision: decideUpdate(currentVersion, policy), policy: policy);
  } catch (_) {
    return (decision: UpdateDecision.none, policy: null);
  }
}

/// 更新を確認し、必要ならダイアログを出す。出したら true。
///
/// - 強制: 閉じられない（戻る操作も無効）。「アップデート」だけ。
/// - 任意: 「あとで」で閉じられる。
/// [openStore] は、ストアを開く処理（url_launcher など）。アプリ側が渡す。
Future<bool> promptForUpdate(
  BuildContext context, {
  required UpdateBackend backend,
  required String currentVersion,
  required void Function(String? storeUrl) openStore,
  KitStrings? strings,
}) async {
  final s = strings ?? KitStrings.of(context);
  final r = await checkForUpdate(backend, currentVersion);
  if (r.decision == UpdateDecision.none || !context.mounted) return false;
  final force = r.decision == UpdateDecision.required;
  final note = r.policy?.message;
  await showDialog<void>(
    context: context,
    barrierDismissible: !force,
    builder: (ctx) => PopScope(
      canPop: !force,
      child: AlertDialog(
        title: Text(force ? s.updateRequiredTitle : s.updateAvailableTitle),
        content: Text([
          force ? s.updateRequiredBody : s.updateAvailableBody,
          if (note != null && note.isNotEmpty) note,
        ].join('\n\n')),
        actions: [
          if (!force) TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(s.updateLater)),
          FilledButton(
            onPressed: () {
              openStore(r.policy?.storeUrl);
              if (!force) Navigator.of(ctx).pop();
            },
            child: Text(s.updateNow),
          ),
        ],
      ),
    ),
  );
  return true;
}
