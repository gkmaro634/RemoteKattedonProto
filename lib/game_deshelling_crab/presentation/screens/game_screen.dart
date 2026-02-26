import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../providers/game_notifier.dart';
import '../../../navigation/route_names.dart';

/// 各ステップに対応する蟹画像のアセットパス
/// `asetts.md` の定義に基づき、「次のアクションを行う前の状態」の画像を表示する。
String _imageForStep(DeconstructionStep step) {
  switch (step) {
    case DeconstructionStep.removeFundoshi:
      // step01: 未処理
      return 'assets/images/deshelling_crab/step01.png';
    case DeconstructionStep.removeLegsWithBody:
      // step02: ふんどしが外れた
      return 'assets/images/deshelling_crab/step02.png';
    case DeconstructionStep.removeGani:
      // step03: 肩肉ごと脚が外れた
      return 'assets/images/deshelling_crab/step03.png';
    case DeconstructionStep.removeMouth:
      // step05: 口が外される前の甲羅
      return 'assets/images/deshelling_crab/step05.png';
    case DeconstructionStep.collectMiso:
      // step06: 口が外された後の甲羅
      return 'assets/images/deshelling_crab/step06.png';
    case DeconstructionStep.detachLegs:
      // step07: 肩肉から脚が外される前
      return 'assets/images/deshelling_crab/step07.png';
    case DeconstructionStep.collectBodyMeat:
      // step08: 肩肉から脚が外された後
      return 'assets/images/deshelling_crab/step08.png';
    case DeconstructionStep.cutLegShell:
      // step09: 関節で分解される前の脚
      return 'assets/images/deshelling_crab/step09.png';
    case DeconstructionStep.extractLegMeat:
      // step11: 切り込みが入った脚（このあと身を取り出す）
      return 'assets/images/deshelling_crab/step11.png';
  }
}

/// 各ステップの「作業説明用」画像のパス（仮）を返す。
String _explanationImageForStep(DeconstructionStep step) {
  // 作業説明用画像のパス assets/images/deshelling_crab/step_detail_01.png を返す
  final number = step.stepNumber.toString().padLeft(2, '0');
  return 'assets/images/deshelling_crab/step_detail_$number.png';
}

