/// 勝手丼ゲームのモデル定義（実装用プレースホルダー）

class KatteedomGameState {
  // ゲーム状態管理用
  final List<String> selectedSeafood = [];
  int score = 0;

  void addSeafood(String seafood) {
    selectedSeafood.add(seafood);
  }

  void reset() {
    selectedSeafood.clear();
    score = 0;
  }
}
