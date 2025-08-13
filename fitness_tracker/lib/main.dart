import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'services/health_calculator.dart';
import 'services/daily_log_repo.dart';
import 'models/user_profile.dart';
import 'models/daily_log.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: FitnessApp()));
}

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/log', builder: (_, __) => const LogTodayScreen()),
  ],
);

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fitness Tracker (No Sensors)',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      routerConfig: router,
    );
  }
}

final todayProvider = Provider<DateTime>((_) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final profileProvider =
    StateNotifierProvider<ProfileController, UserProfile?>((ref) {
  return ProfileController();
});

class ProfileController extends StateNotifier<UserProfile?> {
  ProfileController() : super(null);
  void save(UserProfile profile) => state = profile;
}

final logRepoProvider = Provider<DailyLogRepository>((_) => DailyLogRepository());
final todayLogProvider = FutureProvider<DailyLog>((ref) async {
  final repo = ref.watch(logRepoProvider);
  final date = ref.watch(todayProvider);
  return repo.getLog(date);
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLog = ref.watch(todayLogProvider);
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person),
          ),
          IconButton(
            onPressed: () => context.push('/log'),
            icon: const Icon(Icons.edit_note),
          ),
        ],
      ),
      body: asyncLog.when(
        data: (log) {
          final profileLocal = profile;
          final calculator = HealthCalculator();
          final bmr = profileLocal == null
              ? null
              : calculator.bmr(
                  isMale: profileLocal.sex == Sex.male,
                  weightKg: profileLocal.currentWeightKg,
                  heightCm: profileLocal.heightCm,
                  ageYears: profileLocal.ageYears,
                );
          final tdee = (bmr == null)
              ? null
              : calculator.tdee(bmr, profileLocal!.activityLevel);
          final target = (tdee == null)
              ? null
              : calculator.dailyCaloriesTarget(tdee, profileLocal!.goal);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Today: ${DateFormat.yMMMEd().format(ref.watch(todayProvider))}'),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: const Text('Calories'),
                  subtitle: Text('Consumed: ${log.caloriesInKcal} kcal'
                      '${target != null ? '  •  Target: ${target.round()} kcal' : ''}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Water'),
                  subtitle: Text('${log.waterMl} ml'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Weight'),
                  subtitle: Text(log.weightKg == null ? '—' : '${log.weightKg} kg'),
                ),
              ),
              const SizedBox(height: 12),
              if (profileLocal == null)
                const Text('Complete your profile to get goals → Profile (top right)'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/log'),
                icon: const Icon(Icons.add),
                label: const Text('Log today'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Sex sex = Sex.male;
  final heightCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  ActivityLevel level = ActivityLevel.moderate;
  Goal goal = Goal.lose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<Sex>(
            value: sex,
            items: Sex.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                .toList(),
            onChanged: (v) => setState(() => sex = v ?? Sex.male),
            decoration: const InputDecoration(labelText: 'Sex'),
          ),
          TextField(controller: heightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Height (cm)')),
          TextField(controller: weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Current weight (kg)')),
          TextField(controller: ageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age (years)')),
          DropdownButtonFormField<ActivityLevel>(
            value: level,
            items: ActivityLevel.values
                .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
                .toList(),
            onChanged: (v) => setState(() => level = v ?? ActivityLevel.moderate),
            decoration: const InputDecoration(labelText: 'Activity level'),
          ),
          DropdownButtonFormField<Goal>(
            value: goal,
            items: Goal.values
                .map((g) => DropdownMenuItem(value: g, child: Text(g.name)))
                .toList(),
            onChanged: (v) => setState(() => goal = v ?? Goal.lose),
            decoration: const InputDecoration(labelText: 'Goal'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final profile = UserProfile(
                sex: sex,
                heightCm: double.tryParse(heightCtrl.text) ?? 0,
                currentWeightKg: double.tryParse(weightCtrl.text) ?? 0,
                ageYears: int.tryParse(ageCtrl.text) ?? 18,
                activityLevel: level,
                goal: goal,
              );
              ref.read(profileProvider.notifier).save(profile);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class LogTodayScreen extends ConsumerStatefulWidget {
  const LogTodayScreen({super.key});
  @override
  ConsumerState<LogTodayScreen> createState() => _LogTodayScreenState();
}

class _LogTodayScreenState extends ConsumerState<LogTodayScreen> {
  final caloriesCtrl = TextEditingController();
  final waterCtrl = TextEditingController();
  final weightCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final date = ref.watch(todayProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Log Today')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: caloriesCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories (kcal)')),
            TextField(controller: waterCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Water (ml)')),
            TextField(controller: weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight (kg, optional)')),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final repo = ref.read(logRepoProvider);
                final existing = await repo.getLog(date);
                final updated = existing.copyWith(
                  caloriesInKcal: int.tryParse(caloriesCtrl.text) ?? existing.caloriesInKcal,
                  waterMl: int.tryParse(waterCtrl.text) ?? existing.waterMl,
                  weightKg: double.tryParse(weightCtrl.text) ?? existing.weightKg,
                );
                await repo.saveLog(updated);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
