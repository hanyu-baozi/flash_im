
import 'package:flutter/material.dart';
import 'dart:math';
import 'firework_models.dart';

class FireworksPainter extends CustomPainter {
  final List<Firework> fireworks;

  FireworksPainter({required this.fireworks});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final firework in fireworks) {
      for (final particle in firework.particles) {
        paint.color = particle.color.withOpacity(particle.life);
        canvas.drawCircle(particle.position, particle.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
