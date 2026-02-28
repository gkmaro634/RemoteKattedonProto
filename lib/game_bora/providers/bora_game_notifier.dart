import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_kattedon/game_bora/providers/bora_game_engine.dart';
import '../models/bora_models.dart';


// Riverpod notifier
class BoraGameNotifier extends AutoDisposeNotifier<GameState> {
  BoraGameEngine? _engine;

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
    _engine = null;
    return placeholder;
  }

  void startGame(Character char) {
    if (_engine == null) {
      final initial = GameState(
        phase: GamePhase.waiting,
        character: char,
        boras:
            List.generate(GAME_CONFIG['initialBoraCount'] as int, (_) => generateBora()),
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
      _engine = BoraGameEngine(state: initial, character: char);
    }
    state = _engine!.state;
  }

  void updateFrame(double deltaTime) {
    if (_engine == null) return;
    _engine!.update(deltaTime);
    state = _engine!.state;
  }

  void onCallSupporter() {
    _engine?.callSupporter();
    state = _engine!.state;
  }

  void onRaiseNet() {
    _engine?.raiseNet();
    state = _engine!.state;
  }

  void reset(Character char) {
    if (_engine == null) {
      startGame(char);
    } else {
      _engine!.reset(char);
      state = _engine!.state;
    }
  }
}

final boraGameProvider =
    NotifierProvider.autoDispose<BoraGameNotifier, GameState>(() => BoraGameNotifier());
