import pygame
import sys
import random
import os

# --- 設定 ---
SCREEN_WIDTH = 450
SCREEN_HEIGHT = 600
GENGE_IMAGE_PATH = "genge.png"
BG_IMAGE_PATH = "umi.jpg"
SOUND_PATH = "pochi.mp3"
SOUND_MASTER = "hakushu.mp3"
SOUND_NORMAL = "koto.mp3"
SOUND_ZERO = "gaan.mp3"
SAVE_FILE = "highscore.txt"  # ハイスコア保存用ファイル
TIMER_LIMIT = 15

# --- 初期化 ---
pygame.init()
pygame.mixer.init()
screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
pygame.display.set_caption("ぷるぷるゲンゲ")
clock = pygame.time.Clock()

font = pygame.font.SysFont("meiryo", 30)
font_large = pygame.font.SysFont("meiryo", 45, bold=True)
font_small = pygame.font.SysFont("meiryo", 22, bold=True)


# --- ハイスコア読み書き関数 ---
def load_highscore():
    if os.path.exists(SAVE_FILE):
        try:
            with open(SAVE_FILE, "r") as f:
                return int(f.read())
        except:
            return 0
    return 0


def save_highscore(s):
    try:
        with open(SAVE_FILE, "w") as f:
            f.write(str(s))
    except Exception as e:
        print(f"保存エラー: {e}")


# 画像・音の読み込み
try:
    bg_img = pygame.image.load(BG_IMAGE_PATH).convert()
    bg_img = pygame.transform.scale(bg_img, (SCREEN_WIDTH, SCREEN_HEIGHT))
    raw_img = pygame.image.load(GENGE_IMAGE_PATH).convert_alpha()
    aspect_ratio = raw_img.get_height() / raw_img.get_width()
    base_w, base_h = 400, int(400 * aspect_ratio)
    genge_base = pygame.transform.scale(raw_img, (base_w, base_h))

    puyon_sound = pygame.mixer.Sound(SOUND_PATH)
    res_master = pygame.mixer.Sound(SOUND_MASTER)
    res_normal = pygame.mixer.Sound(SOUND_NORMAL)
    res_zero = pygame.mixer.Sound(SOUND_ZERO)
except Exception as e:
    print(f"読み込みエラー: {e}")


def reset_game():
    # スコア, 開始時間, 揺れ, エフェクト, 音フラグ, ハイスコア再読込
    return 0, pygame.time.get_ticks(), 0, [], False, load_highscore()


# 初期化
score, start_ticks, is_shaking, particles, played_finish_sound, high_score = reset_game()


def get_title(s):
    if s == 0: return "ただの干物"
    if s < 50: return "ぷるぷる初心者"
    if s < 100: return "コラーゲン職人"
    return "伝説のゲンゲマスター"


# --- メインループ ---
running = True
while running:
    if bg_img:
        screen.blit(bg_img, (0, 0))
    else:
        screen.fill((0, 15, 40))

    now = pygame.time.get_ticks()
    seconds = (now - start_ticks) // 1000
    time_left = max(0, TIMER_LIMIT - seconds)

    draw_w = base_w + (is_shaking * 8)
    draw_h = base_h - (is_shaking * 4)
    display_genge = pygame.transform.scale(genge_base, (int(draw_w), int(draw_h)))
    genge_rect = display_genge.get_rect(center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2))
    retry_btn_rect = pygame.Rect(SCREEN_WIDTH // 2 - 110, SCREEN_HEIGHT // 2 + 230, 220, 50)

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

        if event.type == pygame.MOUSEBUTTONDOWN:
            mx, my = pygame.mouse.get_pos()

            # リトライ判定
            if time_left == 0 and retry_btn_rect.collidepoint(mx, my):
                pygame.mixer.stop()
                score, start_ticks, is_shaking, particles, played_finish_sound, high_score = reset_game()
                time_left = TIMER_LIMIT
                continue

                # ゲンゲを叩く
            if time_left > 0:
                if genge_rect.collidepoint(mx, my):
                    score += 1
                    is_shaking = 15
                    puyon_sound.play()
                    for _ in range(12):
                        particles.append([mx, my, random.uniform(-7, 7), random.uniform(-7, 7), 25])

    if is_shaking > 0: is_shaking -= 1
    screen.blit(display_genge, genge_rect)

    for p in particles[:]:
        p[0] += p[2];
        p[1] += p[3];
        p[4] -= 1
        if p[4] > 0:
            pygame.draw.circle(screen, (180, 240, 255), (int(p[0]), int(p[1])), p[4] // 3)
        else:
            particles.remove(p)

    # UI表示（左にスコア・タイマー、右にハイスコア）
    ui_bg = pygame.Surface((SCREEN_WIDTH - 20, 100));
    ui_bg.set_alpha(100);
    ui_bg.fill((0, 0, 0))
    screen.blit(ui_bg, (10, 10))

    screen.blit(font.render(f"ぷるぷる度: {score}", True, (255, 255, 255)), (20, 20))
    screen.blit(font.render(f"残り時間: {time_left}", True, (255, 200, 0)), (20, 60))

    # ハイスコア表示（右寄せ風）
    hs_txt = font_small.render(f"最高記録: {high_score}", True, (200, 255, 200))
    screen.blit(hs_txt, (SCREEN_WIDTH - hs_txt.get_width() - 30, 25))

    # --- 終了判定と音の再生 ---
    if time_left == 0:
        if not played_finish_sound:
            # スコアがハイスコアを更新していたら保存
            if score > high_score:
                high_score = score
                save_highscore(high_score)

            if score >= 100:
                res_master.play()
            elif score > 0:
                res_normal.play()
            else:
                res_zero.play()
            played_finish_sound = True

        banner = pygame.Surface((SCREEN_WIDTH, 170));
        banner.set_alpha(180);
        banner.fill((0, 0, 0))
        screen.blit(banner, (0, SCREEN_HEIGHT // 2 + 125))

        title = get_title(score)
        res_txt = font.render("【判定結果】", True, (255, 255, 255))
        title_txt = font_large.render(title, True, (255, 100, 100))
        screen.blit(res_txt, res_txt.get_rect(center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 + 160)))
        screen.blit(title_txt, title_txt.get_rect(center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 + 210)))

        # ハイスコア更新時のメッセージ
        if score >= high_score and score > 0:
            new_txt = font_small.render("NEW RECORD!", True, (255, 255, 0))
            screen.blit(new_txt, new_txt.get_rect(center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 + 120)))

        pygame.draw.rect(screen, (255, 255, 255), retry_btn_rect, border_radius=15)
        btn_txt = font_small.render("もう一度ぷるぷる", True, (0, 0, 0))
        screen.blit(btn_txt, btn_txt.get_rect(center=retry_btn_rect.center))

    pygame.display.flip()
    clock.tick(60)

pygame.quit()