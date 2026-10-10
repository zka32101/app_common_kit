import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 消す対象ひとつ。端末内のデータ・サーバー上のアカウントなど、アプリが種類ごとに作って渡す。
abstract class DataEraser {
  /// 失敗したときに結果へ出す名前（ログ用。画面には出さない）。
  String get id;

  Future<void> erase();
}

/// 任意の処理で消す。サーバー上のアカウント削除（Cloud Functions の呼び出しなど）に使う。
class CallbackEraser implements DataEraser {
  CallbackEraser(this.id, this._erase);

  @override
  final String id;
  final Future<void> Function() _erase;

  @override
  Future<void> erase() => _erase();
}

/// `SharedPreferences` の保存を消す。
///
/// - [keys] か [prefixes] に当たるキーだけを消す（どちらも空なら何も消さない）
/// - [all] が true なら、すべて消す（アプリ全体の初期化）
class SharedPreferencesEraser implements DataEraser {
  SharedPreferencesEraser({this.keys = const {}, this.prefixes = const [], this.all = false});

  final Set<String> keys;
  final List<String> prefixes;
  final bool all;

  @override
  String get id => 'shared_preferences';

  @override
  Future<void> erase() async {
    final prefs = await SharedPreferences.getInstance();
    if (all) {
      await prefs.clear();
      return;
    }
    for (final k in prefs.getKeys().toList()) {
      if (keys.contains(k) || prefixes.any(k.startsWith)) await prefs.remove(k);
    }
  }
}

/// 削除の結果。
class DeletionResult {
  const DeletionResult({required this.succeeded, required this.failed});

  final List<String> succeeded;

  /// 失敗した対象の id と、そのエラー。
  final Map<String, Object> failed;

  bool get ok => failed.isEmpty;
}

/// データ削除の共通の窓口（各アプリの「データを削除」）。
///
/// 並んだ [erasers] を順に実行する。**ひとつが失敗しても残りを続け**、結果にまとめて返す
/// （サーバーのアカウント削除に失敗しても、端末内のデータは消せるようにするため。逆も同じ）。
/// 順序は「サーバー側 → 端末内」にするとよい（サーバー削除に失敗したら、端末内を残して再試行できる）。
/// その場合は [stopOnFailure] を true にする。
class DataDeletion {
  DataDeletion(this.erasers, {this.stopOnFailure = false});

  final List<DataEraser> erasers;

  /// true なら、最初の失敗でそこで止める（後ろの対象は消さない）。
  final bool stopOnFailure;

  Future<DeletionResult> run() async {
    final ok = <String>[];
    final ng = <String, Object>{};
    for (final e in erasers) {
      try {
        await e.erase();
        ok.add(e.id);
      } catch (err) {
        ng[e.id] = err;
        if (stopOnFailure) break;
      }
    }
    return DeletionResult(succeeded: ok, failed: ng);
  }
}

/// 削除の確認画面の文言。内蔵: ja・en・zh・zh-Hant・ko（zh・zh-Hant・ko は機械翻訳の下書き。公開前に母語話者の確認が要る）。
class DataDeletionStrings {
  const DataDeletionStrings({
    required this.menu,
    required this.title,
    required this.body,
    required this.confirmCheck,
    required this.cancel,
    required this.delete,
    required this.done,
    required this.failed,
  });

  final String menu;
  final String title;
  final String body;
  final String confirmCheck;
  final String cancel;
  final String delete;
  final String done;
  final String failed;

  /// `KitStrings.languageCode`（`ja`・`en`・`zh`・`zh-Hant`・`ko`）に合わせて選ぶ。それ以外は日本語。
  static DataDeletionStrings forCode(String code) => switch (code) {
        'en' => en,
        'zh' => zhHans,
        'zh-Hant' => zhHant,
        'ko' => ko,
        _ => ja,
      };

  static const ja = DataDeletionStrings(
    menu: 'データを削除',
    title: 'データを削除しますか？',
    body: 'この端末の学習記録・設定を削除します。アカウントがある場合は、アカウントも削除します。削除したデータは元に戻せません。',
    confirmCheck: '元に戻せないことを理解しました',
    cancel: 'キャンセル',
    delete: '削除する',
    done: 'データを削除しました',
    failed: '削除できなかったデータがあります。しばらくしてからもう一度お試しください。',
  );
  static const en = DataDeletionStrings(
    menu: 'Delete my data',
    title: 'Delete your data?',
    body:
        'This deletes your study records and settings on this device, and your account if you have one. Deleted data cannot be restored.',
    confirmCheck: 'I understand this cannot be undone',
    cancel: 'Cancel',
    delete: 'Delete',
    done: 'Your data has been deleted',
    failed: 'Some data could not be deleted. Please try again later.',
  );
  static const zhHans = DataDeletionStrings(
    menu: '删除数据',
    title: '要删除数据吗？',
    body: '将删除此设备上的学习记录和设置；如有账号，也会一并删除。删除后的数据无法恢复。',
    confirmCheck: '我已了解此操作无法撤销',
    cancel: '取消',
    delete: '删除',
    done: '数据已删除',
    failed: '部分数据未能删除，请稍后再试。',
  );
  static const zhHant = DataDeletionStrings(
    menu: '刪除資料',
    title: '要刪除資料嗎？',
    body: '將刪除此裝置上的學習紀錄與設定；如有帳號，也會一併刪除。刪除後的資料無法復原。',
    confirmCheck: '我已了解此操作無法復原',
    cancel: '取消',
    delete: '刪除',
    done: '資料已刪除',
    failed: '部分資料未能刪除，請稍後再試。',
  );
  static const ko = DataDeletionStrings(
    menu: '데이터 삭제',
    title: '데이터를 삭제할까요?',
    body: '이 기기의 학습 기록과 설정을 삭제하며, 계정이 있으면 계정도 삭제합니다. 삭제한 데이터는 복구할 수 없습니다.',
    confirmCheck: '되돌릴 수 없음을 이해했습니다',
    cancel: '취소',
    delete: '삭제',
    done: '데이터를 삭제했습니다',
    failed: '삭제하지 못한 데이터가 있습니다. 잠시 후 다시 시도해 주세요.',
  );
}

/// 確認 → 削除 → 結果の通知までをまとめて行う。
///
/// 「元に戻せない」のチェックを入れるまで削除ボタンは押せない。削除中は二重に押せない。
/// 削除が済んだ（失敗を含む）ら [DeletionResult] を返す。キャンセルは null。
/// 削除後の画面遷移（初期画面へ戻す、アプリを再起動する等）は呼び出し側が行う。
Future<DeletionResult?> showDataDeletionFlow(
  BuildContext context,
  DataDeletion deletion, {
  required DataDeletionStrings strings,
}) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (_) => _ConfirmDialog(strings: strings),
  );
  if (go != true || !context.mounted) return null;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final result = await deletion.run();
  messenger?.showSnackBar(SnackBar(content: Text(result.ok ? strings.done : strings.failed)));
  return result;
}

class _ConfirmDialog extends StatefulWidget {
  const _ConfirmDialog({required this.strings});

  final DataDeletionStrings strings;

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return AlertDialog(
      title: Text(s.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.body),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _understood,
            onChanged: (v) => setState(() => _understood = v ?? false),
            title: Text(s.confirmCheck),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.cancel)),
        TextButton(
          onPressed: _understood ? () => Navigator.pop(context, true) : null,
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          child: Text(s.delete),
        ),
      ],
    );
  }
}
