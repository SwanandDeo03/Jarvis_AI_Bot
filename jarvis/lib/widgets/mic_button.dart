import 'package:flutter/material.dart';

class MicButton extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;
  final VoidCallback onToggle;

  const MicButton({
    super.key,
    required this.isListening,
    this.isProcessing = false,
    required this.onToggle,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (widget.isListening) {
          _pulseController.forward();
        }
      }
    });

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(covariant MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isListening) {
      _pulseController.forward();
      _rippleController.repeat();
    } else {
      _pulseController.stop();
      _pulseController.reset();
      _rippleController.stop();
      _rippleController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Color(0xFF00E5FF);
    const Color inactiveColor = Color(0xFF00BCD4);

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple ring 1
          if (widget.isListening)
            AnimatedBuilder(
              animation: _rippleAnimation,
              builder: (context, child) {
                return Container(
                  width: 80 + (60 * _rippleAnimation.value),
                  height: 80 + (60 * _rippleAnimation.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: activeColor.withValues(
                        alpha: 1.0 - _rippleAnimation.value,
                      ),
                      width: 2,
                    ),
                  ),
                );
              },
            ),

          // Ripple ring 2 (offset)
          if (widget.isListening)
            AnimatedBuilder(
              animation: _rippleAnimation,
              builder: (context, child) {
                final delayed = (_rippleAnimation.value + 0.3) % 1.0;
                return Container(
                  width: 80 + (60 * delayed),
                  height: 80 + (60 * delayed),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: activeColor.withValues(
                        alpha: (1.0 - delayed) * 0.5,
                      ),
                      width: 1.5,
                    ),
                  ),
                );
              },
            ),

          // Main mic button
          GestureDetector(
            onTap: widget.isProcessing ? null : widget.onToggle,
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isListening
                        ? const [Color(0xFFFF1744), Color(0xFFD50000)]
                        : const [activeColor, inactiveColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (widget.isListening
                                  ? const Color(0xFFFF1744)
                                  : activeColor)
                              .withValues(alpha: 0.5),
                      blurRadius: widget.isListening ? 30 : 20,
                      spreadRadius: widget.isListening ? 6 : 3,
                    ),
                    BoxShadow(
                      color:
                          (widget.isListening
                                  ? const Color(0xFFFF1744)
                                  : activeColor)
                              .withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  widget.isProcessing
                      ? Icons.hourglass_top_rounded
                      : widget.isListening
                      ? Icons.stop_rounded
                      : Icons.mic_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
