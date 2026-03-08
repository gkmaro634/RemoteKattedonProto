import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remote_kattedon/core/constants/app_constants.dart';
import 'package:remote_kattedon/fishing_in_ishikawa/models/fishing_models.dart';
import 'package:remote_kattedon/fishing_in_ishikawa/services/open_data_service.dart';
import 'package:remote_kattedon/fishing_in_ishikawa/services/scenic_photo_service.dart';
import 'package:url_launcher/url_launcher.dart';

enum FishingPhase {
  waiting,
  waitingForBite,
  biteWindow,
  result,
}

class FishingInIshikawaGameScreen extends StatefulWidget {
  final FishingSpot spot;

  const FishingInIshikawaGameScreen({
    super.key,
    required this.spot,
  });

  @override
  State<FishingInIshikawaGameScreen> createState() =>
      _FishingInIshikawaGameScreenState();
}

class _FishingInIshikawaGameScreenState extends State<FishingInIshikawaGameScreen>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final FishingOpenDataService _openDataService = FishingOpenDataService();
  final ScenicPhotoService _scenicPhotoService = ScenicPhotoService();

  FishingPhase _phase = FishingPhase.waiting;
  late String _message;
  late FishingSpot _currentSpot;
  String? _openDataLabel;
  String? _openDataSource;
  List<ScenicPhoto> _scenicPhotos = const [];
  int _scenicPhotoIndex = 0;
  int _score = 0;
  int _combo = 0;
  int _remainingBiteSeconds = 0;
  double _biteFishXFactor = 0.65;
  double _biteFishYFactor = 0.68;

  Timer? _biteTimer;
  Timer? _countdownTimer;
  Timer? _scenerySwitchTimer;
  late final AnimationController _swimController;

  @override
  void initState() {
    super.initState();
    _currentSpot = widget.spot;
    _message = '${_currentSpot.name}で「投げる」を押して釣りを始めよう';
    _openDataLabel = '接続先: ${_openDataService.currentEndpoint()}';
    _swimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
    _loadOpenData();
    _loadSceneryPhoto();
  }

  Future<void> _loadSceneryPhoto() async {
    try {
      final photos = await _scenicPhotoService.fetchNearSpotGallery(
        widget.spot,
        maxCount: 5,
      );
      if (!mounted || photos.isEmpty) {
        return;
      }
      setState(() {
        _scenicPhotos = photos;
        _scenicPhotoIndex = 0;
      });
      _scenerySwitchTimer?.cancel();
      _scenerySwitchTimer = Timer.periodic(const Duration(seconds: 8), (_) {
        if (!mounted || _scenicPhotos.length < 2) {
          return;
        }
        setState(() {
          _scenicPhotoIndex = (_scenicPhotoIndex + 1) % _scenicPhotos.length;
        });
      });
    } catch (_) {
      // Keep default GSI photo tile background when scenic fetch fails.
    }
  }

  Future<void> _loadOpenData() async {
    try {
      final data = await _openDataService.load();
      final spotData = data.bySpotId(widget.spot.id);

      if (!mounted) {
        return;
      }

      if (spotData == null) {
        setState(() {
          _openDataLabel = 'オープンデータ: 対象データなし';
        });
        return;
      }

      setState(() {
        _currentSpot = widget.spot.withOpenData(spotData);
        _openDataLabel = '対象月: ${data.observedMonth}';
        _openDataSource = data.source;
        if (_phase == FishingPhase.waiting) {
          _message = '${_currentSpot.name}で「投げる」を押して釣りを始めよう';
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _openDataLabel = 'オープンデータの取得に失敗しました';
      });
    }
  }

  Future<void> _openSourceUrl() async {
    final source = _openDataSource;
    if (source == null) {
      return;
    }
    final uri = Uri.tryParse(source);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  Future<void> _openScenerySourceUrl() async {
    final source = _currentScenicPhoto?.pageUrl;
    if (source == null) {
      return;
    }
    final uri = Uri.tryParse(source);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  List<Color> _skyColors(ColorScheme colorScheme) {
    switch (_currentSpot.id) {
      case 'noto_north':
        return [
          colorScheme.primaryContainer,
          colorScheme.primary.withValues(alpha: 0.9),
        ];
      case 'nanao_bay':
        return [
          colorScheme.tertiaryContainer,
          colorScheme.primaryContainer,
        ];
      case 'kanazawa_port':
        return [
          colorScheme.surfaceContainerHighest,
          colorScheme.primary,
        ];
      case 'kaga_offshore':
        return [
          colorScheme.secondaryContainer,
          colorScheme.secondary,
        ];
      default:
        return [
          colorScheme.primaryContainer,
          colorScheme.primary.withValues(alpha: 0.9),
        ];
    }
  }

  String get _sceneryPhotoTileUrl => _currentSpot.sceneryPhotoTileUrl;
    ScenicPhoto? get _currentScenicPhoto =>
      _scenicPhotos.isEmpty ? null : _scenicPhotos[_scenicPhotoIndex];

    String get _effectiveSceneryUrl =>
      _currentScenicPhoto?.imageUrl ?? _sceneryPhotoTileUrl;

  @override
  void dispose() {
    _cancelTimers();
    _scenerySwitchTimer?.cancel();
    _swimController.dispose();
    super.dispose();
  }

  void _cancelTimers() {
    _biteTimer?.cancel();
    _countdownTimer?.cancel();
  }

  void _castLine() {
    if (_phase == FishingPhase.waitingForBite ||
        _phase == FishingPhase.biteWindow) {
      return;
    }

    _cancelTimers();
    final waitSeconds = 2 + _random.nextInt(4);
    setState(() {
      _phase = FishingPhase.waitingForBite;
      _message = '仕掛けを投入… 魚が来るまで待とう';
    });

    _biteTimer = Timer(Duration(seconds: waitSeconds), _startBiteWindow);
  }

  void _startBiteWindow() {
    if (!mounted) {
      return;
    }

    _remainingBiteSeconds = 2;
    setState(() {
      _biteFishXFactor = 0.2 + (_random.nextDouble() * 0.6);
      _biteFishYFactor = 0.52 + (_random.nextDouble() * 0.3);
      _phase = FishingPhase.biteWindow;
      _message = 'アタリ！ 2秒以内に「釣る」！';
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _remainingBiteSeconds--;
      if (_remainingBiteSeconds <= 0) {
        timer.cancel();
        _loseFish();
      } else {
        setState(() {
          _message = 'アタリ！ 残り$_remainingBiteSeconds秒';
        });
      }
    });
  }

  void _hookFish() {
    if (_phase != FishingPhase.biteWindow) {
      return;
    }

    _cancelTimers();
    final fish = _currentSpot.pickFish(_random);

    setState(() {
      _score += 10 + (_combo * 2);
      _combo++;
      _phase = FishingPhase.result;
      _message = '$fish を釣り上げた！ +${10 + ((_combo - 1) * 2)}点';
    });
  }

  void _loseFish() {
    _cancelTimers();
    setState(() {
      _combo = 0;
      _phase = FishingPhase.result;
      _message = '逃げられた… タイミングが遅かった';
    });
  }

  void _resetGame() {
    _cancelTimers();
    setState(() {
      _phase = FishingPhase.waiting;
      _message = '${_currentSpot.name}で「投げる」を押して釣りを始めよう';
      _score = 0;
      _combo = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final skyColors = _skyColors(colorScheme);
    final canCast =
        _phase == FishingPhase.waiting || _phase == FishingPhase.result;
    final canHook = _phase == FishingPhase.biteWindow;

    return Scaffold(
      appBar: AppBar(
        title: Text('Fishing in ISHIKAWA - ${_currentSpot.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
              child: AnimatedBuilder(
                animation: _swimController,
                builder: (context, child) {
                  final swim1X =
                      -40 + (constraints.maxWidth + 80) * _swimController.value;
                  final swim2X = constraints.maxWidth +
                      40 -
                      (constraints.maxWidth + 80) * _swimController.value;

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: skyColors,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Image.network(
                          _effectiveSceneryUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                colorScheme.scrim.withValues(alpha: 0.22),
                                colorScheme.scrim.withValues(alpha: 0.46),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _HudChip(text: _currentSpot.name, icon: Icons.place),
                            _HudChip(text: 'スコア $_score', icon: Icons.stars),
                            _HudChip(text: 'コンボ $_combo', icon: Icons.bolt),
                            if (_currentSpot.totalCatchKg != null)
                              _HudChip(
                                text: '漁獲 ${_currentSpot.totalCatchKg}kg/月',
                                icon: Icons.dataset,
                              ),
                            if (_currentScenicPhoto != null)
                              _HudChip(
                                text:
                                    '写真 ${_scenicPhotoIndex + 1}/${_scenicPhotos.length}',
                                icon: Icons.photo,
                                onTap: _openScenerySourceUrl,
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 22,
                        left: 24,
                        child: Icon(
                          Icons.cloud,
                          color: Colors.white.withValues(alpha: 0.82),
                          size: 40,
                        ),
                      ),
                      Positioned(
                        top: 32,
                        right: 28,
                        child: Icon(
                          Icons.cloud,
                          color: Colors.white.withValues(alpha: 0.72),
                          size: 32,
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 150,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                colorScheme.secondaryContainer
                                    .withValues(alpha: 0.58),
                                colorScheme.secondary.withValues(alpha: 0.94),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: swim1X,
                        bottom: 72,
                        child: Icon(
                          Icons.set_meal,
                          color: Colors.white.withValues(alpha: 0.82),
                          size: 32,
                        ),
                      ),
                      Positioned(
                        left: swim2X,
                        bottom: 104,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..scale(-1.0, 1.0),
                          child: Icon(
                            Icons.set_meal,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 28,
                          ),
                        ),
                      ),
                      if (_phase == FishingPhase.biteWindow)
                        Positioned(
                          left: constraints.maxWidth * _biteFishXFactor,
                          top: constraints.maxHeight * _biteFishYFactor,
                          child: Icon(
                            Icons.set_meal,
                            color: colorScheme.tertiary,
                            size: 44,
                          ),
                        ),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppConstants.defaultPadding,
                          ),
                          padding: const EdgeInsets.all(AppConstants.defaultPadding),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(
                              AppConstants.cardBorderRadius,
                            ),
                          ),
                          child: Text(
                            _message,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.all(AppConstants.smallPadding),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(
                              AppConstants.cardBorderRadius,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: canCast ? _castLine : null,
                                  child: const Text('投げる'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.tonal(
                                  onPressed: canHook ? _hookFish : null,
                                  child: const Text('釣る'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _resetGame,
                                  child: const Text('リセット'),
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
            );
          },
        ),
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;

  const _HudChip({
    required this.text,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(text, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: content,
    );
  }
}
