import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../../models/theme_model.dart'; // Ensure this path is correct
import 'day_attendance_detail.dart';

class MonthlyView extends StatefulWidget {
  final Map<DateTime, Map<String, String>> attendanceData; // Expects {'hour1': 'present'}
  final int currentStreak;
  final String regNo;
  final List<dynamic> timetable; // Normalized timetable
  final List<dynamic> courseMap;

  const MonthlyView({
    Key? key,
    required this.regNo,
    required this.attendanceData,
    required this.currentStreak,
    required this.timetable,
    required this.courseMap,
  }) : super(key: key);

  @override
  State<MonthlyView> createState() => _MonthlyViewState();
}

class _MonthlyViewState extends State<MonthlyView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  static const Color primaryBlue = Color(0xFF1e3a8a);
  static const Color lightBlue = Color(0xFF4A90E2);
  static const Color cyanColor = Color(0xFF00BCD4);

  Map<String, int> _calculateMonthStats() {
    int presentCount = 0;
    int absentCount = 0;
    int odCount = 0;

    widget.attendanceData.forEach((date, hourMap) {
      if (date.month == _focusedDay.month && date.year == _focusedDay.year) {
        int dailyPresent = 0;
        int dailyAbsent = 0;
        int dailyOd = 0;

        hourMap.forEach((hourKey, status) {
          if (status != null) {
            switch (status.toLowerCase()) {
              case 'present':
                dailyPresent++;
                break;
              case 'absent':
                dailyAbsent++;
                break;
              case 'od':
                dailyOd++;
                break;
            }
          }
        });
        presentCount += dailyPresent;
        absentCount += dailyAbsent;
        odCount += dailyOd;
      }
    });
    return {'present': presentCount, 'absent': absentCount, 'od': odCount};
  }

  Color _getTextColor(BuildContext context) =>
      Provider.of<ThemeProvider>(context).isDarkMode ? Colors.white : Colors.black;
  Color _getSecondaryTextColor(BuildContext context) =>
      Provider.of<ThemeProvider>(context).isDarkMode
          ? Colors.white70
          : Colors.grey[600]!;
  Color _getCardColor(BuildContext context) =>
      Provider.of<ThemeProvider>(context).isDarkMode
          ? const Color(0xFF1E1E1E)
          : Colors.white;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final scale = MediaQuery.of(context).textScaler.scale(1.0);
    final screenWidth = MediaQuery.of(context).size.width;
    final double rPadding = screenWidth * 0.04;

    final stats = _calculateMonthStats();
    final present = stats['present'] ?? 0;
    final absent = stats['absent'] ?? 0;
    final od = stats['od'] ?? 0;
    final totalClasses = present + absent + od;
    final percentage = totalClasses > 0
        ? ((present + od) / totalClasses * 100).round()
        : 0;

    final Color percentageColor = isDark ? lightBlue : primaryBlue;

    return Column(
      children: [
        // --- Monthly Stats Header ---
        Container(
          padding: EdgeInsets.all(rPadding),
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(_focusedDay),
                    style: TextStyle(
                        fontSize: 18 * scale,
                        fontWeight: FontWeight.bold,
                        color: _getTextColor(context)),
                  ),
                  Row(
                    children: [
                      _buildLegend('Present', Colors.green, scale),
                      SizedBox(width: rPadding),
                      _buildLegend('Absent', Colors.red, scale),
                      SizedBox(width: rPadding),
                      _buildLegend('OD', Colors.orange, scale),
                    ],
                  ),
                ],
              ),
              SizedBox(height: rPadding),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMonthStat('Present', present.toString(), Colors.green, scale),
                  _buildMonthStat('Absent', absent.toString(), Colors.red, scale),
                  _buildMonthStat('OD', od.toString(), Colors.orange, scale),
                  _buildMonthStat('Percentage', '$percentage%', percentageColor, scale),
                ],
              ),
            ],
          ),
        ),
        // --- Calendar ---
        Expanded(
          child: Container(
            // ✅ CHANGED: Set background to pure white in light mode
            color: isDark ? const Color(0xFF121212) : Colors.white,
            child: Padding(
              padding: EdgeInsets.all(rPadding),
              child: TableCalendar<String>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) {
                  final dayKey = DateTime(day.year, day.month, day.day);
                  return widget.attendanceData.containsKey(dayKey)
                      ? ['has data']
                      : [];
                },
                calendarStyle: CalendarStyle(
                  // ✅ REMOVED: defaultDecoration, weekendDecoration, and outsideDecoration
                  // This prevents the "box box" effect.
                  markersMaxCount: 1,
                  markerDecoration:
                  const BoxDecoration(color: Colors.transparent),
                  todayDecoration: BoxDecoration(
                      color: lightBlue.withOpacity(0.3),
                      shape: BoxShape.circle),
                  selectedDecoration: BoxDecoration(
                      color: primaryBlue, shape: BoxShape.circle),
                  defaultTextStyle: TextStyle(
                      color: _getTextColor(context), fontSize: 14 * scale),
                  selectedTextStyle:
                  TextStyle(color: Colors.white, fontSize: 14 * scale),
                  todayTextStyle: TextStyle(
                      color: _getTextColor(context), fontSize: 14 * scale),
                  weekendTextStyle: TextStyle(
                      color: _getTextColor(context), fontSize: 14 * scale),
                  outsideTextStyle:
                  TextStyle(color: _getSecondaryTextColor(context), fontSize: 12 * scale),
                  outsideDaysVisible: false,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleTextStyle:
                  TextStyle(color: _getTextColor(context), fontSize: 16 * scale),
                  leftChevronIcon: Icon(Icons.chevron_left,
                      color: _getTextColor(context)),
                  rightChevronIcon: Icon(Icons.chevron_right,
                      color: _getTextColor(context)),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                      color: _getTextColor(context), fontSize: 12 * scale),
                  weekendStyle: TextStyle(
                      color: _getTextColor(context), fontSize: 12 * scale),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                          top: 4,
                          right: 4,
                          child: _buildAttendanceMarker(day, scale));
                    }
                    return null;
                  },
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  final dayKey = DateTime(
                      selectedDay.year, selectedDay.month, selectedDay.day);
                  if (widget.attendanceData.containsKey(dayKey)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DayAttendanceDetail(
                          selectedDate: selectedDay,
                          attendanceData: widget.attendanceData[dayKey] ?? {},
                          timetable: widget.timetable,
                          courseMap: widget.courseMap,
                          regNo: widget.regNo,
                        ),
                      ),
                    );
                  } else {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  setState(() => _focusedDay = focusedDay);
                },
              ),
            ),
          ),
        ),
        // --- Achievements Footer ---
        Container(
          padding: EdgeInsets.all(rPadding),
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance Achievements',
                style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.bold,
                    color: _getTextColor(context)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAchievement('Current Streak',
                      '${widget.currentStreak}', Icons.local_fire_department, Colors.orange, scale),
                  _buildAchievement(
                      'Best Month', 'Sept', Icons.emoji_events, Colors.amber, scale),
                  _buildAchievement(
                      'Improvement', '+5%', Icons.trending_up, Colors.green, scale),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(String label, Color color, double scale) {
    return Row(
      children: [
        Container(
            width: 12 * scale,
            height: 12 * scale,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: _getTextColor(context), fontSize: 12 * scale)),
      ],
    );
  }

  Widget _buildMonthStat(String label, String? value, Color color, double scale) {
    return Column(
      children: [
        Text(
            value ?? '0',
            style: TextStyle(fontSize: 20 * scale, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12 * scale, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAttendanceMarker(DateTime day, double scale) {
    final dayKey = DateTime(day.year, day.month, day.day);
    if (!widget.attendanceData.containsKey(dayKey)) return const SizedBox();

    final dayAttendanceMap = widget.attendanceData[dayKey]!;

    bool hasAbsent = dayAttendanceMap.values.any((s) => s.toLowerCase() == 'absent');
    bool hasOd = dayAttendanceMap.values.any((s) => s.toLowerCase() == 'od');

    Color color;
    if (hasAbsent) {
      color = Colors.red;
    } else if (hasOd) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }
    return Container(
        width: 7 * scale,
        height: 7 * scale,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }

  Widget _buildAchievement(
      String title, String value, IconData icon, Color color, double scale) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8 * scale),
          decoration:
          BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24 * scale),
        ),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getTextColor(context),
                fontSize: 14 * scale)),
        Text(title, style: TextStyle(fontSize: 10 * scale, color: Colors.grey)),
      ],
    );
  }
}
