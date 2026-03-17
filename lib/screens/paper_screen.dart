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
import 'settings_screen.dart';

class PaperScreen extends ConsumerStatefulWidget {
  const PaperScreen({super.key});

  @override
  ConsumerState<PaperScreen> createState() => _PaperScreenState();
}

class _PaperScreenState extends ConsumerState<PaperScreen> {
  final TextEditingController _textController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  final FocusNode _focusNode = FocusNode();
  final List<String> _spokenWords = [];
  bool _speechEnabled = false;
  String? _editingEntryId;

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
      _submitEntry(text);
    }
  }

  void _submitEntry(String text) {
    if (text.trim().isEmpty) return;
    
    if (_editingEntryId != null) {
      ref.read(entriesProvider.notifier).updateEntry(_editingEntryId!, text.trim());
      setState(() => _editingEntryId = null);
    } else {
      ref.read(entriesProvider.notifier).addEntry(text.trim());
    }
    _textController.clear();
    _focusNode.unfocus();
  }

  void _startEditing(FoodEntry entry) {
    setState(() {
      _editingEntryId = entry.id;
      _textController.text = entry.text;
    });
    _focusNode.requestFocus();
  }

  void _cancelEditing() {
    setState(() {
      _editingEntryId = null;
      _textController.clear();
    });
    _focusNode.unfocus();
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Nourish',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 22),
                    color: Colors.black38,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
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
            // Paper canvas (editable area)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Tap on canvas to start typing
                  _focusNode.requestFocus();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: entries.isEmpty
                      ? _buildEmptyState()
                      : _buildEntriesList(entries),
                ),
              ),
            ),
            // Input area (appears when typing)
            _buildInputBar(),
            // Daily Pulse
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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

  Widget _buildEmptyState() {
    return Center(
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
            'Start typing on the canvas',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.black38,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'or hold the button to speak',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              color: Colors.black26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList(List<FoodEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length + 1, // +1 for input at top
      itemBuilder: (context, index) {
        if (index == 0) {
          return const SizedBox.shrink(); // Input is below
        }
        final entry = entries[index - 1];
        return _CanvasEntry(
          entry: entry,
          onTap: () => _startEditing(entry),
          onDelete: () => ref.read(entriesProvider.notifier).deleteEntry(entry.id),
        );
      },
    );
  }

  Widget _buildInputBar() {
    final isRecording = ref.watch(isRecordingProvider);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus && _textController.text.isEmpty) {
                  // Keep the bar visible but subtle
                }
              },
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                style: GoogleFonts.inter(fontSize: 16),
                decoration: InputDecoration(
                  hintText: _editingEntryId != null 
                      ? 'Editing entry...'
                      : 'Type what you ate...',
                  hintStyle: GoogleFonts.inter(color: Colors.black26),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onSubmitted: _submitEntry,
                textInputAction: TextInputAction.done,
              ),
            ),
          ),
          if (_editingEntryId != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: Colors.black45,
              onPressed: _cancelEditing,
            ),
          InkDropletFab(
            onPressed: () => _submitEntry(_textController.text),
            onLongPressStart: _startListening,
            onLongPressEnd: _stopListening,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _speechToText.stop();
    super.dispose();
  }
}

class _CanvasEntry extends StatelessWidget {
  final FoodEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CanvasEntry({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF9F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.black.withOpacity(0.05),
            ),
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
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
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
        ),
      ),
    );
  }
}
