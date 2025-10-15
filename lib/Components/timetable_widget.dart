import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/theme_model.dart';

class TimetableWidget extends StatelessWidget {
  final List<dynamic> timetable;
  final bool isLoading;
  final List<dynamic> hourWiseAttendance;

  const TimetableWidget({
    super.key,
    required this.timetable,
    required this.isLoading,
    required this.hourWiseAttendance,
  });

  static const List<String> _timeSlots = [
    '08:45 - 09:45', '09:45 - 10:45', '10:45 - 11:00', '11:00 - 12:00',
    '12:00 - 01:00', '01:00 - 02:00', '02:00 - 03:00', '03:00 - 03:15',
    '03:15 - 04:15', '04:15 - 05:15', '05:30 - 06:30', '06:30 - 07:30',
    '07:30 - 08:30',
  ];

  static const Map<String, String> _slotToHourKeyMap = {
    '08:45 - 09:45': 'hour1',
    '09:45 - 10:45': 'hour2',
    '11:00 - 12:00': 'hour3',
    '12:00 - 01:00': 'hour4',
    '01:00 - 02:00': 'hour5',
    '02:00 - 03:00': 'hour6',
    '03:15 - 04:15': 'hour7',
    '04:15 - 05:15': 'hour8',
    '05:30 - 06:30': 'hour8',
  };

  DateTime _parseTime(String timeStr, DateTime now) {
    final parsedTime = DateFormat('HH:mm').parse(timeStr);
    int hour = parsedTime.hour;
    if (hour >= 1 && hour < 8) {
      hour += 12;
    }
    return DateTime(now.year, now.month, now.day, hour, parsedTime.minute);
  }

  bool _isEmptySchedule(List<dynamic> schedule) {
    if (schedule.isEmpty) return true;
    final today = DateTime.now();
    if (today.weekday > 5) return true;
    final dayIndex = today.weekday - 1;
    if (dayIndex < 0 || dayIndex >= schedule.length) return true;
    final todayData = schedule[dayIndex] as Map<String, dynamic>;
    return todayData.entries.every((entry) {
      if (entry.key.toLowerCase() == 'day') return true;
      final value = entry.value.toString().trim().toLowerCase();
      return value == 'n/a' || value == 'break' || value.isEmpty;
    });
  }

  int? _getCurrentIndex() {
    final now = DateTime.now();
    for (int i = 0; i < _timeSlots.length; i++) {
      final slot = _timeSlots[i];
      final parts = slot.split(' - ');
      if (parts.length < 2) continue;
      try {
        final startTime = _parseTime(parts[0], now);
        final endTime = _parseTime(parts[1], now);
        if (now.isAfter(startTime) && now.isBefore(endTime)) {
          return i;
        }
      } catch (_) {}
    }
    return null;
  }

  Color _getAttendanceColor(String slot, Map<String, dynamic>? todayAttendance) {
    if (todayAttendance == null) {
      return Colors.grey.shade400;
    }
    final hourKey = _slotToHourKeyMap[slot];
    if (hourKey == null) {
      return Colors.transparent;
    }
    final status = todayAttendance[hourKey]?.toString().trim().toLowerCase() ?? '';

    if (status == 'p') {
      return Colors.green.shade400;
    } else if (status == 'a') {
      return Colors.red.shade400;
    } else {
      return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: themeProvider.cardBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isEmptySchedule(timetable)) {
      return Container(
        decoration: BoxDecoration(
          color: themeProvider.cardBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('No classes scheduled for today! 🎉', style: TextStyle(fontSize: 16)),
          ),
        ),
      );
    }

    final today = DateTime.now();
    final todayDateString = DateFormat('dd-MMM-yyyy').format(today);
    Map<String, dynamic>? todayAttendance;
    try {
      todayAttendance = hourWiseAttendance.firstWhere(
            (att) {
          if (att == null || att['dateDay'] == null) return false;
          final backendDate = (att['dateDay'] as String).trim();
          return backendDate.toLowerCase().startsWith(todayDateString.toLowerCase());
        },
        orElse: () => null,
      );
    } catch (_) {
      todayAttendance = null;
    }

    final dayIndex = today.weekday - 1;
    if (dayIndex < 0 || dayIndex >= timetable.length) {
      return Container(
        decoration: BoxDecoration(
          color: themeProvider.cardBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('Enjoy your weekend! 🥳', style: TextStyle(fontSize: 16)),
          ),
        ),
      );
    }

    final todayData = timetable[dayIndex] as Map<String, dynamic>;
    final List<Map<String, dynamic>> transformedTimetable = [];

    for (final slot in _timeSlots) {
      final subject = todayData[slot] ?? 'N/A';
      String room = '';
      String cleanSubject = subject;
      final roomMatch = RegExp(r'\((.*?)\)').firstMatch(subject);
      if (roomMatch != null) {
        room = roomMatch.group(1)!;
        cleanSubject = subject.replaceAll(roomMatch.group(0)!, '').trim();
      }
      final parts = slot.split(' - ');
      final startTime = _parseTime(parts[0], today);
      final endTime = _parseTime(parts[1], today);
      final formattedTime = '${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}';
      final attendanceColor = _getAttendanceColor(slot, todayAttendance);

      transformedTimetable.add({
        'time': formattedTime,
        'subject': cleanSubject,
        'room': room,
        'attendanceColor': attendanceColor,
      });
    }

    final currentIndex = _getCurrentIndex();

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
                Icon(Icons.schedule, color: themeProvider.isDarkMode ? AppTheme.neonBlue : Colors.white),
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transformedTimetable.length,
              itemBuilder: (context, index) {
                final item = transformedTimetable[index];
                final isBreak = item['subject']!.toLowerCase() == 'break';
                final isCurrent = index == currentIndex;

                if (item['subject']!.toLowerCase() == 'n/a' || item['subject']!.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: themeProvider.cardBackgroundColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isCurrent ? AppTheme.neonBlue : Colors.grey.withOpacity(0.2),
                      width: isCurrent ? 2 : 1,
                    ),
                    boxShadow: isCurrent
                        ? [BoxShadow(color: AppTheme.neonBlue.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)]
                        : [],
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isBreak ? Colors.orange.withOpacity(0.2) : AppTheme.primaryBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isBreak ? Icons.free_breakfast_outlined : Icons.menu_book_outlined,
                        color: isBreak ? Colors.orange : AppTheme.primaryBlue,
                      ),
                    ),
                    title: Text(
                      item['subject']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['time']!, style: TextStyle(color: themeProvider.textSecondaryColor, fontSize: 13)),
                        if (item['room']!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(item['room']!, style: TextStyle(color: themeProvider.textSecondaryColor, fontSize: 12)),
                          ),
                      ],
                    ),
                    trailing: isBreak || item['attendanceColor'] == Colors.transparent
                        ? null
                        : Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: item['attendanceColor'],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: themeProvider.isDarkMode
                              ? Colors.white.withOpacity(0.2)
                              : Colors.black.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
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