import 'package:flutter/material.dart';
import 'package:catalyst_app/models/study_session.dart';
import 'package:catalyst_app/theme/app_colors.dart';
import 'widgets/live_timer.dart';
import 'widgets/session_form.dart';

class LogSessionScreen extends StatefulWidget {
  const LogSessionScreen({super.key});
  @override
  State<LogSessionScreen> createState() => _LogSessionScreenState();
}

class _LogSessionScreenState extends State<LogSessionScreen> {
  Subject _selectedSubject = Subject.varc;
  Duration _finalFocusDuration = Duration.zero;
  bool _isSessionEnded = false;
  DateTime? _startTime;
  DateTime? _endTime;

  void _onSessionEnd(
      DateTime startTime, DateTime endTime, Duration focusDuration) {
    setState(() {
      _startTime = startTime;
      _endTime = endTime;
      _finalFocusDuration = focusDuration;
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
            if (!_isSessionEnded)
              LiveTimer(onSessionEnd: _onSessionEnd)
            else
              _buildSessionCompleteHeader(),
            const SizedBox(height: 24),
            if (!_isSessionEnded)
              _buildSubjectSelector()
            else
              SessionForm(
                subject: _selectedSubject,
                startTime: _startTime!,
                endTime: _endTime!,
                focusDuration: _finalFocusDuration,
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
            'Focus Time: ${_finalFocusDuration.inHours}h ${_finalFocusDuration.inMinutes.remainder(60)}m',
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
    final subjects = [Subject.varc, Subject.lrdi, Subject.qa, Subject.misc];
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
        const SizedBox(height: 16),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: subjects.map((subject) {
            return ChoiceChip(
              label: Text(subject.name),
              selected: _selectedSubject == subject,
              onSelected: (isSelected) {
                if (isSelected) {
                  setState(() {
                    _selectedSubject = subject;
                  });
                }
              },
              // --- COLOR FIX: Removed custom colors to use default theme blue ---
            );
          }).toList(),
        ),
      ],
    );
  }
}
