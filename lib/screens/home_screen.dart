import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../models/session.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Meter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/goal');
            },
          )
        ],
      ),
      body: Consumer<SessionProvider>(
        builder: (context, provider, child) {
          final progress = provider.dailyGoal > 0 
              ? provider.todayTotalMinutes / provider.dailyGoal 
              : 0.0;
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Section
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          strokeWidth: 15,
                          backgroundColor: Colors.grey[300],
                          color: Colors.indigo,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${provider.todayTotalMinutes}',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '/ ${provider.dailyGoal} min',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Today\'s Sessions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: provider.todaySessions.isEmpty
                      ? const Center(child: Text('No sessions yet. Start working!'))
                      : ListView.builder(
                          itemCount: provider.todaySessions.length,
                          itemBuilder: (context, index) {
                            // Show newest first
                            final session = provider.todaySessions.reversed.toList()[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Icon(_getIconForType(session.type)),
                                ),
                                title: Text('${session.type} - ${session.durationMinutes} min'),
                                subtitle: session.comment != null && session.comment!.isNotEmpty
                                    ? Text(session.comment!)
                                    : Text(DateFormat.jm().format(session.timestamp)),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/tracker');
        },
        label: const Text('Start Session'),
        icon: const Icon(Icons.play_arrow),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'work': return Icons.work;
      case 'study': return Icons.book;
      case 'side project': return Icons.code;
      default: return Icons.timer;
    }
  }
}
