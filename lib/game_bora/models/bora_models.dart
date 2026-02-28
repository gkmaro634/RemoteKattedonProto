import 'dart:math';

/// キャラクタータイプ
enum CharacterType { power, vision, virtue }

/// キャラクター設定
class Character {
  final CharacterType id;
  final String name;
  final String description;
  final CharacterStats stats;
  final int maxVirtue;
  final String emoji;

  const Character({
    required this.id,
    required this.name,
    required this.description,
    required this.stats,
    required this.maxVirtue,
    required this.emoji,
  });
}

class CharacterStats {
  final int netSpeed;
  final int visionRange;
  final int virtue;

  const CharacterStats({
    required this.netSpeed,
    required this.visionRange,
    required this.virtue,
  });
}

/// 応援者
class Supporter {
  final String id;
  final String name;
  final double speedBonus;
  final double duration;
  double timeLeft;
  final String quality;
  final String emoji;

  Supporter({
    required this.id,
    required this.name,
    required this.speedBonus,
    required this.duration,
    required this.timeLeft,
    required this.quality,
    required this.emoji,
  });
}

/// ボラ
class Bora {
  final String id;
  double x;
  double y;
  final BoraSize size;
  final double speed;
  double direction;
  bool inNet;
  bool escaping;

  Bora({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.direction,
    required this.inNet,
    required this.escaping,
  });
}

enum BoraSize { small, medium, large }

/// ゲームフェーズ
enum GamePhase { title, character, waiting, raising, result }

/// ゲーム状態
class GameState {
  GamePhase phase;
  Character? character;
  List<Bora> boras;
  List<Supporter> supporters;
  double virtueGauge;
  double maxVirtue;
  double netProgress;
  bool isRaising;
  int caughtBoras;
  int escapedBoras;
  int score;
  double gameTime;
  double netSpeed;
  int boraCountInNet;

  GameState({
    required this.phase,
    this.character,
    required this.boras,
    required this.supporters,
    required this.virtueGauge,
    required this.maxVirtue,
    required this.netProgress,
    required this.isRaising,
    required this.caughtBoras,
    required this.escapedBoras,
    required this.score,
    required this.gameTime,
    required this.netSpeed,
    required this.boraCountInNet,
  });
}

/// キャラクターデータ
final Map<CharacterType, Character> CHARACTERS = {
  CharacterType.power: const Character(
    id: CharacterType.power,
    name: 'パワー型',
    description:
        '力強い漁師。網の引き上げがたいへん速く、少ない応援でも短時間で引き上げられる。ボラが逃げる前に網を上げきる力務め漁師。',
    stats: CharacterStats(netSpeed: 8, visionRange: 2, virtue: 2),
    maxVirtue: 60,
    emoji: '💪',
  ),
  CharacterType.vision: const Character(
    id: CharacterType.vision,
    name: '視力型',
    description:
        '鮮い目を持つ漁師。引き上げ中にボラが逃げにくく、人徳ゲージの回復が速い。網の速度は遅いが、ボラを逃さない目で大漁を目指す。',
    stats: CharacterStats(netSpeed: 2, visionRange: 5, virtue: 2),
    maxVirtue: 60,
    emoji: '👁️',
  ),
  CharacterType.virtue: const Character(
    id: CharacterType.virtue,
    name: '人徳型',
    description:
        '村で慕われる漁師。応援を呼ぶコストが安く、最大8人まで呼べる。名人や力持ちなど頑鯊な助っ人が集まりやすい。',
    stats: CharacterStats(netSpeed: 3, visionRange: 3, virtue: 5),
    maxVirtue: 60,
    emoji: '🤝',
  ),
};

const _supporterTemplates = [
  {
    'name': '隣の田中さん',
    'speedBonus': 1.5,
    'duration': 15.0,
    'quality': 'poor',
    'emoji': '👴',
  },
  {
    'name': '漁協の山田さん',
    'speedBonus': 3.0,
    'duration': 20.0,
    'quality': 'normal',
    'emoji': '🧑',
  },
  {
    'name': '元漁師の鈴木さん',
    'speedBonus': 4.5,
    'duration': 25.0,
    'quality': 'good',
    'emoji': '👨‍🦳',
  },
  {
    'name': '若い衆の佐藤くん',
    'speedBonus': 2.5,
    'duration': 18.0,
    'quality': 'normal',
    'emoji': '👦',
  },
  {
    'name': '力持ちの熊田さん',
    'speedBonus': 6.0,
    'duration': 12.0,
    'quality': 'good',
    'emoji': '💪',
  },
  {
    'name': '漁師の名人・能登太郎',
    'speedBonus': 9.0,
    'duration': 30.0,
    'quality': 'excellent',
    'emoji': '🏆',
  },
  {
    'name': '村長の奈さん',
    'speedBonus': 3.5,
    'duration': 22.0,
    'quality': 'normal',
    'emoji': '👩',
  },
  {
    'name': '子供たち',
    'speedBonus': 1.0,
    'duration': 10.0,
    'quality': 'poor',
    'emoji': '👧',
  },
];

