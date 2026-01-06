import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/session_provider.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal & History'),
      ),
      body: Consumer<SessionProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Goal Setting
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Goal',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '${provider.dailyGoal} minutes',
                              style: const TextStyle(fontSize: 24),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditGoalDialog(context, provider),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  child: TableCalendar(
                    firstDay: DateTime.utc(2024, 1, 1),
                    lastDay: DateTime.now(),
                    focusedDay: _focusedDay,
                    calendarFormat: CalendarFormat.month,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month',
                    },
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        if (isSameDay(_selectedDay, selectedDay)) {
                          _selectedDay = null; // Toggle off
                        } else {
                          _selectedDay = selectedDay;
                        }
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                         _focusedDay = focusedDay;
                         _selectedDay = null; // Clear details on page change
                      });
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        return _buildMarker(context, day, provider);
                      },
                    ),
                  ),
                ),
                if (_selectedDay != null) ...[
                  const SizedBox(height: 16),
                  _buildSelectedDayDetails(provider, _selectedDay!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget? _buildMarker(BuildContext context, DateTime day, SessionProvider provider) {
    // Only show markers for past days or today
    final now = DateTime.now();
    final date = DateTime(day.year, day.month, day.day);
    final today = DateTime(now.year, now.month, now.day);
    
    if (date.isAfter(today)) return null;

    final totalMinutes = provider.getTotalMinutesForDay(day);
    final dailyGoalForDate = provider.getGoalForDate(day); // Use effective goal
    final isGoalMet = totalMinutes >= dailyGoalForDate;
    final hasSessions = totalMinutes > 0;
    
    // 3 States Logic:
    // 1. Achieved: totalMinutes >= goal -> Green Check
    // 2. Partial/Missed: 0 < totalMinutes < goal -> Orange/Red Warning
    // 3. None: totalMinutes == 0 -> Grey Dot (or nothing, but user asked for state 3)
    
    IconData icon;
    Color color;

    if (isGoalMet) {
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (hasSessions) {
      // Partial effort
      icon = Icons.access_time_filled; // or warning_amber
      color = Colors.orange;
    } else {
      // No sessions
      icon = Icons.circle; // Small dot
      color = Colors.grey.withOpacity(0.3);
    }
    
    // If it's "None" and it's just a spacer, maybe just a small dot?
    // User said "No sessions found", implying a state. 
    // Let's use a small neutral dot for empty days to keep the calendar looking populated but distinct.
    if (!hasSessions && !isGoalMet) {
       return Positioned(
         bottom: 2,
         child: Container(
           width: 6,
           height: 6,
           decoration: BoxDecoration(
             shape: BoxShape.circle,
             color: color,
           ),
         ),
       );
    }

    return Positioned(
      bottom: 1,
      right: 1,
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }

  Widget _buildSelectedDayDetails(SessionProvider provider, DateTime day) {
    final sessions = provider.getSessionsForDay(day);
    final totalMinutes = provider.getTotalMinutesForDay(day);
    final dailyGoal = provider.getGoalForDate(day);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              'Details for ${day.year}-${day.month}-${day.day}',
              style: const TextStyle(fontWeight: FontWeight.bold),
             ),
             const SizedBox(height: 8),
             Row(
               children: [
                 Text('Total: $totalMinutes minutes'),
                 const Spacer(),
                 Text('Goal: $dailyGoal minutes', style: const TextStyle(color: Colors.grey)),
               ],
             ),
             const Divider(),
             if (sessions.isEmpty)
               const Text('No sessions recorded.')
             else
               ...sessions.map((s) => ListTile(
                 title: Text('${s.type} - ${s.durationMinutes}m'),
                 subtitle: Text(s.comment ?? ''),
                 dense: true,
               )),
          ],
        ),
      ),
    );
  }

  void _showEditGoalDialog(BuildContext context, SessionProvider provider) {
    final controller = TextEditingController(text: provider.dailyGoal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Daily Goal (minutes)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text);
              if (minutes != null && minutes > 0) {
                provider.updateDailyGoal(minutes);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

