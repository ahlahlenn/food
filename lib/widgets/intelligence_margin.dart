import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/food_entry.dart';

class IntelligenceMargin extends StatelessWidget {
  final FoodEntry entry;

  const IntelligenceMargin({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (entry.isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black26,
                ),
              ),
            )
          else ...[
            // Calories - handwritten style
            Text(
              '${entry.calories}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
            Text(
              'kcal',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                color: Colors.black38,
              ),
            ),
            const SizedBox(height: 8),
            // Macros
            _MacroDot('P', entry.protein, Colors.red),
            _MacroDot('C', entry.carbs, Colors.amber.shade600),
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
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: value > 0 ? color : color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${value}g',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: value > 0 ? Colors.black54 : Colors.black26,
            ),
          ),
        ],
      ),
    );
  }
}
