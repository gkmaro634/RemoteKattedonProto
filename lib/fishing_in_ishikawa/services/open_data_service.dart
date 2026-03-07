import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:remote_kattedon/fishing_in_ishikawa/models/fishing_models.dart';

class FishingOpenDataService {
  static const String _defaultDirectCsvUrl =
      'https://ckan.opendata.pref.ishikawa.lg.jp/dataset/b9e71183-5d58-4aa3-8a52-6c436993fa2e/resource/3a8105cc-4b7e-40b5-aa99-ca614d0fa32f/download/catch_amount_type.csv';

  static const String _defaultProxyUrl =
      'https://asia-northeast1-fishxtech-hackathon-teamd.cloudfunctions.net/ishikawaOpenDataProxy';

  static String get _defaultApiUrl => kIsWeb ? _defaultProxyUrl : _defaultDirectCsvUrl;

  static const String _configuredApiUrl = String.fromEnvironment(
    'ISHIKAWA_OPEN_DATA_URL',
    defaultValue: '',
  );

  static String get _apiUrl =>
      _configuredApiUrl.isNotEmpty ? _configuredApiUrl : _defaultApiUrl;

  static const String _assetPath =
      'assets/data/ishikawa_fishing_open_data.json';

  static IshikawaFishingOpenData? _cache;

  Future<IshikawaFishingOpenData> load() async {
    if (_cache != null) {
      return _cache!;
    }

    Object? apiError;
    try {
      if (_apiUrl.isNotEmpty) {
        final apiData = await _loadFromApi(_apiUrl);
        _cache = apiData;
        return _cache!;
      }
    } catch (error) {
      apiError = error;
    }

    final assetData = await _loadFromAsset();
    _cache = IshikawaFishingOpenData(
      datasetName: assetData.datasetName,
      source: _fallbackSourceLabel(apiError),
      observedMonth: assetData.observedMonth,
      spots: assetData.spots,
    );
    return _cache!;
  }

  String _fallbackSourceLabel(Object? apiError) {
    if (apiError == null) {
      return 'ローカル同梱データ（assets/data）';
    }

    if (kIsWeb) {
      return 'ローカル同梱データ（Webでプロキシ経由取得失敗）';
    }

    return 'ローカル同梱データ（公式API取得失敗時フォールバック）';
  }

  Future<IshikawaFishingOpenData> _loadFromAsset() async {
    final jsonText = await rootBundle.loadString(_assetPath);
    final jsonMap = json.decode(jsonText) as Map<String, dynamic>;
    return IshikawaFishingOpenData.fromJson(jsonMap);
  }

  Future<IshikawaFishingOpenData> _loadFromApi(String endpoint) async {
    final uri = Uri.parse(endpoint);
    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Open data API returned ${response.statusCode}');
    }

    final contentType = response.headers['content-type'] ?? '';
    final isCsv = endpoint.toLowerCase().endsWith('.csv') ||
        contentType.toLowerCase().contains('text/csv');

    if (isCsv) {
      return _csvToOpenData(response.body, endpoint);
    }

