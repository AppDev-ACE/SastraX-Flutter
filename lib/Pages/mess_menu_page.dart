import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/theme_model.dart';
import '../services/ApiEndpoints.dart'; // Make sure this path is correct

class MessMenuPage extends StatefulWidget {
  final String url;
  const MessMenuPage({super.key, required this.url});

  @override
  State<MessMenuPage> createState() => _MessMenuPageState();
}

class _MessMenuPageState extends State<MessMenuPage> {
  final List<String> weekDays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  late final PageController _pageController;
  late final ApiEndpoints api;
  List<dynamic> _fullMenu = [];
  List<dynamic> _filtered = [];
  bool isLoading = true;

  late String selectedWeek; // "1".."4"
  late String selectedDayAbbr;

  @override
  void initState() {
    super.initState();
    api = ApiEndpoints(widget.url);
    final now = DateTime.now();
    final todayIdx = now.weekday % 7; // Sunday = 0
    selectedDayAbbr = weekDays[todayIdx];
    _pageController = PageController(initialPage: todayIdx);
    selectedWeek = weekOfMonth(now).toString();
    _fetchMenu();
  }

  int weekOfMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final before = firstDay.weekday % 7;
    final week = ((before + date.day - 1) ~/ 7) + 1;
    return (week - 1) % 4 + 1;
  }

  Future<void> _fetchMenu() async {
    try {
      final res = await http.get(Uri.parse(api.messMenu));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      _fullMenu = jsonDecode(res.body);
      _applyWeekFilter();
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn’t load menu: $e')),
        );
      }
    }
  }

  void _applyWeekFilter() {
    _filtered = _fullMenu
        .where((d) => d['week'].toString() == selectedWeek)
        .toList()
      ..sort((a, b) => _dayIndex(a['day']).compareTo(_dayIndex(b['day'])));

    setState(() => isLoading = false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final todayPos = _filtered.indexWhere((d) =>
      d['day'].toString().substring(0, 3).toUpperCase() == selectedDayAbbr);
      if (_pageController.hasClients && todayPos != -1) {
        _pageController.jumpToPage(todayPos);
      }
    });
  }

  int _dayIndex(String day) =>
      weekDays.indexOf(day.substring(0, 3).toUpperCase());

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (_, theme, __) => Scaffold(
        backgroundColor: theme.backgroundColor,
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
              ? const Center(child: Text('No menu found for this week'))
              : Column(
            children: [
              const SizedBox(height: 12), // small space at top
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _dayRow(theme),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filtered.length,
                  itemBuilder: (_, idx) =>
                      _buildDayMenu(idx, theme),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayMenu(int idx, ThemeProvider theme) {
    final day = _filtered[idx];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        _mealCard('Breakfast', day['breakfast'].join(', '), theme),
        _mealCard('Lunch', day['lunch'].join(', '), theme),
        _mealCard('Snacks', day['snacks'].join(', '), theme),
        _mealCard('Dinner', day['dinner'].join(', '), theme),
      ],
    );
  }

  /// ✅ All days shown in a single row
  Widget _dayRow(ThemeProvider theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: weekDays.map((abbr) {
        final isSel = selectedDayAbbr == abbr;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              final newPage = _filtered.indexWhere((d) =>
              d['day'].toString().substring(0, 3).toUpperCase() == abbr);
              if (newPage != -1) {
                setState(() => selectedDayAbbr = abbr);
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(newPage);
                }
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSel
                    ? (theme.isDarkMode
                    ? Colors.amber[300]
                    : Colors.blueAccent)
                    : theme.cardBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  abbr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSel
                        ? (theme.isDarkMode ? Colors.black : Colors.white)
                        : theme.textColor,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _isCurrentMeal(String mealName) {
    final now = TimeOfDay.now();

    bool inRange(TimeOfDay start, TimeOfDay end) {
      final nowMins = now.hour * 60 + now.minute;
      final startMins = start.hour * 60 + start.minute;
      final endMins = end.hour * 60 + end.minute;
      return nowMins >= startMins && nowMins <= endMins;
    }

    switch (mealName) {
      case 'Breakfast':
        return inRange(
            const TimeOfDay(hour: 7, minute: 30),
            const TimeOfDay(hour: 9, minute: 0));
      case 'Lunch':
        return inRange(
            const TimeOfDay(hour: 12, minute: 0),
            const TimeOfDay(hour: 14, minute: 0));
      case 'Snacks':
        return inRange(
            const TimeOfDay(hour: 17, minute: 30),
            const TimeOfDay(hour: 18, minute: 30));
      case 'Dinner':
        return inRange(
            const TimeOfDay(hour: 19, minute: 30),
            const TimeOfDay(hour: 21, minute: 0));
      default:
        return false;
    }
  }

  Widget _mealCard(String title, String menu, ThemeProvider theme) {
    final palette = {
      'Breakfast': {
        'color': theme.isDarkMode
            ? const Color(0xFFFFD93D)
            : Colors.orange.shade300,
        'icon': Icons.wb_sunny,
        'gradient': LinearGradient(
          colors: [Colors.orange.shade100, Colors.orange.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
      'Lunch': {
        'color': theme.isDarkMode
            ? AppTheme.neonBlue
            : Colors.green.shade300,
        'icon': Icons.lunch_dining,
        'gradient': LinearGradient(
          colors: [Colors.green.shade100, Colors.green.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
      'Snacks': {
        'color': theme.isDarkMode
            ? const Color(0xFFFF6B6B)
            : Colors.purple.shade300,
        'icon': Icons.local_cafe,
        'gradient': LinearGradient(
          colors: [Colors.purple.shade100, Colors.purple.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
      'Dinner': {
        'color': theme.isDarkMode
            ? AppTheme.electricBlue
            : Colors.blue.shade300,
        'icon': Icons.dinner_dining,
        'gradient': LinearGradient(
          colors: [Colors.blue.shade100, Colors.blue.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
    }[title]!;

    final isCurrent = _isCurrentMeal(title);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent
              ? AppTheme.neonBlue
              : (theme.isDarkMode
              ? (palette['color'] as Color).withOpacity(0.3)
              : AppTheme.neonBlue.withOpacity(0.3)),
          width: isCurrent ? 3 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
        gradient: palette['gradient'] as LinearGradient,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: palette['color'] as Color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                palette['icon'] as IconData,
                color: theme.isDarkMode ? Colors.black : Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    menu,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
