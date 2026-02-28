// ボラ待ちやぐらゲーム - 型定義

export type CharacterType = 'power' | 'vision' | 'virtue';

export interface Character {
  id: CharacterType;
  name: string;
  description: string;
  stats: {
    netSpeed: number;       // 網の引き上げ速度 (1-5)
    visionRange: number;    // ボラ視認範囲 (1-5)
    virtue: number;         // 人徳（呼べる応援の数・質） (1-5)
  };
  maxVirtue: number;        // 人徳ゲージ最大値
  emoji: string;
}

export interface Supporter {
  id: string;
  name: string;
  speedBonus: number;       // 引き上げスピード増加量
  duration: number;         // 応援継続時間（秒）
  timeLeft: number;         // 残り時間
  quality: 'poor' | 'normal' | 'good' | 'excellent';
  emoji: string;
}

export interface Bora {
  id: string;
  x: number;               // 位置 (0-100%)
  y: number;               // 深さ (0-100%)
  size: 'small' | 'medium' | 'large';
  speed: number;           // 移動速度
  direction: number;       // 移動方向 (角度)
  inNet: boolean;          // 網の中にいるか
  escaping: boolean;       // 逃げているか
}

export type GamePhase = 
  | 'title'           // タイトル画面
  | 'character'       // キャラクター選択
  | 'waiting'         // ボラを待つ（メインゲーム）
  | 'raising'         // 網を引き上げ中
  | 'result';         // 結果画面

export interface GameState {
  phase: GamePhase;
  character: Character | null;
  boras: Bora[];
  supporters: Supporter[];
  virtueGauge: number;       // 現在の人徳ゲージ
  maxVirtue: number;         // 最大人徳ゲージ
  netProgress: number;       // 網の引き上げ進捗 (0-100)
  isRaising: boolean;        // 網を引き上げ中か
  caughtBoras: number;       // 捕れたボラの数
  escapedBoras: number;      // 逃げたボラの数
  score: number;             // スコア
  gameTime: number;          // ゲーム経過時間（秒）
  netSpeed: number;          // 現在の網引き上げ速度
  boraCountInNet: number;    // 網の中のボラ数
}
