import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:remote_kattedon/game_genge/models/game_state.dart';
import 'package:remote_kattedon/game_genge/services/highscore_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'dart:async';

class GengeGameEngine {
  GengeGameState state;
  final int gameLimit;
  DateTime? startTime;
  bool _running = false;

  GengeGameEngine({
    required this.state,
    required this.gameLimit,
  });

  void start() {
    startTime = DateTime.now();
    _running = true;
  }

  void reset(GengeGameState newState, {bool autoStart = true}) {
    state = newState;
    startTime = null;
    _running = autoStart;
    if (autoStart) {
      start();
    }
  }

  void update() {
    if (!_running || startTime == null) return;
    if (state.isGameOver) return;

    final elapsed = DateTime.now().difference(startTime!).inSeconds;
    final timeLeft = max(0, gameLimit - elapsed);

    // particle update
    // final updatedParticles = [...state.particles];
    // for (var p in updatedParticles) {
    //   p.update();
    // }
    final updated = [...state.particles]..forEach((p) => p.update());
    final alive = updated.where((p) => p.isAlive).toList();
    final newShaking = max(0, state.shakingFrames - 1);

    state = state.copyWith(
      timeLeft: timeLeft,
      particles: alive,
      shakingFrames: newShaking,
      isGameOver: timeLeft == 0,
    );
  }

  void tap(Offset pos) {
    if (!_running || state.isGameOver) return;

    final particles = [...state.particles];
    final random = Random();

    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * 2 * pi;
      final speed = random.nextDouble() * 4 + 3;

      particles.add(
        ParticleData(
          x: pos.dx,
          y: pos.dy,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          lifespan: 25,
        ),
      );
    }

    if (particles.length > 60) {
      particles.removeRange(0, particles.length - 60);
    }

    state = state.copyWith(
      score: state.score + 1,
      shakingFrames: 15,
      particles: particles,
    );
  }
}

/// ハイスコアを取得するプロバイダ
final highscoreProvider = FutureProvider<int>((ref) async {
  return await HighscoreService.loadHighscore();
});

/// ゲーム状態を管理するNotifier

class GengeGameNotifier extends AutoDisposeAsyncNotifier<GengeGameState> {
  GengeGameEngine? _engine;
  static const int _gameLimit = 15; // 秒
  bool _handleGameOver = false;

  // audio player and asset paths
  // 結果用（1回だけ鳴る）とタップ用（連打される）を分ける
  final AudioPlayer _resultPlayer = AudioPlayer();
  late AudioPool _tapPool;

  static const String _soundTap = 'audio/genge/pochi.mp3';
  static const String _soundMaster = 'audio/genge/hakushu.mp3';
  static const String _soundNormal = 'audio/genge/koto.mp3';
  static const String _soundZero = 'audio/genge/gaan.mp3';

  @override
  Future<GengeGameState> build() async {
    print("GengeGameNotifier build");

    _tapPool = await AudioPool.create(
      source: AssetSource(_soundTap),
      maxPlayers: 5,
    );

    final highScore = await HighscoreService.loadHighscore();
    final initial = GengeGameState.initial(highScore);
    _engine = GengeGameEngine(state: initial, gameLimit: _gameLimit);

    ref.onDispose(() {
      _resultPlayer.dispose();
      _tapPool.dispose();

      print("GengeGameNotifier disposed");
    });

    Future.microtask(startGame);

    return initial;
  }

  /// ゲームを開始する
  void startGame() {
    if (_engine == null) return;

    _engine!.start();
    _handleGameOver = false;
    state = AsyncValue.data(_engine!.state);
  }

  /// ゲーム終了処理
  Future<void> _onGameOver(GengeGameState currentState) async {
    // ハイスコア更新チェック
    int newHighScore = currentState.highScore;
    if (currentState.score > currentState.highScore) {
      newHighScore = currentState.score;
      await HighscoreService.saveHighscore(newHighScore);
    }

    // 結果音声を再生
    _playEndSound(currentState.score);

    state = AsyncValue.data(currentState.copyWith(
      isGameOver: true,
      highScore: newHighScore,
    ));
  }

  void _playTapSound() {
    _tapPool.start();
  }

  void _playEndSound(int score) {
    String sound =
        score >= 100 ? _soundMaster : (score > 0 ? _soundNormal : _soundZero);
    _resultPlayer.stop();
    _resultPlayer.play(AssetSource(sound)).catchError((_) {});
  }

  /// ゲンゲをタップしたときの処理
  void onGengePressed(Offset tapPosition) async {
    if (_engine == null) return;

    // タップ音
    _playTapSound();

    _engine!.tap(tapPosition);
    state = AsyncValue.data(_engine!.state);
  }

  /// パーティクルと揺れを更新する
  void updateFrame() {
    if (_engine == null) return;

    _engine!.update();
    final newState = _engine!.state;

    if (newState.isGameOver && !_handleGameOver) {
      _handleGameOver = true;
      _onGameOver(newState);
      return;
    }

    state = AsyncValue.data(newState);
  }

  /// ゲームをリセットする
  void resetGame() async {
    if (_engine == null) return;

    final highScore = await HighscoreService.loadHighscore();
    final initial = GengeGameState.initial(highScore);

    _engine?.reset(initial, autoStart: true);

    _handleGameOver = false;
    state = AsyncValue.data(_engine!.state);
  }
}

/// ゲーム状態プロバイダ
final gengeGameProvider =
    AsyncNotifierProvider.autoDispose<GengeGameNotifier, GengeGameState>(
  () => GengeGameNotifier(),
);
