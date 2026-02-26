import 'package:flutter/material.dart';
import 'package:remote_kattedon/game_genge/models/game_state.dart';
import 'dart:ui' as ui;

/// ゲンゲゲームを描画するカスタムペイナー
class GengeGamePainter extends CustomPainter {
  final GengeGameState gameState;
  final ui.Image? backgroundImage;
  final ui.Image? gengeImage;
  final Offset screenSize;

  GengeGamePainter({
    required this.gameState,
    required this.backgroundImage,
    required this.gengeImage,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 背景を描画（画像がない場合は単色）
    if (backgroundImage != null) {
      canvas.drawImage(backgroundImage!, Offset.zero, Paint());
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color.fromARGB(255, 0, 15, 40),
      );
    }

    // ゲンゲを描画
    if (gengeImage != null) {
      _drawGenge(canvas, size);
    }

    // パーティクルを描画
    _drawParticles(canvas);

    // UI を描画
    _drawUI(canvas, size);

    // ゲームオーバー時のバナーと結果を描画
    if (gameState.isGameOver) {
      _drawGameOverBanner(canvas, size);
    }
  }

  /// ゲンゲを描画
  void _drawGenge(Canvas canvas, Size size) {
    if (gengeImage == null) return;

    const baseWidth = 400.0;
    final aspectRatio = gengeImage!.height / gengeImage!.width;
    final baseHeight = baseWidth * aspectRatio;

    // 揺れ演出によるサイズ変更
    final shakeAmount = gameState.shakingFrames;
    final drawWidth = baseWidth + (shakeAmount * 8);
    final drawHeight = baseHeight - (shakeAmount * 4);

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 描画位置（中央）
    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: drawWidth,
      height: drawHeight,
    );

    canvas.drawImageRect(
      gengeImage!,
      Rect.fromLTWH(
        0,
        0,
        gengeImage!.width.toDouble(),
        gengeImage!.height.toDouble(),
      ),
      rect,
      Paint(),
    );
  }

  /// パーティクルを描画
  void _drawParticles(Canvas canvas) {
    final paint = Paint()..color = const Color.fromARGB(255, 180, 240, 255);

    for (final particle in gameState.particles) {
      final radius = (particle.lifespan / 3).clamp(0, 10).toDouble();
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        radius,
        paint,
      );
    }
  }

  /// UI を描画
  void _drawUI(Canvas canvas, Size size) {
    // 半透明の背景
    final uiBgPaint = Paint()
      ..color = const Color.fromARGB(100, 0, 0, 0);
    canvas.drawRect(
      Rect.fromLTWH(10, 10, size.width - 20, 100),
      uiBgPaint,
    );

    // テキストペインター
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // スコア表示
    textPainter.text = TextSpan(
      text: 'ぷるぷる度: ${gameState.score}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontFamily: 'Meiryo',
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(20, 20));

    // 残り時間表示
    textPainter.text = TextSpan(
      text: '残り時間: ${gameState.timeLeft}',
      style: const TextStyle(
        color: Color.fromARGB(255, 255, 200, 0),
        fontSize: 24,
        fontFamily: 'Meiryo',
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(20, 60));

    // ハイスコア表示（右寄せ）
    textPainter.text = TextSpan(
      text: '最高記録: ${gameState.highScore}',
      style: const TextStyle(
        color: Color.fromARGB(255, 200, 255, 200),
        fontSize: 18,
        fontFamily: 'Meiryo',
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width - textPainter.width - 30, 25),
    );
  }

  /// ゲームオーバーバナーと結果を描画
  void _drawGameOverBanner(Canvas canvas, Size size) {
    // 黒半透明バナー
    final bannerPaint = Paint()..color = const Color.fromARGB(180, 0, 0, 0);
    const double bannerHeight = 170.0;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height / 2 + 125, size.width, bannerHeight),
      bannerPaint,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final centerX = size.width / 2;

    // 「判定結果」テキスト
    textPainter.text = const TextSpan(
      text: '【判定結果】',
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontFamily: 'Meiryo',
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(centerX - textPainter.width / 2, size.height / 2 + 160),
    );

    // 称号テキスト
    textPainter.text = TextSpan(
      text: gameState.getTitle(),
      style: const TextStyle(
        color: Color.fromARGB(255, 255, 100, 100),
        fontSize: 36,
        fontFamily: 'Meiryo',
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(centerX - textPainter.width / 2, size.height / 2 + 210),
    );

    // 新記録メッセージ
    if (gameState.isNewRecord) {
      textPainter.text = const TextSpan(
        text: 'NEW RECORD!',
        style: TextStyle(
          color: Color.fromARGB(255, 255, 255, 0),
          fontSize: 16,
          fontFamily: 'Meiryo',
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, size.height / 2 + 120),
      );
    }

    // リトライボタン
    final buttonRect = Rect.fromCenter(
      center: Offset(centerX, size.height / 2 + 290),
      width: 220,
      height: 50,
    );

    final buttonPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(buttonRect, const Radius.circular(12)),
      buttonPaint,
    );

    textPainter.text = const TextSpan(
      text: 'もう一度ぷるぷる',
      style: TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontFamily: 'Meiryo',
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        centerX - textPainter.width / 2,
        size.height / 2 + 265,
      ),
    );
  }

  /// ゲンゲの矩形（判定用）を取得
  Rect getGengeRect(Size size) {
    if (gengeImage == null) return Rect.zero;
    
    const baseWidth = 400.0;
    final aspectRatio = gengeImage!.height / gengeImage!.width;
    final baseHeight = baseWidth * aspectRatio;

    final shakeAmount = gameState.shakingFrames;
    final drawWidth = baseWidth + (shakeAmount * 8);
    final drawHeight = baseHeight - (shakeAmount * 4);

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    return Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: drawWidth,
      height: drawHeight,
    );
  }

  /// リトライボタンの矩形（判定用）を取得
  Rect getRetryButtonRect(Size size) {
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 + 290),
      width: 220,
      height: 50,
    );
  }

  @override
  bool shouldRepaint(GengeGamePainter oldDelegate) {
    return gameState != oldDelegate.gameState ||
        backgroundImage != oldDelegate.backgroundImage ||
        gengeImage != oldDelegate.gengeImage;
  }
}
