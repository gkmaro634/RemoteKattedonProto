import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_kattedon/game_bora/providers/bora_game_engine.dart';
import 'package:remote_kattedon/game_bora/services/high_score_service.dart';
import '../models/bora_models.dart';

// Riverpod notifier
class BoraGameNotifier extends AutoDisposeAsyncNotifier<GameState> {
  late BoraGameEngine _engine;
  int _highScore = 0;

  @override
  Future<GameState> build() async {
    // Load high score
    _highScore = await HighScoreService.getHighScore();
    // initial placeholder state
    final placeholder = GameState(
      phase: GamePhase.title,
      character: null,
      boras: [],
      supporters: [],
      virtueGauge: 0,
      maxVirtue: 0,
      netProgress: 0,
      isRaising: false,
      caughtBoras: 0,
      escapedBoras: 0,
      score: 0,
      gameTime: 0,
      netSpeed: 0,
      boraCountInNet: 0,
      highScore: _highScore,
      isNewHighScore: false,
    );
    return placeholder;
  }

  GameState createInitialState(Character char) {
    return GameState(
      phase: GamePhase.waiting,
      character: char,
      boras: List.generate(
          GAME_CONFIG['initialBoraCount'] as int, (_) => generateBora()),
      supporters: [],
      virtueGauge: char.maxVirtue.toDouble(),
      maxVirtue: char.maxVirtue.toDouble(),
      netProgress: 0,
      isRaising: false,
      caughtBoras: 0,
      escapedBoras: 0,
      score: 0,
      gameTime: 0,
      netSpeed: char.stats.netSpeed * 2.0,
      boraCountInNet: 0,
      highScore: _highScore,
      isNewHighScore: false,
    );
  }

  void startGame(Character char) {
    final initial = createInitialState(char);
    _engine = BoraGameEngine(state: initial, character: char);
    state = AsyncData(initial);
  }

  void updateFrame(double deltaTime) {
    _engine.update(deltaTime);
    final newState = _engine.state;
    // Check for high score update
    if (newState.phase == GamePhase.result && newState.score > _highScore) {
      _highScore = newState.score;
      HighScoreService.setHighScore(_highScore);
      newState.highScore = _highScore;
      newState.isNewHighScore = true;
    }
    state = AsyncData(newState);
  }

  void onCallSupporter() {
    _engine.callSupporter();
    state = AsyncData(_engine.state);
  }

  void onRaiseNet() {
    _engine.raiseNet();
    state = AsyncData(_engine.state);
  }

  void reset(Character char) {
    _engine.reset(char);
    final newState = _engine.state;
    newState.isNewHighScore = false; // Reset flag
    state = AsyncData(newState);
  }
}

final boraGameProvider =
    AsyncNotifierProvider.autoDispose<BoraGameNotifier, GameState>(
        () => BoraGameNotifier());
