import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:remote_kattedon/fishing_in_ishikawa/models/fishing_models.dart';

class FishingOpenDataService {
  static const String _assetPath =
      'assets/data/ishikawa_fishing_open_data.json';

  static IshikawaFishingOpenData? _cache;

  Future<IshikawaFishingOpenData> load() async {
    if (_cache != null) {
      return _cache!;
    }

    final jsonText = await rootBundle.loadString(_assetPath);
    final jsonMap = json.decode(jsonText) as Map<String, dynamic>;
    _cache = IshikawaFishingOpenData.fromJson(jsonMap);
    return _cache!;
  }

  Future<FishingSpot> enrichSpot(FishingSpot baseSpot) async {
    final data = await load();
    final spotData = data.bySpotId(baseSpot.id);
    if (spotData == null) {
      return baseSpot;
    }
    return baseSpot.withOpenData(spotData);
  }
}
