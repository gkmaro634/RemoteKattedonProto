// 石川釣りゲームのモデル定義（実装用プレースホルダー）

class FishingInIshikawaGameState {
  // ゲーム状態管理用
  int score = 0;
  int combos = 0;
  bool isPaused = false;

  void updateScore(int points) {
    score += points;
  }

  void incrementCombo() {
    combos++;
  }

  void resetCombo() {
    combos = 0;
  }

  void reset() {
    score = 0;
    combos = 0;
    isPaused = false;
  }
}

class FishingSpot {
  final String id;
  final String name;
  final String sceneryName;
  final double mapXFactor;
  final double mapYFactor;
  final List<String> fishCandidates;

  const FishingSpot({
    required this.id,
    required this.name,
    required this.sceneryName,
    required this.mapXFactor,
    required this.mapYFactor,
    required this.fishCandidates,
  });
}

class IshikawaFishingSpots {
  static const List<FishingSpot> all = [
    FishingSpot(
      id: 'noto_north',
      name: '能登北部沖',
      sceneryName: '能登の外浦',
      mapXFactor: 0.35,
      mapYFactor: 0.22,
      fishCandidates: ['メバル', 'カサゴ', 'アジ', 'のどぐろ'],
    ),
    FishingSpot(
      id: 'nanao_bay',
      name: '七尾湾',
      sceneryName: '穏やかな湾内',
      mapXFactor: 0.58,
      mapYFactor: 0.43,
      fishCandidates: ['クロダイ', 'メバル', 'アジ', 'シーバス'],
    ),
    FishingSpot(
      id: 'kanazawa_port',
      name: '金沢港周辺',
      sceneryName: '港の夜景と防波堤',
      mapXFactor: 0.54,
      mapYFactor: 0.69,
      fishCandidates: ['シーバス', 'アジ', 'カサゴ', 'クロダイ'],
    ),
    FishingSpot(
      id: 'kaga_offshore',
      name: '加賀沖',
      sceneryName: '加賀の海岸線',
      mapXFactor: 0.45,
      mapYFactor: 0.86,
      fishCandidates: ['のどぐろ', 'ゲンゲ', 'カサゴ', 'アジ'],
    ),
  ];

  static FishingSpot byId(String? id) {
    return all.firstWhere(
      (spot) => spot.id == id,
      orElse: () => all.first,
    );
  }
}
