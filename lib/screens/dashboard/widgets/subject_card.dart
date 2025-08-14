import 'package:flutter/material.dart';
import 'package:catalyst_app/models/study_session.dart';

class SubjectCard extends StatelessWidget {
  final Subject subject;
  final String progressText;
  final Color color;
  final VoidCallback onTap;

  const SubjectCard({
    super.key,
    required this.subject,
    required this.progressText,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject.name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 0, 0, 0),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              progressText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.9),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
