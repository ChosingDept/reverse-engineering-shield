---
name: reverse-engineering-shield
description: Make reverse engineering useless for any project that ships code to users (web apps, browser extensions, mobile apps, Electron, APIs). Use when writing or refactoring client-side code, configuring production builds, designing bots or business rules, or before publishing a site, extension or app. Includes a build audit script and a self-attack step with REA.
metadata:
  version: "1.0.0"
---

# Reverse Engineering Shield

Every byte you ship to a client can be read. Agent tooling such as
[REA](https://github.com/morluto/rea) explains a web app, an extension, an Electron
bundle, an APK/IPA or a native binary in minutes. The goal is not to *prevent* reading;
it is to make **reading worthless**: the valuable part lives on the server, what ships
to the client ships without a map, what is left is expensive to understand and
traceable to whoever leaked it.

A common real-world failure: production builds that publish `.js.map` files with
`sourcesContent`. Anyone can rebuild the full original source — file names, comments,
business rules, vendor code — from what the site hands to every visitor.

## The five principles (in order of importance)

1. **The brain stays on the server.** Business rules, pricing, scoring, AI prompts,
   model weights, scraping selectors, partner lists and heuristics live behind your API.
   The client renders screens and executes orders.
2. **What ships to the client ships without a map.** No public source maps, minified,
   no comments, no `console`, no internal names, no debug routes.
3. **The server never trusts the client.** Every decision is re-validated server-side
   (license, ownership, limits, price). A modified client can do nothing the original can't.
4. **What must stay on the client is expensive and traceable.** Obfuscate only the
   sensitive code that cannot move; watermark builds per customer/tenant.
5. **Attack yourself before you ship.** Run `scripts/audit.sh` and REA against the final
   artifact. If REA can explain how a feature decides, so can a competitor.

## Workflow

1. **Classify** what you are writing with the table below. Anything in the right column
   that "needs" to be on the client means the design is wrong — move it to an endpoint
   that returns only the result.
2. **Apply the stack checklist** in `references/` for every artifact you produce:
   - Web SPA (Vite, CRA, Next.js, webpack): [references/web.md](references/web.md)
   - Browser extensions (Chrome MV3, Firefox): [references/extensions.md](references/extensions.md)
   - Mobile (React Native/Expo, native Android/iOS, Flutter): [references/mobile.md](references/mobile.md)
   - Desktop (Electron, Tauri, native, Python): [references/desktop.md](references/desktop.md)
   - APIs and backends: [references/api.md](references/api.md)
   - Bots, automations and robots acting on third-party sites: [references/server-driven.md](references/server-driven.md)
   - Watermarks, canaries and legal: [references/traceability.md](references/traceability.md)
3. **Gate the release** with the audit and the REA self-attack (below). Record the
   result in the PR or release notes.

## What may and may not ship to the client

| May ship to the client | Never ships to the client |
|---|---|
| Layout, components, UI copy | Pricing, bidding, scoring, ranking or risk rules |
| Form validation (repeated on the server) | AI prompts, system prompts, few-shot examples, RAG logic |
| Keys that are public by design (Firebase web config, Stripe `pk_`, domain-restricted Maps keys) | Secret keys (`sk_`, AWS, database URLs, JWT secrets, LLM provider keys, service accounts) |
| Feature flag identifiers | Full selector maps, partner lists, bot parameters |
| Calls to **your** API | Direct calls to paid providers (LLM, OCR, data vendors) |
| The current user's own data | Other tenants' data, fields the screen does not use |

## Release gate

```bash
# 1. Audit the artifact that actually ships (folder, .zip, .crx, .xpi, .apk, .ipa, .asar)
scripts/audit.sh path/to/dist
SHIELD_TERMS="pricing,margin,You are" scripts/audit.sh path/to/dist   # your own business terms

# 2. Audit what your live site serves (only domains you own or are authorized to test)
scripts/audit.sh https://your-domain.example

# 3. Attack yourself the way a competitor would
npx -y rea-agents analyze-javascript-application /absolute/path/to/dist --json
```

Exit codes: `2` = at least one CRITICAL (block the release), `1` = WARNING only
(justify or fix), `0` = clean. Then ask: *"Can I explain how feature X decides by
reading this output?"* If yes, that decision is still on the client.

## Questions to ask on every review

- Does the code I am writing on the client reveal **how** we decide something? → server.
- If someone copied this bundle tomorrow, what would they get besides the UI?
- Can a tampered client do anything the server does not re-validate?
- Does the final artifact contain a `.map`, a secret, a prompt, an internal URL, a table name?

## Limits

Obfuscation, Hermes bytecode, R8, certificate pinning and root detection **delay** a
determined attacker; they do not stop one. Only principle 1 removes the value. Use the
rest to raise the cost and to prove copying.
