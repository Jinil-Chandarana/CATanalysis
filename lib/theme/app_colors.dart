import 'package:flutter/material.dart';
import 'package:catalyst_app/models/study_session.dart';

// This class holds our entire app's color palette.
class AppColors {
  // General App Colors
  static const Color background = Color(0xFFF4F6F8);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF2D3748);
  static const Color secondaryText = Color(0xFF2D3748);
  static const Color accent = Color(0xFF4A5568);

  // Subject-Specific Colors
  static const Color varcColor = Color.fromARGB(255, 145, 184, 165);
  static const Color lrdiColor = Color.fromARGB(255, 130, 134, 177);
  static const Color qaColor = Color.fromARGB(255, 126, 160, 191);
  static const Color miscColor = Color(0xFF4A5568);

  // Helper function to get the right color for a subject
  static Color getSubjectColor(Subject subject) {
    switch (subject) {
      case Subject.varc:
        return varcColor;
      case Subject.lrdi:
        return lrdiColor;
      case Subject.qa:
        return qaColor;
      case Subject.misc: // New
        return miscColor;
    }
  }
}
