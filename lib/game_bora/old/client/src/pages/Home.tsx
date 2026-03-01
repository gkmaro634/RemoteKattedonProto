import { useState, useEffect, useRef, useCallback } from 'react';
import { nanoid } from 'nanoid';
import { 
  Character, GamePhase, GameState, Supporter, Bora
} from '@/lib/gameTypes';
import {
  CHARACTERS, generateSupporter, generateBora, calculateNetSpeed,
  calculateBoraEscapeRate, calculateScore, getVirtueCost,
  updateBoraPosition, GAME_CONFIG, isBoraInNetArea, getMaxSupporters, getVirtueRegenRate
} from '@/lib/gameLogic';

// ============================================================
// タイトル画面
// ============================================================
function TitleScreen({ onStart }: { onStart: () => void }) {
  return (
    <div 
      className="min-h-screen flex flex-col items-center justify-center relative overflow-hidden"
      style={{
        backgroundImage: `url(https://d2xsxph8kpxj0f.cloudfront.net/310519663372121079/nhqYHEedyTcwPYWhGoJX9q/title-bg-UznSAvXzTz7zB6ttn7nYdM.webp)`,
        backgroundSize: 'cover',
        backgroundPosition: 'center',
      }}
    >
      <div className="absolute inset-0 bg-black/55" />
      
      <div className="relative z-10 text-center px-4 max-w-lg mx-auto">
        <div className="mb-8">
          <div 
            className="inline-block px-6 py-2 mb-5"
            style={{
              background: 'oklch(0.55 0.22 25 / 0.92)',
              border: '3px solid oklch(0.75 0.15 25)',
              boxShadow: '4px 4px 0 oklch(0.25 0.10 25)',
            }}
          >
            <p className="font-serif-jp text-sm text-white/95 tracking-widest">能登の伝統漁法ゲーム</p>
          </div>
          <h1 
            className="font-serif-jp font-black text-white leading-tight"
            style={{
              fontSize: 'clamp(3rem, 10vw, 5rem)',
              textShadow: '3px 3px 0 oklch(0.25 0.10 25), 6px 6px 0 oklch(0.15 0.05 25)',
              letterSpacing: '0.08em',
            }}
          >
            ボラ待ち<br/>やぐら
          </h1>
        </div>
        
        <div 
          className="mb-10 p-5"
          style={{
            background: 'oklch(0.12 0.04 240 / 0.88)',
            border: '2px solid oklch(0.40 0.08 240)',
            boxShadow: '4px 4px 0 oklch(0.08 0.03 240)',
          }}
        >
          <p className="font-serif-jp text-white/90 text-sm leading-relaxed">
            穴水湾に建てられたやぐらの上から<br/>
            ボラの群れを見張り、最適なタイミングで<br/>
            網を引き上げる伝統の漁を体験しよう
          </p>
          <div className="mt-3 pt-3 border-t border-white/20 text-white/60 text-xs font-serif-jp space-y-1">
            <p>🐟 ボラが網に入ったら網を引き上げよう</p>
            <p>🤝 応援を呼んで引き上げスピードアップ</p>
            <p>⏱️ 120秒以内にできるだけ多く捕ろう</p>
          </div>
        </div>
        
        <button
          onClick={onStart}
          className="btn-washi px-14 py-5 text-xl font-serif-jp rounded-none"
          style={{ letterSpacing: '0.15em' }}
        >
          ゲームを始める
        </button>
        
        <p className="mt-6 text-white/50 text-xs font-serif-jp">
          石川県穴水町の伝統漁法「ボラ待ちやぐら」をモチーフにしたゲームです
        </p>
      </div>
      
      {/* 波 */}
      <div className="absolute bottom-0 left-0 right-0 h-20 overflow-hidden">
        <svg viewBox="0 0 1200 80" className="w-full h-full" preserveAspectRatio="none">
          <path 
            d="M0,40 C150,70 300,10 450,40 C600,70 750,10 900,40 C1050,70 1150,20 1200,40 L1200,80 L0,80 Z" 
            fill="oklch(0.18 0.06 240 / 0.85)"
          />
        </svg>
      </div>
    </div>
  );
}

