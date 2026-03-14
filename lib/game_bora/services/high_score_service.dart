import 'package:shared_preferences/shared_preferences.dart';

class HighScoreService {
  static const String _key = 'bora_high_score';

  static Future<int> getHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }

  static Future<void> setHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, score);
  }
}