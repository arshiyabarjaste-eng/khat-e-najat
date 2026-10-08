#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generate_levels.py
--------------------------------------------------------------------------------
Generates 15 LevelData .json files under /home/z/my-project/data/levels/.

Each level is hand-tuned to be solvable. Object schema:

  {
    "type": "wall" | "goal" | "hazard" | "ball" | "cat" | "crate" |
            "ramp" | "block" | "spike" | "ground" | "platform",
    "position": [x, y],
    "size": [w, h],
    "rotation": 0,            # degrees
    "color": [r, g, b, a],
    "label": "",              # optional Persian text label
    "velocity": [vx, vy],
    "radius": 16              # for circle objects (ball, cat, etc.)
  }

Coordinate system: viewport 720 x 1280 (portrait). Origin top-left.
The level "playspace" is roughly y in [200, 1100] (UI bars above/below).
"""

import json
import shutil
from pathlib import Path

OUT_DIR = Path("/home/z/my-project/data/levels")
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Remove old .tres files from previous (broken) attempt
for f in OUT_DIR.glob("*.tres"):
    f.unlink()

# Common colors
C_TURQUOISE = [0.20, 0.50, 0.45, 1.0]
C_LAPIZ = [0.16, 0.20, 0.50, 1.0]
C_CREAM = [0.93, 0.85, 0.68, 1.0]
C_BRICK = [0.65, 0.27, 0.22, 1.0]
C_GREEN = [0.35, 0.55, 0.25, 1.0]
C_YELLOW = [0.95, 0.78, 0.20, 1.0]
C_GROUND = [0.62, 0.50, 0.34, 1.0]
C_DARKWALL = [0.42, 0.36, 0.30, 1.0]
C_DIRT = [0.55, 0.40, 0.25, 1.0]
C_WATER = [0.30, 0.55, 0.75, 1.0]
C_GREY = [0.35, 0.35, 0.38, 1.0]
C_BALL = [0.90, 0.55, 0.25, 1.0]
C_CRATE = [0.55, 0.40, 0.20, 1.0]
C_SPIKE = [0.20, 0.20, 0.20, 1.0]


def write_json(level_num: int, level: dict) -> None:
    path = OUT_DIR / f"level_{level_num:02d}.json"
    # Ensure level_number matches index
    level["level_number"] = level_num
    path.write_text(
        json.dumps(level, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    print(f"Wrote {path}")


# ============================================================================
# Level Definitions — 15 levels across 3 chapters
# ============================================================================

LEVELS = []

# ----------------------------------------------------------------------------
# CHAPTER 1: کوچه‌های محله (Levels 1-5)
# ----------------------------------------------------------------------------

LEVELS.append({
    "level_id": "level_01",
    "title": "نجات گربه",
    "chapter": 1,
    "brief": "گربه از روی دیوار می‌افته. یه خط بکش تا به حوض نیفته و به سبد برسه.",
    "hint": "یه خط مایل از زیر گربه بکش تا سمت چپ و پایین، مثل یک سرسره.",
    "gravity": 980.0,
    "max_line_length": 900.0,
    "star2_line_threshold": 0.85,
    "star3_line_threshold": 0.55,
    "background_color": C_TURQUOISE,
    "scene_name": "کوچه‌ی محله",
    "objects": [
        {"type": "wall", "position": [0, 0], "size": [80, 1280], "color": C_DARKWALL},
        {"type": "wall", "position": [640, 0], "size": [80, 1280], "color": C_DARKWALL},
        {"type": "ground", "position": [0, 1150], "size": [720, 130], "color": C_GROUND},
        {"type": "platform", "position": [120, 280], "size": [180, 24], "color": C_CREAM},
        {"type": "hazard", "position": [380, 1080], "size": [180, 60], "color": C_WATER, "label": "حوض"},
        {"type": "goal", "position": [100, 1080], "size": [120, 70], "color": C_GREEN, "label": "سبد"},
        {"type": "cat", "position": [180, 250], "size": [50, 50], "color": C_YELLOW, "radius": 22},
    ],
})

LEVELS.append({
    "level_id": "level_02",
    "title": "توپ در حیاط",
    "chapter": 1,
    "brief": "توپ از پشت‌بام می‌افته. یه خط بکش تا به حیاط برسه.",
    "hint": "یه خط مایل بکش که توپ رو از روی دیوار رد کنه و به داخل حیاط بندازه.",
    "gravity": 980.0,
    "max_line_length": 1100.0,
    "background_color": C_TURQUOISE,
    "scene_name": "پشت‌بام",
    "objects": [
        {"type": "wall", "position": [0, 0], "size": [40, 1280], "color": C_DARKWALL},
        {"type": "wall", "position": [680, 0], "size": [40, 1280], "color": C_DARKWALL},
        {"type": "ground", "position": [0, 1150], "size": [720, 130], "color": C_GROUND},
        {"type": "platform", "position": [40, 380], "size": [240, 20], "color": C_CREAM},
        {"type": "wall", "position": [40, 400], "size": [20, 280], "color": C_DARKWALL},
        {"type": "wall", "position": [380, 600], "size": [40, 550], "color": C_DARKWALL},
        {"type": "goal", "position": [490, 1080], "size": [140, 70], "color": C_GREEN, "label": "حیاط"},
        {"type": "ball", "position": [180, 340], "size": [40, 40], "color": C_BALL, "radius": 20},
    ],
})

LEVELS.append({
    "level_id": "level_03",
    "title": "گلدان سقوط‌کننده",
    "chapter": 1,
    "brief": "گلدان از ایوان می‌افته. یه خط بکش تا نشکنه و به جعبه برسه.",
    "hint": "یه خط افقی زیر گلدان بکش تا مثل یک پل، اون رو به سمت جعبه ببره.",
    "gravity": 980.0,
    "max_line_length": 850.0,
    "background_color": C_TURQUOISE,
    "scene_name": "ایوان خانه",
    "objects": [
        {"type": "wall", "position": [0, 0], "size": [40, 1280], "color": C_DARKWALL},
        {"type": "wall", "position": [680, 0], "size": [40, 1280], "color": C_DARKWALL},
        {"type": "ground", "position": [0, 1150], "size": [720, 130], "color": C_GROUND},
        {"type": "platform", "position": [500, 400], "size": [180, 20], "color": C_CREAM},
        {"type": "hazard", "position": [560, 1080], "size": [120, 70], "color": C_SPIKE, "label": "سنگ"},
        {"type": "goal", "position": [80, 1080], "size": [140, 70], "color": C_GREEN, "label": "جعبه"},
        {"type": "crate", "position": [580, 360], "size": [36, 48], "color": C_BRICK},
    ],
})

LEVELS.append({
    "level_id": "level_04",
    "title": "توپ و پشت‌بام",
    "chapter": 1,
    "brief": "توپ از پشت‌بام می‌چرخه. یه خط بکش تا به سبد برسه.",
    "hint": "یه خط منحنی بکش که توپ رو از روی دیوار رد کنه و به سبد بیندازه.",
    "gravity": 980.0,
    "max_line_length": 1300.0,
    "background_color": C_TURQUOISE,
    "scene_name": "پشت‌بام‌ها",
    "objects": [
        {"type": "wall", "position": [0, 0], "size": [40, 1280], "color": C_DARKWALL},
        {"type": "wall", "position": [680, 0], "size": [40, 1280], "color": C_DARKWALL},
        {"type": "ground", "position": [0, 1150], "size": [720, 130], "color": C_GROUND},
        {"type": "platform", "position": [60, 520], "size": [260, 20], "color": C_CREAM, "rotation": -12},
        {"type": "wall", "position": [340, 520], "size": [40, 320], "color": C_DARKWALL},
        {"type": "goal", "position": [510, 1080], "size": [120, 70], "color": C_GREEN, "label": "سبد"},
        {"type": "hazard", "position": [380, 1080], "size": [120, 70], "color": C_SPIKE, "label": "شکاف"},
        {"type": "ball", "position": [110, 470], "size": [40, 40], "color": C_BALL, "radius": 20},
    ],
})

LEVELS.append({
    "level_id": "level_05",
    "title": "وسایل روی شیب",
    "chapter": 1,
    "brief": "جعبه روی شیب می‌لغزه. یه خط بکش تا به نقطه امن برسه.",
    "hint": "یه خط عمودی نزدیک جعبه بکش تا مسیرش رو عوض کنه.",
    "gravity": 980.0,
    "max_line_length": 1000.0,
    "background_color": C_TURQUOISE,
    "scene_name": "شیب محله",
    "objects": [
        {"type": "wall", "position": [0, 0], "size": [40, 1280], "color": C_DARKWALL},
        {"type": "wall", "position": [680, 0], "size": [40, 1280], "color": C_DARKWALL},
        {"type": "ground", "position": [0, 1150], "size": [720, 130], "color": C_GROUND},
        {"type": "platform", "position": [60, 540], "size": [320, 20], "color": C_CREAM, "rotation": 18},
        {"type": "hazard", "position": [420, 1080], "size": [180, 70], "color": C_SPIKE, "label": "خیابان"},
        {"type": "goal", "position": [80, 1080], "size": [140, 70], "color": C_GREEN, "label": "امن"},
        {"type": "crate", "position": [80, 480], "size": [40, 40], "color": C_CRATE},
    ],
})

# ----------------------------------------------------------------------------
# CHAPTER 2: شهر شلوغ (Levels 6-10)
# ----------------------------------------------------------------------------

LEVELS.append({
    "level_id": "level_06",
    "title": "توپ و خیابان",
    "chapter": 2,
    "brief": "توپ از روی جدول می‌افته. یه خط بکش تا به ماشین نخوره.",
    "hint": "یه خط افقی بکش تا توپ رو بالای ماشین نگه‌داره و بعد به سمت مقصد ببر.",
    "gravity": 980.0,
    "max_line_length": 1200.0,
    "background_color": C_CREAM,
    "scene_name": "خیابان شهر",
    "objects": [
        {"type": "wall", "position": [0, 0], "size": [40, 1280], "color": C_DARKWALL},
        {"type": "wall", "position": [680, 0], "size": [40, 1280], "color": C_DARKWALL},
        {"type": "ground", "position": [0, 1150], "size": [720, 130], "color": C_GROUND},
        {"type": "platform", "position": [40, 600], "size": [180, 20], "color": C_CREAM},
        {"type": "hazard", "position": [360, 1080], "size": [120, 70], "color": C_BRICK, "label": "خودرو"},
        {"type": "goal", "position": [540, 1080], "size": [120, 70], "color": C_GREEN, "label": "مقصد"},
        {"type": "ball", "position": [120, 560], "size": [40, 40], "color": C_BALL, "radius": 20},
    ],
})

LEVELS.append({
    "level_id": "level_07",
    "title": "چرخ‌دستی بازار",
    "chapter": 2,
    "brief": "چرخ‌دستی از شیب پایین میاد. یه خط بکش تا از موانع رد بشه.",
    "hint": "یه خط منحنی بکش که چرخ‌دستی رو از روی موانع کوچک عبور بده.",
    "gravity": 980.0,
    "max_line_length": 1400.0,
    "background_color": C_CREAM,
    "scene_name": "بازار سنتی",
    "objects": [
        {"type": "wall", "position": [0, 0], "size": [40, 1280], "color": C_DARKWALL},
        {"type": "wall", "position": [680, 0], "size": [40, 1280], "color": C_DARKWALL},
        {"type": "ground", "position": [0, 1150], "size": [720, 130], "color": C_GROUND},
        {"type": "platform", "position": [60, 380], "size": [300, 20], "color": C_CREAM, "rotation": 25},
        {"type": "wall", "position": [320, 1100], "size": [40, 50], "color": C_DARKWALL},
        {"type": "wall", "position": [440, 1100], "size": [40, 50], "color": C_DARKWALL},
        {"type": "wall", "position": [560, 1100], "size": [40, 50], "color": C_DARKWALL},
        {"type": "goal", "position": [60, 1080], "size": [120, 70], "color": C_GREEN, "label": "مغازه"},
        {"type": "crate", "position": [80, 340], "size": [50, 40], "color": C_CRATE},
    ],
})

LEVELS.append({
    "level_id": "level_08",
    "title": "جعبه و شیب",
    "chapter": 2,
    "brief": "جعبه از شیب تند می‌لغزه. یه خط بکش تا متوقفش کنی و به مقصد برسون.",
    "hint": "یه خط مایل بکش تا مسیر جعبه رو به سمت چپ و پایین هدایت کنه.",
    "gravity": 1100.0,
    "max_line_length": 900.0,
    "background_color": C_CREAM,
    "scene_name": "خیابان شیب‌دار",
    "objects": [
        {"type": "wall", "position": [0, 0], "size": [40, 1280], "color": C_DARKWALL},
        {"type": "wall", "position": [680, 0], "size": [40, 1280], "color": C_DARKWALL},
        {"type": "ground", "position": [0, 1150], "size": [720, 130], "color": C_GROUND},
        {"type": "platform", "position": [60, 480], "size": [400, 20], "color": C_CREAM, "rotation": 30},
        {"type": "hazard", "position": [490, 1080], "size": [180, 70], "color": C_BRICK, "label": "گودال"},
        {"type": "goal", "position": [80, 1080], "size": [140, 70], "color": C_GREEN, "label": "وانت"},
        {"type": "crate", "position": [80, 440], "size": [44, 44], "color": C_CRATE},
    ],
})

LEVELS.append({
    "level_id": "level_09",
    "title": "کوچه موانع",
    "chapter": 2,
    "brief": "توپ از بالای کوچه می‌افته. یه خط بکش تا از موانع رد بشه.",
    "hint": "یه خط منحنی S شکل بکش تا توپ از بین موانع رد بشه.",
    "gravity": 980.0,
    "max_line_length": 1500.0,
    "background_color": C_CREAM,
    "scene_name": "کوچه باریک",
    "objects": [
        {"type": "wall", "position": [0, 0], "size": [40, 1280], "color": C_DARKWALL},
        {"type": "wall", "position": [680, 0], "size": [40, 1280], "color": C_DARKWALL},
        {"type": "ground", "position": [0, 1150], "size": [720, 130], "color": C_GROUND},
        {"type": "platform", "position": [40, 200], "size": [200, 20], "color": C_CREAM},
        {"type": "wall", "position": [200, 400], "size": [40, 200], "color": C_DARKWALL},
        {"type": "wall", "position": [480, 700], "size": [40, 200], "color": C_DARKWALL},
        {"type": "wall", "position": [240, 920], "size": [40, 200], "color": C_DARKWALL},
        {"type": "goal", "position": [500, 1080], "size": [140, 70], "color": C_GREEN, "label": "سبد"},
        {"type": "ball", "position": [120, 160], "size": [40, 40], "color": C_BALL, "radius": 20},
    ],
})

LEVELS.append({
    "level_id": "level_10",
    "title": "ضد ساعت",
    "chapter": 2,
    "brief": "توپ رو در زمان محدود به مقصد برسان.",
    "hint": "مستقیم‌ترین مسیر ممکن رو با خط بساز.",
    "gravity": 980.0,
    "time_limit": 8.0,
    "max_line_length": 1100.0,
    "background_color": C_CREAM,
    "scene_name": "میدان شهر",
    "objects": [
        {"type": "wall", "position": [0, 0], "size": [40, 1280], "color": C_DARKWALL},
        {"type": "wall", "position": [680, 0], "size": [40, 1280], "color": C_DARKWALL},
        {"type": "ground", "position": [0, 1150], "size": [720, 130], "color": C_GROUND},
        {"type": "platform", "position": [60, 320], "size": [200, 20], "color": C_CREAM},
        {"type": "hazard", "position": [240, 1080], "size": [320, 70], "color": C_BRICK, "label": "خیابان"},
        {"type": "goal", "position": [80, 1080], "size": [140, 70], "color": C_GREEN, "label": "مقصد"},
        {"type": "ball", "position": [140, 280], "size": [40, 40], "color": C_BALL, "radius": 20},
    ],
})

# ----------------------------------------------------------------------------
# CHAPTER 3: باغ و روستا (Levels 11-15)
# ----------------------------------------------------------------------------

LEVELS.append({
    "level_id": "level_11",
    "title": "آب به باغچه",
    "chapter": 3,
    "brief": "آب از لوله می‌چکه. یه خط بکش تا به باغچه برسه.",
    "hint": "یه خط مایل بکش که قطرات آب رو به سمت باغچه هدایت کنه.",
    "gravity": 600.0,
    "max_line_length": 1100.0,
    "background_color": C_GREEN,
    "scene_name": "باغ ایرانی",
    "objects": [
        {"type": "wall", "position": [0, 0], "size": [40, 1280], "color": C_DARKWALL},
        {"type": "wall", "position": [680, 0], "size": [40, 1280], "color": C_DARKWALL},
        {"type": "ground", "position": [0, 1150], "size": [720, 130], "color": C_DIRT},
        {"type": "wall", "position": [80, 280], "size": [40, 60], "color": C_GREY},
        {"type": "hazard", "position": [340, 1080], "size": [200, 70], "color": C_SPIKE, "label": "جوی"},
        {"type": "goal", "position": [80, 1080], "size": [180, 70], "color": C_GREEN, "label": "باغچه"},
        {"type": "ball", "position": [100, 360], "size": [24, 24], "color": C_WATER, "radius": 12},
    ],
})

LEVELS.append({
    "level_id": "level_12",
    "title": "گلدان لبه دیوار",
    "chapter": 3,
    "brief": "گلدان از لبه دیوار کاه‌گلی می‌افته. یه خط بکش تا نجاتش بدی.",
    "hint": "یه خط مایل زیر گلدان بکش تا اون رو به سمت چمن هدایت کنه.",
    "gravity": 980.0,
    "max_line_length": 950.0,
    "background_color": C_GREEN,
    "scene_name": "دیوار کاه‌گلی",
    "objects": [
        {"type": "wall", "position": [0, 0], "size": [40, 1280], "color": C_DIRT},
        {"type": "wall", "position": [680, 0], "size": [40, 1280], "color": C_DIRT},
        {"type": "ground", "position": [0, 1150], "size": [720, 130], "color": C_DIRT},
        {"type": "platform", "position": [420, 460], "size": [240, 30], "color": C_DIRT},
        {"type": "hazard", "position": [490, 1080], "size": [180, 70], "color": C_SPIKE, "label": "سنگ"},
        {"type": "goal", "position": [80, 1080], "size": [140, 70], "color": C_GREEN, "label": "چمن"},
        {"type": "crate", "position": [620, 420], "size": [36, 48], "color": C_BRICK},
    ],
})

LEVELS.append({
    "level_id": "level_13",
    "title": "مسیر ناهموار",
    "chapter": 3,
    "brief": "توپ از مسیر ناهموار می‌چرخه. یه خط بکش تا به دروازه برسه.",
    "hint": "یه خط روی یکی از برآمدگی‌ها بکش تا توپ رو به ارتفاع مناسب ببره.",
    "gravity": 980.0,
    "max_line_length": 1300.0,
    "background_color": C_GREEN,
    "scene_name": "زمین خاکی محله",
    "objects": [
        {"type": "wall", "position": [0, 0], "size": [40, 1280], "color": C_DIRT},
        {"type": "wall", "position": [680, 0], "size": [40, 1280], "color": C_DIRT},
        {"type": "ground", "position": [0, 1150], "size": [720, 130], "color": C_DIRT},
        {"type": "platform", "position": [40, 600], "size": [260, 20], "color": C_DIRT, "rotation": -15},
        {"type": "wall", "position": [320, 1080], "size": [50, 70], "color": C_DIRT},
        {"type": "wall", "position": [420, 1060], "size": [50, 90], "color": C_DIRT},
        {"type": "wall", "position": [520, 1040], "size": [50, 110], "color": C_DIRT},
        {"type": "goal", "position": [60, 1080], "size": [140, 70], "color": C_YELLOW, "label": "دروازه"},
        {"type": "ball", "position": [80, 540], "size": [40, 40], "color": C_BALL, "radius": 20},
    ],
})

LEVELS.append({
    "level_id": "level_14",
    "title": "محافظت از میوه",
    "chapter": 3,
    "brief": "میوه از شاخه می‌افته. یه خط بکش تا به سبد برسه.",
    "hint": "یه خط منحنی زیر شاخه بکش تا میوه‌ها رو به سمت سبد ببره.",
    "gravity": 800.0,
    "max_line_length": 1450.0,
    "background_color": C_GREEN,
    "scene_name": "باغ میوه",
    "objects": [
        {"type": "wall", "position": [0, 0], "size": [40, 1280], "color": C_DIRT},
        {"type": "wall", "position": [680, 0], "size": [40, 1280], "color": C_DIRT},
        {"type": "ground", "position": [0, 1150], "size": [720, 130], "color": C_DIRT},
        {"type": "platform", "position": [80, 320], "size": [320, 20], "color": C_DARKWALL},
        {"type": "hazard", "position": [380, 1080], "size": [200, 70], "color": C_SPIKE, "label": "سنگ"},
        {"type": "goal", "position": [80, 1080], "size": [140, 70], "color": C_YELLOW, "label": "سبد"},
        {"type": "ball", "position": [340, 280], "size": [30, 30], "color": C_BRICK, "radius": 15},
    ],
})

LEVELS.append({
    "level_id": "level_15",
    "title": "مرحله پایانی",
    "chapter": 3,
    "brief": "گلدان رو با کمترین خط ممکن نجات بده!",
    "hint": "با یک خط کوتاه و دقیق، مسیر گلدان رو عوض کن.",
    "gravity": 980.0,
    "max_line_length": 600.0,
    "require_special_condition": True,
    "special_condition_text": "فقط یک خط مجاز است",
    "max_line_segments": 1,
    "background_color": C_GREEN,
    "scene_name": "روستای ایران",
    "objects": [
        {"type": "wall", "position": [0, 0], "size": [40, 1280], "color": C_DIRT},
        {"type": "wall", "position": [680, 0], "size": [40, 1280], "color": C_DIRT},
        {"type": "ground", "position": [0, 1150], "size": [720, 130], "color": C_DIRT},
        {"type": "platform", "position": [460, 300], "size": [220, 24], "color": C_DIRT},
        {"type": "wall", "position": [340, 700], "size": [40, 220], "color": C_DIRT},
        {"type": "hazard", "position": [490, 1080], "size": [180, 70], "color": C_SPIKE, "label": "صخره"},
        {"type": "goal", "position": [80, 1080], "size": [180, 70], "color": C_GREEN, "label": "چمن"},
        {"type": "crate", "position": [620, 250], "size": [40, 50], "color": C_BRICK},
    ],
})


# ============================================================================
# Generate
# ============================================================================
for i, lvl in enumerate(LEVELS, start=1):
    write_json(i, lvl)

print(f"\nGenerated {len(LEVELS)} level files (JSON).")
