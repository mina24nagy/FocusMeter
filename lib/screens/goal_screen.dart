import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import 'package:intl/intl.dart';

class GoalScreen extends StatelessWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal & History'),
      ),
      body: Consumer<SessionProvider>(
        builder: (context, provider, child) {
          final history = provider.getGoalHistory(14); // Last 2 weeks
          
          return ListView(
            padding: const EdgeInsets.all(16),
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
                'History (Last 14 Days)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...history.entries.map((entry) {
                final date = entry.key;
                final achieved = entry.value;
                return Card(
                  color: achieved ? Colors.green[50] : Colors.red[50],
                  child: ListTile(
                    title: Text(DateFormat.yMMMd().format(date)),
                    trailing: Icon(
                      achieved ? Icons.check_circle : Icons.close,
                      color: achieved ? Colors.green : Colors.red,
                    ),
                  ),
                );
              }),
            ],
          );
        },
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