    final decoded = json.decode(response.body);
    final normalized = _normalizeApiPayload(decoded);
    return IshikawaFishingOpenData.fromJson(normalized);
  }

  IshikawaFishingOpenData _csvToOpenData(String csvText, String source) {
    final rows = const CsvToListConverter(shouldParseNumbers: false)
        .convert(csvText)
        .where((row) => row.isNotEmpty)
        .toList();

    if (rows.length < 2) {
      throw Exception('CSV has no data rows');
    }

    final header = rows.first.map((cell) => cell.toString()).toList();
    final cityIdx = _findHeaderIndex(header, ['地方公共団体名', '自治体名']);
    final yearIdx = _findHeaderIndex(header, ['対象年度', '年度']);
    final fishIdx = _findHeaderIndex(header, ['漁獲物種類', '魚種']);
    final amountIdx = _findHeaderIndex(header, ['漁獲量((t)', '漁獲量', '数量']);

    if (cityIdx < 0 || yearIdx < 0 || fishIdx < 0 || amountIdx < 0) {
      throw Exception('CSV schema mismatch');
    }

    final latestYear = rows
        .skip(1)
        .map((row) => _toInt(row[yearIdx]))
        .whereType<int>()
        .fold<int>(0, (prev, value) => value > prev ? value : prev);

    final Map<String, Map<String, int>> spotFish = {};
    final Map<String, int> spotTotal = {};

    for (final row in rows.skip(1)) {
      if (row.length <= amountIdx) {
        continue;
      }

      final year = _toInt(row[yearIdx]);
      if (year == null || year != latestYear) {
        continue;
      }

      final cityName = row[cityIdx].toString();
      final spotId = _cityToSpotId(cityName);
      if (spotId == null) {
        continue;
      }

      final fishName = _normalizeFishName(row[fishIdx].toString());
      if (fishName == null) {
        continue;
      }

      final amount = _toInt(row[amountIdx]) ?? 0;
      if (amount <= 0) {
        continue;
      }

      final fishMap = spotFish.putIfAbsent(spotId, () => {});
      fishMap[fishName] = (fishMap[fishName] ?? 0) + amount;
      spotTotal[spotId] = (spotTotal[spotId] ?? 0) + amount;
    }

    if (spotFish.isEmpty) {
      throw Exception('No usable fish data in CSV');
    }

    _fillMissingSpotsWithEstimatedData(spotFish, spotTotal);

    final spots = spotFish.entries
        .map(
          (entry) => SpotFishingOpenData(
            spotId: entry.key,
            totalCatchKg: spotTotal[entry.key] ?? 0,
            fishCatchKg: entry.value,
          ),
        )
        .toList();

    return IshikawaFishingOpenData(
      datasetName: '石川県オープンデータ（種類別漁獲数量）',
      source: source,
      observedMonth: latestYear > 0 ? latestYear.toString() : '',
      spots: spots,
    );
  }

  void _fillMissingSpotsWithEstimatedData(
    Map<String, Map<String, int>> spotFish,
    Map<String, int> spotTotal,
  ) {
    final globalFish = <String, int>{};
    for (final fishMap in spotFish.values) {
      fishMap.forEach((fish, amount) {
        globalFish[fish] = (globalFish[fish] ?? 0) + amount;
      });
    }

    final averageTotal = spotTotal.isEmpty
        ? 100
        : (spotTotal.values.reduce((a, b) => a + b) / spotTotal.length)
            .round();

    for (final baseSpot in IshikawaFishingSpots.all) {
      if (spotFish.containsKey(baseSpot.id)) {
        continue;
      }

      final estimatedFish = _estimateSpotFishFromGlobal(baseSpot, globalFish);

      if (estimatedFish.isEmpty) {
        var seed = 120;
        for (final fish in baseSpot.fishCandidates) {
          estimatedFish[fish] = seed;
          seed = seed > 40 ? seed - 25 : 40;
        }
      }

      final estimatedTotal = estimatedFish.values.fold<int>(0, (sum, v) => sum + v);

      spotFish[baseSpot.id] = estimatedFish;
      spotTotal[baseSpot.id] = estimatedTotal > 0 ? estimatedTotal : averageTotal;
    }
  }

  Map<String, int> _estimateSpotFishFromGlobal(
    FishingSpot baseSpot,
    Map<String, int> globalFish,
  ) {
    final result = <String, int>{};

    for (var i = 0; i < baseSpot.fishCandidates.length; i++) {
      final fish = baseSpot.fishCandidates[i];
      final baseAmount = globalFish[fish] ?? 0;
      if (baseAmount <= 0) {
        continue;
      }

      // Candidate order reflects each spot's typical species priority.
      final rankFactor = 1.15 - (i * 0.12);
      final regionalBias = _regionalFishBias(baseSpot.id, fish);
      final estimated = (baseAmount * rankFactor * regionalBias).round();

      if (estimated > 0) {
        result[fish] = estimated;
      }
    }

    return result;
  }

  double _regionalFishBias(String spotId, String fish) {
    switch (spotId) {
      case 'kaga_offshore':
        if (fish == 'のどぐろ' || fish == 'ゲンゲ') {
          return 1.25;
        }
        if (fish == 'アジ') {
          return 0.9;
        }
        return 1.0;
      case 'kanazawa_port':
        if (fish == 'シーバス' || fish == 'クロダイ') {
          return 1.2;
        }
        if (fish == 'のどぐろ') {
          return 0.8;
        }
        return 1.0;
      case 'nanao_bay':
        if (fish == 'メバル' || fish == 'アジ') {
          return 1.18;
        }
        if (fish == 'シーバス') {
          return 0.92;
        }
        return 1.0;
      case 'noto_north':
        if (fish == 'のどぐろ' || fish == 'カサゴ') {
          return 1.2;
        }
        return 1.0;
      default:
        return 1.0;
    }
  }

  int _findHeaderIndex(List<String> header, List<String> candidates) {
    for (var i = 0; i < header.length; i++) {
      final h = header[i].replaceAll('"', '').trim();
      if (candidates.any((candidate) => h.contains(candidate))) {
        return i;
      }
    }
    return -1;
  }

  int? _toInt(dynamic value) {
    final raw = value.toString().replaceAll(',', '').trim();
    return int.tryParse(raw);
  }

  String? _cityToSpotId(String cityName) {
    if (cityName.contains('加賀')) {
      return 'kaga_offshore';
    }
    if (cityName.contains('金沢')) {
      return 'kanazawa_port';
    }
    if (cityName.contains('七尾')) {
      return 'nanao_bay';
    }
    if (cityName.contains('輪島') || cityName.contains('珠洲') || cityName.contains('能登')) {
      return 'noto_north';
    }
    return null;
  }

  String? _normalizeFishName(String raw) {
    final v = raw.trim().toLowerCase();

    if (v.contains('あじ')) {
      return 'アジ';
    }
    if (v.contains('めばる')) {
      return 'メバル';
    }
    if (v.contains('くろだい') || v.contains('たい類')) {
      return 'クロダイ';
    }
    if (v.contains('すずき') || v.contains('しーばす')) {
      return 'シーバス';
    }
    if (v.contains('かさご')) {
      return 'カサゴ';
    }
    if (v.contains('げんげ')) {
      return 'ゲンゲ';
    }
    if (v.contains('のどぐろ') || v.contains('あかむつ')) {
      return 'のどぐろ';
    }

    return null;
  }

  Map<String, dynamic> _normalizeApiPayload(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected API payload');
    }

    if (decoded.containsKey('spots')) {
      return decoded;
    }

    final result = decoded['result'];
    if (result is Map<String, dynamic>) {
      final records = result['records'];
      if (records is List) {
        final spots = records
            .whereType<Map<String, dynamic>>()
            .map(_recordToSpotJson)
            .toList();

        return {
          'datasetName':
              decoded['datasetName'] ?? decoded['title'] ?? '石川県沿岸漁場統計',
          'source': decoded['source'] ?? _apiUrl,
          'observedMonth': decoded['observedMonth'] ?? '',
          'spots': spots,
        };
      }
    }

    throw Exception('Unsupported API schema');
  }

  Map<String, dynamic> _recordToSpotJson(Map<String, dynamic> record) {
    final spotId = (record['spotId'] ?? record['spot_id'] ?? '') as String;
    final total = (record['totalCatchKg'] ?? record['total_catch_kg'] ?? 0) as num;

    final rawFish = record['fishCatchKg'] ?? record['fish_catch_kg'] ?? {};
    Map<String, dynamic> fishMap;

    if (rawFish is String) {
      fishMap = json.decode(rawFish) as Map<String, dynamic>;
    } else if (rawFish is Map<String, dynamic>) {
      fishMap = rawFish;
    } else {
      fishMap = <String, dynamic>{};
    }

    return {
      'spotId': spotId,
      'totalCatchKg': total,
      'fishCatchKg': fishMap,
    };
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
