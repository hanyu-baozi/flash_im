import 'dart:math';

import 'package:flutter/material.dart';

import '../models/user_profile.dart';

class PatternPainter extends CustomPainter {
  final int seed;
  final int gridSize;
  final Color fillColor;
  final Color bgColor;

  PatternPainter({
    required this.seed,
    this.gridSize = 6,
    this.fillColor = const Color(0xFF4F46E5),
    this.bgColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final cellSize = size.width / gridSize;
    final halfCols = (gridSize / 2).ceil();
    final fillPaint = Paint()..color = fillColor;
    final bgPaint = Paint()..color = bgColor;

    for (var row = 0; row < gridSize; row++) {
      for (var col = 0; col < halfCols; col++) {
        final filled = rng.nextBool();
        final paint = filled ? fillPaint : bgPaint;
        final leftRect = Rect.fromLTWH(
          col * cellSize,
          row * cellSize,
          cellSize,
          cellSize,
        );
        final rightRect = Rect.fromLTWH(
          (gridSize - 1 - col) * cellSize,
          row * cellSize,
          cellSize,
          cellSize,
        );
        canvas.drawRect(leftRect, paint);
        canvas.drawRect(rightRect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PatternPainter oldDelegate) {
    return oldDelegate.seed != seed || oldDelegate.gridSize != gridSize;
  }
}

class PatternAvatar extends StatelessWidget {
  final int seed;
  final double size;
  final int gridSize;
  final double borderRadius;

  const PatternAvatar({
    super.key,
    required this.seed,
    this.size = 80,
    this.gridSize = 6,
    this.borderRadius = 20,
  });

  /// 从 UserProfile 解析头像种子
  /// - avatar 是纯数字字符串→解析为 patternSeed
  /// - avatar 是 http URL→返回 null（自定义头像）
  /// - avatar 为空→使用 userId 作为默认种子
  static int? getPatternSeed(UserProfile profile) {
    final avatar = profile.avatar.trim();
    if (avatar.isEmpty) return profile.userId;
    final seed = int.tryParse(avatar);
    if (seed != null) return seed;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CustomPaint(
        size: Size(size, size),
        painter: PatternPainter(seed: seed, gridSize: gridSize),
      ),
    );
  }
}
