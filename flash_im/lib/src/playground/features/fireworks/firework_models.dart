
import 'package:flutter/material.dart';
import 'dart:math';

class Particle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  double life;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    this.size = 2.0,
    this.life = 1.0,
  });

  void update() {
    position += velocity;
    velocity += const Offset(0, 0.05); // Gravity
    life -= 0.01;
  }

  bool get isDone => life <= 0;
}

class Firework {
  final List<Particle> particles = [];
  final Random random;
  bool isDone = false;

  Firework({
    required Offset origin,
    required int particleCount,
    required Color color,
    required this.random,
  }) {
    for (int i = 0; i < particleCount; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = random.nextDouble() * 4 + 1;
      final velocity = Offset(cos(angle) * speed, sin(angle) * speed);
      particles.add(Particle(
        position: origin,
        velocity: velocity,
        color: color,
        size: random.nextDouble() * 2 + 1,
      ));
    }
  }

  void update() {
    for (var particle in particles) {
      particle.update();
    }
    particles.removeWhere((p) => p.isDone);
    if (particles.isEmpty) {
      isDone = true;
    }
  }
}
