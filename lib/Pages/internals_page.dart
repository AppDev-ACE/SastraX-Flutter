// internals_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'subjectDetailPage.dart';
import 'dart:math';
import '../models/theme_model.dart';

class InternalsPage extends StatelessWidget {
  final String token;
  final String url;
  final String regNo;

  const InternalsPage({
    Key? key,
    required this.token,
    required this.url,
    required this.regNo,
  }) : super(key: key);

  // Dummy data (same as your example)
  final List<Map<String, dynamic>> subjects = const [
    {
      "name": "Data Structures",
      "code": "CSE201",
      "maxInternals": 50,
      "maxEndSem": 100,
      "cia1": 46,
      "cia2": null,
      "cia3": null,
    },
    {
      "name": "Operating Systems",
      "code": "CSE202",
      "maxInternals": 50,
      "maxEndSem": 100,
      "cia1": null,
      "cia2": null,
      "cia3": null,
    },
    {
      "name": "Database Systems",
      "code": "CSE203",
      "maxInternals": 50,
      "maxEndSem": 100,
      "cia1": null,
      "cia2": null,
      "cia3": null,
    },
  ];

  // Convert CIA mark (out of 50) to out-of-20 equivalent
  double _to20(int markOutOf50) => markOutOf50 * 0.4;

  // Compute best 2-of-3 on 20-scale and return sumOutOf40
  double computeBestTwoOutOf40(int? cia1, int? cia2, int? cia3) {
    final List<double> list = [];
    if (cia1 != null) list.add(_to20(cia1));
    if (cia2 != null) list.add(_to20(cia2));
    if (cia3 != null) list.add(_to20(cia3));
    if (list.isEmpty) return 0.0;
    list.sort();
    // pick best two (if only 1 present, take that)
    if (list.length == 1) return list[0];
    return list.sublist(max(0, list.length - 2)).reduce((a, b) => a + b);
  }

  @override
  Widget build(BuildContext context) {
    // Consume the ThemeProvider
    return Consumer<ThemeProvider>(
      builder: (_, theme, __) {
        final isDark = theme.isDarkMode;

        return Scaffold(
          // Set theme-aware background color
          backgroundColor:
          isDark ? AppTheme.darkBackground : Colors.grey[100],
          appBar: AppBar(
            title: const Text('Internal Marks'),
            // Set theme-aware AppBar color
            backgroundColor:
            isDark ? AppTheme.darkBackground : AppTheme.primaryBlue,
            // Set foregroundColor to style back arrow and title
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final cia1 = subject["cia1"] as int?;
              final cia2 = subject["cia2"] as int?;
              final cia3 = subject["cia3"] as int?;
              final bestTwoOutOf40 = computeBestTwoOutOf40(cia1, cia2, cia3);
              final internalOutOf50 =
                  bestTwoOutOf40 + 10; // +10 assignment baseline

              // This Card is now styled like your NeonContainer
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: isDark ? AppTheme.darkSurface : Colors.white,
                elevation: isDark ? 0 : 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  // Add a neon-like border in dark mode
                  side: isDark
                      ? BorderSide(
                      color: AppTheme.neonBlue.withOpacity(0.5), width: 1)
                      : BorderSide.none,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // TODO: Ensure SubjectDetailPage is also theme-aware
                        builder: (_) => SubjectDetailPage(
                          subjectName: subject["name"],
                          subjectCode: subject["code"],
                          maxInternals: subject["maxInternals"],
                          maxEndSem: subject["maxEndSem"],
                          cia1: cia1,
                          cia2: cia2,
                          cia3: cia3,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row: name and code
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                subject["name"],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  // Theme-aware text color
                                  color: isDark
                                      ? AppTheme.neonBlue
                                      : AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                            Text(
                              subject["code"],
                              style: TextStyle(
                                fontSize: 14,
                                // Theme-aware text color
                                color: isDark ? Colors.white70 : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // CIA boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Pass the theme to the helper widget
                            _buildCiaBox("CIA 1", cia1, theme),
                            _buildCiaBox("CIA 2", cia2, theme),
                            _buildCiaBox("CIA 3", cia3, theme),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Current Status label & progress
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Current Status",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                // Theme-aware text color
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              "${bestTwoOutOf40.toStringAsFixed(1)}/40",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                // Theme-aware text color
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: (bestTwoOutOf40 / 40).clamp(0.0, 1.0),
                            // Theme-aware colors
                            backgroundColor: isDark
                                ? AppTheme.darkBackground.withOpacity(0.7)
                                : AppTheme.primaryBlue.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark
                                  ? AppTheme.neonBlue
                                  : AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtext with internal out of 50
                        Text(
                          "Internal Total: ${internalOutOf50.toStringAsFixed(1)}/50  •  Assignment: 10",
                          // Theme-aware text color
                          style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.grey[700],
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Helper widget updated to accept the theme
  Widget _buildCiaBox(String label, dynamic value, ThemeProvider theme) {
    final isDark = theme.isDarkMode;
    final bool hasValue = value != null;

    Color getBackgroundColor() {
      if (isDark) {
        return hasValue
            ? AppTheme.darkSurface
            : AppTheme.darkBackground.withOpacity(0.7);
      } else {
        return hasValue ? Colors.white : Colors.blue.shade50;
      }
    }

    Color getBorderColor() {
      if (isDark) {
        return hasValue
            ? AppTheme.neonBlue
            : AppTheme.neonBlue.withOpacity(0.2);
      } else {
        return Colors.blue.shade200;
      }
    }

    Color getTextColor() {
      if (isDark) {
        return hasValue ? Colors.white : Colors.white54;
      } else {
        return hasValue ? Colors.black87 : Colors.blueGrey;
      }
    }

    return Container(
      width: 96,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: getBackgroundColor(),
        border: Border.all(color: getBorderColor()),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        value?.toString() ?? label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: getTextColor(),
        ),
      ),
    );
  }
}