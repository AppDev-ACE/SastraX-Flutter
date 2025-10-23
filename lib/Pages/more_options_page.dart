import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'home_page.dart';
import 'mess_menu_page.dart';
import 'LeaveApplication.dart';
import 'about_team_screen.dart';
import 'club_hub.dart';
import 'credits_page.dart';
import 'material_bot/material_bot.dart';
import 'material_bot/study_material_bot.dart';
import 'prof_cabin_screen.dart';
import 'paymenthistory.dart';
class MoreOptionsScreen extends StatelessWidget {
  final String token;
  final String url;
  final String regNo;

  const MoreOptionsScreen({
    super.key,
    required this.token,
    required this.url,
    required this.regNo,
  });

  // --- ✅ MODIFIED: This list now only contains options visible to EVERYONE ---
  static const List<Map<String, dynamic>> _baseOptions = [
    {
      'title': 'Credits',
      'subtitle': 'View Credits',
      'icon': Icons.assignment,
      'color': Colors.green,
      'route': 'credits',
    },
    {
      'title': 'Student Clubs',
      'subtitle': 'Explore clubs & societies',
      'icon': Icons.groups,
      'color': Colors.teal,
      'route': 'clubs',
    },
    // 'Mess Menu' & 'Leave Application' are removed and added conditionally
    {
      'title': 'About Team',
      'subtitle': 'Meet the developers',
      'icon': Icons.info_outline,
      'color': Colors.indigo,
      'route': 'about_team',
    },
    {
      'title': 'Study Material Bot',
      'subtitle': 'Chat for Course Materials',
      'icon': Icons.smart_toy_outlined,
      'color': Colors.orange,
      'route': 'material_bot',
    },
    {
      'title': 'Study Wise PYQ Bot',
      'subtitle': 'Find PYQs ',
      'icon': Icons.menu_book_outlined,
      'color': Colors.brown,
      'route': 'study_material_bot',
    },

    {
      'title': 'Know your Professor',
      'subtitle': 'Find Professor Cabin',
      'icon': Icons.person,
      'color': Colors.lightBlue,
      'route': 'know_your_professor',
    },
    {
      'title': 'Payment History',
      'subtitle': 'View your payment history',
      'icon': Icons.money,
      'color': Colors.lightBlue,
      'route': 'payment_history',
    },

  ];

  // --- Data blocks for conditional options ---
  static const Map<String, dynamic> _messMenuOption = {
    'title': 'Mess Menu',
    'subtitle': 'Check weekly food schedule',
    'icon': Icons.restaurant,
    'color': Colors.red,
    'route': 'mess',
  };

  // ✅ ADDED: Leave Application data block
  static const Map<String, dynamic> _leaveApplicationOption = {
    'title': 'Leave Application',
    'subtitle': 'Apply for leave',
    'icon': Icons.outbox,
    'color': Colors.purple,
    'route': 'leave_application',
  };


  @override
  Widget build(BuildContext context) {
    // --- ✅ MODIFIED: Logic now handles both conditional options ---
    final List<Map<String, dynamic>> displayedOptions = List.from(_baseOptions);

    // Read the parsed student info from the static cache
    final cache = DashboardScreen.dashboardCache;
    final studentInfo = cache?['studentInfo'] as Map<String, dynamic>? ?? {};
    print("The Student Info is : ${cache?['studentInfo']}");
    final isHosteler = (studentInfo['status'] ?? '').toLowerCase() == 'hosteler';

    // Conditionally add the options only for hostelers
    if (isHosteler) {
      // Insert Mess Menu at index 2
      displayedOptions.insert(2, _messMenuOption);
      // Insert Leave Application after Mess Menu (now at index 3)
      displayedOptions.insert(3, _leaveApplicationOption);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 210,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 0.95,
          ),
          // Use the new dynamic list
          itemCount: displayedOptions.length,
          itemBuilder: (ctx, i) => _OptionCard(
            data: displayedOptions[i],
            onTap: () => _handleTap(context, displayedOptions[i]['route'] as String),
            index: i,
          ),
        ),
      ),
    );
  }

  // --- (No changes needed in _handleTap) ---
  void _handleTap(BuildContext ctx, String route) {
    final cache = DashboardScreen.dashboardCache;
    final studentInfo = cache?['studentInfo'] as Map<String, dynamic>? ?? {};
    final isFemale = (studentInfo['gender'] ?? '').toLowerCase() == 'female';

    switch (route) {
      case 'credits':
        final List<dynamic> semGrades = cache?['semGrades'] as List<dynamic>? ?? [];
        final List<dynamic> cgpa = cache?['cgpa'] as List<dynamic>? ?? [];

        if (cache == null || semGrades.isEmpty || cgpa.isEmpty) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Data not loaded yet. Please visit the Home screen first.'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => CreditsScreen(
                token: token,
                url: url,
                regNo: regNo,
                initialSemGrades: semGrades,
                initialCgpa: cgpa,
              ),
            ),
          );
        }
        break;

      case 'about_team':
        Navigator.push(ctx, MaterialPageRoute(builder: (_) => AboutTeamScreen()));
        break;
      case 'clubs':
        Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ClubHubPage()));
        break;
        case 'know_your_professor':
        Navigator.push(ctx, MaterialPageRoute(builder: (_) =>  ProfessorCabinScreen()));
        break;

      case 'mess':
        Navigator.push(ctx, MaterialPageRoute(builder: (_) => MessMenuPage(
          url: url,
          isFemaleHosteler: isFemale,
        )));
        break;
      case 'leave_application':
        Navigator.push(ctx, MaterialPageRoute(builder: (_) => LeaveApplicationScreen(token: token , regNo: regNo, apiUrl: url,)));
        break;
      case 'payment_history':
        Navigator.push(ctx, MaterialPageRoute(builder: (_) => PaymentHistoryScreen(token: token , url: url,)));
        break;

      case 'material_bot':
        Navigator.push(ctx, MaterialPageRoute(builder: (_) => MaterialBot(url: url ,token: token)));
        break;
      case 'study_material_bot':
        Navigator.push(ctx, MaterialPageRoute(builder: (_) => StudyMaterialBot(url: url , token: token,)));
        break;

      default:
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('This feature is coming soon!')),
        );
        break;
    }
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.data,
    required this.onTap,
    required this.index,
  });

  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final Color color = data['color'] as Color;
    final onBackgroundColor = Theme.of(context).colorScheme.onBackground;

    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          return Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.30)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      data['icon'],
                      size: 36,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data['title'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: onBackgroundColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['subtitle'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: onBackgroundColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().scale(
              delay: (index * 50).ms,
              curve: Curves.elasticOut,
              duration: 400.ms
          );
        },
      ),
    );
  }
}

