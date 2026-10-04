import 'package:flutter/material.dart';

/// 支出分类定义。key 存数据库，显示文案走 i18n（`expense_` + key）。
class ExpenseCategories {
  static const List<String> keys = [
    'energy', // 油费 / 电费
    'rent', // 车辆租金（临时、按次）
    'maintenance', // 保养维修
    'insurance', // 保险
    'fine', // 罚款
    'wash', // 洗车
    'other', // 其他
  ];

  static String labelKey(String key) => 'expense_$key';

  static IconData iconFor(String key) {
    switch (key) {
      case 'energy':
        return Icons.local_gas_station_outlined;
      case 'rent':
        return Icons.key_outlined;
      case 'maintenance':
        return Icons.build_outlined;
      case 'insurance':
        return Icons.verified_user_outlined;
      case 'fine':
        return Icons.receipt_long_outlined;
      case 'wash':
        return Icons.local_car_wash_outlined;
      case 'other':
      default:
        return Icons.more_horiz_outlined;
    }
  }

  /// 把旧版两个固定字段映射到新分类。
  static Map<String, double> fromLegacy({
    required double energyCost,
    required double vehicleRent,
  }) {
    final map = <String, double>{};
    if (energyCost > 0) map['energy'] = energyCost;
    if (vehicleRent > 0) map['rent'] = vehicleRent;
    return map;
  }
}
