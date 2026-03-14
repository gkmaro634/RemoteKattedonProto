import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_kattedon/game_bora/models/bora_models.dart';
import 'package:remote_kattedon/game_bora/providers/bora_game_notifier.dart';
import 'package:remote_kattedon/game_bora/widgets/bora_game_painter.dart';
import 'package:remote_kattedon/navigation/route_names.dart';
import 'dart:math';

class BoraGameScreen extends ConsumerStatefulWidget {
  final Character? initialCharacter;
  const BoraGameScreen({Key? key, this.initialCharacter}) : super(key: key);

  @override
  ConsumerState<BoraGameScreen> createState() => _BoraGameScreenState();
}

class _BoraGameScreenState extends ConsumerState<BoraGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  ui.Image? _boraImage;
  bool _hasShownHighScoreDialog = false;

  Future<void> _loadBoraImage() async {
    final data = await rootBundle.load('assets/images/bora/bora.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    setState(() {
      _boraImage = frame.image;
    });
  }

  @override
  void initState() {
    super.initState();
    // postpone starting the game until after build completes
    if (widget.initialCharacter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(boraGameProvider.notifier).startGame(widget.initialCharacter!);
      });
    }

    _loadBoraImage();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )
      ..addListener(() {
        ref.read(boraGameProvider.notifier).updateFrame(0.016);

        setState(() {});
      })
      ..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showNewHighScoreDialog(BuildContext context, int score) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🎉 おめでとう！'),
          content: Text('新しいハイスコア $score を達成しました！'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _onCanvasTap(Offset position) {
    // not used for now
  }

  @override
  Widget build(BuildContext context) {
    final gameStateAsync = ref.watch(boraGameProvider);

    return gameStateAsync.when(
      data: (gameState) {
        // Show high score dialog if new high score achieved
        if (gameState.phase == GamePhase.result &&
            gameState.isNewHighScore &&
            !_hasShownHighScoreDialog) {
          _hasShownHighScoreDialog = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showNewHighScoreDialog(context, gameState.score);
          });
        }

        final character = gameState.character;

        return Scaffold(
          appBar: AppBar(
            title: const Text('ボラ待ちやぐら'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(RouteNames.gameSelection),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                if (gameState.phase == GamePhase.waiting ||
                    gameState.phase == GamePhase.raising)
                  Container(
                    color: const Color(0xff141e2e),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(character != null ? '${character.emoji} ${character.name}' : '',
                            style: const TextStyle(color: Colors.white)),
                        Text(
                          '⏱ ${max(0, 120 - gameState.gameTime.floor())}秒',
                          style: TextStyle(
                              color: gameState.gameTime > 100 ? Colors.redAccent : Colors.white),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: GestureDetector(
                    onTapDown: (d) => _onCanvasTap(d.localPosition),
                    child: CustomPaint(
                      painter: BoraGamePainter(gameState: gameState, boraImage: _boraImage),
                      size: Size.infinite,
                    ),
                  ),
                ),
                _buildUiPanel(gameState, character),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }

  Widget _buildUiPanel(GameState state, Character? character) {
    if (character == null) return const SizedBox.shrink();
    final maxSupporters = getMaxSupporters(character);
    final canCall = state.virtueGauge >= getVirtueCost(character) &&
        state.supporters.length < maxSupporters &&
        !state.isRaising;
    final boraInNet = state.boraCountInNet;
    final virtueRatio = state.virtueGauge / state.maxVirtue;
    Color virtueColor;
    if (virtueRatio > 0.6) {
      virtueColor = Colors.green;
    } else if (virtueRatio > 0.3) {
      virtueColor = Colors.yellow;
    } else {
      virtueColor = Colors.red;
    }

    return Container(
      color: const Color(0xff141e2e),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🙏 人徳ゲージ', style: TextStyle(color: Colors.white, fontSize: 12)),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white70),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: virtueRatio,
                        child: Container(color: virtueColor),
                      ),
                    ),
                    Text('${state.virtueGauge.floor()}/${state.maxVirtue.floor()}',
                        style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🎣 引き上げ進捗', style: TextStyle(color: Colors.white, fontSize: 12)),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(border: Border.all(color: Colors.white70)),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: state.netProgress / 100,
                        child: Container(color: state.isRaising ? Colors.red : Colors.blue),
                      ),
                    ),
                    Text('${state.netProgress.floor()}%',
                        style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _actionButton('応援を呼ぶ', canCall ? () => ref.read(boraGameProvider.notifier).onCallSupporter() : null,
                  subtext: '人徳 -${getVirtueCost(character)}'),
              const SizedBox(width: 8),
              _actionButton('網を引き上げる', state.isRaising ? null : () => ref.read(boraGameProvider.notifier).onRaiseNet(),
                  subtext: '網の中 $boraInNet尾'),
            ],
          ),
          // 常に最大3行分の領域を確保し、要素は幅に応じて折り返す
          // 高さは 3 行 * 30px = 90px（必要に応じて調整可）
          SizedBox(
            height: 90,
            child: state.supporters.isNotEmpty
                ? SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: state.supporters.map((s) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(s.emoji),
                              const SizedBox(width: 6),
                              Text(s.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : Container(),
          ),
          if (state.phase == GamePhase.result) _buildResult(state, character),
        ],
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback? onPressed, {String? subtext}) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, textAlign: TextAlign.center),
            if (subtext != null)
              Text(subtext, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(GameState state, Character character) {
    String rankText;
    if (state.score >= 2000) {
      rankText = '大漁！';
    } else if (state.score >= 1200) {
      rankText = '豊漁';
    } else if (state.score >= 600) {
      rankText = '普通';
    } else {
      rankText = '不漁';
    }

    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(rankText, style: const TextStyle(color: Colors.yellow, fontSize: 18)),
          Text('捕れた: ${state.caughtBoras}尾', style: const TextStyle(color: Colors.white, fontSize: 12)),
          Text('逃げた: ${state.escapedBoras}尾', style: const TextStyle(color: Colors.white, fontSize: 12)),
          Text('時間: ${state.gameTime.floor()}秒', style: const TextStyle(color: Colors.white, fontSize: 12)),
          Text('スコア: ${state.score}', style: const TextStyle(color: Colors.white, fontSize: 12)),
          Text('ハイスコア: ${state.highScore}', style: const TextStyle(color: Colors.white, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  ref.read(boraGameProvider.notifier).reset(character);
                },
                child: const Text('もう一度'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  context.go(RouteNames.gameSelection);
                },
                child: const Text('タイトルへ'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
