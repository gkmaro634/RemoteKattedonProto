# SECURITY

## セキュリティ方針

本プロジェクト（Remote Kattedon Prototype）は、Flutter Web アプリケーションを Firebase Hosting 上で公開する静的 Web アプリとして構築されています。

本プロトタイプではサーバサイド処理やユーザーデータ保存機能を持たない構成を採用し、攻撃対象面（Attack Surface）を最小化する設計としています。

加えて、ブラウザレベルでの一般的なWeb攻撃を防止するため、HTTPセキュリティヘッダを設定しています。

---

## 採用アーキテクチャ
Flutter Web (SPA)  
↓  
Firebase Hosting (HTTPS + CDN)  
↓  
Client Browser  

### 特徴

- 静的コンテンツ配信のみ（HTML / JS / Assets）
- サーバサイド実行環境なし
- データベース未使用
- HTTPS 強制通信（Firebase Hosting 標準）

この構成により以下を回避しています：

- サーバ侵入
- SQL Injection
- 認証情報漏洩
- 任意コード実行

---

## 実装済みセキュリティ対策

Firebase Hosting の `firebase.json` にて以下のセキュリティヘッダを設定しています。

### 1. X-Content-Type-Options: nosniff

#### 目的
ブラウザによる MIME タイプ推測（MIME Sniffing）を防止します。

#### 効果
- 宣言された Content-Type 以外としての実行を禁止
- 悪意あるスクリプトの誤実行を防止

---

### 2. X-Frame-Options: SAMEORIGIN

#### 目的
クリックジャッキング攻撃を防止します。

#### 効果
- 外部サイトから iframe 埋め込みを禁止
- UI 操作の不正誘導を防止

---

### 3. X-XSS-Protection: 1; mode=block

#### 目的
古典的なクロスサイトスクリプティング（XSS）攻撃への追加防御。

#### 効果
- ブラウザのXSS検知機能を有効化
- 不審なスクリプト検出時にページ表示をブロック

※ 一部最新ブラウザでは非推奨扱いですが、後方互換目的で設定しています。

---

### 4. Referrer-Policy: strict-origin-when-cross-origin

#### 目的
外部サイト遷移時の情報漏洩を防止。

#### 効果
- 同一サイト内では完全URLを送信
- 外部サイトにはドメイン情報のみ送信
- HTTPS → HTTP 遷移時は Referer を送信しない

---

## HTTPS / CDN 保護

Firebase Hosting により以下が自動的に提供されます。

- HTTPS 強制通信
- Google CDN 配信
- 基本的な DDoS 耐性
- TLS 証明書自動管理

---

## 現時点で未対象の範囲（プロトタイプ制約）

本プロトタイプでは以下は対象外です。

- ユーザー認証
- 決済機能
- 個人情報の保存
- サーバサイドAPI

そのため、認証・権限管理に関する脅威は存在しません。

---

## 将来的なセキュリティ拡張計画

将来機能拡張時には以下を検討します。

- API キーの Cloud Functions 経由化
- Content Security Policy (CSP) 導入
- 認証基盤（Firebase Authentication）
- API Rate Limiting
- アクセスログ監視

---
