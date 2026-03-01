import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_kattedon/game_genge/models/genge_layout.dart';
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

class _GengeGameScreenState extends ConsumerState<GengeGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  ui.Image? _backgroundImage;
  ui.Image? _gengeImage;
  bool _imagesLoaded = false;
  final GlobalKey _paintKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // リセットしてから開始
    final notifier = ref.read(gengeGameProvider.notifier);
    notifier.resetGame();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // 約60FPS
    )
      ..addListener(() {
        if (!mounted) return;

        ref.read(gengeGameProvider.notifier).updateFrame();
      })
      ..repeat();

    _loadImages();
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

  /// ゲーム開始
  void _startGame() {
    final notifier = ref.read(gengeGameProvider.notifier);
    notifier.startGame();
    setState(() {
      // _gameStarted = true;
    });
  }

  /// タップ位置でゲンゲがタップされたか判定
  void _onCanvasTap(Offset position) {
    final gameStateAsyncValue = ref.read(gengeGameProvider);

    gameStateAsyncValue.whenData((gameState) {
      if (!gameState.isGameOver && gameState.timeLeft > 0) {
        final renderBox =
            _paintKey.currentContext!.findRenderObject() as RenderBox;
        final canvasSize = renderBox.size;
        final gengeRect = calcGengeRect(
          canvasSize: canvasSize,
          imageWidth: _gengeImage!.width.toDouble(),
          imageHeight: _gengeImage!.height.toDouble(),
          shakingFrames: gameState.shakingFrames,
        );

        if (_gengeImage == null) return;
        if (gengeRect.contains(position)) {
          ref.read(gengeGameProvider.notifier).onGengePressed(position);
        }
      } 
    });
  }

  Widget _buildRetryButton() {
    return Center(
      child: Transform.translate(
        offset: const Offset(0, 290),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(220, 50),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,

          ),
          onPressed: () {
            ref.read(gengeGameProvider.notifier).resetGame();
            _startGame();
          },
          child: const Text("もう一度ぷるぷる"),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();

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

            return Stack(
              children: [
                GestureDetector(
                  onTapDown: (details) {
                    final renderBox = _paintKey.currentContext!
                        .findRenderObject() as RenderBox;
                    final localPos =
                        renderBox.globalToLocal(details.globalPosition);
                    _onCanvasTap(localPos);
                  },
                  child: CustomPaint(
                    key: _paintKey,
                    painter: GengeGamePainter(
                        gameState: gameState,
                        gengeImage: _gengeImage!,
                        backgroundImage: _backgroundImage!),
                    size: Size.infinite,
                  ),
                ),
                if (gameState.isGameOver) _buildRetryButton(),
              ],
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
