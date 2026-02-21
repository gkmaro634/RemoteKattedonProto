# リモート勝手丼 - Flutter Webアプリ

## 概要

「リモート勝手丼」は、金沢市・近江町市場の海鮮丼注文サービスと、待ち時間を活用した複数のミニゲームを統合したEdutainmentアプリです。

詳細は [design.md](design.md) を参照してください。

## プロジェクト構造

```
lib/
├── main.dart                          # アプリのエントリーポイント
├── core/                              # アプリ共通機能
│   ├── theme/
│   │   └── app_theme.dart             # テーマ・カラーパレット定義
│   └── constants/
│       └── app_constants.dart         # 定数・ゲーム情報
├── navigation/                        # ナビゲーション層
│   ├── route_names.dart               # ルート名の定義
│   └── app_router.dart                # GoRouterの設定
├── screens/                           # 共通画面
│   ├── home_screen.dart               # ホーム画面（注文＆ゲーム選択）
│   └── game_selection_screen.dart     # ゲーム選択画面
├── widgets/                           # 共通ウィジェット
│   └── common_widgets.dart            # GameCard等の再利用可能なUI
├── kattedon/                          # 勝手丼ゲーム
│   ├── screens/
│   │   └── kattedon_start_screen.dart # ゲーム開始画面（実装時にゲーム画面を追加）
│   └── models/
│       └── kattedon_models.dart       # ゲーム状態管理
├── game1/                             # ゲーム1（拡張用テンプレート）
│   ├── screens/
│   │   └── game1_start_screen.dart
│   └── models/
│       └── game1_models.dart
└── game2/                             # ゲーム2（拡張用テンプレート）
    ├── screens/
    │   └── game2_start_screen.dart
    └── models/
        └── game2_models.dart
```

## 特徴

### Webアプリ対応設計
- **レスポンシブデザイン**：PC版では上部メニュー、モバイル版ではボトムナビを使用
- **Flutter Web対応**：`flutter run -d web` で実行可能

### 複数ゲーム並行開発対応
- **統一されたゲーム構造**：各ゲームは独立した`lib/{gameId}/`ディレクトリに配置
- **新規ゲーム追加が簡単**：同じテンプレートに従うだけで統合可能
- **共通UIの再利用**：`common_widgets.dart`で画面統一

### 技術スタック
- **Flutter**：UI フレームワーク
- **go_router**：ナビゲーション管理
- **provider**：状態管理（拡張時使用）

## 画面構成

### 1. ホーム画面（`/`）
- アプリ紹介
- 海鮮丼注文へのリンク（外部URL）
- ゲーム画面へのリンク

### 2. ゲーム選択画面（`/game-selection`）
- 利用可能なゲーム一覧（カード表示）
- 各ゲームカードから開始画面へ遷移

### 3. ゲーム開始画面
- ゲーム説明
- STARTボタン（実装時にゲーム画面へ遷移）
- 戻るボタン（ゲーム一覧へ）

## 新規ゲーム追加方法

### 1. ディレクトリ構造を作成
```
lib/game{n}/
├── screens/
│   └── game{n}_start_screen.dart
└── models/
    └── game{n}_models.dart
```

### 2. ゲーム情報を `app_constants.dart` に追加
```dart
static const List<GameInfo> availableGames = [
  // ...既存ゲーム...
  GameInfo(
    id: 'game{n}',
    title: 'ゲーム{n}の名前',
    description: 'ゲーム説明',
    icon: 'アイコン絵文字',
  ),
];
```

### 3. ルート定義を `route_names.dart` と `app_router.dart` に追加
```dart
// route_names.dart
static const String game{n}Start = '/game{n}-start';

// app_router.dart
GoRoute(
  path: RouteNames.game{n}Start,
  builder: (context, state) => const Game{n}StartScreen(),
),
```

### 4. 開始画面を実装（`game{n}_start_screen.dart`）
- `GameDescriptionCard`でゲーム説明を表示
- `GameStartButton`でゲーム開始
- `BackButton`でゲーム一覧へ戻る

### 5. ゲームの色をテーマに追加（任意）
```dart
// app_theme.dart
static const Color game{n}Color = Color(0xFF...);
```

## セットアップ

```bash
# 依存パッケージをインストール
flutter pub get

# Webアプリとして実行
flutter run -d web

# iOS/Android実行時
flutter run
```

## Build & Deploy

### Web版
```bash
# ビルド
flutter build web

# 生成ファイルは `build/web/` に出力
```

## 開発ガイド

### デザイン統一
- `AppTheme`でテーマ管理
- `AppConstants`で定数管理
- `common_widgets.dart`で UI コンポーネント共有

### 状態管理の拡張
- 将来的に`Provider`を活用して状態管理を追加
- 各ゲームの`models/`に状態管理ロジックを配置

### 新機能の実装
- ゲーム画面は各ゲームの`screens/`に配置
- 共通画面は`screens/`に配置
- 共通配置のウィジェットは`widgets/`に配置

## TODO（実装予定項目）

- [ ] 各ゲームの実装（canvas/animation等）
- [ ] スコア管理・ランキング機能
- [ ] ユーザー認証
- [ ] Analytics 統合
- [ ] 魚介類データベース統合
- [ ] 複数言語対応

## ライセンス

[ライセンス情報をここに記入]

## 作成者

[作成者情報]
