#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generate_screenshots.py
--------------------------------------------------------------------------------
Generates mockup screenshots of the Khat-e Nejat game's various screens.
Each screenshot is a faithful visual representation of how the actual
Godot scene would look at runtime, using the project's color palette and
Persian typography.

Output: /home/z/my-project/download/screenshots/*.png
"""

import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, Rectangle, Circle, Polygon, FancyArrowPatch
import matplotlib.font_manager as fm
import numpy as np
import arabic_reshaper
from bidi.algorithm import get_display

# Load fonts
FONT_REGULAR = "/tmp/vazirmatn_fonts/fonts/ttf/Vazirmatn-Regular.ttf"
FONT_BOLD = "/tmp/vazirmatn_fonts/fonts/ttf/Vazirmatn-Bold.ttf"
FONT_MEDIUM = "/tmp/vazirmatn_fonts/fonts/ttf/Vazirmatn-Medium.ttf"

fm.fontManager.addfont(FONT_REGULAR)
fm.fontManager.addfont(FONT_BOLD)
fm.fontManager.addfont(FONT_MEDIUM)
fm.fontManager.addfont("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")

plt.rcParams["font.family"] = ["Vazirmatn", "DejaVu Sans"]
plt.rcParams["axes.unicode_minus"] = False


def fa(text: str) -> str:
    """Reshape and reorder Persian/Arabic text for display."""
    reshaped = arabic_reshaper.reshape(text)
    return get_display(reshaped)


# Color palette
C_TURQUOISE = "#338073"  # فیروزه‌ای
C_LAPIZ = "#283380"      # لاجوردی
C_CREAM = "#EDD9A8"      # کرم
C_BRICK = "#A64538"      # آجری
C_GREEN = "#598C40"      # سبز طبیعی
C_YELLOW = "#F2C133"     # زرد گرم
C_GROUND = "#9E8056"     # خاکی
C_DARKWALL = "#6B5C4D"   # دیوار تیره
C_DIRT = "#8C6640"       # خاک
C_WATER = "#4D8CBF"      # آب
C_GREY = "#595959"
C_BALL = "#E68C40"
C_CRATE = "#8C6640"
C_SPIKE = "#333333"
C_LINE = "#283380"       # لاجوردی برای خط
C_PANEL_BG = "#283380DD"  # نیمه‌شفاف لاجوردی
C_PANEL_DARK = "#283380F0"

# Output directory
OUT = "/home/z/my-project/download/screenshots"
os.makedirs(OUT, exist_ok=True)


# Phone dimensions (9:16 portrait)
W, H = 720, 1280


def new_canvas():
    fig = plt.figure(figsize=(W/100, H/100), dpi=100)
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_xlim(0, W)
    ax.set_ylim(0, H)
    ax.invert_yaxis()
    ax.axis("off")
    return fig, ax


def draw_phone_frame(ax, color="#1a1a1a"):
    """Draw phone bezel around content."""
    # Subtle dark border to suggest phone screen edges
    ax.add_patch(Rectangle((0, 0), W, H, facecolor=color, edgecolor=None, zorder=-1))


def draw_text(ax, x, y, text, size=14, color="white", ha="center", va="center",
              weight="normal", alpha=1.0, rotation=0):
    """Draw Persian text."""
    ax.text(x, y, fa(text), fontsize=size, color=color, ha=ha, va=va,
            weight=weight, alpha=alpha, rotation=rotation,
            fontfamily="Vazirmatn")


def draw_button(ax, x, y, w, h, text, bg=C_PANEL_DARK, fg="white",
                size=18, radius=0.04, disabled=False, alpha=1.0):
    """Draw a button with rounded corners."""
    if disabled:
        bg = "#66666688"
        fg = "#BBBBBB"
    rect = FancyBboxPatch((x, y), w, h, boxstyle=f"round,pad=0,rounding_size={min(w,h)*radius}",
                          facecolor=bg, edgecolor="none", alpha=alpha)
    ax.add_patch(rect)
    draw_text(ax, x + w/2, y + h/2, text, size=size, color=fg, weight="medium")


def draw_panel(ax, x, y, w, h, bg=C_PANEL_BG, alpha=1.0, radius=0.05):
    rect = FancyBboxPatch((x, y), w, h, boxstyle=f"round,pad=0,rounding_size={min(w,h)*radius}",
                          facecolor=bg, edgecolor="none", alpha=alpha)
    ax.add_patch(rect)


def draw_star(ax, cx, cy, size=20, color=C_YELLOW, outline=C_LAPIZ, filled=True):
    """Draw a 5-point star."""
    angles = np.linspace(0.5*np.pi, 4.5*np.pi, 11)
    r = size
    points = []
    for i, a in enumerate(angles):
        rr = r if i % 2 == 0 else r * 0.4
        points.append([cx + rr*np.cos(a), cy - rr*np.sin(a)])
    polygon = Polygon(points, closed=True, facecolor=color if filled else "#999999",
                      edgecolor=outline, linewidth=1.5)
    ax.add_patch(polygon)


def draw_cat(ax, cx, cy, size=22, color=C_YELLOW):
    """Draw a simplified cat (the player)."""
    # Body (circle)
    ax.add_patch(Circle((cx, cy), size, facecolor=color, edgecolor=C_LAPIZ, lw=2, zorder=5))
    # Ears (triangles)
    ax.add_patch(Polygon([(cx-size*0.7, cy-size*0.6), (cx-size*0.3, cy-size*1.2), (cx, cy-size*0.5)],
                          facecolor=color, edgecolor=C_LAPIZ, lw=1, zorder=5))
    ax.add_patch(Polygon([(cx+size*0.7, cy-size*0.6), (cx+size*0.3, cy-size*1.2), (cx, cy-size*0.5)],
                          facecolor=color, edgecolor=C_LAPIZ, lw=1, zorder=5))
    # Eyes
    ax.add_patch(Circle((cx-size*0.4, cy-size*0.2), size*0.15, facecolor="black", zorder=6))
    ax.add_patch(Circle((cx+size*0.4, cy-size*0.2), size*0.15, facecolor="black", zorder=6))


def draw_ball(ax, cx, cy, radius=20, color=C_BALL):
    ax.add_patch(Circle((cx, cy), radius, facecolor=color, edgecolor=C_LAPIZ, lw=2, zorder=5))
    # Highlight
    ax.add_patch(Circle((cx-radius*0.3, cy-radius*0.3), radius*0.25, facecolor="white", alpha=0.4, zorder=6))


def draw_crate(ax, x, y, w, h, color=C_CRATE):
    ax.add_patch(Rectangle((x, y), w, h, facecolor=color, edgecolor=C_LAPIZ, lw=2, zorder=5))
    # Cross pattern
    ax.plot([x, x+w], [y, y+h], color=C_DARKWALL, lw=1, zorder=6)
    ax.plot([x, x+w], [y+h, y], color=C_DARKWALL, lw=1, zorder=6)


def save(fig, name):
    path = os.path.join(OUT, name)
    fig.savefig(path, dpi=100, facecolor=fig.get_facecolor())
    plt.close(fig)
    print(f"✅ Saved: {path}")
    return path


# ============================================================================
# 1. MAIN MENU
# ============================================================================
def screenshot_main_menu():
    fig, ax = new_canvas()
    # Background: turquoise gradient
    ax.add_patch(Rectangle((0, 0), W, H, facecolor=C_TURQUOISE, edgecolor=None))
    # Subtle decorative pattern (tile-like)
    for i in range(0, W+80, 80):
        for j in range(0, H+80, 80):
            ax.add_patch(Rectangle((i, j), 60, 60, facecolor="white", alpha=0.04, edgecolor=None))

    # Logo area (top)
    # Decorative Iranian-style ring around the title
    cx, cy = W//2, 280
    ax.add_patch(Circle((cx, cy), 110, facecolor="none", edgecolor=C_CREAM, lw=2, alpha=0.5))
    ax.add_patch(Circle((cx, cy), 100, facecolor="none", edgecolor=C_CREAM, lw=1, alpha=0.3))

    # Line + star (game icon)
    # Curving line
    t = np.linspace(0, 1, 50)
    line_x = 60 + 480*t
    line_y = 380 - 200*np.sin(t*np.pi*1.5) + 100*t  # gentle curve up
    ax.plot(line_x, line_y, color=C_LAPIZ, lw=10, solid_capstyle="round", zorder=4)
    # Highlight overlay
    ax.plot(line_x, line_y, color=C_CREAM, lw=3, alpha=0.7, solid_capstyle="round", zorder=5)
    # Source dot
    ax.add_patch(Circle((60, 380), 8, facecolor=C_LAPIZ, zorder=6))
    # Star at end
    draw_star(ax, 540, 180, size=24, color=C_YELLOW, outline=C_LAPIZ, filled=True)

    # Title
    draw_text(ax, W//2, 480, "خط نجات", size=80, color=C_CREAM, weight="bold")
    # Slogan
    draw_text(ax, W//2, 580, "یه خط بکش، یه زندگی رو نجات بده!", size=22, color="white")

    # Buttons
    bx, bw = 140, 440
    bh = 80
    draw_button(ax, bx, 720, bw, bh, "شروع بازی", size=28)
    draw_button(ax, bx, 824, bw, bh, "انتخاب مرحله", size=28)
    draw_button(ax, bx, 928, bw, bh, "تنظیمات", size=28)

    # Progress info
    draw_text(ax, W//2, 1080, "سکه: ۰", size=22, color=C_YELLOW)
    draw_text(ax, W//2, 1130, "پیشرفت: ۰ / ۱۵", size=18, color="white")
    draw_text(ax, W//2, 1230, "نسخه ۰.۱.۰", size=11, color="#AAAAAA")

    return save(fig, "01_main_menu.png")


# ============================================================================
# 2. LEVEL SELECT
# ============================================================================
def screenshot_level_select():
    fig, ax = new_canvas()
    # Background
    ax.add_patch(Rectangle((0, 0), W, H, facecolor=C_GROUND, edgecolor=None))

    # Top bar
    draw_panel(ax, 0, 0, W, 90, bg=C_PANEL_DARK, radius=0)
    draw_text(ax, W//2, 45, "انتخاب مرحله", size=30, color="white", weight="medium")
    draw_text(ax, W-100, 45, "سکه: ۱۲۵", size=20, color=C_YELLOW)

    # Chapter 1
    draw_panel(ax, 20, 110, W-40, 50, bg=C_PANEL_DARK)
    draw_text(ax, W//2, 135, "فصل ۱: کوچه‌های محله", size=22, color="white")

    # Level buttons (5 columns)
    level_titles = ["۱", "۲", "۳", "۴", "۵"]
    unlocked = [True, True, True, False, False]  # 1-3 unlocked, 4-5 locked
    stars = [3, 2, 1, 0, 0]
    for i, (title, unl, st) in enumerate(zip(level_titles, unlocked, stars)):
        x = 30 + i * 138
        y = 180
        if unl:
            draw_button(ax, x, y, 120, 120, title, bg=C_PANEL_DARK, size=36, fg="white")
            # Stars below
            for s in range(3):
                star_filled = s < st
                draw_star(ax, x + 30 + s*30, y + 140, size=12,
                          color=C_YELLOW if star_filled else "#666666",
                          filled=star_filled, outline=C_LAPIZ if star_filled else "#444444")
        else:
            # Lock icon drawn manually
            ax.add_patch(FancyBboxPatch((x, y), 120, 120, boxstyle="round,pad=0,rounding_size=12",
                                       facecolor="#66666688", edgecolor="none"))
            # Lock body
            ax.add_patch(FancyBboxPatch((x+45, y+40), 30, 30, boxstyle="round,pad=0,rounding_size=4",
                                       facecolor="#BBBBBB", edgecolor="none"))
            # Lock shackle
            ax.add_patch(patches.Wedge((x+60, y+70), 14, 0, 180, width=4, facecolor="none",
                                      edgecolor="#BBBBBB", lw=4))
            draw_text(ax, x+60, y+25, title, size=24, color="#BBBBBB")

    # Chapter 2
    draw_panel(ax, 20, 360, W-40, 50, bg=C_PANEL_DARK)
    draw_text(ax, W//2, 385, "فصل ۲: شهر شلوغ", size=22, color="white")

    for i in range(5):
        x = 30 + i * 138
        y = 430
        # Lock icon
        ax.add_patch(FancyBboxPatch((x, y), 120, 120, boxstyle="round,pad=0,rounding_size=12",
                                   facecolor="#66666688", edgecolor="none"))
        ax.add_patch(FancyBboxPatch((x+45, y+40), 30, 30, boxstyle="round,pad=0,rounding_size=4",
                                   facecolor="#BBBBBB", edgecolor="none"))
        ax.add_patch(patches.Wedge((x+60, y+70), 14, 0, 180, width=4, facecolor="none",
                                  edgecolor="#BBBBBB", lw=4))
        draw_text(ax, x+60, y+25, str(i+6), size=24, color="#BBBBBB")

    # Chapter 3
    draw_panel(ax, 20, 610, W-40, 50, bg=C_PANEL_DARK)
    draw_text(ax, W//2, 635, "فصل ۳: باغ و روستا", size=22, color="white")

    for i in range(5):
        x = 30 + i * 138
        y = 680
        ax.add_patch(FancyBboxPatch((x, y), 120, 120, boxstyle="round,pad=0,rounding_size=12",
                                   facecolor="#66666688", edgecolor="none"))
        ax.add_patch(FancyBboxPatch((x+45, y+40), 30, 30, boxstyle="round,pad=0,rounding_size=4",
                                   facecolor="#BBBBBB", edgecolor="none"))
        ax.add_patch(patches.Wedge((x+60, y+70), 14, 0, 180, width=4, facecolor="none",
                                  edgecolor="#BBBBBB", lw=4))
        draw_text(ax, x+60, y+25, str(i+11), size=24, color="#BBBBBB")

    # Bottom bar
    draw_panel(ax, 0, H-80, W, 80, bg=C_PANEL_DARK, radius=0)
    draw_button(ax, W//2-100, H-68, 200, 56, "بازگشت", bg=C_BRICK, size=22)

    return save(fig, "02_level_select.png")


# ============================================================================
# 3. GAMEPLAY - DRAWING PHASE (Level 1)
# ============================================================================
def screenshot_gameplay_drawing():
    fig, ax = new_canvas()
    # Background
    ax.add_patch(Rectangle((0, 0), W, H, facecolor=C_TURQUOISE, edgecolor=None))

    # Sky gradient effect (top to bottom)
    for i in range(120):
        alpha = i / 120 * 0.3
        ax.add_patch(Rectangle((0, i*2), W, 2, facecolor="white", alpha=alpha, edgecolor=None))

    # Top bar (UI panel)
    draw_panel(ax, 0, 0, W, 120, bg=C_PANEL_DARK, radius=0)
    draw_text(ax, W//2, 26, "مرحله ۱ - نجات گربه", size=26, color="white", weight="medium")
    draw_text(ax, W//2, 78, "گربه از روی دیوار می‌افته. یه خط بکش تا به حوض نیفته و به سبد برسه.",
              size=16, color=C_CREAM)

    # Game world objects (mirrors level_01.json)
    # Walls (left/right)
    ax.add_patch(Rectangle((0, 120), 80, 1030, facecolor=C_DARKWALL, edgecolor=None))
    ax.add_patch(Rectangle((640, 120), 80, 1030, facecolor=C_DARKWALL, edgecolor=None))
    # Ground
    ax.add_patch(Rectangle((80, 1150), 560, 130, facecolor=C_GROUND, edgecolor=None))
    # Top platform (where cat sits)
    ax.add_patch(Rectangle((120, 280), 180, 24, facecolor=C_CREAM, edgecolor=C_LAPIZ, lw=1))
    # Hazard: حوض (water basin)
    ax.add_patch(Rectangle((380, 1080), 180, 60, facecolor=C_WATER, edgecolor=C_LAPIZ, lw=2))
    draw_text(ax, 470, 1115, "حوض", size=14, color="white", weight="bold")
    # Goal: basket
    ax.add_patch(Rectangle((100, 1080), 120, 70, facecolor=C_GREEN, edgecolor=C_LAPIZ, lw=2, alpha=0.9))
    draw_text(ax, 160, 1115, "سبد", size=14, color="white", weight="bold")
    # Player: cat on platform
    draw_cat(ax, 210, 240, size=22, color=C_YELLOW)

    # The drawn line (preview) — being drawn by user
    # Mysterious path from below cat diagonally to basket
    line_x = [210, 220, 200, 180, 160, 140, 120]
    line_y = [210, 280, 400, 600, 800, 1000, 1090]
    ax.plot(line_x, line_y, color=C_LAPIZ, lw=8, solid_capstyle="round",
            solid_joinstyle="round", zorder=4, alpha=0.95)
    # Highlight
    ax.plot(line_x, line_y, color=C_CREAM, lw=2, alpha=0.6, solid_capstyle="round", zorder=5)

    # Bottom bar
    draw_panel(ax, 0, H-180, W, 180, bg=C_PANEL_DARK, radius=0)
    # Line progress
    draw_panel(ax, 16, H-168, W-32, 24, bg="#00000044", radius=0.1)
    draw_panel(ax, 16, H-168, (W-32)*0.35, 24, bg=C_YELLOW, radius=0.1)
    draw_text(ax, W//2, H-140, "خط: ۳۱۵ / ۹۰۰", size=14, color="white")

    # Buttons row 1
    bw1 = 120
    bh1 = 60
    gap = 12
    total_w_row1 = bw1*3 + gap*2
    start_x1 = (W - total_w_row1) // 2
    draw_button(ax, start_x1, H-128, bw1, bh1, "بازگشت", size=16)
    draw_button(ax, start_x1 + (bw1+gap), H-128, bw1, bh1, "لغو خط", size=16)
    draw_button(ax, start_x1 + 2*(bw1+gap), H-128, bw1, bh1, "پاک‌کردن", size=16)

    # Buttons row 2
    bw2 = [160, 160, 220]
    total_w_row2 = sum(bw2) + gap*2
    start_x2 = (W - total_w_row2) // 2
    draw_button(ax, start_x2, H-62, bw2[0], 60, "راهنما", size=18)
    draw_button(ax, start_x2 + bw2[0] + gap, H-62, bw2[1], 60, "تلاش مجدد", size=18)
    # Green start button with triangle play icon
    sb_x = start_x2 + 2*bw2[0] + 2*gap
    sb_y = H-62
    draw_button(ax, sb_x, sb_y, bw2[2], 60, "", size=22, bg=C_GREEN)
    # Triangle play icon
    ax.add_patch(Polygon([(sb_x+40, sb_y+20), (sb_x+40, sb_y+40), (sb_x+60, sb_y+30)],
                         facecolor="white", edgecolor=None, zorder=6))
    draw_text(ax, sb_x + bw2[2]//2 + 15, sb_y+30, "شروع", size=22, color="white", ha="center")

    # Hand-drawn finger indicator
    finger_x, finger_y = 130, 1090
    ax.add_patch(Circle((finger_x, finger_y), 18, facecolor="white", alpha=0.3, zorder=10))
    ax.add_patch(Circle((finger_x, finger_y), 8, facecolor="white", alpha=0.6, zorder=11))

    return save(fig, "03_gameplay_drawing.png")


# ============================================================================
# 4. GAMEPLAY - SIMULATION (Physics running)
# ============================================================================
def screenshot_gameplay_simulation():
    fig, ax = new_canvas()
    # Background
    ax.add_patch(Rectangle((0, 0), W, H, facecolor=C_TURQUOISE, edgecolor=None))

    # Top bar
    draw_panel(ax, 0, 0, W, 120, bg=C_PANEL_DARK, radius=0)
    draw_text(ax, W//2, 26, "مرحله ۱ - نجات گربه", size=26, color="white", weight="medium")
    draw_text(ax, W//2, 78, "گربه از روی دیوار می‌افته. یه خط بکش تا به حوض نیفته و به سبد برسه.",
              size=16, color=C_CREAM)

    # Game world
    ax.add_patch(Rectangle((0, 120), 80, 1030, facecolor=C_DARKWALL, edgecolor=None))
    ax.add_patch(Rectangle((640, 120), 80, 1030, facecolor=C_DARKWALL, edgecolor=None))
    ax.add_patch(Rectangle((80, 1150), 560, 130, facecolor=C_GROUND, edgecolor=None))
    ax.add_patch(Rectangle((120, 280), 180, 24, facecolor=C_CREAM, edgecolor=C_LAPIZ, lw=1))
    ax.add_patch(Rectangle((380, 1080), 180, 60, facecolor=C_WATER, edgecolor=C_LAPIZ, lw=2))
    draw_text(ax, 470, 1115, "حوض", size=14, color="white", weight="bold")
    ax.add_patch(Rectangle((100, 1080), 120, 70, facecolor=C_GREEN, edgecolor=C_LAPIZ, lw=2, alpha=0.9))
    draw_text(ax, 160, 1115, "سبد", size=14, color="white", weight="bold")

    # The drawn line (now a physical body)
    line_x = [210, 220, 200, 180, 160, 140, 120]
    line_y = [210, 280, 400, 600, 800, 1000, 1090]
    ax.plot(line_x, line_y, color=C_LAPIZ, lw=8, solid_capstyle="round",
            solid_joinstyle="round", zorder=4)
    ax.plot(line_x, line_y, color=C_CREAM, lw=2, alpha=0.6, solid_capstyle="round", zorder=5)

    # Cat now sliding down the line (mid-simulation)
    draw_cat(ax, 165, 700, size=22, color=C_YELLOW)

    # Motion trail (showing velocity)
    for i, alpha in enumerate([0.05, 0.1, 0.15, 0.25]):
        ax.add_patch(Circle((175 + i*5, 670 - i*10), 20, facecolor=C_YELLOW,
                            alpha=alpha, edgecolor=None, zorder=3))

    # Speed indicator
    # Lightning bolt drawn manually
    bolt_x, bolt_y = 460, 490
    ax.add_patch(Polygon([(bolt_x, bolt_y), (bolt_x+12, bolt_y), (bolt_x+5, bolt_y+15),
                         (bolt_x+12, bolt_y+15), (bolt_x, bolt_y+35), (bolt_x+7, bolt_y+18),
                         (bolt_x, bolt_y+18)],
                         facecolor=C_YELLOW, edgecolor=C_LAPIZ, lw=1, zorder=10))
    draw_text(ax, 530, 510, "در حال شبیه‌سازی...", size=18, color=C_YELLOW, weight="bold")
    # Pulse around cat
    ax.add_patch(Circle((165, 700), 35, facecolor="none", edgecolor=C_YELLOW, lw=2, alpha=0.4, zorder=4))

    # Bottom bar — buttons disabled
    draw_panel(ax, 0, H-180, W, 180, bg=C_PANEL_DARK, radius=0)
    draw_panel(ax, 16, H-168, W-32, 24, bg="#00000044", radius=0.1)
    draw_panel(ax, 16, H-168, (W-32)*0.35, 24, bg=C_YELLOW, radius=0.1)
    draw_text(ax, W//2, H-140, "خط: ۳۱۵ / ۹۰۰", size=14, color="white")

    bw1, bh1, gap = 120, 60, 12
    total_w_row1 = bw1*3 + gap*2
    start_x1 = (W - total_w_row1) // 2
    draw_button(ax, start_x1, H-128, bw1, bh1, "بازگشت", size=16, disabled=True)
    draw_button(ax, start_x1 + (bw1+gap), H-128, bw1, bh1, "لغو خط", size=16, disabled=True)
    draw_button(ax, start_x1 + 2*(bw1+gap), H-128, bw1, bh1, "پاک‌کردن", size=16, disabled=True)

    bw2 = [160, 160, 220]
    total_w_row2 = sum(bw2) + gap*2
    start_x2 = (W - total_w_row2) // 2
    draw_button(ax, start_x2, H-62, bw2[0], 60, "راهنما", size=18, disabled=True)
    draw_button(ax, start_x2 + bw2[0] + gap, H-62, bw2[1], 60, "تلاش مجدد", size=18)
    draw_button(ax, start_x2 + 2*bw2[0] + 2*gap, H-62, bw2[2], 60, "در حال اجرا...", size=18,
                bg="#666666", disabled=True, fg="#BBBBBB")

    return save(fig, "04_gameplay_simulation.png")


# ============================================================================
# 5. WIN PANEL
# ============================================================================
def screenshot_win_panel():
    fig, ax = new_canvas()
    # Background (gameplay behind)
    ax.add_patch(Rectangle((0, 0), W, H, facecolor=C_TURQUOISE, edgecolor=None))
    ax.add_patch(Rectangle((0, 120), 80, 1030, facecolor=C_DARKWALL, edgecolor=None))
    ax.add_patch(Rectangle((640, 120), 80, 1030, facecolor=C_DARKWALL, edgecolor=None))
    ax.add_patch(Rectangle((80, 1150), 560, 130, facecolor=C_GROUND, edgecolor=None))
    ax.add_patch(Rectangle((380, 1080), 180, 60, facecolor=C_WATER, edgecolor=C_LAPIZ, lw=2))
    ax.add_patch(Rectangle((100, 1080), 120, 70, facecolor=C_GREEN, edgecolor=C_LAPIZ, lw=2, alpha=0.9))
    draw_cat(ax, 160, 1060, size=22, color=C_YELLOW)  # cat reached goal!

    # Dark overlay
    ax.add_patch(Rectangle((0, 0), W, H, facecolor="black", alpha=0.7, zorder=10))

    # Win panel (centered)
    pw, ph = 500, 600
    px = (W - pw) // 2
    py = (H - ph) // 2
    draw_panel(ax, px, py, pw, ph, bg=C_PANEL_DARK, radius=0.05)

    # Title
    draw_text(ax, W//2, py+80, "آفرین!", size=44, color=C_CREAM, weight="bold")
    draw_text(ax, W//2, py+135, "نجاتش دادی", size=22, color="white")

    # Stars (3 stars earned)
    star_y = py + 240
    for i in range(3):
        draw_star(ax, W//2 - 80 + i*80, star_y, size=40, color=C_YELLOW, outline=C_LAPIZ)
        # Glow effect
        ax.add_patch(Circle((W//2 - 80 + i*80, star_y), 50, facecolor=C_YELLOW, alpha=0.15, zorder=11))

    # Coins earned
    draw_text(ax, W//2, py + 370, "+ ۱۲۵ سکه", size=28, color=C_YELLOW, weight="bold")

    # Buttons
    bw, bh = 140, 60
    gap = 12
    total = bw*3 + gap*2
    bx = (W - total) // 2
    draw_button(ax, bx, py + 480, bw, bh, "مراحل", size=18, bg=C_GREY)
    draw_button(ax, bx + bw + gap, py + 480, bw, bh, "دوباره", size=18, bg=C_GREY)
    # Next button with arrow
    nb_x = bx + 2*(bw+gap)
    nb_y = py + 480
    draw_button(ax, nb_x, nb_y, bw, bh, "", size=18, bg=C_GREEN)
    draw_text(ax, nb_x + bw//2 - 10, nb_y + bh//2, "بعدی", size=18, color="white")
    # Arrow
    ax.add_patch(Polygon([(nb_x + bw - 30, nb_y + bh//2 - 8),
                         (nb_x + bw - 30, nb_y + bh//2 + 8),
                         (nb_x + bw - 18, nb_y + bh//2)],
                         facecolor="white", edgecolor=None, zorder=6))

    # Confetti effect (small dots)
    rng = np.random.default_rng(42)
    for _ in range(30):
        x = rng.uniform(px+20, px+pw-20)
        y = rng.uniform(py+20, py+ph-20)
        c = rng.choice([C_YELLOW, C_GREEN, C_CREAM, C_BRICK])
        ax.add_patch(Circle((x, y), 4, facecolor=c, alpha=0.4, zorder=12))

    return save(fig, "05_win_panel.png")


# ============================================================================
# 6. LOSE PANEL
# ============================================================================
def screenshot_lose_panel():
    fig, ax = new_canvas()
    # Background (gameplay behind — cat fell into حوض)
    ax.add_patch(Rectangle((0, 0), W, H, facecolor=C_TURQUOISE, edgecolor=None))
    ax.add_patch(Rectangle((0, 120), 80, 1030, facecolor=C_DARKWALL, edgecolor=None))
    ax.add_patch(Rectangle((640, 120), 80, 1030, facecolor=C_DARKWALL, edgecolor=None))
    ax.add_patch(Rectangle((80, 1150), 560, 130, facecolor=C_GROUND, edgecolor=None))
    ax.add_patch(Rectangle((380, 1080), 180, 60, facecolor=C_WATER, edgecolor=C_LAPIZ, lw=2))

    # Cat in water (sad state)
    draw_cat(ax, 470, 1110, size=20, color=C_YELLOW)
    # Splash effect
    for _ in range(8):
        x = np.random.uniform(440, 500)
        y = np.random.uniform(1080, 1110)
        ax.add_patch(Circle((x, y), 4, facecolor="white", alpha=0.6, zorder=6))

    # Dark overlay
    ax.add_patch(Rectangle((0, 0), W, H, facecolor="black", alpha=0.7, zorder=10))

    # Lose panel
    pw, ph = 440, 360
    px = (W - pw) // 2
    py = (H - ph) // 2
    draw_panel(ax, px, py, pw, ph, bg=C_PANEL_DARK, radius=0.05)

    draw_text(ax, W//2, py+70, "ای وای!", size=44, color=C_BRICK, weight="bold")
    draw_text(ax, W//2, py+135, "هدف به خطر افتاد!", size=20, color="#FFB89A")
    # Subtext
    draw_text(ax, W//2, py+180, "گربه به حوض افتاد.", size=14, color="#CCCCCC")

    # Buttons
    bw, bh = 160, 60
    gap = 16
    total = bw*2 + gap
    bx = (W - total) // 2
    draw_button(ax, bx, py+ph-90, bw, bh, "مراحل", size=18, bg=C_GREY)
    draw_button(ax, bx + bw + gap, py+ph-90, bw, bh, "تلاش مجدد", size=18, bg=C_BRICK)

    return save(fig, "06_lose_panel.png")


# ============================================================================
# 7. SETTINGS
# ============================================================================
def screenshot_settings():
    fig, ax = new_canvas()
    # Background
    ax.add_patch(Rectangle((0, 0), W, H, facecolor=C_TURQUOISE, edgecolor=None))

    # Top bar
    draw_panel(ax, 0, 0, W, 80, bg=C_PANEL_DARK, radius=0)
    draw_text(ax, W//2, 40, "تنظیمات", size=28, color="white", weight="medium")
    draw_button(ax, 16, 16, 114, 48, "بازگشت", size=18)

    # Sound card
    draw_panel(ax, 80, 120, W-160, 90, bg=C_PANEL_BG)
    draw_text(ax, 180, 165, "افکت‌های صوتی", size=22, color="white", ha="left")
    # Toggle (on)
    toggle_x = W - 200
    ax.add_patch(FancyBboxPatch((toggle_x, 145), 80, 40, boxstyle="round,pad=0,rounding_size=20",
                                facecolor=C_GREEN, edgecolor=None))
    ax.add_patch(Circle((toggle_x + 60, 165), 16, facecolor="white", zorder=5))
    # Slider
    sx, sy, sw = 380, 155, 100
    ax.add_patch(FancyBboxPatch((sx, sy), sw, 6, boxstyle="round,pad=0,rounding_size=3",
                                facecolor="#FFFFFF44", edgecolor=None))
    ax.add_patch(FancyBboxPatch((sx, sy), sw*0.8, 6, boxstyle="round,pad=0,rounding_size=3",
                                facecolor=C_YELLOW, edgecolor=None))
    ax.add_patch(Circle((sx + sw*0.8, sy+3), 12, facecolor="white", edgecolor=C_LAPIZ, lw=2, zorder=5))

    # Music card
    draw_panel(ax, 80, 226, W-160, 90, bg=C_PANEL_BG)
    draw_text(ax, 180, 271, "موسیقی پس‌زمینه", size=22, color="white", ha="left")
    toggle_x = W - 200
    ax.add_patch(FancyBboxPatch((toggle_x, 251), 80, 40, boxstyle="round,pad=0,rounding_size=20",
                                facecolor=C_GREEN, edgecolor=None))
    ax.add_patch(Circle((toggle_x + 60, 271), 16, facecolor="white", zorder=5))
    sx, sy, sw = 380, 261, 100
    ax.add_patch(FancyBboxPatch((sx, sy), sw, 6, boxstyle="round,pad=0,rounding_size=3",
                                facecolor="#FFFFFF44", edgecolor=None))
    ax.add_patch(FancyBboxPatch((sx, sy), sw*0.7, 6, boxstyle="round,pad=0,rounding_size=3",
                                facecolor=C_YELLOW, edgecolor=None))
    ax.add_patch(Circle((sx + sw*0.7, sy+3), 12, facecolor="white", edgecolor=C_LAPIZ, lw=2, zorder=5))

    # Language card
    draw_panel(ax, 80, 332, W-160, 90, bg=C_PANEL_BG)
    draw_text(ax, 180, 377, "زبان", size=22, color="white", ha="left")
    # Dropdown (showing فارسی)
    dx, dy, dw, dh = 380, 352, 240, 50
    ax.add_patch(FancyBboxPatch((dx, dy), dw, dh, boxstyle="round,pad=0,rounding_size=6",
                                facecolor=C_LAPIZ, edgecolor="white", linewidth=1.5))
    draw_text(ax, dx + dw//2, dy + dh//2, "فارسی", size=18, color="white")
    # Dropdown arrow
    ax.plot([dx + dw - 25, dx + dw - 15, dx + dw - 5],
            [dy + dh//2 - 5, dy + dh//2 + 5, dy + dh//2 - 5], color="white", lw=2)

    # Spacer
    # Reset progress card
    draw_panel(ax, 80, 460, W-160, 90, bg=C_PANEL_BG)
    draw_text(ax, 180, 505, "بازگردانی پیشرفت", size=22, color="#FFB89A", ha="left")
    draw_button(ax, W - 280, 480, 200, 50, "بازگردانی", size=18, bg=C_BRICK)

    # Help text at bottom
    draw_text(ax, W//2, 700, "همه تنظیمات به‌صورت خودکار ذخیره می‌شوند.",
              size=14, color="#CCCCCC")
    draw_text(ax, W//2, 740, "نسخه ۰.۱.۰ — خط نجات",
              size=12, color="#888888")

    return save(fig, "07_settings.png")


# ============================================================================
# 8. HINT PANEL
# ============================================================================
def screenshot_hint_panel():
    fig, ax = new_canvas()
    # Background (gameplay)
    ax.add_patch(Rectangle((0, 0), W, H, facecolor=C_TURQUOISE, edgecolor=None))
    ax.add_patch(Rectangle((0, 120), 80, 1030, facecolor=C_DARKWALL, edgecolor=None))
    ax.add_patch(Rectangle((640, 120), 80, 1030, facecolor=C_DARKWALL, edgecolor=None))
    ax.add_patch(Rectangle((80, 1150), 560, 130, facecolor=C_GROUND, edgecolor=None))
    ax.add_patch(Rectangle((120, 280), 180, 24, facecolor=C_CREAM, edgecolor=C_LAPIZ, lw=1))
    ax.add_patch(Rectangle((380, 1080), 180, 60, facecolor=C_WATER, edgecolor=C_LAPIZ, lw=2))
    ax.add_patch(Rectangle((100, 1080), 120, 70, facecolor=C_GREEN, edgecolor=C_LAPIZ, lw=2, alpha=0.9))
    draw_cat(ax, 210, 240, size=22, color=C_YELLOW)

    # Dark overlay
    ax.add_patch(Rectangle((0, 0), W, H, facecolor="black", alpha=0.7, zorder=10))

    # Hint panel
    pw, ph = 500, 320
    px = (W - pw) // 2
    py = (H - ph) // 2
    draw_panel(ax, px, py, pw, ph, bg=C_PANEL_DARK, radius=0.05)

    # Lightbulb icon (top) — drawn manually
    bulb_cx, bulb_cy = W//2, py + 60
    ax.add_patch(Circle((bulb_cx, bulb_cy), 22, facecolor=C_YELLOW, edgecolor=C_CREAM, lw=2, zorder=11))
    # Base of bulb
    ax.add_patch(Rectangle((bulb_cx - 10, bulb_cy + 18), 20, 12, facecolor=C_GREY, zorder=11))
    # Filament inside
    ax.plot([bulb_cx - 8, bulb_cx, bulb_cx + 8], [bulb_cy - 5, bulb_cy + 8, bulb_cy - 5],
            color=C_LAPIZ, lw=2, zorder=12)
    # Light rays around bulb
    for angle in range(0, 360, 45):
        rad = np.radians(angle)
        x1 = bulb_cx + np.cos(rad) * 28
        y1 = bulb_cy + np.sin(rad) * 28
        x2 = bulb_cx + np.cos(rad) * 38
        y2 = bulb_cy + np.sin(rad) * 38
        ax.plot([x1, x2], [y1, y2], color=C_YELLOW, lw=2, zorder=11, alpha=0.7)

    draw_text(ax, W//2, py + 130, "راهنما", size=28, color=C_CREAM, weight="bold")

    # Hint text (wrapped)
    hint_text = "یه خط مایل از زیر گربه بکش تا سمت چپ و پایین، مثل یک سرسره."
    draw_text(ax, W//2, py + 200, hint_text, size=18, color="white")
    # Second line if needed
    draw_text(ax, W//2, py + 230, "به یاد داشته باش: خط نباید خیلی کوتاه باشه!", size=14, color="#CCCCCC")

    # Close button
    draw_button(ax, W//2 - 90, py + ph - 70, 180, 50, "بستن", size=18, bg=C_GREEN)

    return save(fig, "08_hint_panel.png")


# ============================================================================
# 9. LEVEL 6 (city scene)
# ============================================================================
def screenshot_level_6_city():
    fig, ax = new_canvas()
    # Background (city — warmer color)
    ax.add_patch(Rectangle((0, 0), W, H, facecolor=C_CREAM, edgecolor=None))

    # Top bar
    draw_panel(ax, 0, 0, W, 120, bg=C_PANEL_DARK, radius=0)
    draw_text(ax, W//2, 26, "مرحله ۶ - توپ و خیابان", size=26, color="white", weight="medium")
    draw_text(ax, W//2, 78, "توپ از روی جدول می‌افته. یه خط بکش تا به ماشین نخوره.",
              size=16, color=C_CREAM)
    # Timer
    draw_text(ax, W - 100, 26, "زمان: ۸.۰", size=22, color=C_YELLOW, weight="bold")

    # Sky gradient (top)
    for i in range(120):
        alpha = i / 120 * 0.3
        ax.add_patch(Rectangle((0, i*2 + 120), W, 2, facecolor="white", alpha=alpha, edgecolor=None))

    # Side walls
    ax.add_patch(Rectangle((0, 120), 40, 1030, facecolor=C_DARKWALL, edgecolor=None))
    ax.add_patch(Rectangle((680, 120), 40, 1030, facecolor=C_DARKWALL, edgecolor=None))
    # Ground (street)
    ax.add_patch(Rectangle((40, 1150), 640, 130, facecolor=C_GROUND, edgecolor=None))
    # Sidewalk
    ax.add_patch(Rectangle((40, 600), 180, 20, facecolor=C_CREAM, edgecolor=C_LAPIZ, lw=1))
    # Hazard: car (with windows and wheels)
    # Car body
    ax.add_patch(FancyBboxPatch((360, 1080), 120, 70, boxstyle="round,pad=0,rounding_size=10",
                                facecolor=C_BRICK, edgecolor=C_LAPIZ, lw=2))
    # Car windows
    ax.add_patch(Rectangle((375, 1100), 40, 30, facecolor="#88C0FF", edgecolor=C_LAPIZ, lw=1))
    ax.add_patch(Rectangle((425, 1100), 45, 30, facecolor="#88C0FF", edgecolor=C_LAPIZ, lw=1))
    # Wheels
    ax.add_patch(Circle((390, 1150), 14, facecolor="black", edgecolor="#444", lw=2))
    ax.add_patch(Circle((450, 1150), 14, facecolor="black", edgecolor="#444", lw=2))
    draw_text(ax, 420, 1115, "خودرو", size=12, color="white", weight="bold")

    # Goal: safe zone
    ax.add_patch(FancyBboxPatch((540, 1080), 120, 70, boxstyle="round,pad=0,rounding_size=10",
                                facecolor=C_GREEN, edgecolor=C_LAPIZ, lw=2, alpha=0.9))
    draw_text(ax, 600, 1115, "مقصد", size=14, color="white", weight="bold")

    # Player: ball on sidewalk
    draw_ball(ax, 140, 560, radius=20)

    # Drawn line (arc avoiding the car)
    line_x = [140, 200, 280, 380, 480, 560, 600]
    line_y = [540, 700, 900, 1000, 1020, 1050, 1080]
    ax.plot(line_x, line_y, color=C_LAPIZ, lw=8, solid_capstyle="round",
            solid_joinstyle="round", zorder=4, alpha=0.95)
    ax.plot(line_x, line_y, color=C_CREAM, lw=2, alpha=0.6, solid_capstyle="round", zorder=5)

    # Bottom bar
    draw_panel(ax, 0, H-180, W, 180, bg=C_PANEL_DARK, radius=0)
    draw_panel(ax, 16, H-168, W-32, 24, bg="#00000044", radius=0.1)
    draw_panel(ax, 16, H-168, (W-32)*0.45, 24, bg=C_YELLOW, radius=0.1)
    draw_text(ax, W//2, H-140, "خط: ۵۴۰ / ۱۲۰۰", size=14, color="white")

    bw1, bh1, gap = 120, 60, 12
    total_w_row1 = bw1*3 + gap*2
    start_x1 = (W - total_w_row1) // 2
    draw_button(ax, start_x1, H-128, bw1, bh1, "بازگشت", size=16)
    draw_button(ax, start_x1 + (bw1+gap), H-128, bw1, bh1, "لغو خط", size=16)
    draw_button(ax, start_x1 + 2*(bw1+gap), H-128, bw1, bh1, "پاک‌کردن", size=16)

    bw2 = [160, 160, 220]
    total_w_row2 = sum(bw2) + gap*2
    start_x2 = (W - total_w_row2) // 2
    draw_button(ax, start_x2, H-62, bw2[0], 60, "راهنما", size=18)
    draw_button(ax, start_x2 + bw2[0] + gap, H-62, bw2[1], 60, "تلاش مجدد", size=18)
    # Green start button with triangle play icon
    sb_x = start_x2 + 2*bw2[0] + 2*gap
    sb_y = H-62
    draw_button(ax, sb_x, sb_y, bw2[2], 60, "", size=22, bg=C_GREEN)
    ax.add_patch(Polygon([(sb_x+40, sb_y+20), (sb_x+40, sb_y+40), (sb_x+60, sb_y+30)],
                         facecolor="white", edgecolor=None, zorder=6))
    draw_text(ax, sb_x + bw2[2]//2 + 15, sb_y+30, "شروع", size=22, color="white", ha="center")

    return save(fig, "09_level6_city.png")


# ============================================================================
# 10. LEVEL 11 (village / water)
# ============================================================================
def screenshot_level_11_village():
    fig, ax = new_canvas()
    # Background (green — village)
    ax.add_patch(Rectangle((0, 0), W, H, facecolor=C_GREEN, edgecolor=None))

    # Top bar
    draw_panel(ax, 0, 0, W, 120, bg=C_PANEL_DARK, radius=0)
    draw_text(ax, W//2, 26, "مرحله ۱۱ - آب به باغچه", size=26, color="white", weight="medium")
    draw_text(ax, W//2, 78, "آب از لوله می‌چکه. یه خط بکش تا به باغچه برسه.",
              size=16, color=C_CREAM)

    # Sky
    for i in range(120):
        alpha = i / 120 * 0.3
        ax.add_patch(Rectangle((0, i*2 + 120), W, 2, facecolor="white", alpha=alpha, edgecolor=None))

    # Side walls (dirt)
    ax.add_patch(Rectangle((0, 120), 40, 1030, facecolor=C_DIRT, edgecolor=None))
    ax.add_patch(Rectangle((680, 120), 40, 1030, facecolor=C_DIRT, edgecolor=None))
    # Ground
    ax.add_patch(Rectangle((40, 1150), 640, 130, facecolor=C_DIRT, edgecolor=None))

    # Tree branch (decorative)
    ax.add_patch(Rectangle((40, 180), 320, 16, facecolor=C_DARKWALL, edgecolor=None))
    # Pipe (water source)
    ax.add_patch(Rectangle((80, 280), 40, 60, facecolor=C_GREY, edgecolor=C_LAPIZ, lw=2))
    draw_text(ax, 100, 310, "لوله", size=10, color="white")

    # Water droplets (small blue balls)
    for dy in [0, 40, 80]:
        draw_ball(ax, 100, 380 + dy, radius=8, color=C_WATER)

    # Hazard: ditch (جوی)
    ax.add_patch(Rectangle((340, 1080), 200, 70, facecolor=C_SPIKE, edgecolor=C_LAPIZ, lw=2))
    # Ditch details (lines)
    for i in range(5):
        ax.plot([350 + i*40, 360 + i*40], [1080, 1150], color="#555555", lw=1)
    draw_text(ax, 440, 1115, "جوی", size=14, color="white", weight="bold")

    # Goal: garden plot (with plants)
    ax.add_patch(Rectangle((80, 1080), 180, 70, facecolor=C_GREEN, edgecolor=C_LAPIZ, lw=2, alpha=0.9))
    # Plants in garden
    for px in [110, 150, 190, 230]:
        ax.add_patch(Polygon([(px, 1090), (px-8, 1110), (px+8, 1110)],
                              facecolor=C_GREEN, edgecolor=C_LAPIZ, lw=1, zorder=6))
    draw_text(ax, 170, 1130, "باغچه", size=14, color="white", weight="bold")

    # Drawn line guiding water
    line_x = [100, 100, 110, 130, 160, 200, 240]
    line_y = [470, 600, 750, 900, 1000, 1050, 1080]
    ax.plot(line_x, line_y, color=C_LAPIZ, lw=8, solid_capstyle="round",
            solid_joinstyle="round", zorder=4, alpha=0.95)
    ax.plot(line_x, line_y, color=C_CREAM, lw=2, alpha=0.6, solid_capstyle="round", zorder=5)

    # Bottom bar
    draw_panel(ax, 0, H-180, W, 180, bg=C_PANEL_DARK, radius=0)
    draw_panel(ax, 16, H-168, W-32, 24, bg="#00000044", radius=0.1)
    draw_panel(ax, 16, H-168, (W-32)*0.30, 24, bg=C_YELLOW, radius=0.1)
    draw_text(ax, W//2, H-140, "خط: ۳۳۰ / ۱۱۰۰", size=14, color="white")

    bw1, bh1, gap = 120, 60, 12
    total_w_row1 = bw1*3 + gap*2
    start_x1 = (W - total_w_row1) // 2
    draw_button(ax, start_x1, H-128, bw1, bh1, "بازگشت", size=16)
    draw_button(ax, start_x1 + (bw1+gap), H-128, bw1, bh1, "لغو خط", size=16)
    draw_button(ax, start_x1 + 2*(bw1+gap), H-128, bw1, bh1, "پاک‌کردن", size=16)

    bw2 = [160, 160, 220]
    total_w_row2 = sum(bw2) + gap*2
    start_x2 = (W - total_w_row2) // 2
    draw_button(ax, start_x2, H-62, bw2[0], 60, "راهنما", size=18)
    draw_button(ax, start_x2 + bw2[0] + gap, H-62, bw2[1], 60, "تلاش مجدد", size=18)
    # Green start button with triangle play icon
    sb_x = start_x2 + 2*bw2[0] + 2*gap
    sb_y = H-62
    draw_button(ax, sb_x, sb_y, bw2[2], 60, "", size=22, bg=C_GREEN)
    ax.add_patch(Polygon([(sb_x+40, sb_y+20), (sb_x+40, sb_y+40), (sb_x+60, sb_y+30)],
                         facecolor="white", edgecolor=None, zorder=6))
    draw_text(ax, sb_x + bw2[2]//2 + 15, sb_y+30, "شروع", size=22, color="white", ha="center")

    return save(fig, "10_level11_village.png")


# ============================================================================
# Main
# ============================================================================
if __name__ == "__main__":
    print("Generating screenshots for خط نجات...")
    print()
    screenshot_main_menu()
    screenshot_level_select()
    screenshot_gameplay_drawing()
    screenshot_gameplay_simulation()
    screenshot_win_panel()
    screenshot_lose_panel()
    screenshot_settings()
    screenshot_hint_panel()
    screenshot_level_6_city()
    screenshot_level_11_village()
    print()
    print(f"All screenshots saved to: {OUT}")
