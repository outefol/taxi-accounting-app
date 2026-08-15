class TaxiRecord {
  const TaxiRecord({
    required this.date,
    required this.income,
    required this.distance,
    required this.energyCost,
    required this.vehicleRent,
    required this.note,
  });

  final DateTime date;
  final double income;
  final double distance;
  final double energyCost;
  final double vehicleRent;
  final String note;

  double get totalCost => energyCost + vehicleRent;

  String get uniqueKey =>
      '${date.toIso8601String()}|$income|$distance|$energyCost|'
      '$vehicleRent|$note';

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'income': income,
    'distance': distance,
    'energyCost': energyCost,
    'vehicleRent': vehicleRent,
    'note': note,
  };

  factory TaxiRecord.fromJson(Map<String, dynamic> json) {
    double number(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return TaxiRecord(
      date: DateTime.parse(json['date'] as String),
      income: number('income'),
      distance: number('distance'),
      energyCost: number('energyCost'),
      vehicleRent: number('vehicleRent'),
      note: json['note'] as String? ?? '',
    );
  }
}
