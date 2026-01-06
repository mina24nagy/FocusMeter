import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  bool _isManualMode = true;
  
  // Timer State
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = false;

  // Form State
  String _selectedType = 'Work';
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _manualMinutesController = TextEditingController();



  @override
  void dispose() {
    _timer?.cancel();
    _commentController.dispose();
    _manualMinutesController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _stopTimer() {
    _pauseTimer();
    // Save session
    _saveSession((_elapsedSeconds / 60).ceil());
  }

  void _saveSession(int minutes) {
    if (minutes <= 0) return;

    context.read<SessionProvider>().addSession(
      minutes,
      _selectedType,
      _commentController.text,
    );
    Navigator.pop(context);
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Session'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isManualMode = !_isManualMode;
                // Reset timer if switching
                if (_isManualMode) _pauseTimer();
              });
            },
            child: Text(_isManualMode ? 'Switch to Timer' : 'Switch to Manual'),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Type Selector
            Consumer<SessionProvider>(
              builder: (context, provider, child) {
                final types = provider.sessionTypes;
                // Ensure selected type is valid
                if (!types.contains(_selectedType) && types.isNotEmpty) {
                   // This might happen if we just added a type or loaded from fresh state
                   // But let's just keep _selectedType as is (it might be pre-filled)
                   // Or default to first.
                   if (_selectedType == 'Work' && !types.contains('Work')) {
                       _selectedType = types.first;
                   }
                }

                return DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Session Type',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    ...types.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    )),
                    const DropdownMenuItem(
                      value: '__add_new__',
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 20),
                          SizedBox(width: 8),
                          Text('Add New Type...'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == '__add_new__') {
                      // Show dialog to add new type
                      final newType = await _showAddTypeDialog(context);
                      if (newType != null && newType.isNotEmpty) {
                        await provider.addSessionType(newType);
                        setState(() {
                          _selectedType = newType;
                        });
                      } else {
                        // Revert to previous selection if cancelled
                        // Force rebuild to reset dropdown value visually if needed
                        setState(() {}); 
                      }
                    } else if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Comment
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comment (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),

            if (_isManualMode) ...[
              TextField(
                controller: _manualMinutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final minutes = int.tryParse(_manualMinutesController.text) ?? 0;
                    if (minutes > 0) {
                      _saveSession(minutes);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter valid minutes')),
                      );
                    }
                  },
                  child: const Text('Save Session'),
                ),
              ),
            ] else ...[
              // Timer Display
              Text(
                _formatTime(_elapsedSeconds),
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isRunning)
                    FloatingActionButton.large(
                      onPressed: _startTimer,
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.play_arrow),
                    )
                  else
                    FloatingActionButton.large(
                      onPressed: _pauseTimer,
                      backgroundColor: Colors.orange,
                      child: const Icon(Icons.pause),
                    ),
                  const SizedBox(width: 24),
                  FloatingActionButton.large(
                    onPressed: _elapsedSeconds > 0 ? _stopTimer : null,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.stop),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<String?> _showAddTypeDialog(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Session Type'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Type Name',
            hintText: 'e.g. Reading, Exercise',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
