import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remote_kattedon/core/constants/app_constants.dart';
import 'package:remote_kattedon/fishing_in_ishikawa/models/fishing_models.dart';
import 'package:remote_kattedon/fishing_in_ishikawa/services/open_data_service.dart';
import 'package:remote_kattedon/fishing_in_ishikawa/services/scenic_photo_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const int _maxBait = 5;
  static const String _bestScoreKey = 'fishing_ishikawa_best_score';

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
  int _bestScore = 0;
  int _combo = 0;
  int _baitRemaining = _maxBait;
  int _remainingBiteSeconds = 0;
  double _biteFishXFactor = 0.65;
  double _biteFishYFactor = 0.68;
  double _hookMeter = 0.5;
  double _hookTargetCenter = 0.5;
  double _hookTargetWidth = 0.24;
  int _hookCycleMs = 900;
  int _hookElapsedMs = 0;

  Timer? _biteTimer;
  Timer? _countdownTimer;
  Timer? _hookMeterTimer;
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
    _loadBestScore();
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _bestScore = prefs.getInt(_bestScoreKey) ?? 0;
    });
  }

  Future<void> _saveBestScoreIfNeeded() async {
    if (_score <= _bestScore) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bestScoreKey, _score);
    if (!mounted) {
      return;
    }
    setState(() {
      _bestScore = _score;
    });
  }

  void _updateScoreAndPersistBest(int gained) {
    _score += gained;
    _saveBestScoreIfNeeded();
  }

  Future<void> _loadSceneryPhoto() async {
    try {
      final photos = await _scenicPhotoService.fetchNearSpotGallery(
        widget.spot,
        maxCount: 20,
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
    _hookMeterTimer?.cancel();
  }

  void _castLine() {
    if (_phase == FishingPhase.waitingForBite ||
        _phase == FishingPhase.biteWindow) {
      return;
    }

    if (_baitRemaining <= 0) {
      setState(() {
        _message = 'エサ切れ！ リセットして再挑戦しよう';
      });
      return;
    }

    _cancelTimers();
    final waitSeconds = 2 + _random.nextInt(4);
    setState(() {
      _baitRemaining--;
      _phase = FishingPhase.waitingForBite;
      _message = '仕掛けを投入… 魚が来るまで待とう（エサ残り$_baitRemaining）';
    });

    _biteTimer = Timer(Duration(seconds: waitSeconds), _startBiteWindow);
  }

  void _startBiteWindow() {
    if (!mounted) {
      return;
    }

    _remainingBiteSeconds = 3;
    _hookElapsedMs = 0;
    _hookMeter = _random.nextDouble();
    _hookTargetCenter = 0.2 + (_random.nextDouble() * 0.6);
    _hookTargetWidth = (0.28 - (_combo * 0.012)).clamp(0.14, 0.28);
    _hookCycleMs = (900 - (_combo * 22)).clamp(520, 900);
    setState(() {
      _biteFishXFactor = 0.2 + (_random.nextDouble() * 0.6);
      _biteFishYFactor = 0.52 + (_random.nextDouble() * 0.3);
      _phase = FishingPhase.biteWindow;
      _message = 'アタリ！ 緑ゾーンで「釣る」！';
    });

    _hookMeterTimer = Timer.periodic(const Duration(milliseconds: 70), (timer) {
      if (!mounted || _phase != FishingPhase.biteWindow) {
        timer.cancel();
        return;
      }

      _hookElapsedMs += 70;
      final t = (_hookElapsedMs % _hookCycleMs) / _hookCycleMs;
      final wave = t < 0.5 ? t * 2 : (1 - t) * 2;

      setState(() {
        _hookMeter = wave;
      });
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
          _message = 'アタリ！ 緑ゾーンで釣る（残り$_remainingBiteSeconds秒）';
        });
      }
    });
  }

  void _hookFish() {
    if (_phase != FishingPhase.biteWindow) {
      return;
    }

    _cancelTimers();
    final inTarget =
        (_hookMeter - _hookTargetCenter).abs() <= (_hookTargetWidth / 2);

    if (!inTarget) {
      final diff = _hookMeter - _hookTargetCenter;
      setState(() {
        _combo = 0;
        _phase = FishingPhase.result;
        _message = diff < 0
            ? '合わせが早い！もう少し待とう'
            : '合わせが遅い！次は早めに';
      });
      return;
    }

    final fish = _currentSpot.pickFish(_random);
    final precision =
        1 - ((_hookMeter - _hookTargetCenter).abs() / (_hookTargetWidth / 2));
    final precisionBonus = (precision * 10).round();
    final gained = 10 + (_combo * 2) + precisionBonus;
    setState(() {
      _updateScoreAndPersistBest(gained);
      _combo++;
      _phase = FishingPhase.result;
      _message = '$fish を釣り上げた！ +$gained点';
    });
  }

  void _loseFish() {
    _cancelTimers();
    setState(() {
      _combo = 0;
      _phase = FishingPhase.result;
      _message = '逃げられた… タイミングを合わせよう';
    });
  }

  void _resetGame() {
    _cancelTimers();
    setState(() {
      _phase = FishingPhase.waiting;
      _message = '${_currentSpot.name}で「投げる」を押して釣りを始めよう';
      _score = 0;
      _combo = 0;
      _baitRemaining = _maxBait;
    });
  }

  int _maxReachableScore() {
    final r = _baitRemaining;
    final c = _combo;
    final futurePerfect = (r * (20 + (2 * c))) + (r * (r - 1));
    return _score + futurePerfect;
  }

  bool get _isGameOver {
    final inRound = _phase == FishingPhase.waitingForBite ||
        _phase == FishingPhase.biteWindow;
    return _baitRemaining <= 0 && !inRound;
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
                            _HudChip(text: 'ベスト $_bestScore', icon: Icons.emoji_events),
                            _HudChip(text: 'コンボ $_combo', icon: Icons.bolt),
                            _HudChip(text: 'エサ $_baitRemaining/$_maxBait', icon: Icons.catching_pokemon),
                            if (_isGameOver)
                              _HudChip(text: 'ゲーム終了', icon: Icons.flag),
                            _HudChip(
                              text: '理論最高 ${_maxReachableScore()}',
                              icon: Icons.trending_up,
                            ),
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
                            if (_phase == FishingPhase.biteWindow)
                              _HudChip(
                                text: '緑ゾーンでHIT',
                                icon: Icons.tune,
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
                      if (_phase == FishingPhase.biteWindow)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 84,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface.withValues(alpha: 0.86),
                              borderRadius: BorderRadius.circular(
                                AppConstants.cardBorderRadius,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '合わせゲージ（残り$_remainingBiteSeconds秒）',
                                  style: Theme.of(context).textTheme.labelMedium,
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 14,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: (_hookTargetCenter - (_hookTargetWidth / 2)) *
                                            (constraints.maxWidth - 56),
                                        width:
                                            _hookTargetWidth * (constraints.maxWidth - 56),
                                        top: 0,
                                        bottom: 0,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.75),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: (_hookMeter * (constraints.maxWidth - 56)) - 3,
                                        top: -2,
                                        bottom: -2,
                                        child: Container(
                                          width: 6,
                                          decoration: BoxDecoration(
                                            color: colorScheme.error,
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                                  child: Text('投げる（残り$_baitRemaining）'),
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
                      if (_isGameOver)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.46),
                            alignment: Alignment.center,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.surface.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(
                                  AppConstants.cardBorderRadius,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'GAME OVER',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('最終スコア: $_score'),
                                  Text('ベスト: $_bestScore'),
                                  const SizedBox(height: 12),
                                  FilledButton(
                                    onPressed: _resetGame,
                                    child: const Text('もう一度遊ぶ'),
                                  ),
                                ],
                              ),
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
