import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const currencyKey = 'currency_symbol';

/// 全局货币符号，默认 ¥，设置页可改。
final currencySymbol = ValueNotifier<String>('¥');

Future<void> loadCurrencySymbol(SharedPreferences preferences) async {
  currencySymbol.value = preferences.getString(currencyKey) ?? '¥';
}

/// 格式化金额，统一走这里，不要再手写 '¥'。
String money(double value) =>
    '${currencySymbol.value}${value.toStringAsFixed(2)}';

String fixedCostKey(String vehicleId) => 'fixed_cost_$vehicleId';

Future<double> loadFixedCost(
  SharedPreferences preferences,
  String vehicleId,
) async {
  return preferences.getDouble(fixedCostKey(vehicleId)) ?? 0;
}

Future<void> saveFixedCost(
  SharedPreferences preferences,
  String vehicleId,
  double value,
) async {
  await preferences.setDouble(fixedCostKey(vehicleId), value);
}
