import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/theme_model.dart';
import '../services/ApiEndpoints.dart';

class MessMenuPage extends StatefulWidget {
  final String url;
  const MessMenuPage({super.key, required this.url});

  // ✅ 1. CACHE MOVED HERE
  /// This holds the menu after the first fetch to prevent re-fetching.
  static List<dynamic>? menuCache;

  @override
  State<MessMenuPage> createState() => MessMenuPageState();
}

class MessMenuPageState extends State<MessMenuPage> {
  // ❌ 1. STATIC CACHE VARIABLE REMOVED FROM HERE

  final List<String> weekDays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  late PageController _pageController;
  late final ApiEndpoints api;

  // ✅ 2. STATE INITIALIZED FROM WIDGET'S CACHE
  List<dynamic> _fullMenu = MessMenuPage.menuCache ?? [];
  List<dynamic> _filtered = [];
  bool isLoading = MessMenuPage.menuCache == null;

  late String selectedWeek;
  late String selectedDayAbbr;

  @override
  void initState() {
    super.initState();
    api = ApiEndpoints(widget.url);
    final now = DateTime.now();
    final todayIdx = now.weekday % 7;
    selectedDayAbbr = weekDays[todayIdx];
    _pageController = PageController(initialPage: todayIdx);
    selectedWeek = weekOfMonth(now).toString();

    // ✅ 3. CACHE-AWARE LOADING
    if (MessMenuPage.menuCache == null) {
      // Cache is empty, fetch from Firebase
      _fetchMenu();
    } else {
      // Cache exists, just apply filters
      _applyWeekFilter();
    }
  }

  int weekOfMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final before = firstDay.weekday % 7;
    final week = ((before + date.day - 1) ~/ 7) + 1;
    return (week - 1) % 4 + 1;
  }

  // ✅ 4. POPULATE WIDGET'S CACHE
  Future<void> _fetchMenu() async {
    // Safety check
    if (MessMenuPage.menuCache != null) {
      _fullMenu = MessMenuPage.menuCache!;
      _applyWeekFilter();
      return;
    }

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('cache')
          .doc('messMenu')
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        if (data.containsKey('menu') && data['menu'] is List) {
          _fullMenu = data['menu'] as List<dynamic>;
          MessMenuPage.menuCache = _fullMenu; // ✅ POPULATE THE CACHE
          _applyWeekFilter();
        } else {
          throw Exception("'menu' field is missing or not a list in the document.");
        }
      } else {
        throw Exception("The 'messMenu' document was not found in the 'cache' collection.");
      }
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
    // ... (function is identical)
    _filtered = _fullMenu
        .where((d) => d['week'].toString() == selectedWeek)
        .toList()
      ..sort((a, b) => _dayIndex(a['day']).compareTo(_dayIndex(b['day'])));

    if (mounted) {
      setState(() => isLoading = false);
    }

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
    // ... (build method is identical)
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
              const SizedBox(height: 12),
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
    // ... (build method is identical)
    final day = _filtered[idx];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        _mealCard('Breakfast', (day['breakfast'] as List<dynamic>).join(', '), theme),
        _mealCard('Lunch', (day['lunch'] as List<dynamic>).join(', '), theme),
        _mealCard('Snacks', (day['snacks'] as List<dynamic>).join(', '), theme),
        _mealCard('Dinner', (day['dinner'] as List<dynamic>).join(', '), theme),
      ],
    );
  }

  Widget _dayRow(ThemeProvider theme) {
    // ... (build method is identical)
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: weekDays.map((abbr) {
        final isSel = selectedDayAbbr == abbr;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              final newPage = _filtered.indexWhere((d) =>
              (d['day'] as String?)?.substring(0, 3).toUpperCase() == abbr);

              if (newPage != -1) {
                setState(() => selectedDayAbbr = abbr);
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(newPage);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Menu for $abbr is not available this week.'),
                    duration: const Duration(seconds: 1),
                  ),
                );
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
    // ... (function is identical)
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
    // ... (build method is identical)
    final Map<String, Color> mealColors = {
      'Breakfast': Colors.amber.shade300,
      'Lunch': Colors.lightGreen.shade300,
      'Snacks': Colors.deepOrange.shade300,
      'Dinner': Colors.blue.shade300,
    };

    final palette = {
      'Breakfast': {'icon': Icons.wb_sunny},
      'Lunch': {'icon': Icons.lunch_dining},
      'Snacks': {'icon': Icons.local_cafe},
      'Dinner': {'icon': Icons.dinner_dining},
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
              ? AppTheme.neonBlue.withOpacity(0.3)
              : AppTheme.primaryBlue.withOpacity(0.3)),
          width: isCurrent ? 3 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
        color: mealColors[title]!,
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
                color: mealColors[title]!.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                palette['icon'] as IconData,
                color: Colors.white,
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