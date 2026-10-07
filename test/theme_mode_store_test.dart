import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_common_kit/app_common_kit.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appThemeMode.value = ThemeMode.system;
  });

  test('保存前はsystemのまま', () async {
    await loadSavedThemeMode();
    expect(appThemeMode.value, ThemeMode.system);
  });

  test('setThemeModeで値が変わり、SharedPreferencesに保存される', () async {
    await setThemeMode(ThemeMode.dark);
    expect(appThemeMode.value, ThemeMode.dark);

    appThemeMode.value = ThemeMode.system;
    await loadSavedThemeMode();
    expect(appThemeMode.value, ThemeMode.dark);
  });
}
