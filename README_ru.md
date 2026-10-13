<div align="center">

[English](README.md) · [简体中文](README_zh.md) · [繁體中文](README_zh-TW.md) · [日本語](README_ja.md) · [한국어](README_ko.md) · [Türkçe](README_tr.md) · **Русский** · [Tiếng Việt](README_vi.md) · [ไทย](README_th.md) · [Deutsch](README_de.md) · [Español](README_es.md) · [Français](README_fr.md) · [Українська](README_uk.md) · [Polski](README_pl.md) · [Português (Brasil)](README_pt-BR.md) · [العربية](README_ar.md) · [فارسی](README_fa.md) · [Bahasa Indonesia](README_id.md) · [Italiano](README_it.md)

# Reverse Engineering Shield

### Сделайте реверс-инжиниринг бесполезным.

**Ваш агент может прочитать любое приложение. Агент вашего конкурента — тоже. Выпускайте код, который бесполезно читать.**

[![CI](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml/badge.svg)](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml)
[![MIT license](https://img.shields.io/badge/license-MIT-f4c430?style=flat-square)](LICENSE)
[![Agent skill](https://img.shields.io/badge/agent-skill-5c4ee5?style=flat-square)](.agents/skills/reverse-engineering-shield/SKILL.md)

<code>npx skills add ChosingDept/reverse-engineering-shield</code>

</div>

---

Агентные инструменты вроде [REA](https://github.com/morluto/rea) способны за считанные минуты и без
исходного кода объяснить, как устроено любое веб-приложение, расширение браузера, приложение на Electron,
APK/IPA или нативный бинарный файл. Помешать кому-то *прочитать* то, что вы выпускаете, невозможно.

**Reverse Engineering Shield** — это навык (skill) для агента плюс скрипт аудита, которые делают такое
чтение бессмысленным. Он учит вашего агента для программирования (Claude Code, Codex, Cursor, Gemini CLI
и другие) держать ценные части на сервере, выпускать клиентский код без карт, повторно проверять всё на
стороне сервера, делать оставшееся дорогим для анализа и отслеживаемым — и атаковать собственную сборку
перед каждым релизом.

## Быстрый старт

### Установите навык

```bash
npx skills add ChosingDept/reverse-engineering-shield
```

Или с помощью установщика (по умолчанию копирует навык в `~/.claude/skills`):

```bash
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash
# another skills directory:
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash -s -- --dir ~/.codex/skills
```

Или скопируйте `.agents/skills/reverse-engineering-shield` в папку навыков вашего агента.

### Попросите агента

> Проверь этот проект с помощью reverse-engineering-shield, прежде чем мы опубликуем расширение.

> Наша логика ценообразования находится в React-приложении. Перенеси её за API, следуя reverse-engineering-shield.

> Проведи аудит `dist/` и нашего продакшен-сайта, затем исправь все CRITICAL.

### Или запустите аудит сами

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

Код выхода `2` блокирует релиз, `1` требует обоснования, `0` означает, что всё чисто, — готово для
CI ([пример](docs/ci.md)).

## Как это работает

### Пять принципов

1. **Мозг остаётся на сервере.** Правила, ценообразование, скоринг, промпты, селекторы и
   эвристики живут за вашим API. Клиент только отображает и выполняет.
2. **То, что уходит клиенту, уходит без карты.** Никаких публичных source maps, код минифицирован,
   без комментариев, без `console`, без внутренних имён, без отладочных маршрутов.
3. **Сервер никогда не доверяет клиенту.** Лицензии, права владения, лимиты и цены
   перепроверяются при каждом запросе.
4. **То, что обязано остаться на клиенте, делается дорогим для анализа и отслеживаемым.** Точечная обфускация
   там, где это разрешают магазины, водяные знаки для каждого клиента, canary-записи.
5. **Атакуйте себя до выпуска.** Запустите аудит и REA на финальном артефакте.
   Если REA может объяснить, как функция принимает решения, то сможет и конкурент.

### Что проверяет аудит

| Проверка | Уровень |
|---|---|
| Файлы `.map` в артефакте, встроенные карты, публичные карты на рабочем сайте, `asset-manifest.json` со списком карт | CRITICAL |
| Серверные секреты: AWS, приватные ключи, `sk_live_`, ключи LLM-провайдеров, токены GitHub/Slack, URL баз данных с паролями, сервисные аккаунты | CRITICAL (маскируются в выводе) |
| Открытые `/.git/` и `/.env` на рабочем сайте | CRITICAL |
| Оставшиеся в коде комментарии `sourceMappingURL` | WARNING |
| Ключи Google/Firebase, зашитые в код JWT | WARNING |
| `localhost`, приватные IP, хосты staging/homolog | WARNING |
| AI-промпты, отправленные на клиент (`You are…`, `systemPrompt`, `role: "system"`) | WARNING |
| Ваши собственные бизнес-термины (`SHIELD_TERMS`) | WARNING |
| Неминифицированные файлы, забытые `console.log`/`debugger` | WARNING |
| Бандл React Native, не скомпилированный в байт-код Hermes | WARNING |
| Эндпоинты Swagger/OpenAPI/GraphQL, доступные на рабочем сайте | WARNING |

Входные данные: папки сборки, `.zip`, `.crx`, `.xpi`, `.apk`, `.aab`, `.ipa`, `.asar` или URL.

### Плейбуки по стекам

Навык поставляется с узконаправленными чек-листами, которые агент загружает, когда они актуальны:

| Стек | Плейбук |
|---|---|
| Веб-приложения (Vite, CRA, Next.js, webpack) | [web.md](.agents/skills/reverse-engineering-shield/references/web.md) |
| Расширения браузера (Chrome MV3, Firefox) | [extensions.md](.agents/skills/reverse-engineering-shield/references/extensions.md) |
| Мобильные (React Native/Expo, Android, iOS, Flutter) | [mobile.md](.agents/skills/reverse-engineering-shield/references/mobile.md) |
| Десктоп (Electron, Tauri, нативные, Python) | [desktop.md](.agents/skills/reverse-engineering-shield/references/desktop.md) |
| API и бэкенды | [api.md](.agents/skills/reverse-engineering-shield/references/api.md) |
| Боты и автоматизации | [server-driven.md](.agents/skills/reverse-engineering-shield/references/server-driven.md) |
| Водяные знаки, canary-записи, юридические аспекты | [traceability.md](.agents/skills/reverse-engineering-shield/references/traceability.md) |

## FAQ

**Разве нельзя просто всё обфусцировать?**
Обфускация, байт-код и пиннинг замедляют настойчивого аналитика, но не останавливают его.
Агенты терпеливы. Убрать ценность можно, только перенеся её на сервер. Кроме того, некоторые магазины
запрещают обфускацию — Chrome Web Store отклоняет обфусцированные расширения.

**Заменяет ли это аудит безопасности или пентест?**
Нет. Он охватывает то, что раскрывают ваши клиентские артефакты и публичная поверхность. Сочетайте его
с регулярной работой по безопасности.

**Можно ли запускать режим URL для любого сайта?**
Только для доменов, которыми вы владеете или на тестирование которых у вас есть явное разрешение.

**Какие агенты поддерживаются?**
Любой агент, который загружает навыки `SKILL.md` (Claude Code, Codex, Cursor, Gemini CLI и другие).
Скрипт аудита написан на чистом Bash и работает везде, где есть `curl`, `unzip` и `grep`.

## Участие в разработке

Issues и pull requests приветствуются — особенно новые шаблоны секретов, стеки и плейбуки.
См. [CONTRIBUTING.md](CONTRIBUTING.md). Перед открытием PR запустите `bash tests/run.sh`.

## Лицензия

[MIT](LICENSE) © Chosing Dept. См. [DISCLAIMER.md](DISCLAIMER.md).
