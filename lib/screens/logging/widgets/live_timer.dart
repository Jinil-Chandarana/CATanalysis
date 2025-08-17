import 'dart:async';
import 'package:flutter/material.dart';
import 'package:catalyst_app/theme/app_colors.dart'; // <-- THIS IS THE FIX

class LiveTimer extends StatefulWidget {
  final Function(DateTime startTime, DateTime endTime, Duration focusDuration)
      onSessionEnd;

  const LiveTimer({super.key, required this.onSessionEnd});

  @override
  State<LiveTimer> createState() => _LiveTimerState();
}

class _LiveTimerState extends State<LiveTimer> {
  Timer? _uiTimer;
  bool _isRunning = false;

  // The total duration from all previous completed segments
  Duration _elapsedBeforePause = Duration.zero;

  // The start time of the session (first play press)
  DateTime? _initialStartTime;

  // The start time of the current running segment
  DateTime? _segmentStartTime;

  // This is the total duration displayed on screen
  Duration get _currentDuration {
    if (_isRunning && _segmentStartTime != null) {
      // If running, show saved time PLUS current segment's time
      return _elapsedBeforePause +
          DateTime.now().difference(_segmentStartTime!);
    } else {
      // If paused, just show the saved time
      return _elapsedBeforePause;
    }
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _initialStartTime ??= DateTime.now(); // Set only once
      _segmentStartTime = DateTime.now(); // Reset every time we resume
    });

    // This timer is ONLY for updating the UI every second
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {}); // Just rebuild the widget to update the displayed time
    });
  }

  void _pauseTimer() {
    _uiTimer?.cancel();
    if (_segmentStartTime != null) {
      // Calculate the duration of the segment that just ended
      final segmentDuration = DateTime.now().difference(_segmentStartTime!);
      // Add it to our running total
      _elapsedBeforePause += segmentDuration;
    }
    setState(() {
      _isRunning = false;
    });
  }

  void _endSession() {
    _uiTimer?.cancel();

    // Make sure we have a start time before ending
    if (_initialStartTime == null) return;

    Duration finalFocusDuration = _elapsedBeforePause;

    // If the timer was running when 'End' was pressed, add the final segment's time
    if (_isRunning && _segmentStartTime != null) {
      final finalSegmentDuration =
          DateTime.now().difference(_segmentStartTime!);
      finalFocusDuration += finalSegmentDuration;
    }

    // Pass the initial start time, current end time, and the accurately calculated focus duration
    widget.onSessionEnd(_initialStartTime!, DateTime.now(), finalFocusDuration);
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            _formatDuration(_currentDuration),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _isRunning ? _pauseTimer : _startTimer,
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(_isRunning ? 'Pause' : 'Start'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              ElevatedButton.icon(
                onPressed:
                    _currentDuration > Duration.zero ? _endSession : null,
                icon: const Icon(Icons.stop),
                label: const Text('End Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 138, 44, 44),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
