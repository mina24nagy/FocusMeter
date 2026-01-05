import 'package:hive_flutter/hive_flutter.dart';
import '../models/session.dart';

class StorageService {
  static const String sessionBoxName = 'sessions';
  static const String settingsBoxName = 'settings';
  static const String dailyGoalKey = 'dailyGoal';

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(SessionAdapter());
    await Hive.openBox<Session>(sessionBoxName);
    await Hive.openBox(settingsBoxName);
  }

  Box<Session> get _sessionBox => Hive.box<Session>(sessionBoxName);
  Box get _settingsBox => Hive.box(settingsBoxName);

  Future<void> addSession(Session session) async {
    await _sessionBox.put(session.id, session);
  }

  List<Session> getSessionsForDay(DateTime date) {
    return _sessionBox.values.where((session) {
      return session.timestamp.year == date.year &&
             session.timestamp.month == date.month &&
             session.timestamp.day == date.day;
    }).toList();
  }

  List<Session> getAllSessions() {
    return _sessionBox.values.toList();
  }

  Future<void> setDailyGoal(int minutes) async {
    await _settingsBox.put(dailyGoalKey, minutes);
  }

  int getDailyGoal() {
    return _settingsBox.get(dailyGoalKey, defaultValue: 240); // Default 4 hours
  }
  
  // Calculate total minutes for a specific day
  int getTotalMinutesForDay(DateTime date) {
    final sessions = getSessionsForDay(date);
    return sessions.fold(0, (sum, session) => sum + session.durationMinutes);
  }
}
