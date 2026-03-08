import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remote_kattedon/core/constants/app_constants.dart';
import 'package:remote_kattedon/fishing_in_ishikawa/models/fishing_models.dart';
import 'package:remote_kattedon/fishing_in_ishikawa/services/open_data_service.dart';
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

  FishingPhase _phase = FishingPhase.waiting;
  late String _message;
  late FishingSpot _currentSpot;
  String? _openDataLabel;
  String? _openDataSource;
  int _score = 0;
  int _combo = 0;
  int _remainingBiteSeconds = 0;
  double _biteFishXFactor = 0.65;
  double _biteFishYFactor = 0.68;

  Timer? _biteTimer;
  Timer? _countdownTimer;
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

  @override
  void dispose() {
    _cancelTimers();
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
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.landscape),
                        const SizedBox(width: AppConstants.smallPadding),
                        Text('景色: ${_currentSpot.sceneryName}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '背景: 国土地理院シームレス空中写真',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            if (_currentSpot.totalCatchKg != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('推定漁獲量: ${_currentSpot.totalCatchKg}kg / 月'),
                      Text('主な魚: ${_currentSpot.topFish}'),
                    ],
                  ),
                ),
              ),
            if (_openDataLabel != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
                child: Column(
                  children: [
                    Text(
                      _openDataLabel!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (_openDataSource != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: InkWell(
                              onTap: _openSourceUrl,
                              child: Text(
                                _openDataSource!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'URLをコピー',
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: _openDataSource!),
                              );
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('取得元URLをコピーしました')),
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            const SizedBox(height: AppConstants.smallPadding),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('スコア'),
                        Text(
                          '$_score',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('コンボ'),
                        Text(
                          '$_combo',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.largePadding),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                    child: AnimatedBuilder(
                      animation: _swimController,
                      builder: (context, child) {
                        final swim1X = -40 +
                            (constraints.maxWidth + 80) * _swimController.value;
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
                                _sceneryPhotoTileUrl,
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
                                      colorScheme.scrim.withValues(alpha: 0.18),
                                      colorScheme.scrim.withValues(alpha: 0.42),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 22,
                              left: 24,
                              child: Icon(
                                Icons.cloud,
                                color: Colors.white.withValues(alpha: 0.85),
                                size: 40,
                              ),
                            ),
                            Positioned(
                              top: 32,
                              right: 28,
                              child: Icon(
                                Icons.cloud,
                                color: Colors.white.withValues(alpha: 0.75),
                                size: 32,
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: 140,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      colorScheme.secondaryContainer
                                          .withValues(alpha: 0.7),
                                      colorScheme.secondary.withValues(alpha: 0.95),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: swim1X,
                              bottom: 56,
                              child: Icon(
                                Icons.set_meal,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 32,
                              ),
                            ),
                            Positioned(
                              left: swim2X,
                              bottom: 92,
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..scale(-1.0, 1.0),
                                child: Icon(
                                  Icons.set_meal,
                                  color: Colors.white.withValues(alpha: 0.68),
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
                            Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.defaultPadding,
                                ),
                                padding: const EdgeInsets.all(
                                  AppConstants.defaultPadding,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface.withValues(alpha: 0.85),
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
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            FilledButton(
              onPressed: canCast ? _castLine : null,
              child: const Text('投げる'),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            FilledButton.tonal(
              onPressed: canHook ? _hookFish : null,
              child: const Text('釣る'),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            OutlinedButton(
              onPressed: _resetGame,
              child: const Text('リセット'),
            ),
          ],
        ),
      ),
    );
  }
}
