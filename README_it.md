<div align="center">

[English](README.md) · [简体中文](README_zh.md) · [繁體中文](README_zh-TW.md) · [日本語](README_ja.md) · [한국어](README_ko.md) · [Türkçe](README_tr.md) · [Русский](README_ru.md) · [Tiếng Việt](README_vi.md) · [ไทย](README_th.md) · [Deutsch](README_de.md) · [Español](README_es.md) · [Français](README_fr.md) · [Українська](README_uk.md) · [Polski](README_pl.md) · [Português (Brasil)](README_pt-BR.md) · [العربية](README_ar.md) · [فارسی](README_fa.md) · [Bahasa Indonesia](README_id.md) · **Italiano**

# Reverse Engineering Shield

### Rendi inutile il reverse engineering.

**Il tuo agente può leggere qualsiasi app. Anche quello del tuo concorrente. Rilascia codice che non vale la pena leggere.**

[![CI](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml/badge.svg)](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml)
[![MIT license](https://img.shields.io/badge/license-MIT-f4c430?style=flat-square)](LICENSE)
[![Agent skill](https://img.shields.io/badge/agent-skill-5c4ee5?style=flat-square)](.agents/skills/reverse-engineering-shield/SKILL.md)

<code>npx skills add ChosingDept/reverse-engineering-shield</code>

</div>

---

Strumenti per agenti come [REA](https://github.com/morluto/rea) possono spiegare come
funziona qualsiasi web app, estensione del browser, app Electron, APK/IPA o binario
nativo — in pochi minuti, senza il codice sorgente. Non c'è modo di impedire a qualcuno
di *leggere* ciò che rilasci.

**Reverse Engineering Shield** è una skill per agenti con uno script di audit che rende
questa lettura inutile. Insegna al tuo agente di programmazione (Claude Code, Codex,
Cursor, Gemini CLI e altri) a tenere le parti di valore sul server, rilasciare il codice
client senza mappe, ri-validare tutto lato server, rendere ciò che resta costoso e
tracciabile — e ad attaccare la tua stessa build prima di ogni release.

## Avvio rapido

### Installa la skill

```bash
npx skills add ChosingDept/reverse-engineering-shield
```

Oppure con l'installer (per impostazione predefinita copia la skill in `~/.claude/skills`):

```bash
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash
# another skills directory:
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash -s -- --dir ~/.codex/skills
```

Oppure copia `.agents/skills/reverse-engineering-shield` nella cartella delle skill del tuo agente.

### Chiedi al tuo agente

> Rivedi questo progetto con reverse-engineering-shield prima di pubblicare l'estensione.

> La nostra logica dei prezzi è nell'app React. Spostala dietro l'API seguendo reverse-engineering-shield.

> Fai l'audit di `dist/` e del nostro sito di produzione, poi correggi ogni CRITICAL.

### Oppure esegui tu l'audit

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

L'exit code `2` blocca la release, `1` richiede una giustificazione, `0` è pulito — pronto
per la CI ([esempio](docs/ci.md)).

## Come funziona

### I cinque principi

1. **Il cervello resta sul server.** Regole, prezzi, scoring, prompt, selettori ed
   euristiche vivono dietro la tua API. Il client renderizza ed esegue.
2. **Ciò che va al client ci va senza mappa.** Niente source map pubbliche, codice
   minificato, niente commenti, niente `console`, niente nomi interni, niente route di debug.
3. **Il server non si fida mai del client.** Licenze, titolarità, limiti e prezzi vengono
   ri-validati a ogni richiesta.
4. **Ciò che deve restare sul client è costoso e tracciabile.** Offuscamento mirato
   dove gli store lo consentono, watermark per cliente, record canary.
5. **Attacca te stesso prima di rilasciare.** Esegui l'audit e REA sull'artefatto finale.
   Se REA riesce a spiegare come una funzionalità decide, ci riesce anche un concorrente.

### Cosa controlla l'audit

| Controllo | Gravità |
|---|---|
| File `.map` nell'artefatto, mappe inline, mappe pubbliche sul sito live, `asset-manifest.json` che elenca mappe | CRITICAL |
| Segreti del server: AWS, chiavi private, `sk_live_`, chiavi dei provider LLM, token GitHub/Slack, URL di database con password, service account | CRITICAL (mascherati nell'output) |
| `/.git/` e `/.env` esposti sul sito live | CRITICAL |
| Commenti `sourceMappingURL` lasciati nel codice | WARNING |
| Chiavi Google/Firebase, JWT hard-coded | WARNING |
| `localhost`, IP privati, host di staging/collaudo | WARNING |
| Prompt AI inviati al client (`You are…`, `systemPrompt`, `role: "system"`) | WARNING |
| I tuoi termini di business (`SHIELD_TERMS`) | WARNING |
| File non minificati, residui di `console.log`/`debugger` | WARNING |
| Bundle React Native non compilato in bytecode Hermes | WARNING |
| Endpoint Swagger/OpenAPI/GraphQL raggiungibili sul sito live | WARNING |

Input: cartelle di build, `.zip`, `.crx`, `.xpi`, `.apk`, `.aab`, `.ipa`, `.asar` o un URL.

### Playbook per stack

La skill include checklist mirate che l'agente carica quando servono:

| Stack | Playbook |
|---|---|
| Web app (Vite, CRA, Next.js, webpack) | [web.md](.agents/skills/reverse-engineering-shield/references/web.md) |
| Estensioni del browser (Chrome MV3, Firefox) | [extensions.md](.agents/skills/reverse-engineering-shield/references/extensions.md) |
| Mobile (React Native/Expo, Android, iOS, Flutter) | [mobile.md](.agents/skills/reverse-engineering-shield/references/mobile.md) |
| Desktop (Electron, Tauri, nativo, Python) | [desktop.md](.agents/skills/reverse-engineering-shield/references/desktop.md) |
| API e backend | [api.md](.agents/skills/reverse-engineering-shield/references/api.md) |
| Bot e automazioni | [server-driven.md](.agents/skills/reverse-engineering-shield/references/server-driven.md) |
| Watermark, canary, aspetti legali | [traceability.md](.agents/skills/reverse-engineering-shield/references/traceability.md) |

## FAQ

**Non posso semplicemente offuscare tutto?**
Offuscamento, bytecode e pinning rallentano un analista determinato; non lo fermano.
Gli agenti sono pazienti. Solo spostare il valore sul server lo elimina. Alcuni store
vietano inoltre l'offuscamento — il Chrome Web Store rifiuta le estensioni offuscate.

**Sostituisce le security review o i pentest?**
No. Copre ciò che rivelano i tuoi artefatti client e la tua superficie pubblica.
Affiancalo al regolare lavoro di sicurezza.

**Posso usare la modalità URL su qualsiasi sito?**
Solo su domini di tua proprietà o che sei esplicitamente autorizzato a testare.

**Quali agenti sono supportati?**
Qualsiasi agente che carichi skill `SKILL.md` (Claude Code, Codex, Cursor, Gemini CLI e
altri). Lo script di audit è puro Bash e gira ovunque ci siano `curl`, `unzip` e `grep`.

## Contribuire

Issue e pull request sono benvenute — in particolare nuovi pattern di segreti, stack e
playbook. Vedi [CONTRIBUTING.md](CONTRIBUTING.md). Esegui `bash tests/run.sh` prima di aprire una PR.

## Licenza

[MIT](LICENSE) © Chosing Dept. Vedi [DISCLAIMER.md](DISCLAIMER.md).
