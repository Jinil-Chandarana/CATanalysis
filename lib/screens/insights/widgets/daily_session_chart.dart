import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:catalyst_app/models/study_session.dart';
import 'package:catalyst_app/theme/app_colors.dart';

class DailySessionChart extends StatelessWidget {
  final List<StudySession> sessions;
  const DailySessionChart({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    // A map to assign a vertical lane to each subject
    final subjectOrder = {
      Subject.varc: 0,
      Subject.lrdi: 1,
      Subject.qa: 2,
      Subject.misc: 3,
    };
    const double rowHeight = 25.0; // Height for each subject's lane
    const double leftLabelWidth = 50.0; // Space for "VARC", "QA", etc.

    return SizedBox(
      height: (subjectOrder.length * rowHeight) +
          30, // Total height + space for x-axis
      child: Row(
        children: [
          // Y-Axis Labels (Subject Names)
          SizedBox(
            width: leftLabelWidth,
            child: Column(
              children: subjectOrder.keys.map((subject) {
                return SizedBox(
                  height: rowHeight,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      subject.name,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Chart Area
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final totalWidth = constraints.maxWidth;
                      const totalMinutesInDay = 24 * 60;

                      return Stack(
                        children: [
                          // Background Grid Lines
                          _buildGridLines(totalWidth),

                          // Session Bars
                          ...sessions.map((session) {
                            final top =
                                subjectOrder[session.subject]! * rowHeight;
                            final startMinutes = session.startTime.hour * 60 +
                                session.startTime.minute;
                            final left =
                                (startMinutes / totalMinutesInDay) * totalWidth;
                            final barWidth = (session.focusDuration.inMinutes /
                                    totalMinutesInDay) *
                                totalWidth;

                            return Positioned(
                              top: top +
                                  (rowHeight / 4), // Center the bar vertically
                              left: left,
                              height: rowHeight / 2, // Bar height
                              width: barWidth < 2
                                  ? 2
                                  : barWidth, // Min width of 2px
                              child: Tooltip(
                                message:
                                    '${session.subject.name} at ${DateFormat.jm().format(session.startTime)}\nDuration: ${session.focusDuration.inMinutes} min',
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.getSubjectColor(
                                        session.subject),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
                // X-Axis Labels (Time of Day)
                const SizedBox(height: 5),
                _buildTimeAxis(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridLines(double totalWidth) {
    return Row(
      children: List.generate(4, (index) {
        return Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: index < 3
                  ? Border(
                      right: BorderSide(color: Colors.grey.shade200, width: 1))
                  : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimeAxis() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('12am', style: TextStyle(fontSize: 10)),
        Text('6am', style: TextStyle(fontSize: 10)),
        Text('12pm', style: TextStyle(fontSize: 10)),
        Text('6pm', style: TextStyle(fontSize: 10)),
        Text(''), // Spacer for the end
      ],
    );
  }
}
