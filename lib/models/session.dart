import 'package:hive/hive.dart';

part 'session.g.dart';

@HiveType(typeId: 0)
class Session extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int durationMinutes;

  @HiveField(2)
  final String type;

  @HiveField(3)
  final String? comment;

  @HiveField(4)
  final DateTime timestamp;

  Session({
    required this.id,
    required this.durationMinutes,
    required this.type,
    this.comment,
    required this.timestamp,
  });
}
