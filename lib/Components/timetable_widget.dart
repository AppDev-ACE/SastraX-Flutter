import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/theme_model.dart';

class TimetableWidget extends StatelessWidget {
  final List<dynamic> timetable;
  final bool isLoading;

  const TimetableWidget({
    super.key,
    required this.timetable,
    required this.isLoading,
  });

  bool _isEmptySchedule(List<dynamic> schedule) {
    if (schedule.isEmpty) return true;
    final today = DateTime.now();
    final dayIndex = today.weekday - 1;

    if (dayIndex >= schedule.length) return true;

    final todayData = schedule[dayIndex] as Map<String, dynamic>;
    return todayData.entries.every((entry) {
      final value = entry.value.toString().trim().toLowerCase();
      return value == 'n/a' || value == 'break' || value.isEmpty;
    });
  }

  int? _getCurrentIndex(List<dynamic> schedule) {
    final now = DateTime.now();
    final dayIndex = now.weekday - 1;

    if (dayIndex >= schedule.length) return null;

    final todayData = schedule[dayIndex] as Map<String, dynamic>;
    final timeSlots = [
      '08:45 - 09:45',
      '09:45 - 10:45',
      '10:45 - 11:00',
      '11:00 - 12:00',
      '12:00 - 01:00',
      '01:00 - 02:00',
      '02:00 - 03:00',
      '03:00 - 03:15',
      '03:15 - 04:15',
      '04:15 - 05:15',
      '05:30 - 06:30',
      '06:30 - 07:30',
      '07:30 - 08:30',
    ];

    for (int i = 0; i < timeSlots.length; i++) {
      final slot = timeSlots[i];
      final parts = slot.split(' - ');
      if (parts.length < 2) continue;

      try {
        final start = DateFormat('HH:mm').parse(parts[0]);
        final end = DateFormat('HH:mm').parse(parts[1]);

        final startTime = DateTime(now.year, now.month, now.day, start.hour, start.minute);
        final endTime = DateTime(now.year, now.month, now.day, end.hour, end.minute);

        if (now.isAfter(startTime) && now.isBefore(endTime)) {
          return i;
        }
      } catch (_) {}
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: themeProvider.cardBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.neonBlue.withOpacity(0.3)),
          boxShadow: themeProvider.isDarkMode
              ? [BoxShadow(color: AppTheme.neonBlue.withOpacity(0.2), blurRadius: 15)]
              : [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isEmptySchedule(timetable)) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: themeProvider.cardBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.neonBlue.withOpacity(0.3)),
          boxShadow: themeProvider.isDarkMode
              ? [BoxShadow(color: AppTheme.neonBlue.withOpacity(0.2), blurRadius: 15)]
              : [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: const Text(
          'No timetable available today.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // Convert the timetable data to the correct format for the list builder
    final today = DateTime.now();
    final dayIndex = today.weekday - 1;
    final todayData = timetable[dayIndex] as Map<String, dynamic>;

    final List<Map<String, String>> transformedTimetable = [];
    final timeSlots = [
      '08:45 - 09:45',
      '09:45 - 10:45',
      '10:45 - 11:00',
      '11:00 - 12:00',
      '12:00 - 01:00',
      '01:00 - 02:00',
      '02:00 - 03:00',
      '03:00 - 03:15',
      '03:15 - 04:15',
      '04:15 - 05:15',
      '05:30 - 06:30',
      '06:30 - 07:30',
      '07:30 - 08:30',
    ];
    for (final slot in timeSlots) {
      final subject = todayData[slot] ?? 'N/A';
      String room = '';
      String cleanSubject = subject;
      final roomMatch = RegExp(r'\((.*?)\)').firstMatch(subject);
      if (roomMatch != null) {
        room = roomMatch.group(1)!;
        cleanSubject = subject.replaceAll(roomMatch.group(0)!, '').trim();
      }
      final parts = slot.split(' - ');
      final startTime24 = DateFormat('HH:mm').parse(parts[0]);
      final endTime24 = DateFormat('HH:mm').parse(parts[1]);
      final formattedTime = '${DateFormat('h:mm a').format(startTime24)} - ${DateFormat('h:mm a').format(endTime24)}';

      transformedTimetable.add({
        'time': formattedTime,
        'start': startTime24.toIso8601String(),
        'end': endTime24.toIso8601String(),
        'subject': cleanSubject,
        'room': room,
      });
    }

    final currentIndex = _getCurrentIndex(timetable);

    return Container(
      decoration: BoxDecoration(
        color: themeProvider.cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.neonBlue.withOpacity(0.3)),
        boxShadow: themeProvider.isDarkMode
            ? [BoxShadow(color: AppTheme.neonBlue.withOpacity(0.2), blurRadius: 15)]
            : [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: themeProvider.isDarkMode
                  ? const LinearGradient(colors: [Colors.black, Color(0xFF1A1A1A)])
                  : const LinearGradient(colors: [AppTheme.navyBlue, Color(0xFF3b82f6)]),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: themeProvider.isDarkMode ? AppTheme.neonBlue : Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Today\'s Timetable',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.isDarkMode ? AppTheme.neonBlue : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transformedTimetable.length,
              itemBuilder: (context, index) {
                final item = transformedTimetable[index];
                final isBreak = item['subject']!.toLowerCase() == 'break';
                final isCurrent = index == currentIndex;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: themeProvider.isDarkMode
                          ? (isBreak
                          ? [const Color(0xFF2A1810), const Color(0xFF3A2418)]
                          : [const Color(0xFF0A1A2A), const Color(0xFF152A3A)])
                          : (isBreak
                          ? [Colors.orange[50]!, Colors.orange[100]!]
                          : [Colors.blue[50]!, Colors.blue[100]!]),
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isCurrent ? AppTheme.neonBlue : Colors.transparent,
                      width: isCurrent ? 3 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: themeProvider.isDarkMode
                              ? (isBreak
                              ? [const Color(0xFFFFD93D), const Color(0xFFFFE55C)]
                              : [AppTheme.neonBlue, AppTheme.electricBlue])
                              : (isBreak
                              ? [Colors.orange[400]!, Colors.orange[600]!]
                              : [Colors.blue[400]!, Colors.blue[600]!]),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      item['subject']!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: themeProvider.primaryColor,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['time']!,
                          style: TextStyle(
                            color: themeProvider.textSecondaryColor,
                            fontSize: 13,
                          ),
                        ),
                        if (item['room']!.isNotEmpty)
                          Text(
                            item['room']!,
                            style: TextStyle(
                              color: themeProvider.textSecondaryColor,
                              fontSize: 11.5,
                            ),
                          ),
                      ],
                    ),
                    trailing: Icon(
                      isBreak ? Icons.free_breakfast : Icons.book,
                      color: isBreak
                          ? (themeProvider.isDarkMode ? const Color(0xFFFFD93D) : Colors.orange[600])
                          : (themeProvider.isDarkMode ? AppTheme.neonBlue : Colors.blue[600]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}