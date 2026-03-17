import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _dailyGoal = 2000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildWelcomePage(),
                  _buildGoalPage(),
                ],
              ),
            ),
            _buildBottom(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Simple icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Nourish',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Simple. Private. Your nutrition journal.',
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Daily calorie goal',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 32),
          // Goal display
          Text(
            '$_dailyGoal',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 56,
              fontWeight: FontWeight.w300,
              color: const Color(0xFF6366F1),
            ),
          ),
          Text(
            'kcal',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 32),
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6366F1),
              inactiveTrackColor: Colors.black12,
              thumbColor: const Color(0xFF6366F1),
              overlayColor: const Color(0xFF6366F1).withOpacity(0.1),
            ),
            child: Slider(
              value: _dailyGoal.toDouble(),
              min: 1200,
              max: 4000,
              divisions: 28,
              onChanged: (value) => setState(() => _dailyGoal = value.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1200', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.black38)),
              Text('4000', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.black38)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottom() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button or spacer
          if (_currentPage > 0)
            TextButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Text(
                'Back',
                style: GoogleFonts.inter(color: Colors.black45),
              ),
            )
          else
            const SizedBox(width: 60),
          // Dots
          Row(
            children: List.generate(2, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? const Color(0xFF6366F1)
                      : Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          // Next/Start button
          ElevatedButton(
            onPressed: () async {
              if (_currentPage == 0) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('daily_goal', _dailyGoal);
                await prefs.setBool('onboarding_complete', true);
                widget.onComplete();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              _currentPage == 0 ? 'Next' : 'Start',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
