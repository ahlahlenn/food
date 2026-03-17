import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/entries_provider.dart';

class InkDropletFab extends ConsumerStatefulWidget {
  final VoidCallback onPressed;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  const InkDropletFab({
    super.key,
    required this.onPressed,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  ConsumerState<InkDropletFab> createState() => _InkDropletFabState();
}

class _InkDropletFabState extends ConsumerState<InkDropletFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = ref.watch(isRecordingProvider);

    return GestureDetector(
      onTap: widget.onPressed,
      onLongPressStart: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
        widget.onLongPressStart();
      },
      onLongPressEnd: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onLongPressEnd();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color.lerp(
                    const Color(0xFF6366F1),
                    const Color(0xFFEF4444),
                    _controller.value,
                  )!,
                  Color.lerp(
                    const Color(0xFF4F46E5),
                    const Color(0xFFDC2626),
                    _controller.value,
                  )!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.lerp(
                    const Color(0xFF6366F1).withOpacity(0.4),
                    const Color(0xFFEF4444).withOpacity(0.4),
                    _controller.value,
                  )!,
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: isRecording
                  ? const _PulsingDots()
                  : Icon(
                      _isPressed ? Icons.mic : Icons.add,
                      color: Colors.white,
                      size: 28,
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
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
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = ((_controller.value + delay) % 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3 + (value * 0.7)),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
