<div align="center">

[English](README.md) · [简体中文](README_zh.md) · [繁體中文](README_zh-TW.md) · [日本語](README_ja.md) · [한국어](README_ko.md) · [Türkçe](README_tr.md) · [Русский](README_ru.md) · [Tiếng Việt](README_vi.md) · [ไทย](README_th.md) · [Deutsch](README_de.md) · [Español](README_es.md) · [Français](README_fr.md) · [Українська](README_uk.md) · [Polski](README_pl.md) · **Português (Brasil)** · [العربية](README_ar.md) · [فارسی](README_fa.md) · [Bahasa Indonesia](README_id.md) · [Italiano](README_it.md)

# Reverse Engineering Shield

### Torne a engenharia reversa inútil.

**Seu agente consegue ler qualquer app. O do seu concorrente também. Publique código que não vale nada ler.**

[![CI](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml/badge.svg)](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml)
[![MIT license](https://img.shields.io/badge/license-MIT-f4c430?style=flat-square)](LICENSE)
[![Agent skill](https://img.shields.io/badge/agent-skill-5c4ee5?style=flat-square)](.agents/skills/reverse-engineering-shield/SKILL.md)

<code>npx skills add ChosingDept/reverse-engineering-shield</code>

</div>

---

Ferramentas de agente como o [REA](https://github.com/morluto/rea) conseguem explicar como
funciona qualquer app web, extensão de navegador, app Electron, APK/IPA ou binário nativo —
em minutos, sem o código-fonte. Não há como impedir alguém de *ler* o que você publica.

**Reverse Engineering Shield** é uma skill de agente com um script de auditoria que torna
essa leitura inútil. Ela ensina seu agente de código (Claude Code, Codex, Cursor, Gemini CLI
e outros) a manter as partes valiosas no servidor, entregar o código do cliente sem mapas,
revalidar tudo no servidor, tornar o que sobra caro e rastreável — e a atacar o seu próprio
build antes de cada release.

Ela cobre **qualquer app em qualquer stack**: web, extensões de navegador, mobile,
desktop, .NET e JVM, jogos, WebAssembly, SDKs e pacotes, containers e instalações
on-premise, firmware/IoT, recursos de IA e modelos no dispositivo — e as APIs por trás de
todos eles.

## Início rápido

### Instale a skill

```bash
npx skills add ChosingDept/reverse-engineering-shield
```

Ou com o instalador (por padrão, copia a skill para `~/.claude/skills`):

```bash
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash
# another skills directory:
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash -s -- --dir ~/.codex/skills
```

Ou copie `.agents/skills/reverse-engineering-shield` para a pasta de skills do seu agente.

### Peça ao seu agente

> Revise este projeto com a reverse-engineering-shield antes de publicarmos a extensão.

> Nossa lógica de preços está no app React. Mova-a para trás da API seguindo a reverse-engineering-shield.

> Audite `dist/` e o nosso site de produção, depois corrija todo CRITICAL.

### Ou rode a auditoria você mesmo

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

O código de saída `2` bloqueia o release, `1` pede uma justificativa, `0` está limpo — pronto
para CI ([exemplo](docs/ci.md)).

## Como funciona

### Os cinco princípios

1. **O cérebro fica no servidor.** Regras, preços, scoring, prompts, seletores e
   heurísticas vivem atrás da sua API. O cliente renderiza e executa.
2. **O que vai para o cliente vai sem mapa.** Sem source maps públicos, minificado,
   sem comentários, sem `console`, sem nomes internos, sem rotas de debug.
3. **O servidor nunca confia no cliente.** Licenças, titularidade, limites e preços são
   revalidados a cada requisição.
4. **O que precisa ficar no cliente é caro e rastreável.** Ofuscação direcionada
   onde as lojas permitem, marcas d'água por cliente, registros canário.
5. **Ataque a si mesmo antes de publicar.** Rode a auditoria e o REA contra o artefato final.
   Se o REA consegue explicar como uma funcionalidade decide, um concorrente também consegue.

### O que a auditoria verifica

| Verificação | Severidade |
|---|---|
| Arquivos `.map` no artefato, mapas inline, mapas públicos no site em produção, `asset-manifest.json` listando mapas | CRITICAL |
| Segredos de servidor: AWS, chaves privadas, `sk_live_`, chaves de provedores de LLM, tokens do GitHub/Slack, URLs de banco de dados com senha, service accounts | CRITICAL (mascarados na saída) |
| `/.git/` e `/.env` expostos no site em produção | CRITICAL |
| Comentários `sourceMappingURL` deixados no código | WARNING |
| Chaves Google/Firebase, JWTs fixos no código | WARNING |
| `localhost`, IPs privados, hosts de staging/homologação | WARNING |
| Prompts de IA enviados ao cliente (`You are…`, `systemPrompt`, `role: "system"`) | WARNING |
| Seus próprios termos de negócio (`SHIELD_TERMS`) | WARNING |
| Arquivos não minificados, sobras de `console.log`/`debugger` | WARNING |
| Bundle React Native não compilado para bytecode Hermes | WARNING |
| Endpoints Swagger/OpenAPI/GraphQL acessíveis no site em produção | WARNING |

Entradas: pastas de build, `.zip`, `.crx`, `.xpi`, `.apk`, `.aab`, `.ipa`, `.asar` ou uma URL.

### Playbooks por stack

A skill traz checklists focados que o agente carrega quando relevantes:

| Stack | Playbook |
|---|---|
| Apps web (Vite, CRA, Next.js, webpack) | [web.md](.agents/skills/reverse-engineering-shield/references/web.md) |
| Extensões de navegador (Chrome MV3, Firefox) | [extensions.md](.agents/skills/reverse-engineering-shield/references/extensions.md) |
| Mobile (React Native/Expo, Android, iOS, Flutter) | [mobile.md](.agents/skills/reverse-engineering-shield/references/mobile.md) |
| Desktop (Electron, Tauri, nativo, Python) | [desktop.md](.agents/skills/reverse-engineering-shield/references/desktop.md) |
| .NET e JVM (C#, Java, Kotlin, Scala, bytecode Android) | [managed-runtimes.md](.agents/skills/reverse-engineering-shield/references/managed-runtimes.md) |
| Jogos (Unity, Unreal, Godot) | [games.md](.agents/skills/reverse-engineering-shield/references/games.md) |
| WebAssembly | [webassembly.md](.agents/skills/reverse-engineering-shield/references/webassembly.md) |
| SDKs, pacotes, containers, instalações on-premise | [packages.md](.agents/skills/reverse-engineering-shield/references/packages.md) |
| Firmware, embarcados, IoT | [embedded.md](.agents/skills/reverse-engineering-shield/references/embedded.md) |
| Recursos de IA e modelos no dispositivo | [ai-models.md](.agents/skills/reverse-engineering-shield/references/ai-models.md) |
| APIs e backends | [api.md](.agents/skills/reverse-engineering-shield/references/api.md) |
| Robôs e automações | [server-driven.md](.agents/skills/reverse-engineering-shield/references/server-driven.md) |
| Marcas d'água, canários, jurídico | [traceability.md](.agents/skills/reverse-engineering-shield/references/traceability.md) |

## FAQ

**Não posso simplesmente ofuscar tudo?**
Ofuscação, bytecode e pinning atrasam um analista determinado; não o impedem.
Agentes são pacientes. Só levar o valor para o servidor o elimina. Algumas lojas também
proíbem ofuscação — a Chrome Web Store rejeita extensões ofuscadas.

**Isso substitui revisões de segurança ou pentests?**
Não. Cobre o que seus artefatos de cliente e sua superfície pública revelam. Combine com
o trabalho regular de segurança.

**Posso rodar o modo URL contra qualquer site?**
Somente contra domínios que são seus ou que você tem autorização explícita para testar.

**Quais agentes são suportados?**
Qualquer agente que carregue skills `SKILL.md` (Claude Code, Codex, Cursor, Gemini CLI e
outros). O script de auditoria é Bash puro e roda em qualquer lugar com `curl`, `unzip` e `grep`.

## Contribuindo

Issues e pull requests são bem-vindos — especialmente novos padrões de segredos, stacks e
playbooks. Veja [CONTRIBUTING.md](CONTRIBUTING.md). Rode `bash tests/run.sh` antes de abrir um PR.

## Licença

[MIT](LICENSE) © Chosing Dept. Veja [DISCLAIMER.md](DISCLAIMER.md).
