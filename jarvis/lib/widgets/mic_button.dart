import 'package:flutter/material.dart';

class MicButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const MicButton({
    super.key,
    required this.isListening,
    required this.onStart,
    required this.onStop,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (widget.isListening) {
          _controller.forward();
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isListening) {
      _controller.forward();
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePressStart(_) {
    widget.onStart();
  }

  void _handlePressEnd(_) {
    widget.onStop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _handlePressStart,
      onLongPressEnd: _handlePressEnd,
      child: ScaleTransition(
        scale: _animation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: widget.isListening
                  ? [Colors.redAccent, Colors.red]
                  : [Colors.blueAccent, Colors.blue],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isListening
                    ? Colors.red.withOpacity(0.6)
                    : Colors.blue.withOpacity(0.6),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Icon(
            widget.isListening ? Icons.mic : Icons.mic_none,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}