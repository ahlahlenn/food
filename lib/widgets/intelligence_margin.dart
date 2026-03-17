import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/food_entry.dart';

class IntelligenceMargin extends StatelessWidget {
  final FoodEntry entry;

  const IntelligenceMargin({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (entry.isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            Text(
              '${entry.calories}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: Colors.black87,
              ),
            ),
            Text(
              'kcal',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w300,
                color: Colors.black45,
              ),
            ),
            const SizedBox(height: 8),
            _MacroDot('P', entry.protein, Colors.red),
            _MacroDot('C', entry.carbs, Colors.amber),
            _MacroDot('F', entry.fat, Colors.blue),
          ],
        ],
      ),
    );
  }
}

class _MacroDot extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MacroDot(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color.withOpacity(value > 0 ? 0.8 : 0.2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${value}g',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
