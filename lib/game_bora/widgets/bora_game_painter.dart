import 'package:flutter/material.dart';
import 'package:remote_kattedon/game_bora/models/bora_models.dart';
import 'dart:ui';

/// カスタムペインタでゲームフィールドを描画
class BoraGamePainter extends CustomPainter {
  final GameState gameState;
  BoraGamePainter({required this.gameState});

  // 共通のレイアウト計算用プロパティ
  late final double waterY;
  late final double yagaraX;
  late final double platformY; // 主人公の足場（ロープの起点）

  // 描画前に計算を行うメソッド
  void _calculateLayout(Size size) {
    waterY = size.height * 0.45;
    yagaraX = size.width * 0.78;
    // 櫓の構造に合わせて、前回のコードの足場位置を基準にする
    platformY = waterY - size.height * 0.20; 
  }

  @override
  void paint(Canvas canvas, Size size) {
    _calculateLayout(size);

    // 背景
    _drawBackground(canvas, size);
    // 水面ライン
    _drawWaterLine(canvas, size);
    // サポーター
    _drawSupporters(canvas, size);
    // やぐらと網を結ぶロープ
    _drawRope(canvas, size);
    // ボラ
    _drawBoras(canvas, size);
    // 網中バッジ
    _drawNetBadge(canvas, size);
    // UI情報表示
    _drawStats(canvas, size);
    // やぐらとロープ
    _drawYagara(canvas, size);
    // 網
    _drawNet(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xff6288dc), Color(0xff283ae7)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);
  }

  void _drawWaterLine(Canvas canvas, Size size) {
    final y = size.height * 0.45;
    final paint = Paint()
      ..strokeWidth = 4
      ..shader =
          const LinearGradient(colors: [Color(0xff60aee0), Color(0xffd6fafc)])
              .createShader(
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
      textPainter.text =
          TextSpan(text: s.emoji, style: const TextStyle(fontSize: 24));
      textPainter.layout();
      textPainter.paint(canvas, Offset(dx, y));
      // time bar
      const barWidth = 22.0;
      const barHeight = 3.0;
      final px = dx;
      final py = y + 24;
      final percent = (s.timeLeft / s.duration).clamp(0.0, 1.0);
      final barPaint = Paint()
        ..color =
            s.timeLeft < 5 ? const Color(0xffffa000) : const Color(0xff4caf50);
      canvas.drawRect(
          Rect.fromLTWH(px, py, barWidth * percent, barHeight), barPaint);
      canvas.drawRect(Rect.fromLTWH(px, py, barWidth, barHeight),
          Paint()..style = PaintingStyle.stroke);
    }
  }

  void _drawYagara(Canvas canvas, Size size) {
    // final waterY = size.height * 0.45;
    final centerX = size.width * 0.78;

    // ===== 基本サイズ設定
    final totalHeight = size.height * 0.4;
    final xCrossY = waterY - totalHeight * 0.4; // X字が交差する中心的な高さ
    final baseWidth = size.width * 0.25;
    final topWidth = size.width * 0.18;

    final polePaint = Paint()
      ..color = const Color(0xff54321d)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final rungPaint = Paint()
      ..color = const Color(0xff6b3f24)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    // ===== 1. X状の支柱
    // 左下から右上へ
    canvas.drawLine(Offset(centerX - baseWidth / 2, waterY + 40),
        Offset(centerX + topWidth / 2, xCrossY - totalHeight * 0.5), polePaint);
    // 右下から左上へ
    canvas.drawLine(Offset(centerX + baseWidth / 2, waterY + 40),
        Offset(centerX - topWidth / 2, xCrossY - totalHeight * 0.5), polePaint);

    // ===== 2. Xの交点より下の横棒（梯子部分）
    const rungCount = 5;
    for (int i = 0; i < rungCount; i++) {
      final t = i / (rungCount - 1);
      // 交差点から水面に向かって配置
      final y = lerpDouble(xCrossY + 10, waterY - 5, t)!;

      // 下に行くほど横幅を広くする
      final currentWidth = lerpDouble(20.0, baseWidth * 0.7, t)!;

      canvas.drawLine(
        Offset(centerX - currentWidth / 2, y),
        Offset(centerX + currentWidth / 2, y),
        rungPaint,
      );
    }

    // ===== 3. Xの上部：天井の梁と足場
    // final platformY = xCrossY - 15; // 交差点の少し上（座る場所）
    final roofY = xCrossY - totalHeight * 0.4; // 最上部の梁

    // 足場（主人公が乗る横棒）
    canvas.drawLine(
      Offset(centerX - topWidth * 0.3, platformY),
      Offset(centerX + topWidth * 0.3, platformY),
      rungPaint..strokeWidth = 6,
    );

    // 天井の梁
    canvas.drawLine(
      Offset(centerX - topWidth * 0.6, roofY),
      Offset(centerX + topWidth * 0.6, roofY),
      polePaint..strokeWidth = 8,
    );

    // ===== 4. キャラクターの描画
    final emoji = gameState.character?.emoji ?? "😊";
    final tp = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(text: emoji, style: const TextStyle(fontSize: 24))
      ..layout();

    // 足場の上に配置
    tp.paint(canvas, Offset(centerX - tp.width / 2, platformY - tp.height));
  }

  void _drawRope(Canvas canvas, Size size) {
    // 共通変数を利用
    final netTopY = size.height * (0.45 + 0.02 + (1 - gameState.netProgress / 100) * 0.35);
    final left = size.width * 0.18;
    final right = size.width * 0.82;

    final ropePaint = Paint()
      ..color = const Color(0xffd4a574)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // ロープ始点: やぐらの足場（platformY）から伸びる
    final startPoint = Offset(yagaraX, platformY);

    // ロープ1: 網の右上
    canvas.drawLine(startPoint, Offset(right, netTopY), ropePaint);

    // ロープ2: 網の左上
    canvas.drawLine(startPoint, Offset(left, netTopY), ropePaint);
  }

  void _drawNet(Canvas canvas, Size size) {
    final topY =
        size.height * (0.45 + 0.02 + (1 - gameState.netProgress / 100) * 0.35);
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
      ..strokeWidth = 2;
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
      final radius = {
        BoraSize.small: 7.0,
        BoraSize.medium: 10.0,
        BoraSize.large: 14.0
      }[b.size]!;
      paint.color = b.inNet && !b.escaping
          ? const Color(0xff80ccff)
          : const Color(0xff336699);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(px, py), width: radius * 2, height: radius),
          paint);
      if (b.escaping) paint.color = paint.color.withOpacity(0.3);
    }
  }

  void _drawNetBadge(Canvas canvas, Size size) {
    if (gameState.boraCountInNet <= 0) return;
    final y = size.height * (0.45 + 0.02 + 0.35) + 20;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
        text: '🐟 網の中: ${gameState.boraCountInNet}尾',
        style: const TextStyle(color: Colors.white, fontSize: 14));
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(size.width / 2 - textPainter.width / 2, y));
  }

  void _drawStats(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // 左下: 捕獲数
    final caughtText = '💰 捕獲: ${gameState.caughtBoras}';
    textPainter.text = TextSpan(
      text: caughtText,
      style: const TextStyle(
          color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(8, size.height - 40));

    // 右下: スコア
    final scoreText = '⭐ スコア: ${gameState.score}';
    textPainter.text = TextSpan(
      text: scoreText,
      style: const TextStyle(
          color: Color(0xffffff00),
          fontSize: 14,
          fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(size.width - textPainter.width - 8, size.height - 40));

    // 左上: 応援中人数
    final supporterText =
        '👥 応援: ${gameState.supporters.length}/${getMaxSupporters(gameState.character!)}';
    textPainter.text = TextSpan(
      text: supporterText,
      style: const TextStyle(color: Colors.white, fontSize: 12),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(8, 8));
  }

  @override
  bool shouldRepaint(covariant BoraGamePainter oldDelegate) => true;
}
