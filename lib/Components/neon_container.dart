import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/theme_model.dart';

class NeonContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? color;
  final Color borderColor;
  final List<BoxShadow>? boxShadow;

  const NeonContainer({
    Key? key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.color,
    required this.borderColor,
    this.boxShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color ??
                (themeProvider.isDarkMode
                    ? AppTheme.darkSurface
                    : Colors.white),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: borderColor.withOpacity(
                  themeProvider.isDarkMode ? 0.5 : 0.2), // softer border
              width: 1.2,
            ),
            boxShadow: boxShadow ??
                (themeProvider.isDarkMode
                    ? [
                  BoxShadow(
                    color: borderColor.withOpacity(0.25), // much softer glow
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25), // lighter inner shadow
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
                    : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]),
          ),
          child: child,
        );
      },
    );
  }
}
