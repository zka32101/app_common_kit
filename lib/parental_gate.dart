/// 保護者ゲート（子ども向けアプリで、購入や外部リンクの前に出す簡易な確認）。
///
/// `package:app_common_kit/app_common_kit.dart` からは**出さない**。アプリが同じ名前の部品
/// （`requireParentalGate` や `ParentalGateDialog`）を自前で持っていても、名前が衝突しないようにするため。
/// 使うアプリは、自前のコピーを消して、この入口を import する。
///
/// ```dart
/// import 'package:app_common_kit/parental_gate.dart';
/// ```
library;

export 'parental_gate/parental_gate.dart';
