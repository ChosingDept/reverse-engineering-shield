<div align="center">

[English](README.md) · [简体中文](README_zh.md) · [繁體中文](README_zh-TW.md) · [日本語](README_ja.md) · [한국어](README_ko.md) · [Türkçe](README_tr.md) · [Русский](README_ru.md) · [Tiếng Việt](README_vi.md) · [ไทย](README_th.md) · [Deutsch](README_de.md) · [Español](README_es.md) · **Français** · [Українська](README_uk.md) · [Polski](README_pl.md) · [Português (Brasil)](README_pt-BR.md) · [العربية](README_ar.md) · [فارسی](README_fa.md) · [Bahasa Indonesia](README_id.md) · [Italiano](README_it.md)

# Reverse Engineering Shield

### Rendez la rétro-ingénierie inutile.

**Votre agent peut lire n'importe quelle app. Celui de vos concurrents aussi. Livrez du code qui ne vaut rien à lire.**

[![CI](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml/badge.svg)](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml)
[![MIT license](https://img.shields.io/badge/license-MIT-f4c430?style=flat-square)](LICENSE)
[![Agent skill](https://img.shields.io/badge/agent-skill-5c4ee5?style=flat-square)](.agents/skills/reverse-engineering-shield/SKILL.md)

<code>npx skills add ChosingDept/reverse-engineering-shield</code>

</div>

---

Des outils d'agents comme [REA](https://github.com/morluto/rea) peuvent expliquer le fonctionnement
de n'importe quelle app web, extension de navigateur, app Electron, APK/IPA ou binaire natif, en
quelques minutes et sans le code source. Impossible d'empêcher quelqu'un de *lire* ce que vous livrez.

**Reverse Engineering Shield** est une skill d'agent accompagnée d'un script d'audit qui rend cette
lecture vaine. Elle apprend à votre agent de code (Claude Code, Codex, Cursor, Gemini CLI et
d'autres) à garder les parties précieuses sur le serveur, à livrer le code client sans source maps,
à tout revalider côté serveur, à rendre ce qui reste coûteux et traçable, et à attaquer votre
propre build avant chaque release.

## Démarrage rapide

### Installer la skill

```bash
npx skills add ChosingDept/reverse-engineering-shield
```

Ou avec l'installateur (copie la skill dans `~/.claude/skills` par défaut) :

```bash
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash
# another skills directory:
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash -s -- --dir ~/.codex/skills
```

Ou copiez `.agents/skills/reverse-engineering-shield` dans le dossier de skills de votre agent.

### Demandez à votre agent

> Passe ce projet en revue avec reverse-engineering-shield avant que nous publiions l'extension.

> Notre logique de tarification se trouve dans l'app React. Déplace-la derrière l'API en suivant reverse-engineering-shield.

> Audite `dist/` et notre site de production, puis corrige chaque CRITICAL.

### Ou lancez l'audit vous-même

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

Le code de sortie `2` bloque la release, `1` demande une justification, `0` signifie que tout est
propre ; prêt pour la CI ([exemple](docs/ci.md)).

## Fonctionnement

### Les cinq principes

1. **Le cerveau reste sur le serveur.** Règles, tarifs, scoring, prompts, sélecteurs et
   heuristiques vivent derrière votre API. Le client affiche et exécute.
2. **Ce qui part vers le client part sans carte.** Pas de source maps publiques, code minifié,
   sans commentaires, sans `console`, sans noms internes, sans routes de débogage.
3. **Le serveur ne fait jamais confiance au client.** Licences, propriété, limites et prix sont
   revalidés à chaque requête.
4. **Ce qui doit rester côté client est coûteux et traçable.** Obfuscation ciblée là où
   les stores l'autorisent, filigranes par client, enregistrements canaris.
5. **Attaquez-vous avant de livrer.** Lancez l'audit et REA sur l'artefact final.
   Si REA peut expliquer comment une fonctionnalité prend ses décisions, un concurrent le peut aussi.

### Ce que vérifie l'audit

| Vérification | Sévérité |
|---|---|
| Fichiers `.map` dans l'artefact, maps inline, maps publiques sur le site en ligne, `asset-manifest.json` listant des maps | CRITICAL |
| Secrets serveur : AWS, clés privées, `sk_live_`, clés de fournisseurs de LLM, tokens GitHub/Slack, URL de bases de données avec mots de passe, comptes de service | CRITICAL (masqué dans la sortie) |
| `/.git/` et `/.env` exposés sur le site en ligne | CRITICAL |
| Commentaires `sourceMappingURL` laissés dans le code | WARNING |
| Clés Google/Firebase, JWT codés en dur | WARNING |
| `localhost`, IP privées, hôtes de staging/homologation | WARNING |
| Prompts d'IA livrés au client (`You are…`, `systemPrompt`, `role: "system"`) | WARNING |
| Vos propres termes métier (`SHIELD_TERMS`) | WARNING |
| Fichiers non minifiés, restes de `console.log`/`debugger` | WARNING |
| Bundle React Native non compilé en bytecode Hermes | WARNING |
| Endpoints Swagger/OpenAPI/GraphQL accessibles sur le site en ligne | WARNING |

Entrées : dossiers de build, `.zip`, `.crx`, `.xpi`, `.apk`, `.aab`, `.ipa`, `.asar` ou une URL.

### Playbooks par stack

La skill embarque des checklists ciblées que l'agent charge quand elles sont pertinentes :

| Stack | Playbook |
|---|---|
| Apps web (Vite, CRA, Next.js, webpack) | [web.md](.agents/skills/reverse-engineering-shield/references/web.md) |
| Extensions de navigateur (Chrome MV3, Firefox) | [extensions.md](.agents/skills/reverse-engineering-shield/references/extensions.md) |
| Mobile (React Native/Expo, Android, iOS, Flutter) | [mobile.md](.agents/skills/reverse-engineering-shield/references/mobile.md) |
| Desktop (Electron, Tauri, natif, Python) | [desktop.md](.agents/skills/reverse-engineering-shield/references/desktop.md) |
| API et backends | [api.md](.agents/skills/reverse-engineering-shield/references/api.md) |
| Bots et automatisations | [server-driven.md](.agents/skills/reverse-engineering-shield/references/server-driven.md) |
| Filigranes, canaris, aspects juridiques | [traceability.md](.agents/skills/reverse-engineering-shield/references/traceability.md) |

## FAQ

**Je ne peux pas tout simplement tout obfusquer ?**
L'obfuscation, le bytecode et le pinning ralentissent un analyste déterminé ; ils ne l'arrêtent pas.
Les agents sont patients. Seul le déplacement de la valeur vers le serveur la fait disparaître. Certains stores
interdisent d'ailleurs l'obfuscation : le Chrome Web Store rejette les extensions obfusquées.

**Est-ce que cela remplace les revues de sécurité ou les pentests ?**
Non. Cela couvre ce que révèlent vos artefacts client et votre surface publique. Associez-le à
un travail de sécurité régulier.

**Puis-je lancer le mode URL sur n'importe quel site ?**
Uniquement sur des domaines qui vous appartiennent ou que vous êtes explicitement autorisé à tester.

**Quels agents sont pris en charge ?**
Tout agent qui charge des skills `SKILL.md` (Claude Code, Codex, Cursor, Gemini CLI et
d'autres). Le script d'audit est en Bash pur et tourne partout où `curl`, `unzip` et `grep` sont disponibles.

## Contribuer

Les issues et pull requests sont les bienvenues, en particulier pour de nouveaux motifs de secrets, stacks et playbooks.
Voir [CONTRIBUTING.md](CONTRIBUTING.md). Lancez `bash tests/run.sh` avant d'ouvrir une PR.

## Licence

[MIT](LICENSE) © Chosing Dept. Voir [DISCLAIMER.md](DISCLAIMER.md).
