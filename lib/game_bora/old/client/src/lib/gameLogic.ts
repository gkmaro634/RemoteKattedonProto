// ボラ待ちやぐらゲーム - ゲームロジック

import { Character, CharacterType, Supporter, Bora } from './gameTypes';
import { nanoid } from 'nanoid';

// キャラクター定義
export const CHARACTERS: Record<CharacterType, Character> = {
  power: {
    id: 'power',
    name: 'パワー型',
    description: '力強い漁師。網の引き上げがたいへん速く、少ない応援でも短時間で引き上げられる。ボラが逃げる前に網を上げきる力務め漁師。',
    stats: {
      netSpeed: 8,
      visionRange: 2,
      virtue: 2,
    },
    maxVirtue: 60,
    emoji: '💪',
  },
  vision: {
    id: 'vision',
    name: '視力型',
    description: '鮮い目を持つ漁師。引き上げ中にボラが逃げにくく、人徳ゲージの回復が速い。網の速度は遅いが、ボラを逃さない目で大漁を目指す。',
    stats: {
      netSpeed: 2,
      visionRange: 5,
      virtue: 2,
    },
    maxVirtue: 60,
    emoji: '👁️',
  },
  virtue: {
    id: 'virtue',
    name: '人徳型',
    description: '村で慕われる漁師。応援を呼ぶコストが安く、最大8人まで呼べる。名人や力持ちなど頑鯊な助っ人が集まりやすい。',
    stats: {
      netSpeed: 3,
      visionRange: 3,
      virtue: 5,
    },
    maxVirtue: 60,
    emoji: '🤝',
  },
};

// 応援者プール
const SUPPORTER_POOL = [
  { name: '隣の田中さん', speedBonus: 1.5, duration: 15, quality: 'poor' as const, emoji: '👴' },
  { name: '漁協の山田さん', speedBonus: 3.0, duration: 20, quality: 'normal' as const, emoji: '🧑' },
  { name: '元漁師の鈴木さん', speedBonus: 4.5, duration: 25, quality: 'good' as const, emoji: '👨‍🦳' },
  { name: '若い衆の佐藤くん', speedBonus: 2.5, duration: 18, quality: 'normal' as const, emoji: '👦' },
  { name: '力持ちの熊田さん', speedBonus: 6.0, duration: 12, quality: 'good' as const, emoji: '💪' },
  { name: '漁師の名人・能登太郎', speedBonus: 9.0, duration: 30, quality: 'excellent' as const, emoji: '🏆' },
  { name: '村長の奈さん', speedBonus: 3.5, duration: 22, quality: 'normal' as const, emoji: '👩' },
  { name: '子供たち', speedBonus: 1.0, duration: 10, quality: 'poor' as const, emoji: '👧' },
];

// 応援者を生成する（キャラクターの人徳に応じてガチャ）
export function generateSupporter(character: Character): Supporter {
  const virtue = character.stats.virtue;
  
  // 人徳が高いほど良い応援者が来やすい
  // virtue=5（人徳型）: 名人・力持ちなど強力な応援が集まりやすい
  let weights: number[];
  if (virtue >= 5) {
    // 人徳型: 名人・力持ちの確率大幅アップ
    weights = [0.02, 0.08, 0.20, 0.10, 0.25, 0.28, 0.05, 0.02];
  } else if (virtue >= 4) {
    weights = [0.10, 0.20, 0.25, 0.20, 0.15, 0.05, 0.03, 0.02];
  } else if (virtue >= 3) {
    weights = [0.15, 0.25, 0.20, 0.20, 0.12, 0.02, 0.04, 0.02];
  } else {
    weights = [0.25, 0.30, 0.15, 0.15, 0.10, 0.01, 0.02, 0.02];
  }
  
  const rand = Math.random();
  let cumulative = 0;
  let selectedIndex = 0;
  for (let i = 0; i < weights.length; i++) {
    cumulative += weights[i];
    if (rand < cumulative) {
      selectedIndex = i;
      break;
    }
  }
  
  const template = SUPPORTER_POOL[selectedIndex];
  return {
    id: nanoid(),
    ...template,
    timeLeft: template.duration,
  };
}

// ボラを生成する
export function generateBora(): Bora {
  const sizes = ['small', 'medium', 'large'] as const;
  const size = sizes[Math.floor(Math.random() * sizes.length)];
  
  return {
    id: nanoid(),
    x: Math.random() * 80 + 10, // 10-90%
    y: Math.random() * 60 + 20, // 20-80%（海の中）
    size,
    speed: Math.random() * 0.5 + 0.2,
    direction: Math.random() * 360,
    inNet: false,
    escaping: false,
  };
}

