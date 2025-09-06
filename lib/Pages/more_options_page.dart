import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sastra_x/Pages/home_page.dart'; // Make sure this path is correct

// Import the dedicated pages for each option.
import 'SGPA_calculator.dart';
import 'about_team_screen.dart';
import 'club_hub.dart';
import 'credits_page.dart';
import 'internals_page.dart';


class MoreOptionsScreen extends StatelessWidget {
  const MoreOptionsScreen({super.key});

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
      'title': 'SGPA calculator',
      'subtitle': 'Calculate your SGPA',
      'icon': Icons.calculate_sharp,
      'color': Colors.purple,
      'route': 'sgpa',
    },
    {
      'title': 'Student Clubs',
      'subtitle': 'Explore clubs & societies',
      'icon': Icons.groups,
      'color': Colors.teal,
      'route': 'clubs',
    },
    {
      'title': 'Library',
      'subtitle': 'Digital library access',
      'icon': Icons.library_books,
      'color': Colors.brown,
      'route': 'library',
    },
    {
      'title': 'Transport',
      'subtitle': 'Bus routes & timings',
      'icon': Icons.directions_bus,
      'color': Colors.orange,
      'route': 'transport',
    },
    {
      'title': 'College Events',
      'subtitle': 'Stay updated on events',
      'icon': Icons.event,
      'color': Colors.pink,
      'route': 'events',
    },
    {
      'title': 'About Team',
      'subtitle': 'Meet the developers',
      'icon': Icons.info_outline,
      'color': Colors.indigo,
      'route': 'about_team',
    },
    {
      'title': 'Settings',
      'subtitle': 'App preferences',
      'icon': Icons.settings,
      'color': Colors.grey,
      'route': 'settings',
    },
    {
      'title': 'Help & Support',
      'subtitle': 'Get assistance',
      'icon': Icons.help_outline,
      'color': Colors.red,
      'route': 'help',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('More Options'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Replace the current screen with the HomePage
            Navigator.pushReplacement(
              context,
              // THIS IS THE FIX: Changed MoreOptionsScreen() to HomePage()
              MaterialPageRoute(builder: (context) => const HomePage(regNo: "regNo", url: '',)),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
        Navigator.push(ctx, MaterialPageRoute(builder: (_) => InternalsPage()));
        break;
      case 'credits':
        Navigator.push(
            ctx, MaterialPageRoute(builder: (_) => const CreditsScreen()));
        break;
      case 'sgpa':
        Navigator.push(
            ctx, MaterialPageRoute(builder: (_) => const SgpaCalculator()));
        break;
      case 'about_team':
        Navigator.push(
            ctx, MaterialPageRoute(builder: (_) => AboutTeamScreen()));
        break;
      case 'clubs':
        Navigator.push(ctx, MaterialPageRoute(builder: (_) =>  ClubHubPage()));

      default:
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