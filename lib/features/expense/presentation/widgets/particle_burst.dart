import 'dart:math';
import 'package:flutter/material.dart';

/// Particle burst shown when an expense is added.
/// Uses CustomPainter + AnimationController — no external packages.
class ParticleBurst extends StatefulWidget {
  final Widget child;
  final bool animate;
  final VoidCallback? onComplete;

  const ParticleBurst({
    super.key,
    required this.child,
    this.animate = false,
    this.onComplete,
  });

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = _generateParticles();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    if (widget.animate) _startBurst();
  }

  @override
  void didUpdateWidget(ParticleBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.animate && widget.animate) {
      _particles = _generateParticles();
      _startBurst();
    }
  }

  void _startBurst() {
    _controller.reset();
    _controller.forward().then((_) => widget.onComplete?.call());
  }

  List<_Particle> _generateParticles() {
    final rnd = Random();
    final colors = [
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.amber,
    ];
    return List.generate(20, (_) {
      return _Particle(
        angle: rnd.nextDouble() * 2 * pi,
        distance: 40 + rnd.nextDouble() * 60,
        radius: 3 + rnd.nextDouble() * 5,
        color: colors[rnd.nextInt(colors.length)],
      );
    });
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
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1) return;
    final center = Offset(size.width / 2, size.height / 2);

    for (final p in particles) {
      // Ease-out trajectory
      final eased = Curves.easeOut.transform(progress);
      final offset = Offset(
        center.dx + cos(p.angle) * p.distance * eased,
        center.dy + sin(p.angle) * p.distance * eased,
      );
      final radius = p.radius * (1 - progress * 0.5);
      final opacity = (1 - progress).clamp(0.0, 1.0);

      canvas.drawCircle(
        offset,
        radius,
        Paint()..color = p.color.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double angle;
  final double distance;
  final double radius;
  final Color color;

  const _Particle({
    required this.angle,
    required this.distance,
    required this.radius,
    required this.color,
  });
}
