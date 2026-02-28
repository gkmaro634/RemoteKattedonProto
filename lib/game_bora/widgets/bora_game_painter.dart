import 'package:flutter/material.dart';
import 'package:remote_kattedon/game_bora/models/bora_models.dart';
import 'dart:ui';

/// カスタムペインタでゲームフィールドを描画
class BoraGamePainter extends CustomPainter {
  final GameState gameState;
  BoraGamePainter({required this.gameState});

  @override
  void paint(Canvas canvas, Size size) {
    // 背景
    _drawBackground(canvas, size);
    // 水面ライン
    _drawWaterLine(canvas, size);
    // サポーター
    _drawSupporters(canvas, size);
    // やぐらとロープ
    _drawYagara(canvas, size);
    // 網
    _drawNet(canvas, size);
    // ボラ
    _drawBoras(canvas, size);
    // 網中バッジ
    _drawNetBadge(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xff6288dc), Color(0xff283ae7)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);
  }

  void _drawWaterLine(Canvas canvas, Size size) {
    final y = size.height * 0.45;
    final paint = Paint()
      ..strokeWidth = 4
      ..shader = LinearGradient(colors: const [Color(0xff60aee0), Color(0xffd6fafc)]).createShader(
        Rect.fromLTWH(0, y, size.width, 0),
      );
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  void _drawSupporters(Canvas canvas, Size size) {
    final y = size.height * 0.45 - 50;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < gameState.supporters.length; i++) {
      final s = gameState.supporters[i];
      final dx = size.width * (0.1 + i * 0.07);
      textPainter.text = TextSpan(text: s.emoji, style: const TextStyle(fontSize: 24));
      textPainter.layout();
      textPainter.paint(canvas, Offset(dx, y));
      // time bar
      final barWidth = 22.0;
      final barHeight = 3.0;
      final px = dx;
      final py = y + 24;
      final percent = (s.timeLeft / s.duration).clamp(0.0, 1.0);
      final barPaint = Paint()
        ..color = s.timeLeft < 5 ? const Color(0xffffa000) : const Color(0xff4caf50);
      canvas.drawRect(Rect.fromLTWH(px, py, barWidth * percent, barHeight), barPaint);
      canvas.drawRect(Rect.fromLTWH(px, py, barWidth, barHeight), Paint()..style = PaintingStyle.stroke);
    }
  }

  void _drawYagara(Canvas canvas, Size size) {
    final waterY = size.height * 0.45;
    final paint = Paint()
      ..color = const Color(0xffa0522d)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final leftX = size.width * 0.78;
    canvas.drawLine(Offset(leftX, waterY - 48), Offset(leftX, size.height), paint);
    // simple humanoid figure
    final headPaint = Paint()..color = const Color(0xffffe0b2);
    canvas.drawCircle(Offset(leftX, waterY - 40), 11, headPaint);
  }

  void _drawNet(Canvas canvas, Size size) {
    final topY = size.height * (0.45 + 0.02 + (1 - gameState.netProgress / 100) * 0.35);
    final left = size.width * 0.18;
    final right = size.width * 0.82;
    final bottom = size.height * 0.95;
    final paint = Paint()
      ..color = const Color(0xff777777)
      ..style = PaintingStyle.stroke
      ..strokeWidth = gameState.isRaising ? 3 : 2;
    canvas.drawRect(Rect.fromLTRB(left, topY, right, bottom), paint);
    // grid
    final gridPaint = Paint()
      ..color = const Color(0xff888888)
      ..strokeWidth = 1;
    const step = 18.0;
    for (double x = left; x < right; x += step) {
      canvas.drawLine(Offset(x, topY), Offset(x, bottom), gridPaint);
    }
    for (double y = topY; y < bottom; y += step) {
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
    }
  }

  void _drawBoras(Canvas canvas, Size size) {
    final paint = Paint();
    for (var b in gameState.boras) {
      final px = size.width * b.x / 100;
      final py = size.height * (0.45 + 0.05 + b.y * 0.48 / 100);
      final radius = {BoraSize.small: 7.0, BoraSize.medium: 10.0, BoraSize.large: 14.0}[b.size]!;
      paint.color = b.inNet && !b.escaping ? const Color(0xff80ccff) : const Color(0xff336699);
      canvas.drawOval(Rect.fromCenter(center: Offset(px, py), width: radius * 2, height: radius), paint);
      if (b.escaping) paint.color = paint.color.withOpacity(0.3);
    }
  }

  void _drawNetBadge(Canvas canvas, Size size) {
    if (gameState.boraCountInNet <= 0) return;
    final y = size.height * (0.45 + 0.02 + 0.35) + 20;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
        text: '🐟 網の中: ${gameState.boraCountInNet}匹',
        style: const TextStyle(color: Colors.white, fontSize: 14));
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, y));
  }

  @override
  bool shouldRepaint(covariant BoraGamePainter oldDelegate) => true;
}
