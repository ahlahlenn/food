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
            // Canvas - tap anywhere to type
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Show input when tapping canvas
                  _showInputDialog();
                },
                behavior: HitTestBehavior.opaque,
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
            // Bottom area
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
                  // Mic button only
                  _buildMicButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInputDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _InputSheet(
        initialText: _editingEntryId != null ? _textController.text : '',
        isEditing: _editingEntryId != null,
        onSubmit: (text) {
          _submitEntry(text);
          Navigator.pop(context);
        },
        onCancel: () {
          _cancelEditing();
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildMicButton() {
    final isRecording = ref.watch(isRecordingProvider);

    return GestureDetector(
      onLongPressStart: (_) => _startListening(),
      onLongPressEnd: (_) => _stopListening(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isRecording ? Colors.red : Colors.black87,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isRecording ? Colors.red : Colors.black54).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isRecording
              ? _RecordingIndicator()
              : const Icon(
                  Icons.mic,
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
          Icon(Icons.add, size: 48, color: Colors.black12),
          const SizedBox(height: 16),
          Text(
            'Tap anywhere to write',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
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
          onTap: () {
            _startEditing(entry);
            _showInputDialog();
          },
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

class _InputSheet extends StatefulWidget {
  final String initialText;
  final bool isEditing;
  final Function(String) onSubmit;
  final VoidCallback onCancel;

  const _InputSheet({
    required this.initialText,
    required this.isEditing,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<_InputSheet> createState() => _InputSheetState();
}

class _InputSheetState extends State<_InputSheet> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF9F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Input field
            TextField(
              controller: _controller,
              autofocus: true,
              style: GoogleFonts.jetBrainsMono(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'What did you eat?',
                hintStyle: GoogleFonts.jetBrainsMono(color: Colors.black26, fontSize: 16),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  widget.onSubmit(text);
                }
              },
            ),
            const SizedBox(height: 16),
            // Buttons
            Row(
              children: [
                if (widget.isEditing)
                  TextButton(
                    onPressed: widget.onCancel,
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(color: Colors.black45),
                    ),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      widget.onSubmit(_controller.text);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.isEditing ? 'Update' : 'Add',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTime(entry.timestamp),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: Colors.black26,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
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
