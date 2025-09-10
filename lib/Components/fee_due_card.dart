// fee_due_card.dart
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
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: themeProvider.cardBackgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: themeProvider.isDarkMode
                  ? AppTheme.neonBlue.withOpacity(0.6)
                  : AppTheme.primaryBlue.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: themeProvider.isDarkMode
                ? [
              BoxShadow(
                color: AppTheme.neonBlue.withOpacity(0.6),
                blurRadius: 12,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ]
                : [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: feeDue > 0
                        ? themeProvider.isDarkMode
                        ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)]
                        : [Colors.red[400]!, Colors.red[600]!]
                        : themeProvider.isDarkMode
                        ? [AppTheme.neonBlue, AppTheme.electricBlue]
                        : [Colors.green[400]!, Colors.green[600]!],
                  ),
                  boxShadow: themeProvider.isDarkMode
                      ? [
                    BoxShadow(
                      color: (feeDue > 0
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
                  size: 25,
                  color: themeProvider.isDarkMode ? Colors.black : Colors.white,
                ),
              ),
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
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  feeDue > 0 ? '₹${feeDue.toInt()}' : 'Paid',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: feeDue > 0
                        ? (themeProvider.isDarkMode
                        ? const Color(0xFFFF6B6B)
                        : Colors.red)
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
