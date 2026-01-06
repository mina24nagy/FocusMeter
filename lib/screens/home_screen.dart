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
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      _showEditSessionDialog(context, session);
                                    } else if (value == 'delete') {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Session'),
                                          content: const Text(
                                              'Are you sure you want to delete this session? This will affect your daily goal progress.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              style: TextButton.styleFrom(
                                                  foregroundColor: Colors.red),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await provider.deleteSession(session.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Session deleted')));
                                        }
                                      }
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red, size: 20),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
        label: const Text('Log Session'),
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

  Future<void> _showEditSessionDialog(BuildContext context, Session session) async {
    final durationController = TextEditingController(text: session.durationMinutes.toString());
    final commentController = TextEditingController(text: session.comment);
    String selectedType = session.type;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Session'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Activity Type'),
                  items: ['Work', 'Study', 'Side Project', 'Other']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedType = val!),
                ),
                TextFormField(
                  controller: durationController,
                  decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter minutes';
                    if (int.tryParse(val) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                TextFormField(
                  controller: commentController,
                  decoration: const InputDecoration(labelText: 'Comment (Optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newDuration = int.parse(durationController.text);
                  final updatedSession = Session(
                    id: session.id, // Keep same ID
                    durationMinutes: newDuration,
                    type: selectedType,
                    comment: commentController.text,
                    timestamp: session.timestamp, // Keep original timestamp
                  );
                  
                  context.read<SessionProvider>().updateSession(updatedSession);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session updated')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
