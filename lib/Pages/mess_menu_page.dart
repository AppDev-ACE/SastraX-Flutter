import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/theme_model.dart';
import '../services/ApiEndpoints.dart';
import '../components/theme_toggle_button.dart';

class MessMenuPage extends StatefulWidget {
  final String url;
  final bool isFemaleHosteler;

  const MessMenuPage({
    super.key,
    required this.url,
    required this.isFemaleHosteler,
  });

  static Map<String, List<dynamic>> menuCache = {};

  @override
  State<MessMenuPage> createState() => MessMenuPageState();
}

class MessMenuPageState extends State<MessMenuPage> {
  final List<String> weekDays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  late PageController _pageController;
  late final ApiEndpoints api;
  late String _menuCacheKey;

  List<dynamic> _fullMenu = [];
  List<dynamic> _filtered = [];
  late bool isLoading;

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

    // --- ✅ CORRECTED WEEK CALCULATION ---
    // Instead of calculating the week of the month, we now calculate
    // the week within the continuous 4-week mess cycle.
    selectedWeek = _getMenuWeekCycle(now).toString();
    print("Calculated Menu Cycle Week: $selectedWeek");
    // --- END CORRECTION ---

    _menuCacheKey = widget.isFemaleHosteler ? 'messMenuGirls' : 'messMenu';

    if (MessMenuPage.menuCache.containsKey(_menuCacheKey)) {
      _fullMenu = MessMenuPage.menuCache[_menuCacheKey]!;
      isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyWeekFilter();
      });
    } else {
      isLoading = true;
      _fetchMenu();
    }
  }

  // ❌ REMOVED: The old weekOfMonth function which was causing the issue.

  // --- ✅ ADDED: New helper functions to calculate the correct menu cycle week ---
  /// Calculates the day number within the year (e.g., Feb 1st is day 32).
  int _dayOfYear(DateTime date) {
    return date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  }

  /// Calculates which week of the 4-week menu cycle the current date falls into.
  int _getMenuWeekCycle(DateTime date) {
    final dayOfYear = _dayOfYear(date);
    // Determine the week number of the year.
    final weekOfYear = (dayOfYear / 7).ceil();
    // Map the week of the year to a repeating 1-4 cycle.
    return (weekOfYear - 1) % 4 + 1;
  }
  // --- END ADDITIONS ---

  Future<void> _fetchMenu() async {
    if (MessMenuPage.menuCache.containsKey(_menuCacheKey)) {
      _fullMenu = MessMenuPage.menuCache[_menuCacheKey]!;
      _applyWeekFilter();
      return;
    }

    final String endpointUrl =
    widget.isFemaleHosteler ? api.messMenuGirls : api.messMenu;

    print("Mess menu '$_menuCacheKey' not in cache. Fetching from API: $endpointUrl");

    try {
      final response = await http.get(Uri.parse(endpointUrl));

      if (response.statusCode == 200) {
        final List<dynamic> menuData = jsonDecode(response.body);
        _fullMenu = menuData;
        MessMenuPage.menuCache[_menuCacheKey] = _fullMenu;
        print("Successfully fetched and cached '$_menuCacheKey' menu.");
        _applyWeekFilter();
      } else {
        throw Exception('Failed to load menu. Status code: ${response.statusCode}');
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
    _filtered = _fullMenu
        .where((d) => d['week'].toString() == selectedWeek)
        .toList()
      ..sort((a, b) => _dayIndex(a['day']).compareTo(_dayIndex(b['day'])));

    if (mounted) {
      setState(() => isLoading = false);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final todayPos = _filtered.indexWhere((d) =>
      d['day'].toString().substring(0, 3).toUpperCase() ==
          selectedDayAbbr);
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
        appBar: AppBar(
          title: const Text('Mess Menu'),
          centerTitle: true,
          backgroundColor:
          theme.isDarkMode ? AppTheme.darkBackground : AppTheme.primaryBlue,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ThemeToggleButton(
                isDarkMode: theme.isDarkMode,
                onToggle: theme.toggleTheme,
              ),
            )
          ],
        ),
        backgroundColor: theme.backgroundColor,
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'No menu found for the current cycle (Week $selectedWeek).',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textSecondaryColor),
              ),
            ),
          )
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
                  itemBuilder: (_, idx) => _buildDayMenu(idx, theme),
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
        _mealCard(
            'Breakfast', (day['breakfast'] as List<dynamic>).join(', '), theme),
        _mealCard('Lunch', (day['lunch'] as List<dynamic>).join(', '), theme),
        _mealCard('Snacks', (day['snacks'] as List<dynamic>).join(', '), theme),
        _mealCard('Dinner', (day['dinner'] as List<dynamic>).join(', '), theme),
      ],
    );
  }

  Widget _dayRow(ThemeProvider theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: weekDays.map((abbr) {
        final isSel = selectedDayAbbr == abbr;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              final newPage = _filtered.indexWhere((d) =>
              (d['day'] as String?)?.substring(0, 3).toUpperCase() ==
                  abbr);

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
    final now = TimeOfDay.now();

    bool inRange(TimeOfDay start, TimeOfDay end) {
      final nowMins = now.hour * 60 + now.minute;
      final startMins = start.hour * 60 + start.minute;
      final endMins = end.hour * 60 + end.minute;
      return nowMins >= startMins && nowMins <= endMins;
    }

    switch (mealName) {
      case 'Breakfast':
        return inRange(const TimeOfDay(hour: 7, minute: 30),
            const TimeOfDay(hour: 9, minute: 0));
      case 'Lunch':
        return inRange(const TimeOfDay(hour: 12, minute: 0),
            const TimeOfDay(hour: 14, minute: 0));
      case 'Snacks':
        return inRange(const TimeOfDay(hour: 17, minute: 30),
            const TimeOfDay(hour: 18, minute: 30));
      case 'Dinner':
        return inRange(const TimeOfDay(hour: 19, minute: 30),
            const TimeOfDay(hour: 21, minute: 0));
      default:
        return false;
    }
  }

  Widget _mealCard(String title, String menu, ThemeProvider theme) {
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

