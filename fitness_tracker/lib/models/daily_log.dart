class DailyLog {
  final DateTime date;
  final int caloriesInKcal;
  final int waterMl;
  final double? weightKg;

  const DailyLog({
    required this.date,
    required this.caloriesInKcal,
    required this.waterMl,
    this.weightKg,
  });

  DailyLog copyWith({int? caloriesInKcal, int? waterMl, double? weightKg}) {
    return DailyLog(
      date: date,
      caloriesInKcal: caloriesInKcal ?? this.caloriesInKcal,
      waterMl: waterMl ?? this.waterMl,
      weightKg: weightKg ?? this.weightKg,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'caloriesInKcal': caloriesInKcal,
        'waterMl': waterMl,
        'weightKg': weightKg,
      };

  static DailyLog fromJson(Map<String, dynamic> json) => DailyLog(
        date: DateTime.parse(json['date'] as String),
        caloriesInKcal: json['caloriesInKcal'] as int? ?? 0,
        waterMl: json['waterMl'] as int? ?? 0,
        weightKg: (json['weightKg'] as num?)?.toDouble(),
      );
}