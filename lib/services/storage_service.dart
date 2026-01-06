import 'package:hive_flutter/hive_flutter.dart';
import '../models/session.dart';

class StorageService {
  static const String sessionBoxName = 'sessions';
  static const String settingsBoxName = 'settings';

  static const String dailyGoalKey = 'dailyGoal';
  static const String goalHistoryKey = 'goalHistory';

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

  Future<void> updateSession(Session session) async {
    await _sessionBox.put(session.id, session);
  }

  Future<void> deleteSession(String id) async {
    await _sessionBox.delete(id);
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
    final currentGoal = getDailyGoal();
    
    // If the goal hasn't changed, do nothing
    if (currentGoal == minutes) return;
    
    // Before saving the NEW goal, verify if we need to snapshot the OLD goal.
    // If goalHistory is empty, it means we never tracked changes before.
    // To protect past history, we assume the valid goal UNTIL NOW was the `currentGoal`.
    // So we add an entry for "Start of time" (or effectively up to yesterday/today) -> currentGoal.
    // For simplicity, let's treat history as a list of {date: DateTime, goal: int} sorted by date.
    // When getting goal for Date X, we find the last entry where entry.date <= X.

    final history = _getGoalHistory();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (history.isEmpty) {
        // First time migration: "Yesterday" (and all past) was `currentGoal`.
        // "Today" becomes `minutes`.
        final yesterday = todayDate.subtract(const Duration(days: 1));
        history.add({'date': yesterday.toIso8601String(), 'goal': currentGoal});
    } else {
        // If we already have history, we just check if we need to update "Today's" entry or add new one.
        // If the last entry is BEFORE today, we add a new entry for Today.
        // If the last entry IS today, we just update it (user changed goal multiple times today).
        final lastEntry = history.last;
        final lastDate = DateTime.parse(lastEntry['date'] as String);
        
        if (lastDate.isAtSameMomentAs(todayDate)) {
             // Already changed today, update the record
             history.removeLast();
        }
    }
    
    // Add the new goal effective from Today
    history.add({'date': todayDate.toIso8601String(), 'goal': minutes});
    
    await _settingsBox.put(goalHistoryKey, history);
    await _settingsBox.put(dailyGoalKey, minutes);
  }

  int getDailyGoal() {
    return _settingsBox.get(dailyGoalKey, defaultValue: 240); // Default 4 hours
  }
  
  // Internal helper to get raw history list
  List<dynamic> _getGoalHistory() {
     final raw = _settingsBox.get(goalHistoryKey);
     if (raw == null) return [];
     // Hive might return List<dynamic>, cast if needed or keep dynamic
     return (raw as List).toList();
  }
  
  int getGoalForDate(DateTime date) {
      final history = _getGoalHistory();
      if (history.isEmpty) {
          return getDailyGoal(); // Fallback to current global goal
      }
      
      final targetDate = DateTime(date.year, date.month, date.day);
      
      // Find the last entry where entryDate <= targetDate
      // History should be sorted by date naturally as we append.
      int? effectiveGoal;
      
      for (final entry in history) {
          final entryDate = DateTime.parse(entry['date'] as String);
          if (entryDate.compareTo(targetDate) <= 0) {
              effectiveGoal = entry['goal'] as int;
          } else {
              // Once we pass the target date, previous effectiveGoal was the correct one.
              break;
          }
      }
      
      // If we found a matching history entry, return it.
      // If effectiveGoal is still null (e.g. target date is before the first history entry),
      // we should technically return the 'first' history entry's goal? 
      // OR return the current goal?
      // Our logic in setDailyGoal ensures we backfill "Yesterday" on first run.
      // So effectively the first entry covers all past.
      
      return effectiveGoal ?? (history.first['goal'] as int); 
  }

  // Calculate total minutes for a specific day
  int getTotalMinutesForDay(DateTime date) {
    final sessions = getSessionsForDay(date);
    return sessions.fold(0, (sum, session) => sum + session.durationMinutes);
  }
}
