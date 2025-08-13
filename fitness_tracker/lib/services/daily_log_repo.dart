import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_log.dart';

class DailyLogRepository {
  static String _keyFor(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return 'dailyLog_${d.toIso8601String().substring(0, 10)}';
  }

  Future<DailyLog> getLog(DateTime date) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_keyFor(date));
    if (raw == null) {
      return DailyLog(date: DateTime(date.year, date.month, date.day), caloriesInKcal: 0, waterMl: 0);
    }
    return DailyLog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveLog(DailyLog log) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_keyFor(log.date), jsonEncode(log.toJson()));
  }
}