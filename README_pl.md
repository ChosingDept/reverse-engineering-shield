<div align="center">

[English](README.md) · [简体中文](README_zh.md) · [繁體中文](README_zh-TW.md) · [日本語](README_ja.md) · [한국어](README_ko.md) · [Türkçe](README_tr.md) · [Русский](README_ru.md) · [Tiếng Việt](README_vi.md) · [ไทย](README_th.md) · [Deutsch](README_de.md) · [Español](README_es.md) · [Français](README_fr.md) · [Українська](README_uk.md) · **Polski** · [Português (Brasil)](README_pt-BR.md) · [العربية](README_ar.md) · [فارسی](README_fa.md) · [Bahasa Indonesia](README_id.md) · [Italiano](README_it.md)

# Reverse Engineering Shield

### Spraw, by inżynieria wsteczna była bezużyteczna.

**Twój agent potrafi odczytać każdą aplikację. Agent konkurencji też. Wydawaj kod, którego czytanie nic nie daje.**

[![CI](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml/badge.svg)](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml)
[![MIT license](https://img.shields.io/badge/license-MIT-f4c430?style=flat-square)](LICENSE)
[![Agent skill](https://img.shields.io/badge/agent-skill-5c4ee5?style=flat-square)](.agents/skills/reverse-engineering-shield/SKILL.md)

<code>npx skills add ChosingDept/reverse-engineering-shield</code>

</div>

---

Narzędzia agentowe takie jak [REA](https://github.com/morluto/rea) potrafią w kilka minut,
bez kodu źródłowego, wyjaśnić, jak działa dowolna aplikacja webowa, rozszerzenie
przeglądarki, aplikacja Electron, APK/IPA czy natywna binarka. Nie da się powstrzymać
nikogo przed *czytaniem* tego, co wydajesz.

**Reverse Engineering Shield** to skill dla agenta wraz ze skryptem audytu, który sprawia,
że takie czytanie traci sens. Uczy twojego agenta programistycznego (Claude Code, Codex,
Cursor, Gemini CLI i innych), by trzymał wartościowe elementy na serwerze, wydawał kod
klienta bez map, ponownie walidował wszystko po stronie serwera, czynił to, co zostaje,
kosztownym w analizie i możliwym do namierzenia — a przed każdym wydaniem atakował twój
własny build.

Obejmuje **dowolną aplikację w dowolnym stosie**: web, rozszerzenia przeglądarki,
aplikacje mobilne, desktopowe, .NET i JVM, gry, WebAssembly, SDK i pakiety, kontenery i
instalacje on-premise, firmware/IoT, funkcje AI i modele działające na urządzeniu — oraz
API, które stoją za nimi wszystkimi.

## Szybki start

### Zainstaluj skill

```bash
npx skills add ChosingDept/reverse-engineering-shield
```

Albo za pomocą instalatora (domyślnie kopiuje skill do `~/.claude/skills`):

```bash
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash
# another skills directory:
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash -s -- --dir ~/.codex/skills
```

Albo skopiuj `.agents/skills/reverse-engineering-shield` do folderu skilli swojego agenta.

### Poproś swojego agenta

> Przejrzyj ten projekt za pomocą reverse-engineering-shield, zanim opublikujemy rozszerzenie.

> Nasza logika cenowa jest w aplikacji React. Przenieś ją za API zgodnie z reverse-engineering-shield.

> Zrób audyt `dist/` i naszej strony produkcyjnej, a potem napraw każdy CRITICAL.

### Albo uruchom audyt samodzielnie

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

Kod wyjścia `2` blokuje wydanie, `1` wymaga uzasadnienia, `0` oznacza czysty wynik — gotowe
do CI ([przykład](docs/ci.md)).

## Jak to działa

### Pięć zasad

1. **Mózg zostaje na serwerze.** Reguły, cenniki, scoring, prompty, selektory i
   heurystyki żyją za twoim API. Klient renderuje i wykonuje.
2. **To, co trafia do klienta, trafia tam bez mapy.** Bez publicznych source map, kod
   zminifikowany, bez komentarzy, bez `console`, bez wewnętrznych nazw, bez tras debugowych.
3. **Serwer nigdy nie ufa klientowi.** Licencje, własność zasobów, limity i ceny są
   ponownie walidowane przy każdym żądaniu.
4. **To, co musi zostać po stronie klienta, jest kosztowne i możliwe do namierzenia.**
   Celowana obfuskacja tam, gdzie sklepy na nią pozwalają, znaki wodne per klient,
   rekordy-pułapki (canary).
5. **Zaatakuj się, zanim wydasz.** Uruchom audyt i REA na finalnym artefakcie.
   Jeśli REA potrafi wyjaśnić, jak funkcja podejmuje decyzje, potrafi to też konkurencja.

### Co sprawdza audyt

| Kontrola | Poziom |
|---|---|
| Pliki `.map` w artefakcie, mapy inline, publiczne mapy na działającej stronie, `asset-manifest.json` z listą map | CRITICAL |
| Sekrety serwerowe: AWS, klucze prywatne, `sk_live_`, klucze dostawców LLM, tokeny GitHub/Slack, adresy URL baz danych z hasłami, konta serwisowe | CRITICAL (maskowane w wyniku) |
| `/.git/` i `/.env` wystawione na działającej stronie | CRITICAL |
| Komentarze `sourceMappingURL` pozostawione w kodzie | WARNING |
| Klucze Google/Firebase, wpisane na sztywno JWT | WARNING |
| `localhost`, prywatne adresy IP, hosty staging/homolog | WARNING |
| Prompty AI wysłane do klienta (`You are…`, `systemPrompt`, `role: "system"`) | WARNING |
| Twoje własne terminy biznesowe (`SHIELD_TERMS`) | WARNING |
| Niezminifikowane pliki, pozostałości `console.log`/`debugger` | WARNING |
| Bundle React Native nieskompilowany do bajtkodu Hermes | WARNING |
| Endpointy Swagger/OpenAPI/GraphQL dostępne na działającej stronie | WARNING |

Wejście: foldery z buildem, `.zip`, `.crx`, `.xpi`, `.apk`, `.aab`, `.ipa`, `.asar` lub adres URL.

### Playbooki dla stacków

Skill zawiera ukierunkowane checklisty, które agent wczytuje, gdy są potrzebne:

| Stack | Playbook |
|---|---|
| Aplikacje webowe (Vite, CRA, Next.js, webpack) | [web.md](.agents/skills/reverse-engineering-shield/references/web.md) |
| Rozszerzenia przeglądarki (Chrome MV3, Firefox) | [extensions.md](.agents/skills/reverse-engineering-shield/references/extensions.md) |
| Mobile (React Native/Expo, Android, iOS, Flutter) | [mobile.md](.agents/skills/reverse-engineering-shield/references/mobile.md) |
| Desktop (Electron, Tauri, natywne, Python) | [desktop.md](.agents/skills/reverse-engineering-shield/references/desktop.md) |
| .NET i JVM (C#, Java, Kotlin, Scala, bajtkod Androida) | [managed-runtimes.md](.agents/skills/reverse-engineering-shield/references/managed-runtimes.md) |
| Gry (Unity, Unreal, Godot) | [games.md](.agents/skills/reverse-engineering-shield/references/games.md) |
| WebAssembly | [webassembly.md](.agents/skills/reverse-engineering-shield/references/webassembly.md) |
| SDK, pakiety, kontenery, instalacje on-premise | [packages.md](.agents/skills/reverse-engineering-shield/references/packages.md) |
| Firmware, systemy wbudowane, IoT | [embedded.md](.agents/skills/reverse-engineering-shield/references/embedded.md) |
| Funkcje AI i modele na urządzeniu | [ai-models.md](.agents/skills/reverse-engineering-shield/references/ai-models.md) |
| API i backendy | [api.md](.agents/skills/reverse-engineering-shield/references/api.md) |
| Boty i automatyzacje | [server-driven.md](.agents/skills/reverse-engineering-shield/references/server-driven.md) |
| Znaki wodne, canary, kwestie prawne | [traceability.md](.agents/skills/reverse-engineering-shield/references/traceability.md) |

## FAQ

**Czy nie mogę po prostu wszystkiego zaciemnić?**
Obfuskacja, bajtkod i pinning opóźniają zdeterminowanego analityka; nie zatrzymują go.
Agenci są cierpliwi. Tylko przeniesienie wartości na serwer ją usuwa. Niektóre sklepy
wręcz zabraniają obfuskacji — Chrome Web Store odrzuca zaciemnione rozszerzenia.

**Czy to zastępuje przeglądy bezpieczeństwa lub pentesty?**
Nie. Obejmuje to, co ujawniają twoje artefakty klienckie i publiczna powierzchnia.
Łącz to z regularnymi pracami nad bezpieczeństwem.

**Czy mogę uruchomić tryb URL na dowolnej stronie?**
Tylko na domenach, które posiadasz lub do testowania których masz wyraźne upoważnienie.

**Którzy agenci są obsługiwani?**
Każdy agent, który wczytuje skille `SKILL.md` (Claude Code, Codex, Cursor, Gemini CLI i
inni). Skrypt audytu to czysty Bash i działa wszędzie, gdzie są `curl`, `unzip` i `grep`.

## Współtworzenie

Issues i pull requesty są mile widziane — zwłaszcza nowe wzorce sekretów, stacki i
playbooki. Zobacz [CONTRIBUTING.md](CONTRIBUTING.md). Przed otwarciem PR uruchom `bash tests/run.sh`.

## Licencja

[MIT](LICENSE) © Chosing Dept. Zobacz [DISCLAIMER.md](DISCLAIMER.md).
