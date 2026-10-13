<div align="center">

[English](README.md) · [简体中文](README_zh.md) · [繁體中文](README_zh-TW.md) · [日本語](README_ja.md) · [한국어](README_ko.md) · [Türkçe](README_tr.md) · [Русский](README_ru.md) · [Tiếng Việt](README_vi.md) · [ไทย](README_th.md) · **Deutsch** · [Español](README_es.md) · [Français](README_fr.md) · [Українська](README_uk.md) · [Polski](README_pl.md) · [Português (Brasil)](README_pt-BR.md) · [العربية](README_ar.md) · [فارسی](README_fa.md) · [Bahasa Indonesia](README_id.md) · [Italiano](README_it.md)

# Reverse Engineering Shield

### Machen Sie Reverse Engineering nutzlos.

**Ihr Agent kann jede App lesen. Der Ihrer Konkurrenz auch. Liefern Sie Code aus, dessen Lektüre wertlos ist.**

[![CI](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml/badge.svg)](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml)
[![MIT license](https://img.shields.io/badge/license-MIT-f4c430?style=flat-square)](LICENSE)
[![Agent skill](https://img.shields.io/badge/agent-skill-5c4ee5?style=flat-square)](.agents/skills/reverse-engineering-shield/SKILL.md)

<code>npx skills add ChosingDept/reverse-engineering-shield</code>

</div>

---

Agent-Werkzeuge wie [REA](https://github.com/morluto/rea) können erklären, wie jede Web-App,
Browser-Erweiterung, Electron-App, APK/IPA oder native Binärdatei funktioniert – in wenigen
Minuten und ohne Quellcode. Niemand lässt sich daran hindern, das zu *lesen*, was Sie ausliefern.

**Reverse Engineering Shield** ist ein Agent-Skill samt Audit-Skript, das dieses Lesen
sinnlos macht. Es bringt Ihrem Coding-Agent (Claude Code, Codex, Cursor, Gemini CLI und
anderen) bei, die wertvollen Teile auf dem Server zu behalten, Client-Code ohne Source Maps
auszuliefern, alles serverseitig erneut zu validieren, das Übrige teuer und nachverfolgbar
zu machen – und vor jedem Release den eigenen Build anzugreifen.

## Schnellstart

### Skill installieren

```bash
npx skills add ChosingDept/reverse-engineering-shield
```

Oder mit dem Installer (kopiert den Skill standardmäßig nach `~/.claude/skills`):

```bash
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash
# another skills directory:
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash -s -- --dir ~/.codex/skills
```

Oder kopieren Sie `.agents/skills/reverse-engineering-shield` in den Skills-Ordner Ihres Agents.

### Fragen Sie Ihren Agent

> Prüfe dieses Projekt mit reverse-engineering-shield, bevor wir die Erweiterung veröffentlichen.

> Unsere Preislogik steckt in der React-App. Verschiebe sie gemäß reverse-engineering-shield hinter die API.

> Prüfe `dist/` und unsere Produktivseite und behebe danach jedes CRITICAL.

### Oder führen Sie das Audit selbst aus

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

Exit-Code `2` blockiert das Release, `1` verlangt eine Begründung, `0` bedeutet sauber – bereit
für CI ([Beispiel](docs/ci.md)).

## So funktioniert es

### Die fünf Prinzipien

1. **Das Gehirn bleibt auf dem Server.** Regeln, Preise, Scoring, Prompts, Selektoren und
   Heuristiken liegen hinter Ihrer API. Der Client rendert und führt aus.
2. **Was an den Client geht, geht ohne Source Map.** Keine öffentlichen Source Maps, minifiziert,
   ohne Kommentare, ohne `console`, ohne interne Namen, ohne Debug-Routen.
3. **Der Server vertraut dem Client nie.** Lizenzen, Eigentümerschaft, Limits und Preise werden
   bei jeder Anfrage erneut validiert.
4. **Was auf dem Client bleiben muss, ist teuer und nachverfolgbar.** Gezielte Obfuskierung,
   wo die Stores sie erlauben, Wasserzeichen pro Kunde, Canary-Datensätze.
5. **Greifen Sie sich selbst an, bevor Sie ausliefern.** Führen Sie das Audit und REA gegen das
   finale Artefakt aus. Wenn REA erklären kann, wie ein Feature entscheidet, kann es auch ein Konkurrent.

### Was das Audit prüft

| Prüfung | Schweregrad |
|---|---|
| `.map`-Dateien im Artefakt, Inline-Maps, öffentliche Maps auf der Live-Seite, `asset-manifest.json` mit gelisteten Maps | CRITICAL |
| Server-Geheimnisse: AWS, private Schlüssel, `sk_live_`, Schlüssel von LLM-Anbietern, GitHub/Slack-Tokens, Datenbank-URLs mit Passwörtern, Service-Accounts | CRITICAL (in der Ausgabe maskiert) |
| `/.git/` und `/.env` auf der Live-Seite erreichbar | CRITICAL |
| Im Code verbliebene `sourceMappingURL`-Kommentare | WARNING |
| Google/Firebase-Schlüssel, fest codierte JWTs | WARNING |
| `localhost`, private IPs, Staging-/Homologations-Hosts | WARNING |
| An den Client ausgelieferte KI-Prompts (`You are…`, `systemPrompt`, `role: "system"`) | WARNING |
| Ihre eigenen Geschäftsbegriffe (`SHIELD_TERMS`) | WARNING |
| Nicht minifizierte Dateien, Überbleibsel von `console.log`/`debugger` | WARNING |
| React-Native-Bundle nicht zu Hermes-Bytecode kompiliert | WARNING |
| Swagger-/OpenAPI-/GraphQL-Endpunkte auf der Live-Seite erreichbar | WARNING |

Eingaben: Build-Ordner, `.zip`, `.crx`, `.xpi`, `.apk`, `.aab`, `.ipa`, `.asar` oder eine URL.

### Playbooks pro Stack

Der Skill enthält fokussierte Checklisten, die der Agent bei Bedarf lädt:

| Stack | Playbook |
|---|---|
| Web-Apps (Vite, CRA, Next.js, webpack) | [web.md](.agents/skills/reverse-engineering-shield/references/web.md) |
| Browser-Erweiterungen (Chrome MV3, Firefox) | [extensions.md](.agents/skills/reverse-engineering-shield/references/extensions.md) |
| Mobile (React Native/Expo, Android, iOS, Flutter) | [mobile.md](.agents/skills/reverse-engineering-shield/references/mobile.md) |
| Desktop (Electron, Tauri, nativ, Python) | [desktop.md](.agents/skills/reverse-engineering-shield/references/desktop.md) |
| APIs und Backends | [api.md](.agents/skills/reverse-engineering-shield/references/api.md) |
| Bots und Automatisierungen | [server-driven.md](.agents/skills/reverse-engineering-shield/references/server-driven.md) |
| Wasserzeichen, Canaries, Rechtliches | [traceability.md](.agents/skills/reverse-engineering-shield/references/traceability.md) |

## FAQ

**Kann ich nicht einfach alles obfuskieren?**
Obfuskierung, Bytecode und Pinning bremsen einen entschlossenen Analysten aus; aufhalten können sie ihn nicht.
Agents sind geduldig. Nur wenn Sie den Wert auf den Server verlagern, ist er wirklich weg. Manche Stores
verbieten Obfuskierung sogar – der Chrome Web Store lehnt obfuskierte Erweiterungen ab.

**Ersetzt das Security-Reviews oder Pentests?**
Nein. Es deckt ab, was Ihre Client-Artefakte und Ihre öffentliche Angriffsfläche preisgeben. Kombinieren Sie es mit
regelmäßiger Sicherheitsarbeit.

**Kann ich den URL-Modus gegen jede beliebige Seite ausführen?**
Nur gegen Domains, die Ihnen gehören oder für deren Test Sie ausdrücklich autorisiert sind.

**Welche Agents werden unterstützt?**
Jeder Agent, der `SKILL.md`-Skills lädt (Claude Code, Codex, Cursor, Gemini CLI und
andere). Das Audit-Skript ist reines Bash und läuft überall, wo `curl`, `unzip` und `grep` verfügbar sind.

## Mitwirken

Issues und Pull Requests sind willkommen – insbesondere neue Geheimnis-Muster, Stacks und Playbooks.
Siehe [CONTRIBUTING.md](CONTRIBUTING.md). Führen Sie `bash tests/run.sh` aus, bevor Sie einen PR eröffnen.

## Lizenz

[MIT](LICENSE) © Chosing Dept. Siehe [DISCLAIMER.md](DISCLAIMER.md).
