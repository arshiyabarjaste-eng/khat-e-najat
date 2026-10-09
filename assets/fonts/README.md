# فونت فارسی — Vazirmatn

این پوشه برای قرار دادن فونت فارسی بازی است.

## فونت پیشنهادی: Vazirmatn

- **نام**: Vazirmatn
- **مجوز**: OFL (SIL Open Font License) — رایگان برای استفاده تجاری و غیرتجاری
- **پروژه رسمی**: https://github.com/rastikerdar/vazirmatn
- **نسخه پیشنهادی**: Vazirmatn-Regular.ttf و Vazirmatn-Bold.ttf

## نصب

برای اینکه رابط کاربری فارسی بازی درست نمایش داده شود:

1. فایل‌های زیر را از مخزن رسمی Vazirmatn دانلود کنید:
   - `Vazirmatn-Regular.ttf`
   - `Vazirmatn-Bold.ttf`
   - `Vazirmatn-Medium.ttf` (اختیاری)

2. آن‌ها را در همین پوشه کپی کنید (`/home/z/my-project/assets/fonts/`).

3. در `project.godot` در بخش `[gui]` تنظیمات زیر فعال است:
   ```
   theme/custom_font="res://assets/fonts/Vazirmatn-Regular.ttf"
   ```

4. فونت پشتیبان (fallback) برای حروف لاتین: فایل‌های موجود در `/usr/share/fonts/truetype/dejavu/` به‌صورت خودکار توسط Godot در صورت نیاز استفاده می‌شوند.

## سازگاری

Vazirmatn از:
- تمام حروف فارسی و عربی
- اعداد فارسی و عربی
- حروف لاتین پایه
- نشانه‌های نگارشی رایج فارسی

پشتیبانی می‌کند و برای بازی‌های موبایلی بهینه‌سازی شده است.

## جایگزین‌های مجاز

اگر Vazirmatn در دسترس نبود، این فونت‌ها هم با مجوز OFL مناسب هستند:
- **Shabnam** (by rastikerdar)
- **Sahel** (by rastikerdar)
- **Estedad** (by Estedad-Font)

توجه: در صورت استفاده از فونت دیگری، مسیر در `project.godot` و فایل‌های `.tscn` که فونت را ارجاع می‌دهند را به‌روز کنید.
