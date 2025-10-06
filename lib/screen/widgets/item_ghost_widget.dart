import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';

class GhostWidget extends StatelessWidget {
  final bool isDarkMode;
  final String text;
  final double height;
  final double width;
  final Color? borderColor;
  final Color? backgroundColor;

  const GhostWidget({
    super.key,
    required this.isDarkMode,
    this.text = "Drop task here",
    this.height = 80,
    this.width = 284,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBorderColor = Colors.grey.shade500;
    final defaultBackgroundColor = isDarkMode
        ? Colors.grey.shade800.withOpacity(0.5)
        : Colors.grey.shade200.withOpacity(0.5);

    return DottedBorder(
      borderType: BorderType.RRect,
      radius: const Radius.circular(12),
      padding: EdgeInsets.zero,
      dashPattern: const [8, 4],
      color: borderColor ?? defaultBorderColor,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: backgroundColor ?? defaultBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.grey.shade800,
            ),
          ),
        ),
      ),
    );
  }
}