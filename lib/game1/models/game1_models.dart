/// ゲーム1のモデル定義（実装用プレースホルダー）

class Game1GameState {
  // ゲーム状態管理用
  int score = 0;
  int level = 1;
  bool isGameOver = false;

  void updateScore(int points) {
    score += points;
  }

  void levelUp() {
    level++;
  }

  void reset() {
    score = 0;
    level = 1;
    isGameOver = false;
  }
}
