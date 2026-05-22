import 'dart:math';
import 'package:flutter/material.dart';

/// Hand-drawn line chart using Path and Canvas. No chart libraries.
class SpendArcLineChart extends StatefulWidget {
  final List<double> data;
  final List<String> labels;
  final Color? lineColor;

  const SpendArcLineChart({
    super.key,
    required this.data,
    this.labels = const [],
    this.lineColor,
  });

  @override
  State<SpendArcLineChart> createState() => _SpendArcLineChartState();
}

class _SpendArcLineChartState extends State<SpendArcLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
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
          size: const Size(double.infinity, 180),
          painter: _LineChartPainter(
            data: widget.data,
            labels: widget.labels,
            progress: _animation.value,
            lineColor: widget.lineColor ?? theme.colorScheme.primary,
            gridColor: theme.colorScheme.outlineVariant,
            textStyle: theme.textTheme.bodySmall!,
          ),
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final double progress;
  final Color lineColor;
  final Color gridColor;
  final TextStyle textStyle;

  static const double _padLeft = 48;
  static const double _padRight = 16;
  static const double _padTop = 16;
  static const double _padBottom = 32;

  _LineChartPainter({
    required this.data,
    required this.labels,
    required this.progress,
    required this.lineColor,
    required this.gridColor,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartW = size.width - _padLeft - _padRight;
    final chartH = size.height - _padTop - _padBottom;
    final maxVal = data.reduce(max) * 1.1; // 10% headroom

    // ─── Grid lines ────────────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 4; i++) {
      final y = _padTop + chartH * (1 - i / 4);
      canvas.drawLine(
        Offset(_padLeft, y),
        Offset(_padLeft + chartW, y),
        gridPaint,
      );

      // Y-axis labels
      _drawText(
        canvas,
        '₹${(maxVal * i / 4).toStringAsFixed(0)}',
        Offset(0, y - 6),
        size: 10,
      );
    }

    // ─── Fill area ─────────────────────────────────────────────────────────
    final fillPath = Path();
    final visibleCount = (data.length * progress).ceil().clamp(2, data.length);

    for (int i = 0; i < visibleCount; i++) {
      final x = _padLeft + (i / (data.length - 1)) * chartW;
      final rawY = _padTop + chartH * (1 - data[i] / maxVal);

      // Interpolate the last point for smooth animation
      final y = i == visibleCount - 1 && progress < 1
          ? _interpolateY(i, visibleCount, chartH, maxVal)
          : rawY;

      i == 0 ? fillPath.moveTo(x, y) : fillPath.lineTo(x, y);
    }

    // Close fill area
    final lastX = _padLeft + ((visibleCount - 1) / (data.length - 1)) * chartW;
    fillPath
      ..lineTo(lastX, _padTop + chartH)
      ..lineTo(_padLeft, _padTop + chartH)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lineColor.withOpacity(0.2), lineColor.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, _padTop, size.width, chartH))
        ..style = PaintingStyle.fill,
    );

    // ─── Line ──────────────────────────────────────────────────────────────
    final linePath = Path();
    for (int i = 0; i < visibleCount; i++) {
      final x = _padLeft + (i / (data.length - 1)) * chartW;
      final y = _padTop + chartH * (1 - data[i] / maxVal);
      i == 0 ? linePath.moveTo(x, y) : linePath.lineTo(x, y);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // ─── Data points ───────────────────────────────────────────────────────
    for (int i = 0; i < visibleCount; i++) {
      final x = _padLeft + (i / (data.length - 1)) * chartW;
      final y = _padTop + chartH * (1 - data[i] / maxVal);

      canvas.drawCircle(x as Offset, (Paint()..color = Colors.white..style = PaintingStyle.fill) as double, 4 as Paint);
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // ─── X-axis labels ─────────────────────────────────────────────────────
    if (labels.isNotEmpty) {
      for (int i = 0; i < min(labels.length, data.length); i++) {
        final x = _padLeft + (i / (data.length - 1)) * chartW;
        _drawText(
          canvas,
          labels[i],
          Offset(x - 16, size.height - _padBottom + 8),
          size: 10,
        );
      }
    }
  }

  double _interpolateY(int i, int visibleCount, double chartH, double maxVal) {
    if (i == 0) return _padTop + chartH * (1 - data[0] / maxVal);
    final prev = _padTop + chartH * (1 - data[i - 1] / maxVal);
    final curr = _padTop + chartH * (1 - data[i] / maxVal);
    final t = (data.length * progress) - (i - 1);
    return prev + (curr - prev) * t;
  }

  void _drawText(Canvas canvas, String text, Offset offset, {double size = 11}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle.copyWith(fontSize: size),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.progress != progress;
}
