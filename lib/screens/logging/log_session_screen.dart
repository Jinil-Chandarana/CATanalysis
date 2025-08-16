import 'package:flutter/material.dart';
import 'package:catalyst_app/models/study_session.dart';
import 'widgets/live_timer.dart';
import 'widgets/session_form.dart';

class LogSessionScreen extends StatefulWidget {
  const LogSessionScreen({super.key});

  @override
  State<LogSessionScreen> createState() => _LogSessionScreenState();
}

class _LogSessionScreenState extends State<LogSessionScreen> {
  Subject _selectedSubject = Subject.varc;
  Duration _finalDuration = Duration.zero;
  bool _isSessionEnded = false;

  // NEW: Add state variables for start and end times
  DateTime? _startTime;
  DateTime? _endTime;

  void _onSessionEnd(DateTime startTime, DateTime endTime) {
    setState(() {
      _startTime = startTime;
      _endTime = endTime;
      _finalDuration = endTime.difference(startTime);
      _isSessionEnded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log a New Session'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Show timer OR the "Session Complete" message
            if (!_isSessionEnded)
              LiveTimer(onSessionEnd: _onSessionEnd)
            else
              _buildSessionCompleteHeader(),

            const SizedBox(height: 24),

            // Show subject selection OR the final form
            if (!_isSessionEnded)
              _buildSubjectSelector()
            else
              SessionForm(
                subject: _selectedSubject,
                // Pass the new time objects to the form
                startTime: _startTime!,
                endTime: _endTime!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCompleteHeader() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 60),
          const SizedBox(height: 8),
          Text(
            'Session Complete!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            'Time: ${_finalDuration.inHours}h ${_finalDuration.inMinutes.remainder(60)}m ${_finalDuration.inSeconds.remainder(60)}s',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Please fill in the details below.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Subject',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SegmentedButton<Subject>(
          segments: const [
            ButtonSegment(value: Subject.varc, label: Text('VARC')),
            ButtonSegment(value: Subject.lrdi, label: Text('LRDI')),
            ButtonSegment(value: Subject.qa, label: Text('QA')),
          ],
          selected: {_selectedSubject},
          onSelectionChanged: (newSelection) {
            setState(() {
              _selectedSubject = newSelection.first;
            });
          },
          style: SegmentedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              textStyle: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
