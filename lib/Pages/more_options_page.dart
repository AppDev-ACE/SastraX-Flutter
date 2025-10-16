import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'LeaveApplication.dart';
import 'about_team_screen.dart';
import 'club_hub.dart';
import 'credits_page.dart';
import 'internals_page.dart';

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

  static const List<Map<String, dynamic>> _options = [
    {
      'title': 'Student Internals',
      'subtitle': 'View marks & grades',
      'icon': Icons.assessment,
      'color': Colors.blue,
      'route': 'internals',
    },
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
    {
      'title': 'Leave Application',
      'subtitle': 'Apply for leave',
      'icon': Icons.outbox,
      'color': Colors.purple,
      'route': 'leave_application',
    },
    {
      'title': 'About Team',
      'subtitle': 'Meet the developers',
      'icon': Icons.info_outline,
      'color': Colors.indigo,
      'route': 'about_team',
    },
  ];

  @override
  Widget build(BuildContext context) {
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
          itemCount: _options.length,
          itemBuilder: (ctx, i) => _OptionCard(
            data: _options[i],
            onTap: () => _handleTap(context, _options[i]['route'] as String),
            index: i,
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext ctx, String route) {
    switch (route) {
      case 'internals':
        Navigator.push(
            ctx,
            MaterialPageRoute(
                builder: (_) =>
                    InternalsPage(token: token, url: url, regNo: regNo)));
        break;
      case 'credits':
        Navigator.push(
            ctx,
            MaterialPageRoute(
                builder: (_) =>
                    CreditsScreen(token: token, url: url, regNo: regNo)));
        break;
      case 'about_team':
        Navigator.push(
            ctx, MaterialPageRoute(builder: (_) => AboutTeamScreen()));
        break;
      case 'clubs':
        Navigator.push(
            ctx, MaterialPageRoute(builder: (_) => const ClubHubPage()));
        break;
      case 'leave_application':
      // Corrected navigation to the screen widget
        Navigator.push(
            ctx, MaterialPageRoute(builder: (_) => const LeaveApplicationScreen()));
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
              duration: 400.ms);
        },
      ),
    );
  }
}