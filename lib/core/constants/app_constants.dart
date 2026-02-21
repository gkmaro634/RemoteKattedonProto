class AppConstants {
  // アプリ名
  static const String appName = 'リモート勝手丼';
  static const String appSubtitle = 'Edutainment Seafood Bowl';

  // URL（勝手丼注文ページなど）
  static const String katteedomOrderUrl = 'https://example.com/order';

  // ゲーム定義
  static const List<GameInfo> availableGames = [
    GameInfo(
      id: 'deshellingCrab',
      title: '蟹解体チャレンジ',
      description: '蟹を正しい手順で解体しよう！',
      icon: '🦀',
    ),
    GameInfo(
      id: 'game2',
      title: 'ゲーム2',
      description: 'プレースホルダー：ゲーム2の説明',
      icon: '🎯',
    ),
  ];

  // UI定数
  static const double cardBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
}

class GameInfo {
  final String id;
  final String title;
  final String description;
  final String icon;

  const GameInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}
