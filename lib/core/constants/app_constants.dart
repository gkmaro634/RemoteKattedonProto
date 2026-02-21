class AppConstants {
  // アプリ名
  static const String appName = 'リモート勝手丼';
  static const String appSubtitle = 'Edutainment Seafood Bowl';

  // URL（勝手丼注文ページなど）
  static const String katteedomOrderUrl = 'https://example.com/order';

  // ゲーム定義
  static const List<GameInfo> availableGames = [
    GameInfo(
      id: 'kattedon',
      title: '勝手丼マスター',
      description: '魚介類を選んで海鮮丼を作ろう！\n漁業の知識も自然に学べます。',
      icon: '🍣',
    ),
    GameInfo(
      id: 'game1',
      title: 'ゲーム1',
      description: 'プレースホルダー：ゲーム1の説明',
      icon: '🎮',
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
