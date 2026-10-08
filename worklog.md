# Worklog — خط نجات (Khat-e Nejat)

این فایل لاگ مشترک همه‌ی agentها برای پروژه «خط نجات» است.

---
Task ID: 1
Agent: main (orchestrator)
Task: ساخت کامل پروژه بازی موبایلی خط نجات با Godot 4.3 — نسخه ۰.۱.۰ قابل بازی

Work Log:
- ساخت ساختار پوشه‌ها: scenes/, scripts/, data/levels/, assets/{themes,fonts,icons,audio}, tests/, download/
- ساخت project.godot برای Godot 4.3 با تنظیمات اندروید، autoload singletons، input mappings، layer names، RTL، viewport 720×1280
- پیاده‌سازی ۳ singleton:
  * GameManager.gd: state machine، coins، chapters، level unlock logic
  * SaveManager.gd: JSON save در user://save.json، schema migration، deep merge
  * AudioManager.gd: pooled SFX players، bus volume control، graceful missing-asset handling
- ساخت LevelData.gd به‌عنوان کلاس RefCounted (نه Resource) که از JSON لود می‌شود. تغییر از .tres به .tres به دلیل مشکلات typed Array[Dictionary] در فرمت tres.
- ساخت اسکریپت generate_levels.py که ۱۵ فایل JSON تولید می‌کند (دستی و قابل ویرایش).
- پیاده‌سازی LineDrawer.gd: ورودی لمسی+ماوسی، نرم‌سازی Douglas-Peucker، max length، multi-stroke، preview line، undo، clear.
- پیاده‌سازی PhysicsController.gd: ساخت StaticBody2D از wall/ground/platform، Area2D از goal/hazard، RigidBody2D از player، تبدیل strokes به SegmentShape2D، gravity setup، reset، win/lose triggers.
- پیاده‌سازی LevelManager.gd: هماهنگی داده ↔ engine، state machine، star computation، attempts tracking.
- پیاده‌سازی UIManager.gd: تمام UI gameplay شامل panels win/lose/hint، progress bar، button handlers، Persian digits، UI exclusion rects.
- پیاده‌سازی gameplay.gd: ریشه صحنه بازی، wire-up همه signalها، OOB check، tutorial flag.
- ساخت gameplay.tscn با ساختار کامل: World (PhysicsController, LineDrawer)، LevelManager، UIManager (TopBar, BottomBar, WinPanel, LosePanel, HintPanel).
- ساخت صفحات UI فارسی: main_menu.tscn, level_select.tscn, settings.tscn, result_screen.tscn — همه با layout_dir=3 (RTL).
- ساخت object scene templates: drawable_line.tscn, goal_area.tscn, hazard_area.tscn, level_object.tscn با scripts مربوطه.
- ساخت persian_theme.tres با StyleBoxFlat لاجوردی، font sizes و button styles.
- ساخت icon.svg (آیکون فیروزه‌ای با خط منحنی و ستاره).
- نوشتن README.md جامع (معرفی، راه‌اندازی، ساختار، افزودن مرحله، کنترل‌ها، معماری، ساخت APK، آزمون‌ها، مشکلات شناخته‌شده، آینده‌نگاری).
- ساخت export_presets.cfg کامل برای اندروید.
- ساخت tests/test_notes.md با سناریوهای آزمون و Honest reporting.
- نوشتن README فارسی برای fonts/ و audio/.

Stage Summary:
- نسخه ۰.۱.۰ پروژه ساخته شد و شامل تمام فایل‌های لازم برای باز شدن در Godot 4.3 است.
- ۱۵ مرحله JSON در ۳ فصل با محیط‌های متفاوت (محله، شهر، روستا) و راه‌حل‌های منطقی.
- معماری ماژولار: هر مسئولیت در اسکریپت جدا (GameManager، SaveManager، AudioManager، LevelManager، PhysicsController، LineDrawer، UIManager، gameplay).
- رابط کاربری فارسی راست‌چین با اعداد فارسی و دکمه‌های لمسی بزرگ.
- فیزیک پایدار: خطوط به StaticBody2D با SegmentShape2D تبدیل می‌شوند تا قابل پیش‌بینی باشند.
- ذخیره خودکار در user://save.json با schema migration.
- هیچ وابستگی به SDK پولی یا خارجی وجود ندارد.
- مواردی که نیازمند اجرای واقعی در Godot هستند با ⚠️ در tests/test_notes.md مشخص شده‌اند.
- هنوز نیازمند: نصب فونت Vazirmatn توسط کاربر (با مجوز OFL).
