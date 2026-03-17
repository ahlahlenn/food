import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/groq_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  String _status = '';
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  void _loadApiKey() {
    if (GroqService.hasApiKey) {
      _apiKeyController.text = '••••••••••••••••';
    } else {
      _apiKeyController.text = '';
    }
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty || key == '••••••••••••••••') {
      return;
    }
    
    setState(() {
      _status = 'Saving...';
      _isEditing = false;
    });
    
    GroqService.setApiKey(key);
    
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _status = 'Saved ✓');
    }
    
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _status = '';
        _apiKeyController.text = '••••••••••••••••';
      });
    }
  }

  Future<void> _clearApiKey() async {
    setState(() => _status = 'Clearing...');
    await GroqService.clearApiKey();
    if (mounted) {
      setState(() {
        _apiKeyController.text = '';
        _status = 'Cleared ✓';
      });
    }
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _status = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // API Key section
          Text(
            'Groq API Key',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black45,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  GroqService.hasApiKey 
                      ? 'AI parsing is enabled' 
                      : 'Add your key for AI-powered parsing',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: GroqService.hasApiKey ? Colors.green : Colors.black38,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _apiKeyController,
                  obscureText: true,
                  enabled: _isEditing || !GroqService.hasApiKey,
                  style: GoogleFonts.jetBrainsMono(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'gsk_...',
                    hintStyle: GoogleFonts.jetBrainsMono(color: Colors.black26),
                    filled: true,
                    fillColor: const Color(0xFFFAF9F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onTap: () {
                    if (GroqService.hasApiKey && !_isEditing) {
                      setState(() {
                        _isEditing = true;
                        _apiKeyController.text = '';
                        _apiKeyController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _apiKeyController.text.length),
                        );
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveApiKey,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _status.isNotEmpty ? _status : 'Save Key',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    if (GroqService.hasApiKey) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _clearApiKey,
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // About
          Text(
            'About',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black45,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _InfoRow('App', 'Nourish'),
                _InfoRow('Version', '1.0.0'),
                _InfoRow('AI', GroqService.hasApiKey ? 'Enabled' : 'Local only'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 14, color: Colors.black54)),
          Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 13, color: Colors.black38)),
        ],
      ),
    );
  }
}
