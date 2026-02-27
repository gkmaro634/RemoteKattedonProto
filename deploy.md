# 🚀 Webデプロイ手順（Flutter + Firebase Hosting）

本プロジェクトは Flutter Web を Firebase Hosting にデプロイして公開します。

---
## 1. 前提条件

以下がインストール済みであること。

- Flutter SDK
- Node.js
- Firebase CLI
- Git

確認コマンド：

```bash
flutter --version
firebase --version
```

## 2. 初回セットアップ（各メンバー1回のみ）
### Firebaseログイン

```bash
firebase login
```

### Webサポート有効化（未実施の場合）

```bash
flutter config --enable-web
```

## 3. ローカル動作確認

```bash
flutter run -d chrome
```
ブラウザでアプリが起動することを確認。

## 4. Webビルド

```bash
flutter build web
```

生成物：
`build/web/`

## 5. Firebaseへデプロイ
```bash
firebase deploy
```

成功するといかが表示される：

```
Hosting URL: https://xxxxx.we.app
```

# Makefileを使う場合
以下コマンドでビルド＋デプロイを同時実行：

```bash
make release
```

以下コマンドでホスティングされたWebアプリを表示：

```bash
make open
```
