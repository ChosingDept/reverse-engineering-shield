<div align="center">

[English](README.md) · [简体中文](README_zh.md) · [繁體中文](README_zh-TW.md) · [日本語](README_ja.md) · [한국어](README_ko.md) · [Türkçe](README_tr.md) · [Русский](README_ru.md) · [Tiếng Việt](README_vi.md) · [ไทย](README_th.md) · [Deutsch](README_de.md) · [Español](README_es.md) · [Français](README_fr.md) · [Українська](README_uk.md) · [Polski](README_pl.md) · [Português (Brasil)](README_pt-BR.md) · **العربية** · [فارسی](README_fa.md) · [Bahasa Indonesia](README_id.md) · [Italiano](README_it.md)

# Reverse Engineering Shield

### اجعل الهندسة العكسية بلا جدوى.

**وكيلك قادر على قراءة أي تطبيق. وكذلك وكيل منافسك. انشر شيفرة لا قيمة لقراءتها.**

[![CI](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml/badge.svg)](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml)
[![MIT license](https://img.shields.io/badge/license-MIT-f4c430?style=flat-square)](LICENSE)
[![Agent skill](https://img.shields.io/badge/agent-skill-5c4ee5?style=flat-square)](.agents/skills/reverse-engineering-shield/SKILL.md)

<code>npx skills add ChosingDept/reverse-engineering-shield</code>

</div>

<div dir="rtl">

---

تستطيع أدوات الوكلاء مثل [REA](https://github.com/morluto/rea) أن تشرح طريقة عمل أي
تطبيق ويب أو إضافة متصفح أو تطبيق Electron أو APK/IPA أو ملف ثنائي أصلي — في دقائق،
ومن دون الشيفرة المصدرية. لا توجد طريقة لمنع أحد من *قراءة* ما تنشره.

**Reverse Engineering Shield** هي مهارة (skill) للوكلاء مع سكربت تدقيق يجعلان هذه
القراءة بلا فائدة. تُعلّم وكيل البرمجة لديك (Claude Code وCodex وCursor وGemini CLI
وغيرها) أن يُبقي الأجزاء القيّمة على الخادم، وأن ينشر شيفرة العميل من دون خرائط، وأن
يعيد التحقق من كل شيء على الخادم، وأن يجعل ما يتبقى مكلفًا وقابلًا للتتبع — وأن يهاجم
البناء (build) الخاص بك قبل كل إصدار.

وهي تغطي **أي تطبيق على أي تقنية (stack)**: الويب، وإضافات المتصفح، والهاتف المحمول، وسطح
المكتب، و.NET وJVM، والألعاب، وWebAssembly، وحزم SDK والحزم البرمجية، والحاويات والتثبيتات
المحلية (on-prem)، والبرامج الثابتة/IoT، وميزات الذكاء الاصطناعي والنماذج العاملة على
الجهاز — وواجهات API التي تقف خلفها جميعًا.

## البدء السريع

### ثبّت المهارة

```bash
npx skills add ChosingDept/reverse-engineering-shield
```

أو باستخدام المُثبِّت (ينسخ المهارة إلى `~/.claude/skills` افتراضيًا):

```bash
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash
# another skills directory:
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash -s -- --dir ~/.codex/skills
```

أو انسخ `.agents/skills/reverse-engineering-shield` إلى مجلد المهارات الخاص بوكيلك.

### اطلب من وكيلك

> راجِع هذا المشروع باستخدام reverse-engineering-shield قبل أن ننشر الإضافة.

> منطق التسعير لدينا موجود في تطبيق React. انقله إلى خلف الـ API وفقًا لـ reverse-engineering-shield.

> دقّق `dist/` وموقعنا في بيئة الإنتاج، ثم أصلح كل CRITICAL.

### أو شغّل التدقيق بنفسك

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

رمز الخروج `2` يمنع الإصدار، و`1` يطلب تبريرًا، و`0` يعني أن النتيجة نظيفة — جاهز
للاستخدام في CI ([مثال](docs/ci.md)).

## كيف يعمل

### المبادئ الخمسة

1. **العقل يبقى على الخادم.** القواعد والتسعير والتقييم (scoring) والـ prompts
   والمحددات (selectors) والاستدلالات تعيش خلف الـ API الخاص بك. العميل يعرض وينفّذ فقط.
2. **ما يصل إلى العميل يصل من دون خريطة.** لا خرائط مصدر عامة، شيفرة مُصغَّرة،
   بلا تعليقات، بلا `console`، بلا أسماء داخلية، بلا مسارات تصحيح (debug).
3. **الخادم لا يثق بالعميل أبدًا.** يُعاد التحقق من التراخيص والملكية والحدود والأسعار
   في كل طلب.
4. **ما يجب أن يبقى على العميل يكون مكلفًا وقابلًا للتتبع.** تعمية (obfuscation) موجّهة
   حيث تسمح المتاجر بذلك، وعلامات مائية لكل عميل، وسجلات canary.
5. **هاجِم نفسك قبل أن تنشر.** شغّل التدقيق وREA على الناتج النهائي.
   إذا استطاع REA أن يشرح كيف تتخذ ميزةٌ ما قرارها، فسيستطيع منافسك ذلك أيضًا.

### ما الذي يفحصه التدقيق

| الفحص | الخطورة |
|---|---|
| ملفات `.map` في الناتج، والخرائط المضمّنة (inline)، والخرائط العامة على الموقع المباشر، و`asset-manifest.json` الذي يسرد خرائط | CRITICAL |
| أسرار الخادم: AWS، والمفاتيح الخاصة، و`sk_live_`، ومفاتيح مزوّدي LLM، ورموز GitHub/Slack، وعناوين قواعد بيانات تتضمن كلمات مرور، وحسابات الخدمة | CRITICAL (مُقنَّعة في المخرجات) |
| `/.git/` و`/.env` مكشوفان على الموقع المباشر | CRITICAL |
| تعليقات `sourceMappingURL` متروكة في الشيفرة | WARNING |
| مفاتيح Google/Firebase، ورموز JWT مكتوبة مباشرة في الشيفرة | WARNING |
| `localhost`، وعناوين IP خاصة، ومضيفات staging/homolog | WARNING |
| prompts ذكاء اصطناعي مُرسلة إلى العميل (`You are…`، `systemPrompt`، `role: "system"`) | WARNING |
| مصطلحات عملك الخاصة (`SHIELD_TERMS`) | WARNING |
| ملفات غير مُصغَّرة، وبقايا `console.log`/`debugger` | WARNING |
| حزمة React Native غير مُترجمة إلى bytecode الخاص بـ Hermes | WARNING |
| نقاط Swagger/OpenAPI/GraphQL يمكن الوصول إليها على الموقع المباشر | WARNING |

المدخلات: مجلدات البناء، `.zip`، `.crx`، `.xpi`، `.apk`، `.aab`، `.ipa`، `.asar`، أو عنوان URL.

### أدلة العمل حسب التقنية

تأتي المهارة مع قوائم تحقق مركّزة يحمّلها الوكيل عند الحاجة:

| التقنية | دليل العمل |
|---|---|
| تطبيقات الويب (Vite، CRA، Next.js، webpack) | [web.md](.agents/skills/reverse-engineering-shield/references/web.md) |
| إضافات المتصفح (Chrome MV3، Firefox) | [extensions.md](.agents/skills/reverse-engineering-shield/references/extensions.md) |
| الهاتف المحمول (React Native/Expo، Android، iOS، Flutter) | [mobile.md](.agents/skills/reverse-engineering-shield/references/mobile.md) |
| سطح المكتب (Electron، Tauri، أصلي، Python) | [desktop.md](.agents/skills/reverse-engineering-shield/references/desktop.md) |
| .NET وJVM (C#، Java، Kotlin، Scala، شيفرة بايت Android) | [managed-runtimes.md](.agents/skills/reverse-engineering-shield/references/managed-runtimes.md) |
| الألعاب (Unity، Unreal، Godot) | [games.md](.agents/skills/reverse-engineering-shield/references/games.md) |
| WebAssembly | [webassembly.md](.agents/skills/reverse-engineering-shield/references/webassembly.md) |
| حزم SDK، الحزم البرمجية، الحاويات، التثبيتات المحلية (on-prem) | [packages.md](.agents/skills/reverse-engineering-shield/references/packages.md) |
| البرامج الثابتة (Firmware)، الأنظمة المدمجة، IoT | [embedded.md](.agents/skills/reverse-engineering-shield/references/embedded.md) |
| ميزات الذكاء الاصطناعي والنماذج على الجهاز | [ai-models.md](.agents/skills/reverse-engineering-shield/references/ai-models.md) |
| واجهات API والخوادم الخلفية | [api.md](.agents/skills/reverse-engineering-shield/references/api.md) |
| الروبوتات والأتمتة | [server-driven.md](.agents/skills/reverse-engineering-shield/references/server-driven.md) |
| العلامات المائية، وسجلات canary، والجوانب القانونية | [traceability.md](.agents/skills/reverse-engineering-shield/references/traceability.md) |

## الأسئلة الشائعة

**ألا يمكنني ببساطة تعمية كل شيء؟**
التعمية والـ bytecode والـ pinning تؤخّر المحلل المُصِرّ، لكنها لا توقفه.
الوكلاء صبورون. وحده نقل القيمة إلى الخادم يزيلها. كما أن بعض المتاجر تحظر
التعمية — إذ يرفض Chrome Web Store الإضافات المُعمّاة.

**هل يحلّ هذا محل مراجعات الأمان أو اختبارات الاختراق؟**
لا. إنه يغطي ما تكشفه نواتج العميل وسطحك العام. استخدمه جنبًا إلى جنب مع
أعمال الأمان المعتادة.

**هل يمكنني تشغيل وضع URL على أي موقع؟**
فقط على النطاقات التي تملكها أو التي لديك تفويض صريح باختبارها.

**ما الوكلاء المدعومون؟**
أي وكيل يحمّل مهارات `SKILL.md` (Claude Code وCodex وCursor وGemini CLI وغيرها).
سكربت التدقيق مكتوب بـ Bash خالص ويعمل في أي مكان يتوفر فيه `curl` و`unzip` و`grep`.

## المساهمة

نرحّب بالـ issues وطلبات السحب (pull requests) — وخاصة أنماط الأسرار الجديدة والتقنيات
وأدلة العمل. راجع [CONTRIBUTING.md](CONTRIBUTING.md). شغّل `bash tests/run.sh` قبل فتح PR.

## الترخيص

[MIT](LICENSE) © Chosing Dept. راجع [DISCLAIMER.md](DISCLAIMER.md).

</div>
