import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../models/food_entry.dart';
import '../providers/entries_provider.dart';
import '../widgets/intelligence_margin.dart';
import '../widgets/daily_pulse.dart';
import 'settings_screen.dart';

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
  bool _isRecording = false;
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
    setState(() => _isRecording = true);
    _speechToText.listen(
      onResult: (result) {
        setState(() {
          _spokenWords.add(result.recognizedWords);
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      onSoundLevelChange: (level) {},
    );
    ref.read(isRecordingProvider.notifier).state = true;
  }

  void _stopListening() {
    _speechToText.stop();
    setState(() => _isRecording = false);
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
  }

  void _startEditing(FoodEntry entry) {
    setState(() {
      _editingEntryId = entry.id;
      _textController.text = entry.text;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingEntryId = null;
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(entriesProvider);
    final totals = ref.watch(dailyTotalsProvider);
    final goal = ref.watch(dailyGoalProvider);
    final streakAsync = ref.watch(streakProvider);
    final isRecording = ref.watch(isRecordingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
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
                ],
              ),
            ),
            // Canvas - no boxes, just paper
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAF9F6),
                  ),
                  child: entries.isEmpty
                      ? _buildEmptyState()
                      : _buildEntriesList(entries),
                ),
              ),
            ),
            // Input area - only shows when typing
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _textController.text.isNotEmpty || _editingEntryId != null ? 64 : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _textController.text.isNotEmpty || _editingEntryId != null ? 1 : 0,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          style: GoogleFonts.jetBrainsMono(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Type your meal...',
                            hintStyle: GoogleFonts.jetBrainsMono(color: Colors.black26, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onChanged: (_) => setState(() {}),
                          onSubmitted: _submitEntry,
                        ),
                      ),
                      if (_editingEntryId != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: Colors.black45,
                          onPressed: _cancelEditing,
                        ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.send_rounded,
                          size: 20,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Daily Pulse + FAB
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
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
                  const SizedBox(width: 16),
                  _buildActionButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final hasText = _textController.text.isNotEmpty;
    final isRecording = ref.watch(isRecordingProvider);

    return GestureDetector(
      onTap: () {
        if (hasText) {
          _submitEntry(_textController.text);
        }
      },
      onLongPressStart: (_) => _startListening(),
      onLongPressEnd: (_) => _stopListening(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isRecording
                ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                : hasText
                    ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)]
                    : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isRecording ? const Color(0xFFEF4444) : const Color(0xFF6366F1))
                  .withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isRecording
              ? _RecordingIndicator()
              : Icon(
                  hasText ? Icons.send_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 24,
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tap + to add',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 16,
              color: Colors.black26,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'or hold mic to speak',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              color: Colors.black18,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList(List<FoodEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _HandwrittenEntry(
          entry: entry,
          onTap: () => _startEditing(entry),
          onDelete: () => ref.read(entriesProvider.notifier).deleteEntry(entry.id),
        );
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _speechToText.stop();
    super.dispose();
  }
}

class _HandwrittenEntry extends StatelessWidget {
  final FoodEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HandwrittenEntry({
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
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: Colors.red.withOpacity(0.5)),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handwritten text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timestamp in small italic
                    Text(
                      _formatTime(entry.timestamp),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: Colors.black26,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Main entry - handwritten style
                    Text(
                      entry.text,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 15,
                        color: Colors.black87,
                        fontWeight: FontWeight.w300,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Intelligence margin
              IntelligenceMargin(entry: entry),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(dt.year, dt.month, dt.day);
    
    if (entryDay == today) {
      return DateFormat('h:mm a').format(dt);
    } else if (entryDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${DateFormat('h:mm a').format(dt)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(dt);
    }
  }
}

class _RecordingIndicator extends StatefulWidget {
  @override
  State<_RecordingIndicator> createState() => _RecordingIndicatorState();
}

class _RecordingIndicatorState extends State<_RecordingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(0),
            const SizedBox(width: 3),
            _dot(0.2),
            const SizedBox(width: 3),
            _dot(0.4),
          ],
        );
      },
    );
  }

  Widget _dot(double delay) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3 + (_controller.value + delay) % 1 * 0.7),
        shape: BoxShape.circle,
      ),
    );
  }
}
