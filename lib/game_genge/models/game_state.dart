/// ゲンゲゲームの状態を表す
class GengeGameState {
  final int score;
  final int timeLeft;
  final int highScore;
  final bool isGameOver;
  final bool playedFinishSound;
  final int shakingFrames;
  final List<ParticleData> particles;

  const GengeGameState({
    required this.score,
    required this.timeLeft,
    required this.highScore,
    required this.isGameOver,
    required this.playedFinishSound,
    required this.shakingFrames,
    required this.particles,
  });

  /// ゲーム開始時の初期状態
  factory GengeGameState.initial(int highScore) {
    return GengeGameState(
      score: 0,
      timeLeft: 15,
      highScore: highScore,
      isGameOver: false,
      playedFinishSound: false,
      shakingFrames: 0,
      particles: [],
    );
  }

  GengeGameState copyWith({
    int? score,
    int? timeLeft,
    int? highScore,
    bool? isGameOver,
    bool? playedFinishSound,
    int? shakingFrames,
    List<ParticleData>? particles,
  }) {
    return GengeGameState(
      score: score ?? this.score,
      timeLeft: timeLeft ?? this.timeLeft,
      highScore: highScore ?? this.highScore,
      isGameOver: isGameOver ?? this.isGameOver,
      playedFinishSound: playedFinishSound ?? this.playedFinishSound,
      shakingFrames: shakingFrames ?? this.shakingFrames,
      particles: particles ?? this.particles,
    );
  }

  /// スコアに応じた称号を返す
  String getTitle() {
    if (score == 0) return 'ただの干物';
    if (score < 50) return 'ぷるぷる初心者';
    if (score < 100) return 'コラーゲン職人';
    return '伝説のゲンゲマスター';
  }

  /// 新記録更新したかどうか
  bool get isNewRecord => score > highScore && score > 0;
}

/// パーティクルのデータ
class ParticleData {
  double x;
  double y;
  double vx;
  double vy;
  int lifespan;

  ParticleData({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.lifespan,
  });

  /// パーティクルを更新する
  void update() {
    x += vx;
    y += vy;
    lifespan--;
  }

  /// パーティクルがまだ生きているか
  bool get isAlive => lifespan > 0;
}
