import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_kattedon/game_genge/providers/game_notifier.dart';
import 'package:remote_kattedon/game_genge/widgets/genge_game_painter.dart';
import 'package:remote_kattedon/navigation/route_names.dart';
import 'dart:async';
import 'dart:ui' as ui;

class GengeGameScreen extends ConsumerStatefulWidget {
  const GengeGameScreen({super.key});

  @override
  ConsumerState<GengeGameScreen> createState() => _GengeGameScreenState();
}

class _GengeGameScreenState extends ConsumerState<GengeGameScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  ui.Image? _backgroundImage;
  ui.Image? _gengeImage;
  bool _imagesLoaded = false;
  bool _gameStarted = false;
  // late Timer _paintUpdateTimer;

  @override
  void initState() {
    super.initState();

    // リセットしてから開始
    final notifier = ref.read(gengeGameProvider.notifier);
    notifier.resetGame();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // 約60FPS
    )..addListener(() {
        ref.read(gengeGameProvider.notifier).updateParticles();
        setState(() {});
      })
      ..repeat();

    _loadImages();
    // _startPaintUpdateTimer();
  }

  /// 画像を非同期で読み込む
  void _loadImages() async {
    try {
      final bgImage = await _loadImageAsset('assets/images/genge/umi.jpg');
      final gengeImg = await _loadImageAsset('assets/images/genge/genge.png');

      if (mounted) {
        setState(() {
          _backgroundImage = bgImage;
          _gengeImage = gengeImg;
          _imagesLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to load images: $e');
    }
  }

  /// アセットから画像を読み込む
  Future<ui.Image> _loadImageAsset(String assetPath) async {
    final data = await DefaultAssetBundle.of(context).load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// ペイント更新タイマーを開始
  // void _startPaintUpdateTimer() {
  //   _paintUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
  //     // the widget may be disposed by the time the timer fires
  //     if (!mounted) return;
  //     final notifier = ref.read(gengeGameProvider.notifier);
  //     notifier.updateParticles();
  //     // safe to call setState since mounted is true
  //     setState(() {});
  //   });
  // }

  /// ゲーム開始
  void _startGame() {
    final notifier = ref.read(gengeGameProvider.notifier);
    notifier.startGame();
    setState(() {
      _gameStarted = true;
    });
  }

  /// タップ位置でゲンゲがタップされたか判定
  void _onCanvasTap(Offset position) {
    final gameStateAsyncValue = ref.read(gengeGameProvider);

    gameStateAsyncValue.whenData((gameState) {
      if (!gameState.isGameOver && gameState.timeLeft > 0) {
        // ゲンゲの矩形を取得
        final screenSize = MediaQuery.of(context).size;

        if (_gengeImage == null) return;

        // ゲンゲのサイズ計算
        const baseWidth = 400.0;
        final aspectRatio =
            _gengeImage!.height.toDouble() / _gengeImage!.width.toDouble();
        final baseHeight = baseWidth * aspectRatio;

        final shakeAmount = gameState.shakingFrames;
        final drawWidth = baseWidth + (shakeAmount * 8);
        final drawHeight = baseHeight - (shakeAmount * 4);

        final centerX = screenSize.width / 2;
        final centerY = screenSize.height / 2;

        final gengeRect = Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: drawWidth,
          height: drawHeight,
        );

        if (gengeRect.contains(position)) {
          ref.read(gengeGameProvider.notifier).onGengePressed(position);
        }
      } else if (gameState.isGameOver) {
        // リトライボタン判定
        final screenSize = MediaQuery.of(context).size;
        const buttonWidth = 220.0;
        const buttonHeight = 50.0;

        final retryButtonRect = Rect.fromCenter(
          center: Offset(screenSize.width / 2, screenSize.height / 2 + 290),
          width: buttonWidth,
          height: buttonHeight,
        );

        if (retryButtonRect.contains(position)) {
          ref.read(gengeGameProvider.notifier).resetGame();
          setState(() {
            _gameStarted = false;
          });
          _startGame();
        }
      }
    });
  }

  @override
  void dispose() {
    // 画面を離れるときにタイマーを止めておく
    final notifier = ref.read(gengeGameProvider.notifier);
    notifier.resetGame();

    _animationController.dispose();
    // _paintUpdateTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameAsyncState = ref.watch(gengeGameProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ぷるぷるゲンゲ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RouteNames.gameSelection),
        ),
      ),
      body: SafeArea(
        child: gameAsyncState.when(
          data: (gameState) {
            if (!_imagesLoaded) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (!_gameStarted) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'ぷるぷるゲンゲをタップしてスコアを稼ごう！',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '15秒間のタイムアタック',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.tonalIcon(
                      onPressed: _startGame,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('ゲーム開始'),
                    ),
                  ],
                ),
              );
            }

            return GestureDetector(
              onTapDown: (details) => _onCanvasTap(details.localPosition),
              child: CustomPaint(
                painter: GengeGamePainter(
                  gameState: gameState,
                  backgroundImage: _backgroundImage,
                  gengeImage: _gengeImage,
                  screenSize: Offset(
                    MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height,
                  ),
                ),
                size: Size.infinite,
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('エラーが発生しました: $error'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
