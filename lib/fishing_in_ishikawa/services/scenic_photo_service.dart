import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:remote_kattedon/fishing_in_ishikawa/models/fishing_models.dart';

class ScenicPhoto {
  final String imageUrl;
  final String title;
  final String pageUrl;
  final String? author;
  final String? license;

  const ScenicPhoto({
    required this.imageUrl,
    required this.title,
    required this.pageUrl,
    this.author,
    this.license,
  });
}

class ScenicPhotoService {
  static const String _apiHost = 'commons.wikimedia.org';
  static const String _geoRadius = '10000';
  static const List<String> _seaKeywords = [
    'sea',
    'ocean',
    'coast',
    'coastal',
    'shore',
    'beach',
    'bay',
    'harbor',
    'harbour',
    'port',
    'seaside',
    'waterfront',
    'japan sea',
    '日本海',
    '海',
    '海岸',
    '湾',
    '漁港',
    '港',
    '海辺',
    '波',
  ];

  static const List<String> _nonSeaKeywords = [
    'temple',
    'shrine',
    'station',
    'museum',
    'school',
    'mountain',
    'street',
    'forest',
    '寺',
    '神社',
    '駅',
    '学校',
    '山',
    '公園',
    '城',
  ];

  static const Map<String, List<String>> _spotSearchHints = {
    'noto_north': ['Noto coast Ishikawa', 'Outer Noto Peninsula coast'],
    'nanao_bay': ['Nanao Bay Ishikawa', '七尾湾 海'],
    'kanazawa_port': ['Kanazawa Port Ishikawa sea', '金沢港 海'],
    'kaga_offshore': ['Kaga coast Ishikawa sea', '加賀 海岸 日本海'],
  };

  Future<List<ScenicPhoto>> fetchNearSpotGallery(
    FishingSpot spot, {
    int maxCount = 20,
  }) async {
    final geoUri = Uri.https(_apiHost, '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'generator': 'geosearch',
      'ggsnamespace': '6',
      'ggscoord': '${spot.latitude}|${spot.longitude}',
      // Commons geosearch max radius is 10,000m.
      'ggsradius': _geoRadius,
      'ggslimit': '20',
      'prop': 'imageinfo',
      'iiprop': 'url|extmetadata|user|mime|size',
      'iiurlwidth': '1800',
      'origin': '*',
    });

    final collected = <_ScoredPhoto>[];
    final seen = <String>{};

    final geoCandidates = await _fetchCandidates(geoUri);
    _collectScored(spot, geoCandidates, collected, seen);

    final hints = _spotSearchHints[spot.id] ?? const [];
    for (final hint in hints) {
      final searchUri = Uri.https(_apiHost, '/w/api.php', {
        'action': 'query',
        'format': 'json',
        'generator': 'search',
        'gsrnamespace': '6',
        'gsrlimit': '15',
        'gsrsearch': hint,
        'prop': 'imageinfo',
        'iiprop': 'url|extmetadata|user|mime|size',
        'iiurlwidth': '1800',
        'origin': '*',
      });

      final searchCandidates = await _fetchCandidates(searchUri);
      _collectScored(spot, searchCandidates, collected, seen);
    }

    if (collected.isEmpty) {
      return const [];
    }

    final seaLike = collected
        .where((e) => e.score >= 4 && _isSeaLikeText(e.searchableText))
        .toList();
    if (seaLike.isNotEmpty) {
      seaLike.sort((a, b) => b.score.compareTo(a.score));
      return seaLike.take(maxCount).map((e) => e.photo).toList();
    }

    // Some areas (especially port/offshore spots) have sparse metadata.
    // Use a softer coastal filter before giving up.
    final coastalLike = collected
        .where((e) => e.score >= 1 && _hasCoastalSignal(e.searchableText))
        .toList();
    if (coastalLike.isNotEmpty) {
      coastalLike.sort((a, b) => b.score.compareTo(a.score));
      return coastalLike.take(maxCount).map((e) => e.photo).toList();
    }

    // Final fallback for specific port spots: avoid blank gallery.
    if (spot.id == 'kanazawa_port' || spot.id == 'kaga_offshore') {
      final fallback = collected.where((e) => e.score >= 0).toList();
      if (fallback.isNotEmpty) {
        fallback.sort((a, b) => b.score.compareTo(a.score));
        return fallback.take(maxCount).map((e) => e.photo).toList();
      }
    }

