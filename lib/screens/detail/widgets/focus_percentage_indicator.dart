import 'package:flutter/material.dart';
import 'dart:math' as math;

class FocusPercentageIndicator extends StatelessWidget {
  final double percentage;
  final Color color;
  final double size;

  const FocusPercentageIndicator({
    super.key,
    required this.percentage,
    required this.color,
    this.size = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background grey circle
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade200),
          ),
          // Foreground colored progress arc
          CircularProgressIndicator(
            value: percentage,
            strokeWidth: 5,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: Text(
              '${(percentage * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: size * 0.28, // Font size scales with widget size
              ),
            ),
          ),
        ],
      ),
    );
  }
}
