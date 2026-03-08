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

  Future<ScenicPhoto?> fetchNearSpot(FishingSpot spot) async {
    final uri = Uri.https(_apiHost, '/w/api.php', {
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

    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final query = decoded['query'];
    if (query is! Map<String, dynamic>) {
      return null;
    }

    final pages = query['pages'];
    if (pages is! Map<String, dynamic> || pages.isEmpty) {
      return null;
    }

    final candidates = <ScenicPhoto>[];

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
      if (metadata is Map<String, dynamic>) {
        license = (metadata['LicenseShortName'] is Map)
            ? (metadata['LicenseShortName']['value'] ?? '').toString()
            : null;
        author = (metadata['Artist'] is Map)
            ? (metadata['Artist']['value'] ?? '').toString()
            : null;
      }

      candidates.add(
        ScenicPhoto(
          imageUrl: imageUrl,
          title: title.replaceFirst('File:', ''),
          pageUrl: descriptionUrl,
          license: license,
          author: author,
        ),
      );
    }

    if (candidates.isEmpty) {
      return null;
    }

    // Stable photo selection per spot.
    final index = spot.id.codeUnits.fold<int>(0, (sum, c) => sum + c) % candidates.length;
    return candidates[index];
  }
}
