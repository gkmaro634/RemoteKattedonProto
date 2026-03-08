import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_kattedon/core/theme/app_theme.dart';
import 'package:remote_kattedon/core/constants/app_constants.dart';
import 'package:remote_kattedon/fishing_in_ishikawa/models/fishing_models.dart';
import 'package:remote_kattedon/fishing_in_ishikawa/services/open_data_service.dart';
import 'package:remote_kattedon/widgets/common_widgets.dart';
import 'package:remote_kattedon/navigation/route_names.dart';
import 'package:url_launcher/url_launcher.dart';

class FishingInIshikawaStartScreen extends StatefulWidget {
  const FishingInIshikawaStartScreen({super.key});

  @override
  State<FishingInIshikawaStartScreen> createState() =>
      _FishingInIshikawaStartScreenState();
}

class _FishingInIshikawaStartScreenState
    extends State<FishingInIshikawaStartScreen> {
  static const int _mapZoom = 7;
  static const int _mapTileX = 112;
  static const int _mapTileY = 49;
  static const double _tileSize = 256.0;
  static const double _pinIconSize = 32.0;

  static const String _ishikawaMapTileUrl =
      'https://cyberjapandata.gsi.go.jp/xyz/std/7/112/49.png';

  final FishingOpenDataService _openDataService = FishingOpenDataService();

  FishingSpot _selectedSpot = IshikawaFishingSpots.all.first;
  IshikawaFishingOpenData? _openData;
  String? _openDataError;

  late final String _endpointLabel;

  @override
  void initState() {
    super.initState();
    _endpointLabel = _openDataService.currentEndpoint();
    _loadOpenData();
  }

  Future<void> _loadOpenData() async {
    try {
      final data = await _openDataService.load();
      if (!mounted) {
        return;
      }

      setState(() {
        _openData = data;
        _selectedSpot = _enrichedSpot(_selectedSpot);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _openDataError = 'オープンデータの読み込みに失敗しました';
      });
    }
  }

  FishingSpot _enrichedSpot(FishingSpot baseSpot) {
    final spotData = _openData?.bySpotId(baseSpot.id);
    if (spotData == null) {
      return baseSpot;
    }
    return baseSpot.withOpenData(spotData);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  Offset _spotPositionInMap(FishingSpot spot, BoxConstraints constraints) {
    final worldSize = (1 << _mapZoom) * _tileSize;

    final lonX = ((spot.longitude + 180.0) / 360.0) * worldSize;
    final latRad = spot.latitude * math.pi / 180.0;
    final latY =
        (1 - (math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi)) /
            2 *
        worldSize;

    final tileLeft = _mapTileX * _tileSize;
    final tileTop = _mapTileY * _tileSize;
    final xInTile = lonX - tileLeft;
    final yInTile = latY - tileTop;

    final scale = math.max(
      constraints.maxWidth / _tileSize,
      constraints.maxHeight / _tileSize,
    );
    final renderedWidth = _tileSize * scale;
    final renderedHeight = _tileSize * scale;
    final cropLeft = (renderedWidth - constraints.maxWidth) / 2;
    final cropTop = (renderedHeight - constraints.maxHeight) / 2;

    final x = (xInTile * scale) - cropLeft;
    final y = (yInTile * scale) - cropTop;

    return Offset(
      x.clamp(0.0, constraints.maxWidth),
      y.clamp(0.0, constraints.maxHeight),
    );
  }

  List<Widget> _topFishChips(FishingSpot spot) {
    final sorted = spot.fishWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<int>(0, (sum, e) => sum + e.value);

    if (total <= 0 || sorted.isEmpty) {
      return const [Chip(label: Text('データなし'))];
    }

    return sorted.take(3).map((entry) {
      final ratio = (entry.value / total) * 100;
      return Chip(label: Text('${entry.key} ${ratio.toStringAsFixed(1)}%'));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('石川釣りゲーム'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const GameDescriptionCard(
                    title: '石川釣りゲーム',
                    description:
                        '石川県マップから漁場を選んで、景色を眺めながら釣りを楽しもう。',
                    accentColor: AppTheme.fishingInIshikawaColor,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: SizedBox(
                        height: 320,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.cardBorderRadius,
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          _ishikawaMapTileUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return CustomPaint(
                                              painter: _IshikawaMapPainter(
                                                fillColor: colorScheme.surface,
                                                strokeColor: colorScheme.primary,
                                              ),
                                            );
                                          },
                                        ),
                                        DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                colorScheme.surface
                                                    .withValues(alpha: 0.18),
                                                colorScheme.surface
                                                    .withValues(alpha: 0.34),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 8,
                                  bottom: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface
                                          .withValues(alpha: 0.84),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '地図: 国土地理院',
                                      style: Theme.of(context).textTheme.labelSmall,
                                    ),
                                  ),
                                ),
                                for (final spot in IshikawaFishingSpots.all)
                                  Builder(
                                    builder: (context) {
                                      final position = _spotPositionInMap(
                                        spot,
                                        constraints,
                                      );
                                      final left =
                                          (position.dx - (_pinIconSize / 2)).clamp(
                                        0.0,
                                        constraints.maxWidth - _pinIconSize,
                                      );
                                      final top = (position.dy - _pinIconSize)
                                          .clamp(
                                        0.0,
                                        constraints.maxHeight - _pinIconSize,
                                      );

                                      return Positioned(
                                        left: left,
                                        top: top,
                                        child: Column(
                                          children: [
                                            InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              onTap: () {
                                                setState(() {
                                                  _selectedSpot = _enrichedSpot(spot);
                                                });
                                              },
                                              child: SizedBox(
                                                width: _pinIconSize,
                                                height: _pinIconSize,
                                                child: Icon(
                                                  Icons.location_on,
                                                  size: _selectedSpot.id == spot.id
                                                      ? 34
                                                      : 28,
                                                  color: _selectedSpot.id == spot.id
                                                      ? colorScheme.error
                                                      : colorScheme.primary,
                                                ),
                                              ),
                                            ),
                                            IgnorePointer(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.surface
                                                      .withValues(alpha: 0.85),
                                                  borderRadius:
                                                      BorderRadius.circular(999),
                                                ),
                                                child: Text(
                                                  spot.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.landscape),
                      title: Text(_selectedSpot.name),
                      subtitle: Text(
                        _selectedSpot.totalCatchKg == null
                            ? '景色: ${_selectedSpot.sceneryName}'
                            : '景色: ${_selectedSpot.sceneryName}\n'
                                '推定漁獲量: ${_selectedSpot.totalCatchKg}kg / 月  主な魚: ${_selectedSpot.topFish}',
                      ),
                    ),
                  ),
                  if (_selectedSpot.fishWeights.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.defaultPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('上位魚種と割合（Top 3）'),
                            const SizedBox(height: AppConstants.smallPadding),
                            Wrap(
                              spacing: AppConstants.smallPadding,
                              runSpacing: AppConstants.smallPadding,
                              children: _topFishChips(_selectedSpot),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_selectedSpot.fishWeights.isNotEmpty)
                    _OpenDataVisualizationCard(spot: _selectedSpot),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.dataset),
                      title: Text(_openData?.datasetName ?? 'オープンデータ読み込み中...'),
                      subtitle: _openData == null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('接続先:'),
                                _SourceLinkText(
                                  url: _endpointLabel,
                                  onTap: () => _openUrl(_endpointLabel),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('対象月: ${_openData!.observedMonth}'),
                                const SizedBox(height: 2),
                                const Text('取得元:'),
                                _SourceLinkText(
                                  url: _openData!.source,
                                  onTap: () => _openUrl(_openData!.source),
                                ),
                              ],
                            ),
                    ),
                  ),
                  if (_openDataError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppConstants.smallPadding),
                      child: Text(
                        _openDataError!,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: AppConstants.largePadding * 1.5),

                  GameStartButton(
                    label: 'START',
                    onPressed: () {
                      context.go(
                        '${RouteNames.fishingInIshikawaGame}?spot=${_selectedSpot.id}',
                      );
                    },
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  GoBackButton(
                    onPressed: () => context.go(RouteNames.gameSelection),
                    label: 'ゲーム一覧に戻る',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenDataVisualizationCard extends StatelessWidget {
  final FishingSpot spot;

  const _OpenDataVisualizationCard({
    required this.spot,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = spot.fishWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topItems = sorted.take(6).toList();
    final total = sorted.fold<int>(0, (sum, e) => sum + e.value);
    final maxValue = topItems.isEmpty
        ? 1
        : topItems.fold<int>(0, (max, e) => e.value > max ? e.value : max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  '漁獲生データ可視化（$spot.name）',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text('合計: $total  / 上位${topItems.length}魚種を表示'),
            const SizedBox(height: AppConstants.defaultPadding),
            for (final item in topItems)
              _FishAmountBarRow(
                fishName: item.key,
                amount: item.value,
                maxAmount: maxValue,
                total: total,
              ),
          ],
        ),
      ),
    );
  }
}

class _FishAmountBarRow extends StatelessWidget {
  final String fishName;
  final int amount;
  final int maxAmount;
  final int total;

  const _FishAmountBarRow({
    required this.fishName,
    required this.amount,
    required this.maxAmount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (amount / total);
    final barValue = maxAmount <= 0 ? 0.0 : (amount / maxAmount);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(fishName),
              Text('$amount (${(ratio * 100).toStringAsFixed(1)}%)'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: barValue),
        ],
      ),
    );
  }
}

