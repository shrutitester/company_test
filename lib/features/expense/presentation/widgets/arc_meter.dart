import 'dart:math';
import 'package:flutter/material.dart';

/// Arc meter showing budget usage. Built entirely with CustomPainter.
/// No third-party chart libraries used.
class ArcMeter extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double totalBudget;
  final double spent;
  final Color? color;

  const ArcMeter({
    super.key,
    required this.progress,
    required this.totalBudget,
    required this.spent,
    this.color,
  });

  @override
  State<ArcMeter> createState() => _ArcMeterState();
}

class _ArcMeterState extends State<ArcMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(ArcMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(220, 220),
          painter: _ArcMeterPainter(
            progress: _animation.value,
            primaryColor: widget.color ?? theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surfaceVariant,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(_animation.value * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'of budget used',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${widget.spent.toStringAsFixed(0)} / ₹${widget.totalBudget.toStringAsFixed(0)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ArcMeterPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color backgroundColor;

  _ArcMeterPainter({
    required this.progress,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const startAngle = pi * 0.75; // 135 degrees
    const sweepAngle = pi * 1.5; // 270 degree arc

    // Background track
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = backgroundColor
        ..strokeWidth = 18
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Determine color (red when > 80%)
    final Color arcColor = progress > 0.8
        ? Color.lerp(primaryColor, Colors.red, (progress - 0.8) / 0.2)!
        : primaryColor;

    // Progress arc with gradient effect
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle * progress,
        colors: [arcColor.withOpacity(0.7), arcColor],
      ).createShader(rect)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle * progress, false, progressPaint);

    // Tick marks
    for (int i = 0; i <= 10; i++) {
      final angle = startAngle + sweepAngle * (i / 10);
      final outerPoint = Offset(
        center.dx + (radius + 14) * cos(angle),
        center.dy + (radius + 14) * sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - 14) * cos(angle),
        center.dy + (radius - 14) * sin(angle),
      );
      canvas.drawLine(
        innerPoint,
        outerPoint,
        Paint()
          ..color = backgroundColor.withOpacity(0.6)
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcMeterPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor;
  }
}
