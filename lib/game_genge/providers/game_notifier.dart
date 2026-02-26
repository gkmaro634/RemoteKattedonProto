import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:remote_kattedon/game_genge/models/game_state.dart';
import 'package:remote_kattedon/game_genge/services/highscore_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'dart:async';

/// ハイスコアを取得するプロバイダ
final highscoreProvider = FutureProvider<int>((ref) async {
  return await HighscoreService.loadHighscore();
});

/// ゲーム状態を管理するNotifier

class GengeGameNotifier extends AsyncNotifier<GengeGameState> {
  Timer? _gameTimer;
  late DateTime _gameStartTime;
  static const int _gameLimit = 15; // 秒

  // audio player and asset paths
  final AudioPlayer _audioPlayer = AudioPlayer();
  static const String _soundTap = 'assets/audio/genge/pochi.mp3';
  static const String _soundMaster = 'assets/audio/genge/hakushu.mp3';
  static const String _soundNormal = 'assets/audio/genge/koto.mp3';
  static const String _soundZero = 'assets/audio/genge/gaan.mp3';


  @override
  Future<GengeGameState> build() async {
    final highScore = await HighscoreService.loadHighscore();
    return GengeGameState.initial(highScore);
  }

  /// ゲームを開始する
  void startGame() {
    _gameStartTime = DateTime.now();
    // cancel any existing timer before starting a new one
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _updateGameTime();
    });
  }

  /// ゲーム時間を更新する
  void _updateGameTime() {
    final elapsed = DateTime.now().difference(_gameStartTime).inSeconds;
    final timeLeft = max(0, _gameLimit - elapsed);

    state.whenData((gameState) {
      if (gameState.timeLeft != timeLeft) {
        final newState = gameState.copyWith(timeLeft: timeLeft);

        // ゲーム終了判定
        if (timeLeft == 0 && !gameState.isGameOver) {
          _onGameOver(newState);
        } else {
          state = AsyncValue.data(newState);
        }
      }
    });
  }

  /// ゲーム終了処理
  Future<void> _onGameOver(GengeGameState currentState) async {
    _gameTimer?.cancel();

    // ハイスコア更新チェック
    int newHighScore = currentState.highScore;
    if (currentState.score > currentState.highScore) {
      newHighScore = currentState.score;
      await HighscoreService.saveHighscore(newHighScore);
    }

    // 結果音声を再生
    try {
      if (currentState.score >= 100) {
        await _audioPlayer.play(AssetSource(_soundMaster));
      } else if (currentState.score > 0) {
        await _audioPlayer.play(AssetSource(_soundNormal));
      } else {
        await _audioPlayer.play(AssetSource(_soundZero));
      }
    } catch (_) {}

    final finalState = currentState.copyWith(
      isGameOver: true,
      highScore: newHighScore,
    );
    state = AsyncValue.data(finalState);
  }

  /// ゲンゲをタップしたときの処理
  void onGengePressed(Offset tapPosition) async {
    final gameState = state.value;
    if (gameState == null || gameState.isGameOver || gameState.timeLeft <= 0) {
      return;
    }

    // タップ音
    try {
      await _audioPlayer.play(AssetSource(_soundTap));
    } catch (_) {}

    // スコア加算
    final newScore = gameState.score + 1;

    // パーティクル生成（6個）
    final particles = [...gameState.particles];
    final random = Random();
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * 2 * pi;
      final speed = random.nextDouble() * 4 + 3;
      particles.add(
        ParticleData(
          x: tapPosition.dx,
          y: tapPosition.dy,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          lifespan: 25,
        ),
      );
    }
    if (particles.length > 60) {
      particles.removeRange(0, particles.length - 60);
    }

    final newState = gameState.copyWith(
      score: newScore,
      shakingFrames: 15,
      particles: particles,
    );

    state = AsyncValue.data(newState);
  }

  /// パーティクルと揺れを更新する
  void updateParticles() {
    state.whenData((gameState) {
      if (gameState.isGameOver) return;

      // パーティクル更新
      final updatedParticles = [...gameState.particles];
      for (var particle in updatedParticles) {
        particle.update();
      }
      final aliveParticles = updatedParticles.where((p) => p.isAlive).toList();

      // 揺れ更新
      final newShaking = max(0, gameState.shakingFrames - 1);

      final newState = gameState.copyWith(
        shakingFrames: newShaking,
        particles: aliveParticles,
      );

      state = AsyncValue.data(newState);
    });
  }

  /// ゲームをリセットする
  void resetGame() async {
    _gameTimer?.cancel();
    final highScore = await HighscoreService.loadHighscore();
    state = AsyncValue.data(GengeGameState.initial(highScore));
  }
}

/// ゲーム状態プロバイダ
final gengeGameProvider = AsyncNotifierProvider<GengeGameNotifier, GengeGameState>(
  () => GengeGameNotifier(),
);
