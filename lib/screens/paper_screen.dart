import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../models/food_entry.dart';
import '../providers/entries_provider.dart';
import '../widgets/intelligence_margin.dart';
import '../widgets/daily_pulse.dart';
import '../widgets/ink_droplet_fab.dart';

class PaperScreen extends ConsumerStatefulWidget {
  const PaperScreen({super.key});

  @override
  ConsumerState<PaperScreen> createState() => _PaperScreenState();
}

class _PaperScreenState extends ConsumerState<PaperScreen> {
  final TextEditingController _textController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  final List<String> _spokenWords = [];
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() {
    _spokenWords.clear();
    _speechToText.listen(
      onResult: (result) {
        setState(() {
          _spokenWords.add(result.recognizedWords);
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
    ref.read(isRecordingProvider.notifier).state = true;
  }

  void _stopListening() {
    _speechToText.stop();
    ref.read(isRecordingProvider.notifier).state = false;
    
    if (_spokenWords.isNotEmpty) {
      final text = _spokenWords.join(' ');
      _textController.text = text;
      _addEntry(text);
    }
  }

  void _addEntry(String text) {
    if (text.trim().isEmpty) return;
    ref.read(entriesProvider.notifier).addEntry(text.trim());
    _textController.clear();
  }

  void _updateEntry(FoodEntry entry, String text) {
    if (text.trim().isEmpty) return;
    ref.read(entriesProvider.notifier).updateEntry(entry.id, text.trim());
  }

  void _deleteEntry(String id) {
    ref.read(entriesProvider.notifier).deleteEntry(id);
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(entriesProvider);
    final totals = ref.watch(dailyTotalsProvider);
    final goal = ref.watch(dailyGoalProvider);
    final streakAsync = ref.watch(streakProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Spino',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('EEEE, MMM d').format(DateTime.now()),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            // Paper entries
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_note,
                            size: 64,
                            color: Colors.black12,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'What did you eat?',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              color: Colors.black38,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + or hold mic to log',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              color: Colors.black26,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _PaperEntry(
                          entry: entry,
                          onUpdate: (text) => _updateEntry(entry, text),
                          onDelete: () => _deleteEntry(entry.id),
                        );
                      },
                    ),
            ),
            // Input area
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _textController,
                        style: GoogleFonts.inter(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Log your meal...',
                          hintStyle: GoogleFonts.inter(
                            color: Colors.black26,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: _addEntry,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkDropletFab(
                    onPressed: () => _addEntry(_textController.text),
                    onLongPressStart: _startListening,
                    onLongPressEnd: _stopListening,
                  ),
                ],
              ),
            ),
            // Daily Pulse
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: streakAsync.when(
                data: (streak) => DailyPulse(
                  currentCalories: totals['calories'] ?? 0,
                  goal: goal,
                  protein: totals['protein'] ?? 0,
                  carbs: totals['carbs'] ?? 0,
                  fat: totals['fat'] ?? 0,
                  streak: streak,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _speechToText.stop();
    super.dispose();
  }
}

class _PaperEntry extends StatelessWidget {
  final FoodEntry entry;
  final Function(String) onUpdate;
  final VoidCallback onDelete;

  const _PaperEntry({
    required this.entry,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.text,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a').format(entry.timestamp),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: Colors.black26,
                  ),
                ),
              ],
            ),
          ),
          IntelligenceMargin(entry: entry),
        ],
      ),
    );
  }
}
