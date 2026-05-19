
import 'package:flutter/material.dart';
import 'dart:math';
import 'fireworks_painter.dart';
import 'firework_models.dart';

class FireworksPage extends StatefulWidget {
  const FireworksPage({super.key});

  @override
  State<FireworksPage> createState() => _FireworksPageState();
}

class _FireworksPageState extends State<FireworksPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Firework> _fireworks = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
        setState(() {
          for (var firework in _fireworks) {
            firework.update();
          }
          _fireworks.removeWhere((firework) => firework.isDone);
        });
      });
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _launchFirework(Offset position) {
    final hue = _random.nextDouble() * 360;
    final color = HSLColor.fromAHSL(1.0, hue, 1.0, 0.5).toColor();
    _fireworks.add(Firework(
      origin: position,
      particleCount: 100 + _random.nextInt(100),
      color: color,
      random: _random,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) => _launchFirework(details.localPosition),
        child: CustomPaint(
          painter: FireworksPainter(fireworks: _fireworks),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
