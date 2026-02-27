// 石川釣りゲームのモデル定義（実装用プレースホルダー）

class FishingInIshikawaGameState {
  // ゲーム状態管理用
  int score = 0;
  int combos = 0;
  bool isPaused = false;

  void updateScore(int points) {
    score += points;
  }

  void incrementCombo() {
    combos++;
  }

  void resetCombo() {
    combos = 0;
  }

  void reset() {
    score = 0;
    combos = 0;
    isPaused = false;
  }
}
