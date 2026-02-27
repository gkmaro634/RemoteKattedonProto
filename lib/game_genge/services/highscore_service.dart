import 'package:shared_preferences/shared_preferences.dart';

/// ハイスコアを管理するサービス
class HighscoreService {
  static const String _highscoreKey = 'genge_highscore';

  /// ハイスコアを読み込む
  static Future<int> loadHighscore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_highscoreKey) ?? 0;
    } catch (e) {
      print('Failed to load highscore: $e');
      return 0;
    }
  }

  /// ハイスコアを保存する
  static Future<bool> saveHighscore(int score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setInt(_highscoreKey, score);
    } catch (e) {
      print('Failed to save highscore: $e');
      return false;
    }
  }
}
