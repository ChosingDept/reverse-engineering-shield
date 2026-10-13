<div align="center">

**English** · [简体中文](README_zh.md) · [繁體中文](README_zh-TW.md) · [日本語](README_ja.md) · [한국어](README_ko.md) · [Türkçe](README_tr.md) · [Русский](README_ru.md) · [Tiếng Việt](README_vi.md) · [ไทย](README_th.md) · [Deutsch](README_de.md) · [Español](README_es.md) · [Français](README_fr.md) · [Українська](README_uk.md) · [Polski](README_pl.md) · [Português (Brasil)](README_pt-BR.md) · [العربية](README_ar.md) · [فارسی](README_fa.md) · [Bahasa Indonesia](README_id.md) · [Italiano](README_it.md)

# Reverse Engineering Shield

### Make reverse engineering useless.

**Your agent can read any app. So can your competitor's. Ship code that is worthless to read.**

[![CI](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml/badge.svg)](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml)
[![MIT license](https://img.shields.io/badge/license-MIT-f4c430?style=flat-square)](LICENSE)
[![Agent skill](https://img.shields.io/badge/agent-skill-5c4ee5?style=flat-square)](.agents/skills/reverse-engineering-shield/SKILL.md)

<code>npx skills add ChosingDept/reverse-engineering-shield</code>

</div>

---

Agent tooling such as [REA](https://github.com/morluto/rea) can explain how any web
app, browser extension, Electron app, APK/IPA or native binary works — in minutes,
without the source code. There is no way to stop someone from *reading* what you ship.

**Reverse Engineering Shield** is an agent skill plus an audit script that makes the
reading pointless. It teaches your coding agent (Claude Code, Codex, Cursor, Gemini CLI
and others) to keep the valuable parts on the server, ship client code without maps,
re-validate everything server-side, make what is left expensive and traceable — and to
attack your own build before every release.

## Quick start

### Install the skill

```bash
npx skills add ChosingDept/reverse-engineering-shield
```

Or with the installer (copies the skill to `~/.claude/skills` by default):

```bash
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash
# another skills directory:
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash -s -- --dir ~/.codex/skills
```

Or copy `.agents/skills/reverse-engineering-shield` into your agent's skills folder.

### Ask your agent

> Review this project with reverse-engineering-shield before we publish the extension.

> Our pricing logic is in the React app. Move it behind the API following reverse-engineering-shield.

> Audit `dist/` and our production site, then fix every CRITICAL.

### Or run the audit yourself

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

Exit code `2` blocks the release, `1` asks for a justification, `0` is clean — ready for
CI ([example](docs/ci.md)).

## How it works

### The five principles

1. **The brain stays on the server.** Rules, pricing, scoring, prompts, selectors and
   heuristics live behind your API. The client renders and executes.
2. **What ships to the client ships without a map.** No public source maps, minified,
   no comments, no `console`, no internal names, no debug routes.
3. **The server never trusts the client.** Licenses, ownership, limits and prices are
   re-validated on every request.
4. **What must stay on the client is expensive and traceable.** Targeted obfuscation
   where stores allow it, per-customer watermarks, canary records.
5. **Attack yourself before you ship.** Run the audit and REA against the final artifact.
   If REA can explain how a feature decides, so can a competitor.

### What the audit checks

| Check | Severity |
|---|---|
| `.map` files in the artifact, inline maps, public maps on the live site, `asset-manifest.json` listing maps | CRITICAL |
| Server secrets: AWS, private keys, `sk_live_`, LLM provider keys, GitHub/Slack tokens, database URLs with passwords, service accounts | CRITICAL (masked in output) |
| `/.git/` and `/.env` exposed on the live site | CRITICAL |
| `sourceMappingURL` comments left in code | WARNING |
| Google/Firebase keys, hard-coded JWTs | WARNING |
| `localhost`, private IPs, staging/homolog hosts | WARNING |
| AI prompts shipped to the client (`You are…`, `systemPrompt`, `role: "system"`) | WARNING |
| Your own business terms (`SHIELD_TERMS`) | WARNING |
| Unminified files, `console.log`/`debugger` leftovers | WARNING |
| React Native bundle not compiled to Hermes bytecode | WARNING |
| Swagger/OpenAPI/GraphQL endpoints reachable on the live site | WARNING |

Inputs: build folders, `.zip`, `.crx`, `.xpi`, `.apk`, `.aab`, `.ipa`, `.asar`, or a URL.

### Stack playbooks

The skill ships focused checklists the agent loads when relevant:

| Stack | Playbook |
|---|---|
| Web apps (Vite, CRA, Next.js, webpack) | [web.md](.agents/skills/reverse-engineering-shield/references/web.md) |
| Browser extensions (Chrome MV3, Firefox) | [extensions.md](.agents/skills/reverse-engineering-shield/references/extensions.md) |
| Mobile (React Native/Expo, Android, iOS, Flutter) | [mobile.md](.agents/skills/reverse-engineering-shield/references/mobile.md) |
| Desktop (Electron, Tauri, native, Python) | [desktop.md](.agents/skills/reverse-engineering-shield/references/desktop.md) |
| APIs and backends | [api.md](.agents/skills/reverse-engineering-shield/references/api.md) |
| Bots and automations | [server-driven.md](.agents/skills/reverse-engineering-shield/references/server-driven.md) |
| Watermarks, canaries, legal | [traceability.md](.agents/skills/reverse-engineering-shield/references/traceability.md) |

## FAQ

**Can't I just obfuscate everything?**
Obfuscation, bytecode and pinning delay a determined analyst; they do not stop one.
Agents are patient. Only moving the value to the server removes it. Some stores also
forbid obfuscation — the Chrome Web Store rejects obfuscated extensions.

**Does this replace security reviews or pentests?**
No. It covers what your client artifacts and public surface reveal. Pair it with
regular security work.

**Can I run the URL mode against any site?**
Only against domains you own or are explicitly authorized to test.

**Which agents are supported?**
Any agent that loads `SKILL.md` skills (Claude Code, Codex, Cursor, Gemini CLI and
others). The audit script is plain Bash and runs anywhere with `curl`, `unzip` and `grep`.

## Contributing

Issues and pull requests are welcome — new secret patterns, stacks and playbooks
especially. See [CONTRIBUTING.md](CONTRIBUTING.md). Run `bash tests/run.sh` before opening a PR.

## License

[MIT](LICENSE) © Chosing Dept. See [DISCLAIMER.md](DISCLAIMER.md).
