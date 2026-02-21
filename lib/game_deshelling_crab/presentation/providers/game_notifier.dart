import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';

/// 正解/不正解の一時的な表示用状態（UI専用）。
@immutable
class ResultUiState {
  const ResultUiState({
    required this.symbol,
    this.imagePath,
  });

  /// '◯' または '✕'
  final String symbol;

  /// 作業説明用画像のパス（任意）
  final String? imagePath;
}

/// GameNotifier が管理する状態。
/// [GameState] に加え、プレイヤーが選択中のツールを保持する。
@immutable
class GameNotifierState {
  const GameNotifierState({
    required this.gameState,
    this.selectedTool = ToolType.hand,
    this.resultUi,
  });

  final GameState gameState;
  final ToolType selectedTool;
  final ResultUiState? resultUi;

  GameNotifierState copyWith({
    GameState? gameState,
    ToolType? selectedTool,
    ResultUiState? resultUi,
    bool clearResultUi = false,
  }) {
    return GameNotifierState(
      gameState: gameState ?? this.gameState,
      selectedTool: selectedTool ?? this.selectedTool,
      resultUi: clearResultUi ? null : (resultUi ?? this.resultUi),
    );
  }
}

/// ゲーム状態を管理する Riverpod Notifier。
/// design.md / models.dart に基づき、初期は removeFundoshi・未処理状態から開始し、
/// 現在は「ツールのみを選ぶ」シンプルなゲームとして selectTool / attemptAction を提供する。
final gameNotifierProvider =
    NotifierProvider<GameNotifier, GameNotifierState>(GameNotifier.new);

class GameNotifier extends Notifier<GameNotifierState> {
  @override
  GameNotifierState build() {
    return _initialState();
  }

  GameNotifierState _initialState() {
    return const GameNotifierState(
      gameState: GameState(
        currentStep: DeconstructionStep.removeFundoshi,
        // 現在の仕様では面情報は使用しないため any で固定
        currentSide: SideType.any,
        completedSteps: [],
        isGameOver: false,
      ),
      selectedTool: ToolType.hand,
    );
  }

  /// 一時的な結果表示（◯/✕ と説明画像）を設定する。
  void showResult(ResultUiState ui) {
    state = state.copyWith(resultUi: ui);
  }

  /// 結果表示をクリアする。
  void clearResult() {
    state = state.copyWith(clearResultUi: true);
  }

  /// ゲームを最初の状態にリセットする。
  void reset() {
    state = _initialState();
  }

  /// 現在選択中のツールを更新する。
  void selectTool(ToolType tool) {
    state = state.copyWith(selectedTool: tool);
  }

  /// 現在の面とツールでアクションを試行する。
  /// 現在は「ツールのみ」をチェックし、正解であれば次のステップへ進む。
  void attemptAction() {
    final game = state.gameState;
    if (game.isGameOver) return;

    final step = game.currentStep;
    final tool = state.selectedTool;

    // 面(SideType)は使用しないため、SideType.any を渡してツールだけを判定。
    if (step.isCorrectAction(tool, SideType.any)) {
      final next = step.next;
      final completed = [...game.completedSteps, step];
      if (next == null) {
        state = state.copyWith(
          gameState: game.copyWith(
            completedSteps: completed,
            isGameOver: true,
          ),
        );
      } else {
        state = state.copyWith(
          gameState: game.copyWith(
            currentStep: next,
            completedSteps: completed,
          ),
        );
      }
    } else {
      debugPrint(
        '不正解: ツール=$tool / 要求ツール=${step.requiredTool}',
      );
    }
  }
}
