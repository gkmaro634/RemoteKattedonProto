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
├── game_deshelling_crab/              # 蟹解体ゲーム (deshellingCrab)
│   ├── screens/
│   │   ├── deshellingcrab_start_screen.dart # ゲーム開始画面
│   │   └── presentation/screens/game_screen.dart # ゲーム実行画面
│   ├── models/
│   │   └── models.dart                # ゲーム状態管理
│   └── presentation/
│       └── providers/
│           └── game_notifier.dart     # Riverpod状態管理
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

## 石川釣りゲームのオープンデータ（実API）設定

石川釣りゲームは、`flutter run` だけでデフォルトAPIへ自動接続します。  
API取得に失敗した場合は `assets/data/ishikawa_fishing_open_data.json` に自動フォールバックします。

デフォルト接続先（石川県公式オープンデータCSV）：

```text
https://ckan.opendata.pref.ishikawa.lg.jp/dataset/b9e71183-5d58-4aa3-8a52-6c436993fa2e/resource/3a8105cc-4b7e-40b5-aa99-ca614d0fa32f/download/catch_amount_type.csv
```

`ISHIKAWA_OPEN_DATA_URL` を指定すると、接続先を上書きできます。

```bash
# 実APIを使って起動（Web）
flutter run -d web --dart-define=ISHIKAWA_OPEN_DATA_URL=https://example.com/ishikawa/fishing.json

# モバイル/デスクトップでも同様
flutter run --dart-define=ISHIKAWA_OPEN_DATA_URL=https://example.com/ishikawa/fishing.json
```

### APIで受け付けるJSON形式

1. 直接形式（推奨）
```json
{
  "datasetName": "...",
  "source": "...",
  "observedMonth": "2026-02",
  "spots": [
    {
      "spotId": "noto_north",
      "totalCatchKg": 1240,
      "fishCatchKg": { "のどぐろ": 320, "メバル": 290 }
    }
  ]
}
```

2. `result.records` 形式（CKAN互換）
- レコード内のキーは `spotId / spot_id`, `totalCatchKg / total_catch_kg`, `fishCatchKg / fish_catch_kg` をサポート

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
