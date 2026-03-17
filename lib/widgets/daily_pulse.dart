import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class DailyPulse extends StatelessWidget {
  final int currentCalories;
  final int goal;
  final int protein;
  final int carbs;
  final int fat;
  final int streak;

  const DailyPulse({
    super.key,
    required this.currentCalories,
    required this.goal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentCalories / goal).clamp(0.0, 1.0);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Daily Pulse label
              Text(
                '✦ Daily Pulse',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 1, height: 12, color: Colors.black12),
              const SizedBox(width: 16),
              // Calories
              Text(
                '$currentCalories',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                ' / $goal',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 1, height: 12, color: Colors.black12),
              const SizedBox(width: 16),
              // Macro dots
              _MacroIndicator(color: Colors.red, value: protein),
              const SizedBox(width: 8),
              _MacroIndicator(color: Colors.amber, value: carbs),
              const SizedBox(width: 8),
              _MacroIndicator(color: Colors.blue, value: fat),
              const SizedBox(width: 16),
              Container(width: 1, height: 12, color: Colors.black12),
              const SizedBox(width: 16),
              // Streak
              if (streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${streak}d',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroIndicator extends StatelessWidget {
  final Color color;
  final int value;

  const _MacroIndicator({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.withOpacity(value > 0 ? 0.9 : 0.2),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${value}g',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
