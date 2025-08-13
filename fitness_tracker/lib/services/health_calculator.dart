import '../models/user_profile.dart';

class HealthCalculator {
  double bmi({required double weightKg, required double heightCm}) {
    if (weightKg <= 0 || heightCm <= 0) return 0;
    final h = heightCm / 100.0;
    return weightKg / (h * h);
  }

  double bmr({
    required bool isMale,
    required double weightKg,
    required double heightCm,
    required int ageYears,
  }) {
    if (weightKg <= 0 || heightCm <= 0 || ageYears <= 0) return 0;
    final base = 10 * weightKg + 6.25 * heightCm - 5 * ageYears;
    return isMale ? base + 5 : base - 161;
  }

  double tdee(double bmr, ActivityLevel level) {
    if (bmr <= 0) return 0;
    final m = switch (level) {
      ActivityLevel.sedentary => 1.2,
      ActivityLevel.light => 1.375,
      ActivityLevel.moderate => 1.55,
      ActivityLevel.veryActive => 1.725,
      ActivityLevel.extraActive => 1.9,
    };
    return bmr * m;
  }

  double dailyCaloriesTarget(double tdee, Goal goal) {
    if (tdee <= 0) return 0;
    return switch (goal) {
      Goal.lose => tdee - 400,
      Goal.maintain => tdee,
      Goal.gain => tdee + 300,
    };
  }
}