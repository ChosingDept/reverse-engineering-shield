<div align="center">

[English](README.md) · [简体中文](README_zh.md) · [繁體中文](README_zh-TW.md) · [日本語](README_ja.md) · [한국어](README_ko.md) · [Türkçe](README_tr.md) · [Русский](README_ru.md) · [Tiếng Việt](README_vi.md) · [ไทย](README_th.md) · [Deutsch](README_de.md) · [Español](README_es.md) · [Français](README_fr.md) · **Українська** · [Polski](README_pl.md) · [Português (Brasil)](README_pt-BR.md) · [العربية](README_ar.md) · [فارسی](README_fa.md) · [Bahasa Indonesia](README_id.md) · [Italiano](README_it.md)

# Reverse Engineering Shield

### Зробіть реверс-інжиніринг марним.

**Ваш агент може прочитати будь-який застосунок. Агент вашого конкурента — теж. Випускайте код, який немає сенсу читати.**

[![CI](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml/badge.svg)](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml)
[![MIT license](https://img.shields.io/badge/license-MIT-f4c430?style=flat-square)](LICENSE)
[![Agent skill](https://img.shields.io/badge/agent-skill-5c4ee5?style=flat-square)](.agents/skills/reverse-engineering-shield/SKILL.md)

<code>npx skills add ChosingDept/reverse-engineering-shield</code>

</div>

---

Інструменти для агентів, як-от [REA](https://github.com/morluto/rea), можуть пояснити, як працює
будь-який вебзастосунок, розширення браузера, Electron-застосунок, APK/IPA чи нативний бінарник, —
за лічені хвилини й без вихідного коду. Завадити комусь *прочитати* те, що ви випускаєте, неможливо.

**Reverse Engineering Shield** — це скіл для агента разом зі скриптом аудиту, який робить таке
читання безглуздим. Він навчає вашого агента для програмування (Claude Code, Codex, Cursor,
Gemini CLI та інших) тримати цінні частини на сервері, постачати клієнтський код без source maps,
повторно перевіряти все на боці сервера, робити те, що залишилося, дорогим для аналізу й
відстежуваним, — і атакувати власну збірку перед кожним релізом.

Він охоплює **будь-який застосунок на будь-якому стеку**: веб, розширення браузера, мобільні,
десктоп, .NET і JVM, ігри, WebAssembly, SDK і пакети, контейнери й локальні (on-prem) інсталяції,
прошивки/IoT, ШІ-функції та моделі на пристрої — і API, що стоять за всім цим.

## Швидкий старт

### Встановіть скіл

```bash
npx skills add ChosingDept/reverse-engineering-shield
```

Або за допомогою інсталятора (за замовчуванням копіює скіл у `~/.claude/skills`):

```bash
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash
# another skills directory:
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash -s -- --dir ~/.codex/skills
```

Або скопіюйте `.agents/skills/reverse-engineering-shield` у теку скілів вашого агента.

### Попросіть свого агента

> Перевір цей проєкт за допомогою reverse-engineering-shield, перш ніж ми опублікуємо розширення.

> Наша логіка ціноутворення знаходиться в React-застосунку. Перенеси її за API згідно з reverse-engineering-shield.

> Проаудитуй `dist/` і наш продакшн-сайт, а потім виправ кожен CRITICAL.

### Або запустіть аудит самостійно

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

Код виходу `2` блокує реліз, `1` вимагає обґрунтування, `0` означає, що все чисто, — готово
для CI ([приклад](docs/ci.md)).

## Як це працює

### П'ять принципів

1. **Мозок залишається на сервері.** Правила, ціноутворення, скоринг, промпти, селектори та
   евристики живуть за вашим API. Клієнт лише рендерить і виконує.
2. **Те, що потрапляє до клієнта, потрапляє без мапи.** Жодних публічних source maps, мініфікація,
   без коментарів, без `console`, без внутрішніх назв, без налагоджувальних маршрутів.
3. **Сервер ніколи не довіряє клієнту.** Ліцензії, право власності, ліміти й ціни
   перевіряються повторно під час кожного запиту.
4. **Те, що мусить залишитися на клієнті, дороге для аналізу й відстежуване.** Точкова обфускація
   там, де її дозволяють магазини, водяні знаки для кожного клієнта, записи-канарки.
5. **Атакуйте себе до релізу.** Запустіть аудит і REA проти фінального артефакту.
   Якщо REA може пояснити, як функція ухвалює рішення, то зможе й конкурент.

### Що перевіряє аудит

| Перевірка | Рівень серйозності |
|---|---|
| Файли `.map` в артефакті, вбудовані мапи, публічні мапи на живому сайті, `asset-manifest.json` зі списком мап | CRITICAL |
| Серверні секрети: AWS, приватні ключі, `sk_live_`, ключі LLM-провайдерів, токени GitHub/Slack, URL баз даних із паролями, сервісні акаунти | CRITICAL (маскуються у виводі) |
| Відкриті `/.git/` і `/.env` на живому сайті | CRITICAL |
| Коментарі `sourceMappingURL`, що залишилися в коді | WARNING |
| Ключі Google/Firebase, жорстко закодовані JWT | WARNING |
| `localhost`, приватні IP-адреси, staging-/тестові хости | WARNING |
| Промпти ШІ, що постачаються клієнту (`You are…`, `systemPrompt`, `role: "system"`) | WARNING |
| Ваші власні бізнес-терміни (`SHIELD_TERMS`) | WARNING |
| Немініфіковані файли, залишки `console.log`/`debugger` | WARNING |
| Бандл React Native не скомпільовано в байт-код Hermes | WARNING |
| Ендпоінти Swagger/OpenAPI/GraphQL, доступні на живому сайті | WARNING |

Вхідні дані: теки збірки, `.zip`, `.crx`, `.xpi`, `.apk`, `.aab`, `.ipa`, `.asar` або URL.

### Плейбуки для стеків

Скіл містить цільові чеклісти, які агент завантажує, коли вони доречні:

| Стек | Плейбук |
|---|---|
| Вебзастосунки (Vite, CRA, Next.js, webpack) | [web.md](.agents/skills/reverse-engineering-shield/references/web.md) |
| Розширення браузера (Chrome MV3, Firefox) | [extensions.md](.agents/skills/reverse-engineering-shield/references/extensions.md) |
| Мобільні (React Native/Expo, Android, iOS, Flutter) | [mobile.md](.agents/skills/reverse-engineering-shield/references/mobile.md) |
| Десктоп (Electron, Tauri, нативні, Python) | [desktop.md](.agents/skills/reverse-engineering-shield/references/desktop.md) |
| .NET і JVM (C#, Java, Kotlin, Scala, байт-код Android) | [managed-runtimes.md](.agents/skills/reverse-engineering-shield/references/managed-runtimes.md) |
| Ігри (Unity, Unreal, Godot) | [games.md](.agents/skills/reverse-engineering-shield/references/games.md) |
| WebAssembly | [webassembly.md](.agents/skills/reverse-engineering-shield/references/webassembly.md) |
| SDK, пакети, контейнери, локальні (on-prem) інсталяції | [packages.md](.agents/skills/reverse-engineering-shield/references/packages.md) |
| Прошивки, вбудовані системи, IoT | [embedded.md](.agents/skills/reverse-engineering-shield/references/embedded.md) |
| ШІ-функції та моделі на пристрої | [ai-models.md](.agents/skills/reverse-engineering-shield/references/ai-models.md) |
| API та бекенди | [api.md](.agents/skills/reverse-engineering-shield/references/api.md) |
| Боти й автоматизації | [server-driven.md](.agents/skills/reverse-engineering-shield/references/server-driven.md) |
| Водяні знаки, канарки, юридичні питання | [traceability.md](.agents/skills/reverse-engineering-shield/references/traceability.md) |

## Поширені запитання

**Хіба не можна просто обфускувати все?**
Обфускація, байт-код і пінінг сповільнюють наполегливого аналітика, але не зупиняють його.
Агенти терплячі. Лише перенесення цінності на сервер справді її прибирає. До того ж деякі магазини
забороняють обфускацію — Chrome Web Store відхиляє обфусковані розширення.

**Чи замінює це рев'ю безпеки або пентести?**
Ні. Це охоплює те, що розкривають ваші клієнтські артефакти та публічна поверхня. Поєднуйте його
з регулярною роботою з безпеки.

**Чи можна запускати режим URL проти будь-якого сайту?**
Лише проти доменів, якими ви володієте або які вам явно дозволено тестувати.

**Які агенти підтримуються?**
Будь-який агент, що завантажує скіли `SKILL.md` (Claude Code, Codex, Cursor, Gemini CLI та
інші). Скрипт аудиту написаний на чистому Bash і працює будь-де, де є `curl`, `unzip` і `grep`.

## Як долучитися

Issues і pull requests вітаються — особливо нові шаблони секретів, стеки й плейбуки.
Див. [CONTRIBUTING.md](CONTRIBUTING.md). Запустіть `bash tests/run.sh`, перш ніж відкривати PR.

## Ліцензія

[MIT](LICENSE) © Chosing Dept. Див. [DISCLAIMER.md](DISCLAIMER.md).
