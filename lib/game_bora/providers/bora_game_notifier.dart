import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_kattedon/game_bora/providers/bora_game_engine.dart';
import '../models/bora_models.dart';

// Riverpod notifier
class BoraGameNotifier extends AutoDisposeNotifier<GameState> {
  late BoraGameEngine _engine;

  @override
  GameState build() {
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
    );
  }

  void startGame(Character char) {
    final initial = createInitialState(char);
    _engine = BoraGameEngine(state: initial, character: char);
    state = initial;
    // if (_engine == null) {
    //   final initial = createInitialState(char);
    //   _engine = BoraGameEngine(state: initial, character: char);
    // }
    // state = _engine!.state;
  }

  void updateFrame(double deltaTime) {
    _engine.update(deltaTime);
    state = _engine.state;
  }

  void onCallSupporter() {
    _engine.callSupporter();
    state = _engine.state;
  }

  void onRaiseNet() {
    _engine.raiseNet();
    state = _engine.state;
  }

  void reset(Character char) {
    _engine.reset(char);
    state = _engine.state;

    // if (_engine == null) {
    //   startGame(char);
    // } else {
    //   _engine.reset(char);
    //   state = _engine.state;
    // }
  }
}

final boraGameProvider =
    NotifierProvider.autoDispose<BoraGameNotifier, GameState>(
        () => BoraGameNotifier());
