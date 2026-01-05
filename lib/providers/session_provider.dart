import 'package:flutter/material.dart';
import '../models/session.dart';
import '../services/storage_service.dart';
import 'package:uuid/uuid.dart';

class SessionProvider with ChangeNotifier {
  final StorageService _storageService;

  SessionProvider(this._storageService);

  int get dailyGoal => _storageService.getDailyGoal();

  List<Session> get todaySessions => _storageService.getSessionsForDay(DateTime.now());

  int get todayTotalMinutes => _storageService.getTotalMinutesForDay(DateTime.now());

  Future<void> addSession(int minutes, String type, String? comment) async {
    final session = Session(
      id: const Uuid().v4(),
      durationMinutes: minutes,
      type: type,
      comment: comment,
      timestamp: DateTime.now(),
    );
    await _storageService.addSession(session);
    notifyListeners();
  }

  Future<void> updateDailyGoal(int minutes) async {
    await _storageService.setDailyGoal(minutes);
    notifyListeners();
  }
  
  // For Goal View
  Map<DateTime, bool> getGoalHistory(int days) {
    final history = <DateTime, bool>{};
    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      // Normalize date to midnight for key
      final dateKey = DateTime(date.year, date.month, date.day);
      final totalMinutes = _storageService.getTotalMinutesForDay(date);
      // Note: This uses the CURRENT goal for past days. 
      // Ideally we'd store the goal snapshot, but for simplicity we compare against current goal 
      // or maybe we can say if > 0 it's something. 
      // Let's stick to comparing against current goal for now as per simple requirements.
      history[dateKey] = totalMinutes >= dailyGoal;
    }
    return history;
  }
}
