import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:catalyst_app/theme/app_colors.dart';

class DaySelector extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  const DaySelector({super.key, required this.onDateSelected});
  @override
  State<DaySelector> createState() => _DaySelectorState();
}

class _DaySelectorState extends State<DaySelector> {
  late final List<DateTime> _days;
  late DateTime _selectedDay;
  late final ScrollController _scrollController;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _days = List.generate(30, (i) {
      final date = now.subtract(Duration(days: i));
      return DateTime(date.year, date.month, date.day);
    }).reversed.toList();
    final todayIndex =
        _days.indexWhere((day) => day.isAtSameMomentAs(_selectedDay));
    _scrollController =
        ScrollController(initialScrollOffset: todayIndex * 68.0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final day = _days[index];
          final isSelected = day.isAtSameMomentAs(_selectedDay);
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDay = day);
              widget.onDateSelected(day);
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                // --- COLOR FIX: Use the default theme primary color for selections ---
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.E().format(day),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.d().format(day),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