String _generateId() {
  return DateTime.now().microsecondsSinceEpoch.toString() +
      Random().nextInt(100000).toString();
}

Supporter generateSupporter(Character character) {
  final virtue = character.stats.virtue;
  List<double> weights;
  if (virtue >= 5) {
    weights = [0.02, 0.08, 0.20, 0.10, 0.25, 0.28, 0.05, 0.02];
  } else if (virtue >= 4) {
    weights = [0.10, 0.20, 0.25, 0.20, 0.15, 0.05, 0.03, 0.02];
  } else if (virtue >= 3) {
    weights = [0.15, 0.25, 0.20, 0.20, 0.12, 0.02, 0.04, 0.02];
  } else {
    weights = [0.25, 0.30, 0.15, 0.15, 0.10, 0.01, 0.02, 0.02];
  }
  final rand = Random().nextDouble();
  double cumulative = 0;
  int selected = 0;
  for (int i = 0; i < weights.length; i++) {
    cumulative += weights[i];
    if (rand < cumulative) {
      selected = i;
      break;
    }
  }
  final tpl = _supporterTemplates[selected];
  return Supporter(
    id: _generateId(),
    name: tpl['name'] as String,
    speedBonus: tpl['speedBonus'] as double,
    duration: tpl['duration'] as double,
    timeLeft: tpl['duration'] as double,
    quality: tpl['quality'] as String,
    emoji: tpl['emoji'] as String,
  );
}

Bora generateBora() {
  const sizes = BoraSize.values;
  final size = sizes[Random().nextInt(sizes.length)];
  return Bora(
    id: _generateId(),
    x: Random().nextDouble() * 80 + 10,
    y: Random().nextDouble() * 60 + 20,
    size: size,
    speed: Random().nextDouble() * 0.5 + 0.2,
    direction: Random().nextDouble() * 360,
    inNet: false,
    escaping: false,
  );
}

bool isBoraInNetArea(Bora bora) {
  return bora.x >= 20 && bora.x <= 80 && bora.y >= 35 && bora.y <= 90;
}

double calculateNetSpeed(Character character, List<Supporter> supporters) {
  final baseSpeed = character.stats.netSpeed * 2;
  final supportBonus = supporters.fold<double>(0, (sum, s) => sum + s.speedBonus);
  final countMultiplier = 1 + supporters.length * 0.2;
  return (baseSpeed + supportBonus) * countMultiplier;
}

double calculateBoraEscapeRate(double netSpeed, [Character? character]) {
  const baseEscapeRate = 0.5;
  final speedFactor = max(0, 1 - netSpeed / 20);
  final rawRate = baseEscapeRate + speedFactor * 0.5;
  if (character?.id == CharacterType.vision) return rawRate * 0.3;
  return rawRate;
}

int calculateScore(int caughtBoras, double gameTime, List<Supporter> supporters) {
  final baseScore = caughtBoras * 100;
  final timeBonus = max(0, 300 - gameTime).toInt() * 2;
  final supporterBonus = supporters.length * 50;
  return baseScore + timeBonus + supporterBonus;
}

int getVirtueCost(Character character) {
  if (character.id == CharacterType.virtue) return 8;
  return 12;
}

Bora updateBoraPosition(Bora bora, double deltaTime, [bool isRaising = false]) {
  if (bora.escaping) {
    bora.x += bora.speed * 3 * cos(bora.direction * pi / 180) * deltaTime;
    bora.y += bora.speed * 3 * sin(bora.direction * pi / 180) * deltaTime;
    return bora;
  }
  final newDirection = bora.direction + (Random().nextDouble() - 0.5) * 30;
  double newX = bora.x + bora.speed * cos(newDirection * pi / 180) * deltaTime * 10;
  double newY = bora.y + bora.speed * sin(newDirection * pi / 180) * deltaTime * 10;
  newX = newX.clamp(5, 95);
  newY = newY.clamp(30, 90);
  final newInNet = isRaising && !bora.inNet
      ? false
      : isBoraInNetArea(Bora(
            id: bora.id,
            x: newX,
            y: newY,
            size: bora.size,
            speed: bora.speed,
            direction: newDirection,
            inNet: bora.inNet,
            escaping: bora.escaping,
          ));
  bora.x = newX;
  bora.y = newY;
  bora.direction = newDirection;
  bora.inNet = newInNet;
  return bora;
}

const GAME_CONFIG = {
  'initialBoraCount': 8,
  'maxBoraCount': 20,
  'minBoraCount': 3,
  'boraSpawnInterval': 3,
  'boraSpawnCount': 2,
  'boraDecreaseInterval': 5,
  'netRaiseThreshold': 5,
  'supporterArrivalDelay': 3,
  'maxSupporters': 5,
  'maxSupportersVirtue': 8,
};

int getMaxSupporters(Character character) {
  return character.id == CharacterType.virtue
      ? GAME_CONFIG['maxSupportersVirtue'] as int
      : GAME_CONFIG['maxSupporters'] as int;
}

double getVirtueRegenRate(Character character) {
  if (character.id == CharacterType.vision) return 2;
  return 1;
}
