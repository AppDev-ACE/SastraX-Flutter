import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/theme_model.dart';

class FeeDueCard extends StatelessWidget {
  final double feeDue;

  const FeeDueCard({Key? key, required this.feeDue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final hasDue = feeDue > 0;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: themeProvider.cardBackgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? AppTheme.neonBlue.withOpacity(0.3)
                  : AppTheme.primaryBlue.withOpacity(0.3),
              width: 1.5,
            ),
            // FIX: Shadow is now a single glow effect in dark mode for consistency.
            boxShadow: isDark
                ? [
              BoxShadow(
                color: (hasDue ? Colors.red.shade400 : AppTheme.neonBlue)
                    .withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ]
                : [
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: hasDue
                        ? isDark
                        ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)]
                        : [Colors.red[400]!, Colors.red[600]!]
                        : isDark
                        ? [AppTheme.neonBlue, AppTheme.electricBlue]
                        : [Colors.green[400]!, Colors.green[600]!],
                  ),
                  boxShadow: isDark
                      ? [
                    BoxShadow(
                      color: (hasDue
                          ? const Color(0xFFFF6B6B)
                          : AppTheme.neonBlue)
                          .withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                      : null,
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  size: 22,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Fee Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  hasDue ? '₹${feeDue.toInt()}' : 'Paid',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: hasDue
                        ? (isDark ? const Color(0xFFFF6B6B) : Colors.red)
                        : themeProvider.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}