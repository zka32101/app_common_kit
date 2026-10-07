import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 表示モード（ライト／ダーク／端末設定に従う）の永続化。`MaterialApp` の
/// `themeMode` にこの [appThemeMode] をリッスンさせれば、値を変えるだけで
/// 即座に全画面へ反映される（`MaterialApp` 自体がリスナーになるため、
/// `AppShell` の `IndexedStack` によるタブのマウント保持を気にする必要はない）。
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await loadSavedThemeMode();
///   runApp(const MyApp());
/// }
///
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
///         valueListenable: appThemeMode,
///         builder: (context, mode, _) => MaterialApp(
///           theme: UkalabTheme.light(field: ...),
///           darkTheme: UkalabTheme.dark(field: ...),
///           themeMode: mode,
///           home: ...,
///         ),
///       );
/// }
/// ```
final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

const _key = 'app_common_kit_theme_mode';

/// 起動時に `SharedPreferences` から復元する。`runApp` より前に呼ぶ想定。
Future<void> loadSavedThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_key);
  appThemeMode.value = ThemeMode.values.firstWhere(
    (m) => m.name == saved,
    orElse: () => ThemeMode.system,
  );
}

/// 表示モードを変更し、端末内に保存する（設定画面から呼ぶ想定）。
Future<void> setThemeMode(ThemeMode mode) async {
  appThemeMode.value = mode;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_key, mode.name);
}
