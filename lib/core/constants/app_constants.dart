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
      id: 'fishingInIshikawa',
      title: '石川釣りゲーム',
      description: '石川県の色んな漁場を巡りながら、釣りを楽しむゲームです。\n\n',
      icon: '🎣',
    ),
    GameInfo(
      id: 'genge',
      title: 'ぷるぷるゲンゲ',
      description: 'ゲンゲを連打してスコアを稼ごう！',
      icon: 'assets/images/icons/icon_genge.png',
      iconType: 'image',
    ),
    GameInfo(
      id: 'bora',
      title: 'ボラ待ちやぐら',
      description: 'ボラの群れを待って網を引き上げよう！',
      icon: 'assets/images/icons/icon_bora.png',
      iconType: 'image',
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
  final String iconType; // 'emoji' または 'image'

  const GameInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.iconType = 'emoji',
  });
}
