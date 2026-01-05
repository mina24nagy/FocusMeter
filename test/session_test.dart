import 'package:flutter_test/flutter_test.dart';
import 'package:focus_tracker/models/session.dart';

void main() {
  group('Session Model', () {
    test('should create session correctly', () {
      final now = DateTime.now();
      final session = Session(
        id: '1',
        durationMinutes: 30,
        type: 'Work',
        comment: 'Deep work',
        timestamp: now,
      );

      expect(session.id, '1');
      expect(session.durationMinutes, 30);
      expect(session.type, 'Work');
      expect(session.comment, 'Deep work');
      expect(session.timestamp, now);
    });
  });
}