class _SourceLinkText extends StatelessWidget {
  final String url;
  final VoidCallback onTap;

  const _SourceLinkText({
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onTap,
            child: Text(
              url,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'URLをコピー',
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: url));
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('取得元URLをコピーしました')),
            );
          },
        ),
      ],
    );
  }
}

class _IshikawaMapPainter extends CustomPainter {
  final Color fillColor;
  final Color strokeColor;

  const _IshikawaMapPainter({
    required this.fillColor,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.32, size.height * 0.10)
      ..lineTo(size.width * 0.27, size.height * 0.24)
      ..lineTo(size.width * 0.34, size.height * 0.38)
      ..lineTo(size.width * 0.30, size.height * 0.56)
      ..lineTo(size.width * 0.38, size.height * 0.80)
      ..lineTo(size.width * 0.46, size.height * 0.92)
      ..lineTo(size.width * 0.56, size.height * 0.88)
      ..lineTo(size.width * 0.60, size.height * 0.69)
      ..lineTo(size.width * 0.63, size.height * 0.54)
      ..lineTo(size.width * 0.67, size.height * 0.40)
      ..lineTo(size.width * 0.58, size.height * 0.28)
      ..lineTo(size.width * 0.50, size.height * 0.16)
      ..lineTo(size.width * 0.42, size.height * 0.05)
      ..close();

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor.withValues(alpha: 0.95);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = strokeColor
      ..strokeWidth = 2.2;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _IshikawaMapPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor;
  }
}
