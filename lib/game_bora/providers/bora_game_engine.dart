import 'dart:math';
import '../models/bora_models.dart';

class _PendingSupporter {
  final Supporter supporter;
  final int arrivalTime;
  _PendingSupporter({required this.supporter, required this.arrivalTime});
}

class BoraGameEngine {
  GameState state;
  final Character character;
  // timers
  double _boraSpawnTimer = 0;
  double _boraDecreaseTimer = 0;
  double _virtueRegenTimer = 0;

  // pending supporters (arrivalTime in milliseconds since epoch)
  final List<_PendingSupporter> pending = [];

  BoraGameEngine({required this.state, required this.character});

  void reset(Character char) {
    state = GameState(
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
    _boraSpawnTimer = 0;
    _boraDecreaseTimer = 0;
    _virtueRegenTimer = 0;
    pending.clear();
  }

  void update(double deltaTime) {
    updateFish(deltaTime);
    updateSupporters(deltaTime);
    updateNet(deltaTime);
    updateTimer(deltaTime);
    
    if (state.phase == GamePhase.result) return;
    state.gameTime += deltaTime;

    final now = DateTime.now().millisecondsSinceEpoch;

    // handle supporter arrivals
    final arrived = pending.where((p) => p.arrivalTime <= now).toList();
    pending.removeWhere((p) => p.arrivalTime <= now);
    if (arrived.isNotEmpty) {
      state.supporters.addAll(arrived.map((p) => p.supporter));
    }

    if (!state.isRaising) {
      // decrement supporter timers
      state.supporters = state.supporters
          .map((s) {
            s.timeLeft = s.timeLeft - deltaTime;
            return s;
          })
          .where((s) => s.timeLeft > 0)
          .toList();
    }

    // calculate speed
    state.netSpeed = calculateNetSpeed(character, state.supporters);

    // virtue regen
    _virtueRegenTimer += deltaTime;
    if (_virtueRegenTimer >= 2) {
      _virtueRegenTimer = 0;
      state.virtueGauge = min(
          state.maxVirtue, state.virtueGauge + getVirtueRegenRate(character));
    }

    // update bora positions
    state.boras = state.boras
        .map((b) => updateBoraPosition(b, deltaTime, state.isRaising))
        .toList();

    if (state.isRaising) {
      state.netProgress =
          min(100, state.netProgress + state.netSpeed * deltaTime);
      // escape logic
      final escapeRate = calculateBoraEscapeRate(state.netSpeed, character);
      final escapeChance = escapeRate * deltaTime * 0.25;
      int escapedCount = 0;
      state.boras = state.boras.map((b) {
        if (b.inNet && !b.escaping && Random().nextDouble() < escapeChance) {
          escapedCount++;
          b.escaping = true;
          b.direction = Random().nextDouble() * 360;
        }
        return b;
      }).toList();
      state.escapedBoras += escapedCount;
      // remove escaped off-screen
      state.boras = state.boras.where((b) {
        if (b.escaping && (b.x < -5 || b.x > 105 || b.y < 15 || b.y > 100)) {
          return false;
        }
        return true;
      }).toList();
      // finished raising
      if (state.netProgress >= 100) {
        final caught = state.boras.where((b) => b.inNet && !b.escaping).length;
        state.caughtBoras += caught;
        state.boras = state.boras.where((b) => !b.inNet).toList();
        state.score =
            calculateScore(state.caughtBoras, state.gameTime, state.supporters);
        state.netProgress = 0;
        state.isRaising = false;
      }
    } else {
      // waiting mode spawn / decrease
      _boraSpawnTimer += deltaTime;
      if (_boraSpawnTimer >= (GAME_CONFIG['boraSpawnInterval'] as num)) {
        _boraSpawnTimer = 0;
        if (state.boras.length < (GAME_CONFIG['maxBoraCount'] as int)) {
          final count = min((GAME_CONFIG['boraSpawnCount'] as int),
              (GAME_CONFIG['maxBoraCount'] as int) - state.boras.length);
          state.boras.addAll(List.generate(count, (_) => generateBora()));
        }
      }
      _boraDecreaseTimer += deltaTime;
      if (_boraDecreaseTimer >= (GAME_CONFIG['boraDecreaseInterval'] as num)) {
        _boraDecreaseTimer = 0;
        if (state.boras.length > (GAME_CONFIG['minBoraCount'] as int)) {
          final idx = Random().nextInt(state.boras.length);
          state.boras.removeAt(idx);
          state.escapedBoras++;
        }
      }
    }

    state.boraCountInNet =
        state.boras.where((b) => b.inNet && !b.escaping).length;

    if (state.gameTime >= 120) {
      state.phase = GamePhase.result;
    }
  }

  void updateFish(double deltaTime) {}

  void updateSupporters(double deltaTime) {}

  void updateNet(double deltaTime) {}

  void updateTimer(double deltaTime) {}

  void callSupporter() {
    if (state.character == null) return;
    final cost = getVirtueCost(state.character!);
    if (state.virtueGauge < cost) return;
    if (state.supporters.length >= getMaxSupporters(state.character!)) return;
    if (state.isRaising) return;

    final supporter = generateSupporter(state.character!);
    final arrival = DateTime.now().millisecondsSinceEpoch +
        (GAME_CONFIG['supporterArrivalDelay'] as int) * 1000;
    pending.add(_PendingSupporter(supporter: supporter, arrivalTime: arrival));
    state.virtueGauge = max(0, state.virtueGauge - cost);
  }

  void raiseNet() {
    if (!state.isRaising) {
      state.isRaising = true;
    }
  }
}
