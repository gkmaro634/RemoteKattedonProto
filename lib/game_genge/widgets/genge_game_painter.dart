import 'package:flutter/material.dart';
import 'package:remote_kattedon/game_genge/models/game_state.dart';
import 'dart:ui' as ui;

import 'package:remote_kattedon/game_genge/models/genge_layout.dart';

/// ゲンゲゲームを描画するカスタムペインター
class GengeGamePainter extends CustomPainter {
  final GengeGameState gameState;
  final ui.Image? backgroundImage;
  final ui.Image? gengeImage;
  late final TextPainter scorePainter;
  late final TextPainter timePainter;
  late final TextPainter highScorePainter;
  late final Paint particlePaint;
  late final Paint uiBgPaint;
  late final Paint bannerPaint;
  late final double gengeAspectRatio;
  late final int gengeImageWidth;
  late final int gengeImageHeight;

  GengeGamePainter({
    required this.gameState,
    required this.backgroundImage,
    required this.gengeImage,
  }) {
    // テキストペインター
    scorePainter = TextPainter(textDirection: TextDirection.ltr);
    timePainter = TextPainter(textDirection: TextDirection.ltr);
    highScorePainter = TextPainter(textDirection: TextDirection.ltr);

    particlePaint = Paint()..color = const Color.fromARGB(255, 180, 240, 255);
    uiBgPaint = Paint()..color = const Color.fromARGB(100, 0, 0, 0);
    bannerPaint = Paint()..color = const Color.fromARGB(180, 0, 0, 0);

    if (gengeImage != null) {
      gengeImageWidth = gengeImage!.width;
      gengeImageHeight = gengeImage!.height;
      gengeAspectRatio = gengeImageHeight / gengeImageWidth;
    }
  }

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

    final srcRect = Rect.fromLTWH(
      0,
      0,
      gengeImageWidth.toDouble(),
      gengeImageHeight.toDouble(),
    );
    // 描画位置（中央）
    final rect = calcGengeRect(
      canvasSize: size,
      imageWidth: gengeImageWidth.toDouble(),
      imageHeight: gengeImageHeight.toDouble(),
      shakingFrames: gameState.shakingFrames,
    );
    canvas.drawImageRect(
      gengeImage!,
      srcRect,
      rect,
      Paint(),
    );
  }

  /// パーティクルを描画
  void _drawParticles(Canvas canvas) {
    for (final particle in gameState.particles) {
      final radius = (particle.lifespan / 3).clamp(0, 10).toDouble();
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        radius,
        particlePaint,
      );
    }
  }

  /// UI を描画
  void _drawUI(Canvas canvas, Size size) {
    // 半透明の背景
    canvas.drawRect(
      Rect.fromLTWH(10, 10, size.width - 20, 100),
      uiBgPaint,
    );

    // テキストは事前作成したTextPainterを使う

    // スコア表示
    scorePainter.text = TextSpan(
      text: 'ぷるぷる度: ${gameState.score}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontFamily: 'Meiryo',
      ),
    );
    scorePainter.layout();
    scorePainter.paint(canvas, const Offset(20, 20));

    // 残り時間表示
    timePainter.text = TextSpan(
      text: '残り時間: ${gameState.timeLeft}',
      style: const TextStyle(
        color: Color.fromARGB(255, 255, 200, 0),
        fontSize: 24,
        fontFamily: 'Meiryo',
      ),
    );
    timePainter.layout();
    timePainter.paint(canvas, const Offset(20, 60));

    // ハイスコア表示（右寄せ）
    highScorePainter.text = TextSpan(
      text: '最高記録: ${gameState.highScore}',
      style: const TextStyle(
        color: Color.fromARGB(255, 200, 255, 200),
        fontSize: 18,
        fontFamily: 'Meiryo',
        fontWeight: FontWeight.bold,
      ),
    );
    highScorePainter.layout();
    highScorePainter.paint(
      canvas,
      Offset(size.width - highScorePainter.width - 30, 25),
    );
  }

  /// ゲームオーバーバナーと結果を描画
  void _drawGameOverBanner(Canvas canvas, Size size) {
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
  bool shouldRepaint(GengeGamePainter oldDelegate) => true;
}
