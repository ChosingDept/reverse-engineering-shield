<div align="center">

[English](README.md) · [简体中文](README_zh.md) · [繁體中文](README_zh-TW.md) · [日本語](README_ja.md) · [한국어](README_ko.md) · [Türkçe](README_tr.md) · [Русский](README_ru.md) · [Tiếng Việt](README_vi.md) · [ไทย](README_th.md) · [Deutsch](README_de.md) · [Español](README_es.md) · [Français](README_fr.md) · [Українська](README_uk.md) · [Polski](README_pl.md) · [Português (Brasil)](README_pt-BR.md) · [العربية](README_ar.md) · **فارسی** · [Bahasa Indonesia](README_id.md) · [Italiano](README_it.md)

# Reverse Engineering Shield

### مهندسی معکوس را بی‌فایده کنید.

**ایجنت شما می‌تواند هر اپی را بخواند. ایجنت رقیب شما هم. کدی منتشر کنید که خواندنش هیچ ارزشی ندارد.**

[![CI](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml/badge.svg)](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml)
[![MIT license](https://img.shields.io/badge/license-MIT-f4c430?style=flat-square)](LICENSE)
[![Agent skill](https://img.shields.io/badge/agent-skill-5c4ee5?style=flat-square)](.agents/skills/reverse-engineering-shield/SKILL.md)

<code>npx skills add ChosingDept/reverse-engineering-shield</code>

</div>

<div dir="rtl">

---

ابزارهای ایجنتی مانند [REA](https://github.com/morluto/rea) می‌توانند توضیح دهند که هر
وب‌اپ، افزونهٔ مرورگر، اپ Electron، APK/IPA یا باینری نیتیو چگونه کار می‌کند — در چند
دقیقه و بدون کد منبع. هیچ راهی برای جلوگیری از اینکه کسی آنچه را منتشر می‌کنید *بخواند*
وجود ندارد.

**Reverse Engineering Shield** یک مهارت (skill) برای ایجنت به‌همراه یک اسکریپت ممیزی است
که این خواندن را بی‌ثمر می‌کند. این مهارت به ایجنت کدنویسی شما (Claude Code، Codex،
Cursor، Gemini CLI و دیگران) یاد می‌دهد بخش‌های ارزشمند را روی سرور نگه دارد، کد سمت
کلاینت را بدون مپ منتشر کند، همه‌چیز را دوباره در سمت سرور اعتبارسنجی کند، آنچه باقی
می‌ماند را پرهزینه و قابل‌ردیابی کند — و پیش از هر انتشار، به build خود شما حمله کند.

## شروع سریع

### نصب مهارت

```bash
npx skills add ChosingDept/reverse-engineering-shield
```

یا با نصب‌کننده (به‌طور پیش‌فرض مهارت را در `~/.claude/skills` کپی می‌کند):

```bash
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash
# another skills directory:
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash -s -- --dir ~/.codex/skills
```

یا `.agents/skills/reverse-engineering-shield` را در پوشهٔ مهارت‌های ایجنت خود کپی کنید.

### از ایجنت خود بخواهید

> پیش از اینکه افزونه را منتشر کنیم، این پروژه را با reverse-engineering-shield بررسی کن.

> منطق قیمت‌گذاری ما در اپ React است. طبق reverse-engineering-shield آن را به پشت API منتقل کن.

> `dist/` و سایت پروداکشن ما را ممیزی کن، سپس همهٔ موارد CRITICAL را برطرف کن.

### یا ممیزی را خودتان اجرا کنید

```bash
.agents/skills/reverse-engineering-shield/scripts/audit.sh dist/
.agents/skills/reverse-engineering-shield/scripts/audit.sh extension.zip
.agents/skills/reverse-engineering-shield/scripts/audit.sh https://your-domain.example
SHIELD_TERMS="pricing,margin,You are" .agents/skills/reverse-engineering-shield/scripts/audit.sh dist/
```

```text
CRITICAL 10 source maps in the artifact (they rebuild the original source): assets/index.js.map …
WARNING  8 files still reference a source map (sourceMappingURL); if the .map is on the server, it leaks
ok       no server-side secrets
WARNING  internal/staging URLs in the artifact: http://localhost:3003

result: 1 critical, 2 warning(s)
```

کد خروج `2` انتشار را مسدود می‌کند، `1` توجیه می‌خواهد، و `0` یعنی تمیز — آماده برای
CI ([نمونه](docs/ci.md)).

## چگونه کار می‌کند

### پنج اصل

1. **مغز روی سرور می‌ماند.** قوانین، قیمت‌گذاری، امتیازدهی، promptها، selectorها و
   هیوریستیک‌ها پشت API شما قرار دارند. کلاینت فقط رندر و اجرا می‌کند.
2. **آنچه به کلاینت می‌رسد، بدون مپ می‌رسد.** بدون source map عمومی، minify‌شده،
   بدون کامنت، بدون `console`، بدون نام‌های داخلی، بدون مسیرهای دیباگ.
3. **سرور هرگز به کلاینت اعتماد نمی‌کند.** لایسنس‌ها، مالکیت، محدودیت‌ها و قیمت‌ها
   در هر درخواست دوباره اعتبارسنجی می‌شوند.
4. **آنچه باید روی کلاینت بماند، پرهزینه و قابل‌ردیابی است.** مبهم‌سازی (obfuscation)
   هدفمند در جاهایی که فروشگاه‌ها اجازه می‌دهند، واترمارک برای هر مشتری، رکوردهای canary.
5. **پیش از انتشار به خودتان حمله کنید.** ممیزی و REA را روی خروجی نهایی اجرا کنید.
   اگر REA بتواند توضیح دهد یک قابلیت چگونه تصمیم می‌گیرد، رقیب شما هم می‌تواند.

### ممیزی چه چیزهایی را بررسی می‌کند

| بررسی | شدت |
|---|---|
| فایل‌های `.map` در خروجی، مپ‌های inline، مپ‌های عمومی روی سایت زنده، `asset-manifest.json` که مپ‌ها را فهرست می‌کند | CRITICAL |
| اسرار سرور: AWS، کلیدهای خصوصی، `sk_live_`، کلیدهای ارائه‌دهندگان LLM، توکن‌های GitHub/Slack، URLهای پایگاه داده همراه با رمز عبور، حساب‌های سرویس | CRITICAL (در خروجی پوشانده می‌شوند) |
| `/.git/` و `/.env` در معرض دید روی سایت زنده | CRITICAL |
| کامنت‌های `sourceMappingURL` باقی‌مانده در کد | WARNING |
| کلیدهای Google/Firebase، JWTهای هاردکدشده | WARNING |
| `localhost`، IPهای خصوصی، میزبان‌های staging/homolog | WARNING |
| promptهای هوش مصنوعی ارسال‌شده به کلاینت (`You are…`، `systemPrompt`، `role: "system"`) | WARNING |
| اصطلاحات تجاری خودتان (`SHIELD_TERMS`) | WARNING |
| فایل‌های minify‌نشده، باقی‌ماندهٔ `console.log`/`debugger` | WARNING |
| باندل React Native که به bytecode مربوط به Hermes کامپایل نشده است | WARNING |
| اندپوینت‌های Swagger/OpenAPI/GraphQL قابل‌دسترس روی سایت زنده | WARNING |

ورودی‌ها: پوشه‌های build، `.zip`، `.crx`، `.xpi`، `.apk`، `.aab`، `.ipa`، `.asar` یا یک URL.

### راهنماهای هر استک

این مهارت چک‌لیست‌های متمرکزی همراه دارد که ایجنت در صورت نیاز بارگذاری می‌کند:

| استک | راهنما |
|---|---|
| وب‌اپ‌ها (Vite، CRA، Next.js، webpack) | [web.md](.agents/skills/reverse-engineering-shield/references/web.md) |
| افزونه‌های مرورگر (Chrome MV3، Firefox) | [extensions.md](.agents/skills/reverse-engineering-shield/references/extensions.md) |
| موبایل (React Native/Expo، Android، iOS، Flutter) | [mobile.md](.agents/skills/reverse-engineering-shield/references/mobile.md) |
| دسکتاپ (Electron، Tauri، نیتیو، Python) | [desktop.md](.agents/skills/reverse-engineering-shield/references/desktop.md) |
| APIها و بک‌اندها | [api.md](.agents/skills/reverse-engineering-shield/references/api.md) |
| ربات‌ها و اتوماسیون‌ها | [server-driven.md](.agents/skills/reverse-engineering-shield/references/server-driven.md) |
| واترمارک‌ها، canaryها، مسائل حقوقی | [traceability.md](.agents/skills/reverse-engineering-shield/references/traceability.md) |

## پرسش‌های متداول

**نمی‌توانم همه‌چیز را فقط مبهم‌سازی کنم؟**
مبهم‌سازی، bytecode و pinning یک تحلیلگر مصمم را کُند می‌کنند؛ متوقفش نمی‌کنند.
ایجنت‌ها صبورند. تنها انتقال ارزش به سرور است که آن را از دسترس خارج می‌کند. برخی
فروشگاه‌ها هم مبهم‌سازی را ممنوع می‌کنند — Chrome Web Store افزونه‌های مبهم‌شده را رد می‌کند.

**آیا این جایگزین بازبینی‌های امنیتی یا تست نفوذ می‌شود؟**
خیر. این ابزار آنچه را که خروجی‌های سمت کلاینت و سطح عمومی شما فاش می‌کنند پوشش می‌دهد.
آن را در کنار کارهای امنیتی منظم به کار ببرید.

**آیا می‌توانم حالت URL را روی هر سایتی اجرا کنم؟**
فقط روی دامنه‌هایی که مالک آن‌ها هستید یا صراحتاً مجاز به آزمودنشان هستید.

**از کدام ایجنت‌ها پشتیبانی می‌شود؟**
هر ایجنتی که مهارت‌های `SKILL.md` را بارگذاری کند (Claude Code، Codex، Cursor، Gemini CLI و
دیگران). اسکریپت ممیزی Bash خالص است و هر جا که `curl`، `unzip` و `grep` باشد اجرا می‌شود.

## مشارکت

از issueها و pull requestها استقبال می‌کنیم — به‌ویژه الگوهای جدید اسرار، استک‌ها و
راهنماها. [CONTRIBUTING.md](CONTRIBUTING.md) را ببینید. پیش از باز کردن PR، `bash tests/run.sh` را اجرا کنید.

## مجوز

[MIT](LICENSE) © Chosing Dept. [DISCLAIMER.md](DISCLAIMER.md) را ببینید.

</div>