/// 解体ゲームのプロトタイプ画面。
/// 画面上部: 進捗バー + Step情報（右側に◯/✕）
/// 中央: ステップに対応する蟹画像
/// 下部: ツール選択・解体実行
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  // duration used by the central image transition (AnimatedSwitcher)
  // keep this in sync with the wait used after showing detailImage
  static const Duration _imageTransitionDuration = Duration(seconds: 1);

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _isActionInProgress = false;

  static String _toolLabel(ToolType tool) {
    return switch (tool) {
      ToolType.hand => '素手',
      ToolType.scissors => 'はさみ',
      ToolType.knife => '包丁',
      ToolType.chopsticks => '箸',
    };
  }

  @override
  Widget build(BuildContext context) {
    final notifierState = ref.watch(gameNotifierProvider);
    final game = notifierState.gameState;
    final notifier = ref.read(gameNotifierProvider.notifier);
    final step = game.currentStep;
    final totalSteps = DeconstructionStep.values.length;
    final resultUi = notifierState.resultUi;

    if (game.isGameOver) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('蟹解体ゲーム'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(RouteNames.deshellingCrabStart),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
/// 借体画面の完成画像 を表示し、戻るボタンを出し（ゲームクリア継美带までの流れ
                        child: Image.asset(
                          'assets/images/deshelling_crab/step13.png', // 完成画像
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image_not_supported, size: 80),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'クリア！',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '全${DeconstructionStep.values.length}ステップ完了',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  onPressed: () {
                    notifier.reset();
                  },
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('最初からやり直す'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('蟹解体ゲーム'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RouteNames.deshellingCrabStart),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 全体工程の進捗表示
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '工程 ${step.stepNumber} / $totalSteps',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: game.progress.clamp(0, 1),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 画面上部: 現在のステップ名と、必要なツール（右側に◯/✕、説明画像）
              _StepHeader(
                step: step,
                resultSymbol: resultUi?.symbol,
                resultImagePath: resultUi?.imagePath,
              ),
              const SizedBox(height: 24),

              // 画面中央: 蟹画像（ステップごとに切り替え）
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 透過PNGの透明部分を単色で表示（チェッカーを出さない）
                    Expanded(
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: AnimatedSwitcher(
                            duration: GameScreen._imageTransitionDuration,
                            switchInCurve: Curves.easeIn,
                            switchOutCurve: Curves.easeOut,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(opacity: animation, child: child),
                            child: ClipRRect(
                              key: ValueKey(resultUi?.imagePath ?? _imageForStep(step)),
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // 黒い背景（透過PNG用）
                                  Container(color: Colors.black),
                                  // 蟹の画像
                                  Image.asset(
                                    resultUi?.imagePath ?? _imageForStep(step),
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.image_not_supported,
                                      size: 80,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // 画面下部: 4つのツールボタン
              Text(
                'ツールを選択',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: ToolType.values.map((tool) {
                  final isSelected = notifierState.selectedTool == tool;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _ToolButton(
                        tool: tool,
                        label: _toolLabel(tool),
                        isSelected: isSelected,
                        onTap: () => notifier.selectTool(tool),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 解体実行ボタン
              FilledButton(
                onPressed: (notifierState.resultUi != null || _isActionInProgress)
                    ? null
                    : () async {
                        // prevent re-entrancy and disable during animations
                        setState(() => _isActionInProgress = true);
                        try {
                          // SideType は無視し、ツールのみで正解判定
                          final correct = step.isCorrectAction(
                            notifierState.selectedTool,
                            SideType.any,
                          );
                          if (!context.mounted) return;

                          if (correct) {
                            // 正解: detailImage を表示 → 表示完了後に次の工程へ
                            final detailImage = _explanationImageForStep(step);
                            notifier.showResult(
                              ResultUiState(symbol: '◯', imagePath: detailImage),
                            );

                            // wait for the image transition (in) and keep detail image visible
                            await Future.delayed(GameScreen._imageTransitionDuration + const Duration(seconds: 1));
                            if (!context.mounted) return;

                            // advance step and trigger the transition (detail -> next step)
                            notifier.attemptAction();
                            notifier.clearResult();

                            // keep button disabled until the final image transition finishes
                            await Future.delayed(GameScreen._imageTransitionDuration);
                          } else {
                            // 不正解: 0.5秒だけ ✕ を表示（ステップは進めない）
                            notifier.showResult(const ResultUiState(symbol: '✕'));
                            await Future.delayed(const Duration(milliseconds: 500));
                            if (!context.mounted) return;
                            notifier.clearResult();
                          }
                        } finally {
                          if (mounted) setState(() => _isActionInProgress = false);
                        }
                      },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('解体実行'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.step,
    this.resultSymbol,
    this.resultImagePath,
  });

  final DeconstructionStep step;
  final String? resultSymbol;
  final String? resultImagePath;

  static String _toolLabel(ToolType tool) {
    return switch (tool) {
      ToolType.hand => '素手',
      ToolType.scissors => 'はさみ',
      ToolType.knife => '包丁',
      ToolType.chopsticks => '箸',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step ${step.stepNumber}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
              ],
            ),
            if (resultSymbol != null)
              Text(
                resultSymbol!,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: resultSymbol == '◯'
                      ? Colors.green
                      : Theme.of(context).colorScheme.error,
                ),
              ),

            // _Chip(label: 'ツール: ${_toolLabel(step.requiredTool)}'),
            // if (resultImagePath != null) ...[
            //   const SizedBox(height: 8),
            //   ClipRRect(
            //     borderRadius: BorderRadius.circular(8),
            //     child: Image.asset(
            //       resultImagePath!,
            //       height: 80,
            //       fit: BoxFit.contain,
            //       errorBuilder: (_, __, ___) =>
            //           const Icon(Icons.image_not_supported, size: 32),
            //     ),
            //   ),
            // ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.tool,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final ToolType tool;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _iconFor(tool),
                size: 28,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(ToolType tool) {
    return switch (tool) {
      ToolType.hand => Icons.back_hand,
      ToolType.scissors => Icons.content_cut,
      ToolType.knife => Icons.restaurant,
      ToolType.chopsticks => Icons.ramen_dining,
    };
  }
}
