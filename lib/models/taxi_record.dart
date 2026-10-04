import 'dart:convert';

import 'expense_categories.dart';

/// 一条记账：某一天的收入 + 按分类的支出。
class TaxiRecord {
  const TaxiRecord({
    this.id,
    required this.date,
    this.income = 0,
    this.distance = 0,
    Map<String, double>? expenses,
    this.note = '',
  }) : expenses = expenses ?? const {};

  final int? id;
  final DateTime date;
  final double income;
  final double distance;
  final Map<String, double> expenses;
  final String note;

  double get totalCost => expenses.values.fold(0.0, (a, b) => a + b);

  double get net => income - totalCost;

  /// 仅日期部分，用于按天分组。
  DateTime get dayOnly => DateTime(date.year, date.month, date.day);

  String get uniqueKey =>
      '${date.toIso8601String()}|$income|$distance|'
      '${_expensesKey()}|$note';

  String _expensesKey() {
    final entries = expenses.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) => '${e.key}:${e.value}').join(',');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'income': income,
    'distance': distance,
    'expenses': expenses,
    'note': note,
  };

  factory TaxiRecord.fromJson(Map<String, dynamic> json) {
    double number(String key) => (json[key] as num?)?.toDouble() ?? 0;

    Map<String, double> expenses;
    final rawExpenses = json['expenses'];
    if (rawExpenses is Map) {
      expenses = {
        for (final entry in rawExpenses.entries)
          entry.key.toString(): (entry.value as num?)?.toDouble() ?? 0,
      }..removeWhere((_, v) => v == 0);
    } else {
      // 兼容 v1 备份：energyCost / vehicleRent 两个固定字段。
      expenses = ExpenseCategories.fromLegacy(
        energyCost: number('energyCost'),
        vehicleRent: number('vehicleRent'),
      );
    }

    return TaxiRecord(
      id: (json['id'] as num?)?.toInt(),
      date: DateTime.parse(json['date'] as String),
      income: number('income'),
      distance: number('distance'),
      expenses: expenses,
      note: json['note'] as String? ?? '',
    );
  }

  /// 写入 SQLite 的行。
  Map<String, dynamic> toDbRow(String vehicleId) => {
    'vehicle_id': vehicleId,
    'date': _dateOnlyIso(date),
    'income': income,
    'distance': distance,
    'expenses': jsonEncode(expenses),
    'note': note,
    'created_at': DateTime.now().toIso8601String(),
  };

  factory TaxiRecord.fromDbRow(Map<String, dynamic> row) {
    Map<String, double> expenses = {};
    final raw = row['expenses'] as String?;
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        expenses = {
          for (final entry in decoded.entries)
            entry.key: (entry.value as num?)?.toDouble() ?? 0,
        }..removeWhere((_, v) => v == 0);
      } catch (_) {
        expenses = {};
      }
    }
    return TaxiRecord(
      id: row['id'] as int?,
      date: DateTime.parse(row['date'] as String),
      income: (row['income'] as num?)?.toDouble() ?? 0,
      distance: (row['distance'] as num?)?.toDouble() ?? 0,
      expenses: expenses,
      note: row['note'] as String? ?? '',
    );
  }

  static String _dateOnlyIso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  TaxiRecord copyWith({
    int? id,
    DateTime? date,
    double? income,
    double? distance,
    Map<String, double>? expenses,
    String? note,
  }) {
    return TaxiRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      income: income ?? this.income,
      distance: distance ?? this.distance,
      expenses: expenses ?? Map<String, double>.from(this.expenses),
      note: note ?? this.note,
    );
  }
}
