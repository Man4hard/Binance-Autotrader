import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EngineToggleButton extends StatefulWidget {
  final bool isRunning;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final bool isLoading;

  const EngineToggleButton({
    super.key,
    required this.isRunning,
    required this.onStart,
    required this.onStop,
    this.isLoading = false,
  });

  @override
  State<EngineToggleButton> createState() => _EngineToggleButtonState();
}

class _EngineToggleButtonState extends State<EngineToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isRunning) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(EngineToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning && !oldWidget.isRunning) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isRunning && oldWidget.isRunning) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isRunning ? kProfitColor : kTextSecondary;
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isRunning ? _pulseAnim.value : 1.0,
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
          boxShadow: widget.isRunning
              ? [
                  BoxShadow(
                    color: kProfitColor.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.isLoading
                ? null
                : (widget.isRunning ? widget.onStop : widget.onStart),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: widget.isLoading
                  ? SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(
                      widget.isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      color: color,
                      size: 36,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