// ============================================================
// キャラクター選択画面
// ============================================================
function CharacterSelectScreen({ onSelect }: { onSelect: (char: Character) => void }) {
  const [selected, setSelected] = useState<string | null>(null);
  
  const statBar = (value: number, max: number = 5) => (
    <div className="flex gap-1">
      {Array.from({ length: max }).map((_, i) => (
        <div
          key={i}
          className="h-2.5 w-5 rounded-sm"
          style={{
            background: i < value 
              ? 'oklch(0.55 0.22 25)' 
              : 'oklch(0.22 0.05 240)',
            border: '1px solid oklch(0.32 0.07 240)',
          }}
        />
      ))}
    </div>
  );
  
  return (
    <div 
      className="min-h-screen flex flex-col items-center justify-center py-8 px-4"
      style={{ background: 'oklch(0.12 0.04 240)' }}
    >
      <div className="w-full max-w-4xl">
        <div className="text-center mb-8">
          <h2 
            className="font-serif-jp text-3xl md:text-4xl font-black text-white mb-2"
            style={{ textShadow: '2px 2px 0 oklch(0.25 0.10 25)', letterSpacing: '0.05em' }}
          >
            主人公を選ぶ
          </h2>
          <p className="text-white/55 font-serif-jp text-sm">
            それぞれの特技を活かして大漁を目指そう
          </p>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-5 mb-8">
          {Object.values(CHARACTERS).map((char) => (
            <button
              key={char.id}
              onClick={() => setSelected(char.id)}
              className="text-left transition-all duration-150"
              style={{
                background: selected === char.id 
                  ? 'oklch(0.22 0.08 240)' 
                  : 'oklch(0.17 0.05 240)',
                border: selected === char.id 
                  ? '3px solid oklch(0.55 0.22 25)' 
                  : '2px solid oklch(0.28 0.06 240)',
                boxShadow: selected === char.id 
                  ? '5px 5px 0 oklch(0.35 0.15 25 / 0.5), 0 0 20px oklch(0.55 0.22 25 / 0.25)' 
                  : '3px 3px 0 oklch(0.08 0.03 240)',
                padding: '1.5rem',
                transform: selected === char.id ? 'translate(-2px, -2px)' : 'none',
              }}
            >
              <div className="text-5xl mb-3 text-center">{char.emoji}</div>
              
              <h3 
                className="font-serif-jp text-xl font-bold text-white mb-2 text-center"
                style={{ letterSpacing: '0.05em' }}
              >
                {char.name}
              </h3>
              
              <p className="text-white/65 text-xs mb-4 leading-relaxed font-serif-jp">
                {char.description}
              </p>
              
              <div className="space-y-2">
                {[
                  { label: '引き上げ速度', value: char.stats.netSpeed },
                  { label: '視力', value: char.stats.visionRange },
                  { label: '人徳', value: char.stats.virtue },
                ].map(stat => (
                  <div key={stat.label} className="flex items-center justify-between">
                    <span className="text-white/55 text-xs font-serif-jp">{stat.label}</span>
                    {statBar(stat.value)}
                  </div>
                ))}
              </div>
              
              <div 
                className="mt-3 text-center text-xs font-serif-jp py-1"
                style={{ 
                  background: selected === char.id ? 'oklch(0.55 0.22 25)' : 'oklch(0.20 0.05 240)',
                  color: selected === char.id ? 'white' : 'oklch(0.50 0.05 240)',
                  border: selected === char.id ? 'none' : '1px solid oklch(0.28 0.06 240)',
                }}
              >
                {selected === char.id ? '✓ 選択中' : 'クリックして選択'}
              </div>
            </button>
          ))}
        </div>
        
        <div className="text-center">
          <button
            onClick={() => selected && onSelect(CHARACTERS[selected as keyof typeof CHARACTERS])}
            disabled={!selected}
            className="btn-washi px-14 py-4 text-xl font-serif-jp rounded-none disabled:opacity-40 disabled:cursor-not-allowed"
            style={{ letterSpacing: '0.1em' }}
          >
            この漁師で始める
          </button>
        </div>
      </div>
    </div>
  );
}

