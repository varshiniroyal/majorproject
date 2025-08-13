enum Sex { male, female }

enum ActivityLevel { sedentary, light, moderate, veryActive, extraActive }

enum Goal { lose, maintain, gain }

class UserProfile {
  final Sex sex;
  final double heightCm;
  final double currentWeightKg;
  final int ageYears;
  final ActivityLevel activityLevel;
  final Goal goal;

  const UserProfile({
    required this.sex,
    required this.heightCm,
    required this.currentWeightKg,
    required this.ageYears,
    required this.activityLevel,
    required this.goal,
  });
}