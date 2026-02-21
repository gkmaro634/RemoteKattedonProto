import 'package:flutter/foundation.dart';

enum ToolType { hand, scissors, knife, chopsticks }

/// もともとは表(front)/裏(back)を持っていたが、
/// 現在のゲーム仕様では「ツールのみを選ぶ」シンプルな進行のため
/// SideType は実質的には使用しない（常に any として扱う）。
enum SideType { front, back, any }

/// JFいしかわ流・解体ステップの定義
///
/// 現在のゲーム仕様では「ステップごとに正しいツールを当てる」だけなので、
/// すべてのステップの requiredSide を SideType.any に統一している。
enum DeconstructionStep {
  removeFundoshi(1, 'ふんどしを外す', ToolType.hand, SideType.any),
  removeLegsWithBody(2, '肩肉ごと脚を外す', ToolType.hand, SideType.any),
  removeGani(3, '肩肉からガニを外す', ToolType.hand, SideType.any),
  removeMouth(4, '甲羅から口を外す', ToolType.hand, SideType.any),
  collectMiso(5, 'カニ味噌・内子を回収する', ToolType.chopsticks, SideType.any),
  detachLegs(6, '肩肉から脚を外す', ToolType.hand, SideType.any),
  collectBodyMeat(7, '肩肉から身を回収する', ToolType.chopsticks, SideType.any),
  cutLegShell(8, '脚に切込みを入れる', ToolType.scissors, SideType.any),
  extractLegMeat(9, '脚の身を取り出す', ToolType.hand, SideType.any);

  final int stepNumber;
  final String label;
  final ToolType requiredTool;
  final SideType requiredSide;
  const DeconstructionStep(
    this.stepNumber,
    this.label,
    this.requiredTool,
    this.requiredSide,
  );
}

extension DeconstructionStepExt on DeconstructionStep {
  /// 次のステップを取得する
  DeconstructionStep? get next {
    final nextIndex = index + 1;
    return nextIndex < DeconstructionStep.values.length
        ? DeconstructionStep.values[nextIndex]
        : null;
  }

  /// プレイヤーのアクションが正解か判定する
  bool isCorrectAction(ToolType tool, SideType side) {
    final sideMatch = requiredSide == SideType.any || requiredSide == side;
    return requiredTool == tool && sideMatch;
  }
}

@immutable
class GameState {
  final DeconstructionStep currentStep;
  final SideType currentSide;
  final List<DeconstructionStep> completedSteps; // 履歴
  final bool isGameOver;

  const GameState({
    required this.currentStep,
    this.currentSide = SideType.back,
    this.completedSteps = const [],
    this.isGameOver = false,
  });

  // 進捗率を計算するゲッターなどがあるとUIで使いやすい
  double get progress =>
      (currentStep.stepNumber - 1) / DeconstructionStep.values.length;

  GameState copyWith({
    DeconstructionStep? currentStep,
    SideType? currentSide,
    List<DeconstructionStep>? completedSteps,
    bool? isGameOver,
  }) {
    return GameState(
      currentStep: currentStep ?? this.currentStep,
      currentSide: currentSide ?? this.currentSide,
      completedSteps: completedSteps ?? this.completedSteps,
      isGameOver: isGameOver ?? this.isGameOver,
    );
  }
}
