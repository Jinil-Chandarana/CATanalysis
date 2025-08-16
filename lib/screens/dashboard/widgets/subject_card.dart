import 'package:flutter/material.dart';
import 'package:catalyst_app/models/study_session.dart';
import 'package:catalyst_app/theme/app_colors.dart';

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
    // This final logic applies the border ONLY to the Misc card.
    final BoxDecoration cardDecoration;

    if (subject == Subject.misc) {
      // Style for the Misc card: White background with a black border.
      cardDecoration = BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color.fromARGB(255, 45, 78, 100),
            width: 2.0), // The border
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 78, 78, 78).withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      );
    } else {
      // Style for all other cards: Original pastel color, NO border.
      cardDecoration = BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        // No border property here
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject.name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              progressText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.primaryText.withOpacity(0.9),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
