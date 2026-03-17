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
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PulseItem(
                label: '${currentCalories}',
                sublabel: '/$goal',
                highlight: true,
              ),
              Container(width: 1, height: 16, color: Colors.black12),
              _PulseItem(
                label: '${protein}g',
                sublabel: 'P',
                color: Colors.red.shade400,
              ),
              Container(width: 1, height: 16, color: Colors.black12),
              _PulseItem(
                label: '${carbs}g',
                sublabel: 'C',
                color: Colors.amber.shade600,
              ),
              Container(width: 1, height: 16, color: Colors.black12),
              _PulseItem(
                label: '${fat}g',
                sublabel: 'F',
                color: Colors.blue.shade400,
              ),
              if (streak > 0) ...[
                Container(width: 1, height: 16, color: Colors.black12),
                _PulseItem(
                  label: '${streak}d',
                  sublabel: 'streak',
                  color: Colors.black54,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseItem extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color? color;
  final bool highlight;

  const _PulseItem({
    required this.label,
    required this.sublabel,
    this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: highlight ? 14 : 12,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
              color: color ?? Colors.black87,
            ),
          ),
          Text(
            sublabel,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