// ============================================================
// ゲームフィールド（SVGキャンバス）
// ============================================================
// レイアウト設計:
//   0% 〜 45%  : 空エリア（やぐら・岸・応援者・主人公が存在）
//   45%        : 水面ライン
//   45% 〜 100%: 海エリア（ボラ・定置網が存在）
function GameCanvas({ 
  state, 
  character 
}: { 
  state: GameState; 
  character: Character;
}) {
  // 水面ラインの位置（%）
  const WATER_LINE = 45;
  // 網の上端：水面直下から始まり、引き上げると水面に近づく
  // netProgress=0 → 水面+5% 〜 bottom=5%
  // netProgress=100 → 水面+1% （ほぼ水面まで上がる）
  const netTopBelowWater = WATER_LINE + 2 + (1 - state.netProgress / 100) * 35;
  
  return (
    <div className="relative w-full h-full overflow-hidden">
      {/* === 空（上半分） === */}
      <div 
        className="absolute left-0 right-0"
        style={{
          top: 0,
          height: `${WATER_LINE}%`,
          background: 'linear-gradient(180deg, oklch(0.62 0.10 215) 0%, oklch(0.52 0.10 220) 60%, oklch(0.45 0.10 225) 100%)',
        }}
      />
      
      {/* === 海（下半分） === */}
      <div 
        className="absolute left-0 right-0"
        style={{
          top: `${WATER_LINE}%`,
          bottom: 0,
          background: 'linear-gradient(180deg, oklch(0.38 0.12 225) 0%, oklch(0.28 0.10 235) 50%, oklch(0.20 0.08 245) 100%)',
        }}
      />
      
      {/* === 水面ライン === */}
      <div 
        className="absolute left-0 right-0"
        style={{
          top: `${WATER_LINE}%`,
          height: '4px',
          background: 'linear-gradient(90deg, oklch(0.60 0.10 200), oklch(0.78 0.08 205), oklch(0.60 0.10 200))',
          boxShadow: '0 3px 14px oklch(0.55 0.12 210 / 0.7)',
          zIndex: 10,
        }}
      />
      
      {/* 波紋（水面上） */}
      {[20, 38, 55, 72].map((x, i) => (
        <div
          key={i}
          className="absolute"
          style={{
            left: `${x}%`,
            top: `${WATER_LINE}%`,
            width: '60px',
            height: '12px',
            transform: 'translate(-50%, -50%)',
            border: '1.5px solid oklch(0.78 0.08 200 / 0.35)',
            borderRadius: '50%',
            animation: `wave ${2.5 + i * 0.4}s ease-in-out infinite`,
            animationDelay: `${i * 0.55}s`,
            zIndex: 11,
          }}
        />
      ))}
      

      
      {/* 応援者たち（水面より上の空エリアに浮かぶ） */}
      {state.supporters.map((supporter, i) => (
        <div
          key={supporter.id}
          className="absolute"
          style={{
            left: `${10 + i * 7}%`,
            top: `${WATER_LINE - 22}%`,
            zIndex: 12,
            animation: 'supporterRun 0.8s ease-out forwards',
          }}
        >
          <div className="text-center" style={{ fontSize: '20px', lineHeight: 1 }}>
            {supporter.emoji}
          </div>
          {/* 残り時間バー */}
          <div 
            style={{
              width: '22px',
              height: '3px',
              background: 'oklch(0.22 0.05 240)',
              border: '1px solid oklch(0.40 0.06 240)',
              marginTop: '2px',
            }}
          >
            <div
              style={{
                width: `${(supporter.timeLeft / supporter.duration) * 100}%`,
                height: '100%',
                background: supporter.timeLeft < 5 
                  ? 'oklch(0.55 0.22 25)' 
                  : 'oklch(0.55 0.18 145)',
                transition: 'width 0.3s linear',
              }}
            />
          </div>
        </div>
      ))}
      
      {/* === やぐら（右側・水面をまたいで建つ） === */}
      {/* やぐらは海中に樫が刺さり、上部が水面より上に出る構造 */}
      <div 
        className="absolute right-0"
        style={{
          width: '22%',
          top: `${WATER_LINE - 48}%`,
          height: '70%',
          zIndex: 8,
        }}
      >
        <svg viewBox="0 0 100 300" className="w-full h-full" preserveAspectRatio="xMidYMin meet">
          {/* 主人公（やぐら最上部） */}
          {/* 笠 */}
          <ellipse cx="50" cy="8" rx="18" ry="6" fill="oklch(0.58 0.08 70)" stroke="oklch(0.42 0.07 60)" strokeWidth="1.5"/>
          {/* 頭 */}
          <circle cx="50" cy="18" r="11" fill="oklch(0.68 0.10 60)" stroke="oklch(0.40 0.07 55)" strokeWidth="2"/>
          {/* 胴体 */}
          <line x1="50" y1="29" x2="50" y2="60" stroke="oklch(0.38 0.07 55)" strokeWidth="5" strokeLinecap="round"/>
          {/* 腕（見張りポーズ） */}
          <line x1="32" y1="40" x2="50" y2="36" stroke="oklch(0.38 0.07 55)" strokeWidth="4" strokeLinecap="round"/>
          <line x1="50" y1="36" x2="68" y2="40" stroke="oklch(0.38 0.07 55)" strokeWidth="4" strokeLinecap="round"/>
          {/* 脚 */}
          <line x1="50" y1="60" x2="38" y2="82" stroke="oklch(0.38 0.07 55)" strokeWidth="4" strokeLinecap="round"/>
          <line x1="50" y1="60" x2="62" y2="82" stroke="oklch(0.38 0.07 55)" strokeWidth="4" strokeLinecap="round"/>
          {/* やぐらの主柱（水面をまたぐ） */}
          <line x1="50" y1="82" x2="15" y2="300" stroke="oklch(0.42 0.07 55)" strokeWidth="7" strokeLinecap="round"/>
          <line x1="50" y1="82" x2="85" y2="300" stroke="oklch(0.42 0.07 55)" strokeWidth="7" strokeLinecap="round"/>
          {/* 横桟（上段） */}
          <line x1="22" y1="140" x2="78" y2="140" stroke="oklch(0.42 0.07 55)" strokeWidth="5" strokeLinecap="round"/>
          {/* 横桟（中段） */}
          <line x1="18" y1="195" x2="82" y2="195" stroke="oklch(0.42 0.07 55)" strokeWidth="5" strokeLinecap="round"/>
          {/* 斜め補強 */}
          <line x1="22" y1="140" x2="50" y2="195" stroke="oklch(0.38 0.06 55)" strokeWidth="3.5"/>
          <line x1="78" y1="140" x2="50" y2="195" stroke="oklch(0.38 0.06 55)" strokeWidth="3.5"/>
          {/* 水中の樫（薄く表示） */}
          <line x1="50" y1="195" x2="15" y2="300" stroke="oklch(0.42 0.07 55 / 0.4)" strokeWidth="5" strokeLinecap="round"/>
          <line x1="50" y1="195" x2="85" y2="300" stroke="oklch(0.42 0.07 55 / 0.4)" strokeWidth="5" strokeLinecap="round"/>
        </svg>
      </div>
      
      {/* === ロープ（やぐら→網） === */}
      <svg 
        className="absolute inset-0 w-full h-full pointer-events-none" 
        style={{ zIndex: 9 }}
        preserveAspectRatio="none"
        viewBox="0 0 100 100"
      >
        {/* やぐら頂点から網の左端へ */}
        <line 
          x1="88" y1={WATER_LINE - 38}
          x2="18" y2={netTopBelowWater}
          stroke="oklch(0.62 0.07 70)"
          strokeWidth="0.5"
          strokeDasharray={state.isRaising ? "2,1.5" : "none"}
        />
        {/* やぐら頂点から網の右端へ */}
        <line 
          x1="88" y1={WATER_LINE - 38}
          x2="82" y2={netTopBelowWater}
          stroke="oklch(0.62 0.07 70)"
          strokeWidth="0.5"
          strokeDasharray={state.isRaising ? "2,1.5" : "none"}
        />
      </svg>
      
      {/* === 定置網（水面より下） === */}
      <div
        className="absolute"
        style={{
          left: '18%',
          right: '18%',
          top: `${netTopBelowWater}%`,
          bottom: '5%',
          border: `2px solid oklch(0.68 0.06 75 / ${state.isRaising ? '1' : '0.7'})`,
          borderTop: `${state.isRaising ? '3' : '2'}px solid oklch(0.78 0.12 75 / 0.95)`,
          background: 'oklch(0.65 0.05 75 / 0.05)',
          transition: 'top 0.15s ease',
          zIndex: 5,
        }}
      >
        {/* 網の格子模様 */}
        <svg className="absolute inset-0 w-full h-full" preserveAspectRatio="none">
          <defs>
            <pattern id="netGrid" x="0" y="0" width="18" height="18" patternUnits="userSpaceOnUse">
              <path d="M0,0 L18,18 M18,0 L0,18" stroke="oklch(0.68 0.06 75 / 0.35)" strokeWidth="1"/>
            </pattern>
          </defs>
          <rect width="100%" height="100%" fill="url(#netGrid)"/>
        </svg>
        
        {/* 引き上げ中ラベル */}
        {state.isRaising && (
          <div className="absolute -top-7 left-1/2 transform -translate-x-1/2 whitespace-nowrap z-10">
            <span 
              className="font-serif-jp text-xs px-3 py-1 font-bold"
              style={{ 
                background: 'oklch(0.55 0.22 25)',
                color: 'white',
                boxShadow: '2px 2px 0 oklch(0.30 0.12 25)',
                letterSpacing: '0.05em',
              }}
            >
              ▲ 引き上げ中！
            </span>
          </div>
        )}
      </div>
      
      {/* === ボラたち（水中） === */}
      {state.boras.map((bora) => {
        const sizeMap = { small: 14, medium: 20, large: 28 };
        const sz = sizeMap[bora.size];
        // ボラのY座標は水面以下に収める（WATER_LINE + 余白 〜 95%）
        const boraY = WATER_LINE + 5 + bora.y * 0.48;
        const isInNet = bora.inNet && !bora.escaping;
        
        return (
          <div
            key={bora.id}
            className="absolute"
            style={{
              left: `${bora.x}%`,
              top: `${boraY}%`,
              transform: 'translate(-50%, -50%)',
              transition: 'left 0.25s ease, top 0.25s ease',
              zIndex: 4,
              opacity: bora.escaping ? 0.25 : isInNet ? 0.92 : 0.70,
            }}
          >
            <svg width={sz} height={sz * 0.42} viewBox="0 0 40 17">
              <ellipse cx="22" cy="8.5" rx="17" ry="7" 
                fill={isInNet ? 'oklch(0.80 0.10 215)' : 'oklch(0.55 0.08 230)'}
                stroke={isInNet ? 'oklch(0.62 0.12 215)' : 'oklch(0.42 0.08 235)'}
                strokeWidth="1.5"
              />
              <path d="M5,8.5 L0,3 L0,14 Z" 
                fill={isInNet ? 'oklch(0.74 0.10 215)' : 'oklch(0.48 0.08 230)'}
              />
              <circle cx="32" cy="7" r="1.5" fill="oklch(0.15 0.02 240)" />
            </svg>
          </div>
        );
      })}
      
      {/* === 網の中のボラ数バッジ === */}
      {state.boraCountInNet > 0 && (
        <div 
          className="absolute"
          style={{
            left: '50%',
            top: `${netTopBelowWater + 10}%`,
            transform: 'translate(-50%, -50%)',
            zIndex: 13,
          }}
        >
          <div 
            className="font-serif-jp text-white font-bold text-xs px-3 py-1.5"
            style={{
              background: 'oklch(0.25 0.10 240 / 0.92)',
              border: '2px solid oklch(0.48 0.12 220)',
              boxShadow: '2px 2px 0 oklch(0.12 0.05 240)',
              whiteSpace: 'nowrap',
            }}
          >
            🐟 網の中: {state.boraCountInNet}尾
            {state.boraCountInNet >= GAME_CONFIG.netRaiseThreshold && (
              <span style={{ color: 'oklch(0.80 0.18 80)', marginLeft: '6px' }}>← 引き上げ時！</span>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

// ============================================================
// UIパネル（下部コントロール）
// ============================================================
function UIPanel({
  state,
  character,
  onRaiseNet,
  onCallSupporter,
}: {
  state: GameState;
  character: Character;
  onRaiseNet: () => void;
  onCallSupporter: () => void;
}) {
  const maxSupporters = getMaxSupporters(character);
  const canCallSupporter = 
    state.virtueGauge >= getVirtueCost(character) && 
    state.supporters.length < maxSupporters &&
    !state.isRaising;
  
  const boraInNet = state.boraCountInNet;
  
  const virtueRatio = state.virtueGauge / state.maxVirtue;
  const virtueColor = virtueRatio > 0.6 
    ? 'oklch(0.55 0.18 145)' 
    : virtueRatio > 0.3 
      ? 'oklch(0.65 0.18 80)' 
      : 'oklch(0.55 0.22 25)';
  
  return (
    <div 
      className="flex-shrink-0"
      style={{
        background: 'oklch(0.14 0.04 240)',
        borderTop: '3px solid oklch(0.28 0.06 240)',
      }}
    >
      {/* ゲージ行 */}
      <div className="grid grid-cols-2 gap-3 px-3 pt-3 pb-2">
        <div>
          <div className="flex items-center justify-between mb-1">
            <span className="font-serif-jp text-xs text-white/65">🙏 人徳ゲージ</span>
            <span className="font-serif-jp text-xs text-white/65">
              {Math.floor(state.virtueGauge)}/{state.maxVirtue}
            </span>
          </div>
          <div className="gauge-bar">
            <div
              className="h-full transition-all duration-300"
              style={{
                width: `${virtueRatio * 100}%`,
                background: virtueColor,
                boxShadow: `0 0 5px ${virtueColor}`,
              }}
            />
          </div>
        </div>
        
        <div>
          <div className="flex items-center justify-between mb-1">
            <span className="font-serif-jp text-xs text-white/65">🎣 引き上げ進捗</span>
            <span className="font-serif-jp text-xs text-white/65">
              {Math.floor(state.netProgress)}%
            </span>
          </div>
          <div className="gauge-bar">
            <div
              className="h-full transition-all duration-100"
              style={{
                width: `${state.netProgress}%`,
                background: state.isRaising 
                  ? 'oklch(0.55 0.22 25)' 
                  : 'oklch(0.32 0.10 240)',
                boxShadow: state.isRaising ? '0 0 6px oklch(0.55 0.22 25)' : 'none',
              }}
            />
          </div>
        </div>
      </div>
      
      {/* スコア行 */}
      <div className="grid grid-cols-3 gap-2 px-3 pb-2">
        {[
          { icon: '🐟', label: '捕獲', value: state.caughtBoras, unit: '尾' },
          { icon: '🏆', label: 'スコア', value: state.score, unit: '' },
          { icon: '🤝', label: '応援中', value: state.supporters.length, unit: '人' },
        ].map(item => (
          <div 
            key={item.label}
            className="text-center py-1.5"
            style={{
              background: 'oklch(0.19 0.05 240)',
              border: '1px solid oklch(0.28 0.06 240)',
            }}
          >
            <div className="font-serif-jp text-xs text-white/55">{item.icon} {item.label}</div>
            <div className="font-serif-jp text-xl font-bold text-white">
              {item.value}<span className="text-xs text-white/60">{item.unit}</span>
            </div>
          </div>
        ))}
      </div>
      
      {/* ボタン行 */}
      <div className="grid grid-cols-2 gap-3 px-3 pb-3">
        <button
          onClick={onCallSupporter}
          disabled={!canCallSupporter}
          className="py-3 font-serif-jp text-sm font-bold rounded-none transition-all"
          style={{
            background: canCallSupporter 
              ? 'oklch(0.30 0.12 240)' 
              : 'oklch(0.20 0.04 240)',
            color: canCallSupporter ? 'white' : 'oklch(0.40 0.04 240)',
            border: canCallSupporter 
              ? '2px solid oklch(0.45 0.12 240)' 
              : '2px solid oklch(0.25 0.05 240)',
            boxShadow: canCallSupporter ? '3px 3px 0 oklch(0.15 0.07 240)' : 'none',
            letterSpacing: '0.05em',
          }}
        >
          🤝 応援を呼ぶ<br/>
          <span className="text-xs opacity-65">
            人徳 -{getVirtueCost(character)} / {state.supporters.length}/{maxSupporters}人
          </span>
        </button>
        
        <button
          onClick={onRaiseNet}
          disabled={state.isRaising}
          className="py-3 font-serif-jp text-sm font-bold rounded-none transition-all"
          style={{
            background: state.isRaising 
              ? 'oklch(0.32 0.12 25)' 
              : boraInNet >= GAME_CONFIG.netRaiseThreshold 
                ? 'oklch(0.55 0.22 25)' 
                : 'oklch(0.42 0.18 25)',
            color: 'white',
            border: state.isRaising 
              ? '2px solid oklch(0.25 0.10 25)' 
              : '2px solid oklch(0.45 0.18 25)',
            boxShadow: !state.isRaising ? '3px 3px 0 oklch(0.25 0.12 25)' : 'none',
            letterSpacing: '0.05em',
            animation: boraInNet >= GAME_CONFIG.netRaiseThreshold && !state.isRaising 
              ? 'pulse-glow 1.5s ease-in-out infinite' 
              : 'none',
          }}
        >
          🎣 網を引き上げる<br/>
          <span className="text-xs opacity-75">
            {state.isRaising ? '引き上げ中...' : `網の中 ${boraInNet}尾`}
          </span>
        </button>
      </div>
      
      {/* 応援者リスト */}
      {state.supporters.length > 0 && (
        <div 
          className="px-3 pb-2 flex gap-1.5 flex-wrap"
          style={{ borderTop: '1px solid oklch(0.22 0.05 240)', paddingTop: '6px' }}
        >
          {state.supporters.map((s) => (
            <div
              key={s.id}
              className="flex items-center gap-1 px-2 py-0.5 text-xs font-serif-jp"
              style={{
                background: 'oklch(0.20 0.06 240)',
                border: '1px solid oklch(0.32 0.08 240)',
                color: 'white',
              }}
            >
              <span>{s.emoji}</span>
              <span className="text-white/80">{s.name}</span>
              <span 
                style={{
                  color: s.timeLeft < 5 ? 'oklch(0.65 0.22 25)' : 'oklch(0.65 0.15 160)',
                  marginLeft: '2px',
                }}
              >
                {Math.ceil(s.timeLeft)}s
              </span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

// ============================================================
// 結果画面
// ============================================================
function ResultScreen({ 
  state, 
  character, 
  onRestart, 
  onBackToTitle 
}: { 
  state: GameState; 
  character: Character;
  onRestart: () => void;
  onBackToTitle: () => void;
}) {
  const rank = state.score >= 2000 ? { text: '大漁！', color: 'oklch(0.65 0.18 80)', msg: '素晴らしい！伝説の漁師だ！' }
    : state.score >= 1200 ? { text: '豊漁', color: 'oklch(0.55 0.18 145)', msg: '見事な腕前！' }
    : state.score >= 600 ? { text: '普通', color: 'oklch(0.55 0.12 220)', msg: 'まずまずの漁だ' }
    : { text: '不漁', color: 'oklch(0.55 0.22 25)', msg: '次はもっとうまくやれる！' };
  
  return (
    <div 
      className="min-h-screen flex flex-col items-center justify-center py-8 px-4"
      style={{ background: 'oklch(0.12 0.04 240)' }}
    >
      <div className="w-full max-w-md">
        <div 
          className="text-center p-6 mb-5"
          style={{
            background: 'oklch(0.17 0.05 240)',
            border: '3px solid oklch(0.32 0.08 240)',
            boxShadow: '6px 6px 0 oklch(0.08 0.03 240)',
          }}
        >
          <div 
            className="font-serif-jp text-6xl font-black mb-1"
            style={{ color: rank.color, textShadow: `2px 2px 0 oklch(0.12 0.03 240)` }}
          >
            {rank.text}
          </div>
          <div className="font-serif-jp text-white/70 text-sm mb-1">{rank.msg}</div>
          <div className="font-serif-jp text-white/50 text-xs">
            {character.emoji} {character.name}での漁の記録
          </div>
        </div>
        
        <div 
          className="p-5 mb-5"
          style={{
            background: 'oklch(0.17 0.05 240)',
            border: '2px solid oklch(0.28 0.06 240)',
            boxShadow: '4px 4px 0 oklch(0.08 0.03 240)',
          }}
        >
          <h3 className="font-serif-jp text-white font-bold mb-4 text-center pb-2" style={{ borderBottom: '1px solid oklch(0.28 0.06 240)' }}>
            漁の記録
          </h3>
          <div className="space-y-2.5">
            {[
              { label: '捕れたボラ', value: `${state.caughtBoras}尾`, icon: '🐟' },
              { label: '逃げたボラ', value: `${state.escapedBoras}尾`, icon: '💨' },
              { label: '漁の時間', value: `${Math.floor(state.gameTime)}秒`, icon: '⏱️' },
              { label: '最終スコア', value: `${state.score}点`, icon: '🏆', highlight: true },
            ].map((item) => (
              <div 
                key={item.label}
                className="flex items-center justify-between py-2 px-3"
                style={{
                  background: item.highlight ? 'oklch(0.22 0.08 240)' : 'transparent',
                  border: item.highlight ? '1px solid oklch(0.38 0.10 240)' : 'none',
                }}
              >
                <span className="font-serif-jp text-white/65 text-sm">
                  {item.icon} {item.label}
                </span>
                <span 
                  className="font-serif-jp font-bold"
                  style={{ 
                    color: item.highlight ? 'oklch(0.75 0.15 80)' : 'white',
                    fontSize: item.highlight ? '1.3rem' : '1rem',
                  }}
                >
                  {item.value}
                </span>
              </div>
            ))}
          </div>
        </div>
        
        <div className="grid grid-cols-2 gap-4">
          <button
            onClick={onRestart}
            className="btn-washi py-4 font-serif-jp font-bold rounded-none"
            style={{ letterSpacing: '0.08em' }}
          >
            もう一度<br/>
            <span className="text-xs opacity-75">同じ漁師で</span>
          </button>
          <button
            onClick={onBackToTitle}
            className="btn-indigo py-4 font-serif-jp font-bold rounded-none"
            style={{ letterSpacing: '0.08em' }}
          >
            タイトルへ<br/>
            <span className="text-xs opacity-75">漁師を変える</span>
          </button>
        </div>
      </div>
    </div>
  );
}

// ============================================================
// メインゲームコンポーネント
// ============================================================
export default function Home() {
  const [phase, setPhase] = useState<GamePhase>('title');
  const [character, setCharacter] = useState<Character | null>(null);
  const [gameState, setGameState] = useState<GameState | null>(null);
  const gameLoopRef = useRef<number | null>(null);
  const lastTimeRef = useRef<number>(0);
  const pendingSupportersRef = useRef<{ supporter: Supporter; arrivalTime: number }[]>([]);
  const boraSpawnTimerRef = useRef(0);
  const boraDecreaseTimerRef = useRef(0);
  const virtueRegenTimerRef = useRef(0);
  
  const initGame = useCallback((char: Character) => {
    const initialBoras: Bora[] = Array.from({ length: GAME_CONFIG.initialBoraCount }, () => generateBora());
    setGameState({
      phase: 'waiting',
      character: char,
      boras: initialBoras,
      supporters: [],
      virtueGauge: char.maxVirtue,
      maxVirtue: char.maxVirtue,
      netProgress: 0,
      isRaising: false,
      caughtBoras: 0,
      escapedBoras: 0,
      score: 0,
      gameTime: 0,
      netSpeed: char.stats.netSpeed * 2,
      boraCountInNet: 0,
    });
    pendingSupportersRef.current = [];
    boraSpawnTimerRef.current = 0;
    boraDecreaseTimerRef.current = 0;
    virtueRegenTimerRef.current = 0;
  }, []);
  
  const handleCharacterSelect = useCallback((char: Character) => {
    setCharacter(char);
    initGame(char);
    setPhase('waiting');
  }, [initGame]);
  
  const handleCallSupporter = useCallback(() => {
    if (!character || !gameState) return;
    const cost = getVirtueCost(character);
    if (gameState.virtueGauge < cost) return;
    if (gameState.supporters.length >= getMaxSupporters(character)) return;
    if (gameState.isRaising) return;
    
    const supporter = generateSupporter(character);
    const arrivalTime = Date.now() + GAME_CONFIG.supporterArrivalDelay * 1000;
    pendingSupportersRef.current.push({ supporter, arrivalTime });
    
    setGameState(prev => prev ? {
      ...prev,
      virtueGauge: Math.max(0, prev.virtueGauge - cost),
    } : prev);
  }, [character, gameState]);
  
  const handleRaiseNet = useCallback(() => {
    setGameState(prev => {
      if (!prev || prev.isRaising) return prev;
      return { ...prev, isRaising: true };
    });
  }, []);
  
  // ゲームループ
  useEffect(() => {
    if (phase !== 'waiting' || !character) return;
    
    const gameLoop = (timestamp: number) => {
      if (lastTimeRef.current === 0) lastTimeRef.current = timestamp;
      const deltaTime = Math.min((timestamp - lastTimeRef.current) / 1000, 0.1);
      lastTimeRef.current = timestamp;
      
      const now = Date.now();
      
      boraSpawnTimerRef.current += deltaTime;
      boraDecreaseTimerRef.current += deltaTime;
      virtueRegenTimerRef.current += deltaTime;
      
      // 応援者の到着チェック
      const arrivedSupporters = pendingSupportersRef.current.filter(p => p.arrivalTime <= now);
      pendingSupportersRef.current = pendingSupportersRef.current.filter(p => p.arrivalTime > now);
      
      setGameState(prev => {
        if (!prev || prev.phase === 'result') return prev;
        
        let newState = { ...prev };
        newState.gameTime += deltaTime;
        
        // 応援者の到着
        if (arrivedSupporters.length > 0) {
          newState.supporters = [...newState.supporters, ...arrivedSupporters.map(p => p.supporter)];
        }
        
        // 応援者のタイムアウト（引き上げ中はタイマーを止める）
        if (!newState.isRaising) {
          newState.supporters = newState.supporters
            .map(s => ({ ...s, timeLeft: s.timeLeft - deltaTime }))
            .filter(s => s.timeLeft > 0);
        }
        
        // 網の引き上げ速度計算
        const netSpeed = calculateNetSpeed(character, newState.supporters);
        newState.netSpeed = netSpeed;
        
        // 人徳ゲージの自然回復（視力型は2倍速い）
        const regenRate = character ? getVirtueRegenRate(character) : 1;
        if (virtueRegenTimerRef.current >= 2) {
          virtueRegenTimerRef.current = 0;
          newState.virtueGauge = Math.min(newState.maxVirtue, newState.virtueGauge + regenRate);
        }
        
        // ボラの移動（引き上げ中は新たに網に入れないよう isRaising を渡す）
        newState.boras = newState.boras.map(bora => updateBoraPosition(bora, deltaTime, newState.isRaising));
        
        if (newState.isRaising) {
          // 網の引き上げ中
          newState.netProgress = Math.min(100, newState.netProgress + netSpeed * deltaTime);
          
          // 引き上げ中にボラが逃げる（視力型は逃げ率大幅低減）
          const escapeRate = calculateBoraEscapeRate(netSpeed, character ?? undefined);
          const escapeChance = escapeRate * deltaTime * 0.25;
          
          let escapedCount = 0;
          newState.boras = newState.boras.map(bora => {
            if (bora.inNet && !bora.escaping && Math.random() < escapeChance) {
              escapedCount++;
              return { ...bora, escaping: true, direction: Math.random() * 360 };
            }
            return bora;
          });
          newState.escapedBoras += escapedCount;
          
          // 画面外に出た逃げたボラを除去
          newState.boras = newState.boras.filter(b => {
            if (b.escaping && (b.x < -5 || b.x > 105 || b.y < 15 || b.y > 100)) {
              return false;
            }
            return true;
          });
          
          // 引き上げ完了
          if (newState.netProgress >= 100) {
            const caught = newState.boras.filter(b => b.inNet && !b.escaping).length;
            newState.caughtBoras += caught;
            newState.boras = newState.boras.filter(b => !b.inNet);
            newState.score = calculateScore(newState.caughtBoras, newState.gameTime, newState.supporters);
            newState.netProgress = 0;
            newState.isRaising = false;
          }
        } else {
          // 待機中：ボラの自然増減
          if (boraSpawnTimerRef.current >= GAME_CONFIG.boraSpawnInterval) {
            boraSpawnTimerRef.current = 0;
            if (newState.boras.length < GAME_CONFIG.maxBoraCount) {
              const count = Math.min(GAME_CONFIG.boraSpawnCount, GAME_CONFIG.maxBoraCount - newState.boras.length);
              const newBoras = Array.from({ length: count }, () => generateBora());
              newState.boras = [...newState.boras, ...newBoras];
            }
          }
          
          if (boraDecreaseTimerRef.current >= GAME_CONFIG.boraDecreaseInterval) {
            boraDecreaseTimerRef.current = 0;
            if (newState.boras.length > GAME_CONFIG.minBoraCount) {
              const idx = Math.floor(Math.random() * newState.boras.length);
              newState.boras = newState.boras.filter((_, i) => i !== idx);
              newState.escapedBoras++;
            }
          }
        }
        
        // 網の中のボラ数更新
        newState.boraCountInNet = newState.boras.filter(b => b.inNet && !b.escaping).length;
        
        // ゲーム終了（120秒）
        if (newState.gameTime >= 120) {
          return { ...newState, phase: 'result' };
        }
        
        return newState;
      });
      
      gameLoopRef.current = requestAnimationFrame(gameLoop);
    };
    
    lastTimeRef.current = 0;
    gameLoopRef.current = requestAnimationFrame(gameLoop);
    
    return () => {
      if (gameLoopRef.current) {
        cancelAnimationFrame(gameLoopRef.current);
        gameLoopRef.current = null;
      }
    };
  }, [phase, character]);
  
  // フェーズ変更監視
  useEffect(() => {
    if (gameState?.phase === 'result' && phase === 'waiting') {
      if (gameLoopRef.current) {
        cancelAnimationFrame(gameLoopRef.current);
        gameLoopRef.current = null;
      }
      setPhase('result');
    }
  }, [gameState?.phase, phase]);
  
  const handleRestart = useCallback(() => {
    if (character) {
      if (gameLoopRef.current) {
        cancelAnimationFrame(gameLoopRef.current);
        gameLoopRef.current = null;
      }
      lastTimeRef.current = 0;
      initGame(character);
      setPhase('waiting');
    }
  }, [character, initGame]);
  
  const handleBackToTitle = useCallback(() => {
    if (gameLoopRef.current) {
      cancelAnimationFrame(gameLoopRef.current);
      gameLoopRef.current = null;
    }
    setPhase('title');
    setCharacter(null);
    setGameState(null);
  }, []);
  
  // ゲーム中のヘッダー
  const GameHeader = () => (
    <div 
      className="flex items-center justify-between px-4 py-2 flex-shrink-0"
      style={{
        background: 'oklch(0.14 0.05 240)',
        borderBottom: '2px solid oklch(0.28 0.06 240)',
      }}
    >
      <div className="flex items-center gap-2">
        <span className="font-serif-jp text-white font-bold text-sm tracking-wider">ボラ待ちやぐら</span>
        {character && (
          <span 
            className="font-serif-jp text-xs px-2 py-0.5"
            style={{
              background: 'oklch(0.22 0.06 240)',
              border: '1px solid oklch(0.32 0.08 240)',
              color: 'white',
            }}
          >
            {character.emoji} {character.name}
          </span>
        )}
      </div>
      {gameState && (
        <div className="flex items-center gap-3">
          <div 
            className="font-serif-jp text-sm font-bold px-3 py-0.5"
            style={{
              background: gameState.gameTime > 100 ? 'oklch(0.45 0.18 25 / 0.8)' : 'oklch(0.20 0.05 240)',
              color: gameState.gameTime > 100 ? 'white' : 'oklch(0.65 0.05 240)',
              border: '1px solid oklch(0.30 0.06 240)',
            }}
          >
            ⏱ {Math.max(0, 120 - Math.floor(gameState.gameTime))}秒
          </div>
          <button
            onClick={handleBackToTitle}
            className="font-serif-jp text-xs text-white/35 hover:text-white/65 transition-colors"
          >
            終了
          </button>
        </div>
      )}
    </div>
  );
  
  return (
    <div className="min-h-screen flex flex-col" style={{ background: 'oklch(0.12 0.04 240)' }}>
      {phase === 'title' && <TitleScreen onStart={() => setPhase('character')} />}
      
      {phase === 'character' && (
        <CharacterSelectScreen onSelect={handleCharacterSelect} />
      )}
      
      {phase === 'waiting' && gameState && character && (
        <div className="flex flex-col" style={{ height: '100dvh' }}>
          <GameHeader />
          <div className="flex-1 overflow-hidden">
            <GameCanvas state={gameState} character={character} />
          </div>
          <UIPanel
            state={gameState}
            character={character}
            onRaiseNet={handleRaiseNet}
            onCallSupporter={handleCallSupporter}
          />
        </div>
      )}
      
      {phase === 'result' && gameState && character && (
        <ResultScreen
          state={gameState}
          character={character}
          onRestart={handleRestart}
          onBackToTitle={handleBackToTitle}
        />
      )}
    </div>
  );
}
