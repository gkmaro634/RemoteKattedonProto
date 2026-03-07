import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_kattedon/core/theme/app_theme.dart';
import 'package:remote_kattedon/core/constants/app_constants.dart';
import 'package:remote_kattedon/fishing_in_ishikawa/models/fishing_models.dart';
import 'package:remote_kattedon/widgets/common_widgets.dart';
import 'package:remote_kattedon/navigation/route_names.dart';

class FishingInIshikawaStartScreen extends StatefulWidget {
  const FishingInIshikawaStartScreen({super.key});

  @override
  State<FishingInIshikawaStartScreen> createState() =>
      _FishingInIshikawaStartScreenState();
}

class _FishingInIshikawaStartScreenState
    extends State<FishingInIshikawaStartScreen> {
  FishingSpot _selectedSpot = IshikawaFishingSpots.all.first;

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
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(
                                        AppConstants.cardBorderRadius,
                                      ),
                                    ),
                                    child: CustomPaint(
                                      painter: _IshikawaMapPainter(
                                        fillColor: colorScheme.surface,
                                        strokeColor: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                for (final spot in IshikawaFishingSpots.all)
                                  Positioned(
                                    left: (constraints.maxWidth * spot.mapXFactor) -
                                        22,
                                    top: (constraints.maxHeight * spot.mapYFactor) -
                                        32,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(24),
                                      onTap: () {
                                        setState(() {
                                          _selectedSpot = spot;
                                        });
                                      },
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: _selectedSpot.id == spot.id
                                                ? 34
                                                : 28,
                                            color: _selectedSpot.id == spot.id
                                                ? colorScheme.error
                                                : colorScheme.primary,
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
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
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
                      subtitle: Text('景色: ${_selectedSpot.sceneryName}'),
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
