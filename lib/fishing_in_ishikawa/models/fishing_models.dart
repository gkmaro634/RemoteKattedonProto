import 'dart:math';

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
  final double latitude;
  final double longitude;
  final int sceneryZoom;
  final List<String> fishCandidates;
  final Map<String, int> fishWeights;
  final int? totalCatchKg;

  const FishingSpot({
    required this.id,
    required this.name,
    required this.sceneryName,
    required this.mapXFactor,
    required this.mapYFactor,
    required this.latitude,
    required this.longitude,
    this.sceneryZoom = 12,
    required this.fishCandidates,
    this.fishWeights = const {},
    this.totalCatchKg,
  });

  FishingSpot withOpenData(SpotFishingOpenData data) {
    final sortedFish = data.fishCatchKg.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final mergedCandidates = sortedFish.isEmpty
        ? List<String>.from(fishCandidates)
        : sortedFish.map((entry) => entry.key).toList();

    return FishingSpot(
      id: id,
      name: name,
      sceneryName: sceneryName,
      mapXFactor: mapXFactor,
      mapYFactor: mapYFactor,
      latitude: latitude,
      longitude: longitude,
      sceneryZoom: sceneryZoom,
      fishCandidates: mergedCandidates,
      fishWeights: data.fishCatchKg,
      totalCatchKg: data.totalCatchKg,
    );
  }

  /// Open photo tile around this spot (GSI seamless photo, open data).
  String get sceneryPhotoTileUrl {
    final zoom = sceneryZoom;
    final x = _long2tile(longitude, zoom);
    final y = _lat2tile(latitude, zoom);
    return 'https://cyberjapandata.gsi.go.jp/xyz/seamlessphoto/$zoom/$x/$y.jpg';
  }

  static int _long2tile(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  static int _lat2tile(double lat, int zoom) {
    final latRad = lat * pi / 180.0;
    final n = 1 << zoom;
    final value = (1 - (log(tan(latRad) + 1 / cos(latRad)) / pi)) / 2 * n;
    return value.floor();
  }

  String get topFish {
    if (fishWeights.isEmpty) {
      return fishCandidates.isNotEmpty ? fishCandidates.first : 'データなし';
    }
    final sorted = fishWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  String pickFish(Random random) {
    if (fishWeights.isEmpty) {
      if (fishCandidates.isEmpty) {
        return '魚';
      }
      return fishCandidates[random.nextInt(fishCandidates.length)];
    }

    final totalWeight = fishWeights.values.fold<int>(0, (sum, w) => sum + w);
    if (totalWeight <= 0) {
      if (fishCandidates.isEmpty) {
        return '魚';
      }
      return fishCandidates[random.nextInt(fishCandidates.length)];
    }

    var target = random.nextInt(totalWeight);
    for (final entry in fishWeights.entries) {
      target -= entry.value;
      if (target < 0) {
        return entry.key;
      }
    }

    return fishCandidates.isNotEmpty ? fishCandidates.first : '魚';
  }
}

class SpotFishingOpenData {
  final String spotId;
  final int totalCatchKg;
  final Map<String, int> fishCatchKg;

  const SpotFishingOpenData({
    required this.spotId,
    required this.totalCatchKg,
    required this.fishCatchKg,
  });

  factory SpotFishingOpenData.fromJson(Map<String, dynamic> json) {
    final fishCatch = Map<String, dynamic>.from(json['fishCatchKg'] as Map);
    return SpotFishingOpenData(
      spotId: json['spotId'] as String,
      totalCatchKg: (json['totalCatchKg'] as num).round(),
      fishCatchKg: fishCatch.map(
        (key, value) => MapEntry(key, (value as num).round()),
      ),
    );
  }
}

class IshikawaFishingOpenData {
  final String datasetName;
  final String source;
  final String observedMonth;
  final List<SpotFishingOpenData> spots;

  const IshikawaFishingOpenData({
    required this.datasetName,
    required this.source,
    required this.observedMonth,
    required this.spots,
  });

  factory IshikawaFishingOpenData.fromJson(Map<String, dynamic> json) {
    final spotsJson = (json['spots'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    return IshikawaFishingOpenData(
      datasetName: json['datasetName'] as String,
      source: json['source'] as String,
      observedMonth: json['observedMonth'] as String,
      spots: spotsJson.map(SpotFishingOpenData.fromJson).toList(),
    );
  }

  SpotFishingOpenData? bySpotId(String spotId) {
    for (final spot in spots) {
      if (spot.spotId == spotId) {
        return spot;
      }
    }
    return null;
  }
}

class IshikawaFishingSpots {
  static const List<FishingSpot> all = [
    FishingSpot(
      id: 'noto_north',
      name: '能登北部沖',
      sceneryName: '能登の外浦',
      mapXFactor: 0.35,
      mapYFactor: 0.22,
      latitude: 37.43,
      longitude: 136.92,
      fishCandidates: ['メバル', 'カサゴ', 'アジ', 'のどぐろ'],
    ),
    FishingSpot(
      id: 'nanao_bay',
      name: '七尾湾',
      sceneryName: '穏やかな湾内',
      mapXFactor: 0.58,
      mapYFactor: 0.43,
      latitude: 37.08,
      longitude: 136.99,
      fishCandidates: ['クロダイ', 'メバル', 'アジ', 'シーバス'],
    ),
    FishingSpot(
      id: 'kanazawa_port',
      name: '金沢港周辺',
      sceneryName: '港の夜景と防波堤',
      mapXFactor: 0.54,
      mapYFactor: 0.69,
      latitude: 36.61,
      longitude: 136.60,
      fishCandidates: ['シーバス', 'アジ', 'カサゴ', 'クロダイ'],
    ),
    FishingSpot(
      id: 'kaga_offshore',
      name: '加賀沖',
      sceneryName: '加賀の海岸線',
      mapXFactor: 0.45,
      mapYFactor: 0.86,
      latitude: 36.25,
      longitude: 136.28,
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