    return const [];
  }

  Future<ScenicPhoto?> fetchNearSpot(FishingSpot spot) async {
    final gallery = await fetchNearSpotGallery(spot, maxCount: 1);
    if (gallery.isEmpty) {
      return null;
    }
    return gallery.first;
  }

  void _collectScored(
    FishingSpot spot,
    List<_PhotoCandidate> candidates,
    List<_ScoredPhoto> out,
    Set<String> seen,
  ) {
    for (final candidate in candidates) {
      if (seen.contains(candidate.photo.pageUrl)) {
        continue;
      }
      seen.add(candidate.photo.pageUrl);

      final score = _seaScore(spot, candidate.searchableText);
      out.add(
        _ScoredPhoto(
          photo: candidate.photo,
          score: score,
          searchableText: candidate.searchableText,
        ),
      );
    }
  }

  bool _isSeaLikeText(String text) {
    for (final keyword in _seaKeywords) {
      if (text.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  bool _hasCoastalSignal(String text) {
    const coastalSignals = [
      'coast',
      'shore',
      'bay',
      'harbor',
      'harbour',
      'port',
      'seaside',
      'waterfront',
      '日本海',
      '海',
      '海岸',
      '湾',
      '港',
      '漁港',
    ];

    for (final keyword in coastalSignals) {
      if (text.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  Future<List<_PhotoCandidate>> _fetchCandidates(Uri uri) async {
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const [];
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return const [];
    }

    final query = decoded['query'];
    if (query is! Map<String, dynamic>) {
      return const [];
    }

    final pages = query['pages'];
    if (pages is! Map<String, dynamic> || pages.isEmpty) {
      return const [];
    }

    final candidates = <_PhotoCandidate>[];

    for (final value in pages.values) {
      if (value is! Map<String, dynamic>) {
        continue;
      }

      final title = (value['title'] ?? '').toString();
      final imageInfoList = value['imageinfo'];
      if (title.isEmpty || imageInfoList is! List || imageInfoList.isEmpty) {
        continue;
      }

      final imageInfo = imageInfoList.first;
      if (imageInfo is! Map<String, dynamic>) {
        continue;
      }

      final mime = (imageInfo['mime'] ?? '').toString().toLowerCase();
      if (!mime.contains('jpeg') && !mime.contains('jpg') && !mime.contains('png')) {
        continue;
      }

      final imageUrl = (imageInfo['thumburl'] ?? imageInfo['url'] ?? '').toString();
      final descriptionUrl = (imageInfo['descriptionurl'] ?? '').toString();
      if (imageUrl.isEmpty || descriptionUrl.isEmpty) {
        continue;
      }

      final width = (imageInfo['thumbwidth'] ?? imageInfo['width'] ?? 0);
      final height = (imageInfo['thumbheight'] ?? imageInfo['height'] ?? 0);
      final widthNum = width is num ? width.toInt() : int.tryParse(width.toString()) ?? 0;
      final heightNum =
          height is num ? height.toInt() : int.tryParse(height.toString()) ?? 0;

      if (widthNum < 600 || heightNum < 300) {
        continue;
      }

      final metadata = imageInfo['extmetadata'];
      String? license;
      String? author;
      var searchableText = title;
      if (metadata is Map<String, dynamic>) {
        license = (metadata['LicenseShortName'] is Map)
            ? (metadata['LicenseShortName']['value'] ?? '').toString()
            : null;
        author = (metadata['Artist'] is Map)
            ? (metadata['Artist']['value'] ?? '').toString()
            : null;

        final description = (metadata['ImageDescription'] is Map)
            ? (metadata['ImageDescription']['value'] ?? '').toString()
            : '';
        final objectName = (metadata['ObjectName'] is Map)
            ? (metadata['ObjectName']['value'] ?? '').toString()
            : '';
        searchableText = '$title $description $objectName';
      }

      candidates.add(
        _PhotoCandidate(
          photo: ScenicPhoto(
            imageUrl: imageUrl,
            title: title.replaceFirst('File:', ''),
            pageUrl: descriptionUrl,
            license: license,
            author: author,
          ),
          searchableText: _stripHtml(searchableText).toLowerCase(),
        ),
      );
    }

    return candidates;
  }

  int _seaScore(FishingSpot spot, String text) {
    var score = 0;

    for (final keyword in _seaKeywords) {
      if (text.contains(keyword)) {
        score += 2;
      }
    }

    for (final keyword in _nonSeaKeywords) {
      if (text.contains(keyword)) {
        score -= 2;
      }
    }

    final spotName = spot.name.toLowerCase();
    if (text.contains('nanao') && spot.id == 'nanao_bay') {
      score += 2;
    }
    if (text.contains('kanazawa') && spot.id == 'kanazawa_port') {
      score += 2;
    }
    if (text.contains('noto') && spot.id == 'noto_north') {
      score += 2;
    }
    if ((text.contains('kaga') || text.contains('加賀')) &&
        spot.id == 'kaga_offshore') {
      score += 2;
    }
    if (text.contains(spotName)) {
      score += 1;
    }

    return score;
  }

  String _stripHtml(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll('&nbsp;', ' ');
  }
}

class _PhotoCandidate {
  final ScenicPhoto photo;
  final String searchableText;

  const _PhotoCandidate({
    required this.photo,
    required this.searchableText,
  });
}

class _ScoredPhoto {
  final ScenicPhoto photo;
  final int score;
  final String searchableText;

  const _ScoredPhoto({
    required this.photo,
    required this.score,
    required this.searchableText,
  });
}