// ボラが網の中にいるかチェック（網の領域: x=20-80%, y=40-90%）
export function isBoraInNetArea(bora: Bora): boolean {
  return bora.x >= 20 && bora.x <= 80 && bora.y >= 35 && bora.y <= 90;
}

// 網の引き上げ速度を計算する
export function calculateNetSpeed(character: Character, supporters: Supporter[]): number {
  const baseSpeed = character.stats.netSpeed * 2; // 基本速度（%/秒）
  const supportBonus = supporters.reduce((sum, s) => sum + s.speedBonus, 0);
  // 人数に応じた乗算ボーナス（1人ごとに+20%増加）
  const countMultiplier = 1 + supporters.length * 0.2;
  return (baseSpeed + supportBonus) * countMultiplier;
}

// ボラが逃げる速度（網の引き上げ中に減少するボラの数/秒）
// 視力型はボラの動きを予測して逃げを最小限に抑える
export function calculateBoraEscapeRate(netSpeed: number, character?: Character): number {
  // 速度が遅いほど多くのボラが逃げる
  const baseEscapeRate = 0.5;
  const speedFactor = Math.max(0, 1 - netSpeed / 20);
  const rawRate = baseEscapeRate + speedFactor * 0.5;
  // 視力型は逃げ率を大幅低減（70%削減）
  if (character?.id === 'vision') return rawRate * 0.3;
  return rawRate;
}

// スコアを計算する
export function calculateScore(caughtBoras: number, gameTime: number, supporters: Supporter[]): number {
  const baseScore = caughtBoras * 100;
  const timeBonus = Math.max(0, 300 - gameTime) * 2;
  const supporterBonus = supporters.length * 50;
  return baseScore + timeBonus + supporterBonus;
}

// 人徳ゲージのコスト（応援を呼ぶたびに消費）
// 人徳型は安いコストで多く呼べるのが優位性
export function getVirtueCost(character: Character): number {
  if (character.id === 'virtue') return 8;  // 人徳型: 安コスト
  return 12; // パワー型・視力型: 標準コスト
}

// ボラの移動を更新する
// isRaising=true のとき、網の外にいるボラは inNet を更新しない（引き上げ中は新たに入れない）
export function updateBoraPosition(bora: Bora, deltaTime: number, isRaising = false): Bora {
  if (bora.escaping) {
    return {
      ...bora,
      x: bora.x + bora.speed * 3 * Math.cos(bora.direction * Math.PI / 180) * deltaTime,
      y: bora.y + bora.speed * 3 * Math.sin(bora.direction * Math.PI / 180) * deltaTime,
    };
  }
  
  // ランダムに方向を変える
  const newDirection = bora.direction + (Math.random() - 0.5) * 30;
  let newX = bora.x + bora.speed * Math.cos(newDirection * Math.PI / 180) * deltaTime * 10;
  let newY = bora.y + bora.speed * Math.sin(newDirection * Math.PI / 180) * deltaTime * 10;
  
  // 境界チェック（海の範囲内に収める）
  newX = Math.max(5, Math.min(95, newX));
  newY = Math.max(30, Math.min(90, newY));
  
  // 引き上げ中は、まだ網に入っていないボラが新たに入れないようにする
  const newInNet = isRaising && !bora.inNet
    ? false
    : isBoraInNetArea({ ...bora, x: newX, y: newY });
  
  return {
    ...bora,
    x: newX,
    y: newY,
    direction: newDirection,
    inNet: newInNet,
  };
}

// ゲームの難易度設定
export const GAME_CONFIG = {
  initialBoraCount: 8,
  maxBoraCount: 20,
  minBoraCount: 3,
  boraSpawnInterval: 3,    // 秒ごとにボラが増える
  boraSpawnCount: 2,       // 一度に増えるボラの数
  boraDecreaseInterval: 5, // 秒ごとにボラが減る（自然に逃げる）
  netRaiseThreshold: 5,    // 網の中にこの数以上のボラがいると引き上げ推奨
  supporterArrivalDelay: 3, // 応援が来るまでの遅延（秒）
  maxSupporters: 5,        // パワー型・視力型の応援最大数
  maxSupportersVirtue: 8,  // 人徳型の応援最大数（優位性）
};

// キャラクターに応じた応援最大数を返す
export function getMaxSupporters(character: Character): number {
  return character.id === 'virtue' ? GAME_CONFIG.maxSupportersVirtue : GAME_CONFIG.maxSupporters;
}

// 人徳ゲージの自然回復速度を返す（視力型は2倍速い）
export function getVirtueRegenRate(character: Character): number {
  if (character.id === 'vision') return 2; // 視力型: 2秒ごと1回復
  return 1; // その他: 標準回復
}
