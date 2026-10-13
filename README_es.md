<div align="center">

[English](README.md) · [简体中文](README_zh.md) · [繁體中文](README_zh-TW.md) · [日本語](README_ja.md) · [한국어](README_ko.md) · [Türkçe](README_tr.md) · [Русский](README_ru.md) · [Tiếng Việt](README_vi.md) · [ไทย](README_th.md) · [Deutsch](README_de.md) · **Español** · [Français](README_fr.md) · [Українська](README_uk.md) · [Polski](README_pl.md) · [Português (Brasil)](README_pt-BR.md) · [العربية](README_ar.md) · [فارسی](README_fa.md) · [Bahasa Indonesia](README_id.md) · [Italiano](README_it.md)

# Reverse Engineering Shield

### Haz que la ingeniería inversa sea inútil.

**Tu agente puede leer cualquier app. El de tu competencia, también. Publica código que no valga nada leer.**

[![CI](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml/badge.svg)](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml)
[![MIT license](https://img.shields.io/badge/license-MIT-f4c430?style=flat-square)](LICENSE)
[![Agent skill](https://img.shields.io/badge/agent-skill-5c4ee5?style=flat-square)](.agents/skills/reverse-engineering-shield/SKILL.md)

<code>npx skills add ChosingDept/reverse-engineering-shield</code>

</div>

---

Herramientas de agentes como [REA](https://github.com/morluto/rea) pueden explicar cómo funciona
cualquier app web, extensión de navegador, app Electron, APK/IPA o binario nativo, en minutos
y sin el código fuente. No hay forma de impedir que alguien *lea* lo que publicas.

**Reverse Engineering Shield** es una skill para agentes más un script de auditoría que hace que
esa lectura no sirva de nada. Enseña a tu agente de programación (Claude Code, Codex, Cursor,
Gemini CLI y otros) a mantener las partes valiosas en el servidor, a publicar el código del cliente
sin source maps, a volver a validar todo en el servidor, a hacer que lo que quede sea caro y
rastreable, y a atacar tu propio build antes de cada release.

Cubre **cualquier app en cualquier stack**: web, extensiones de navegador, móvil, escritorio,
.NET y JVM, juegos, WebAssembly, SDKs y paquetes, contenedores e instalaciones on-premise,
firmware/IoT, funciones de IA y modelos que se ejecutan en el dispositivo, y las APIs que hay
detrás de todo ello.

## Inicio rápido

### Instala la skill

```bash
npx skills add ChosingDept/reverse-engineering-shield
```

O con el instalador (copia la skill a `~/.claude/skills` por defecto):

```bash
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash
# another skills directory:
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash -s -- --dir ~/.codex/skills
```

O copia `.agents/skills/reverse-engineering-shield` en la carpeta de skills de tu agente.

### Pídeselo a tu agente

> Revisa este proyecto con reverse-engineering-shield antes de publicar la extensión.

> Nuestra lógica de precios está en la app de React. Muévela detrás de la API siguiendo reverse-engineering-shield.

> Audita `dist/` y nuestro sitio de producción, y luego corrige cada CRITICAL.

### O ejecuta la auditoría tú mismo

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

El código de salida `2` bloquea el release, `1` pide una justificación y `0` indica que está limpio;
listo para CI ([ejemplo](docs/ci.md)).

## Cómo funciona

### Los cinco principios

1. **El cerebro se queda en el servidor.** Reglas, precios, scoring, prompts, selectores y
   heurísticas viven detrás de tu API. El cliente renderiza y ejecuta.
2. **Lo que llega al cliente llega sin mapa.** Sin source maps públicos, minificado,
   sin comentarios, sin `console`, sin nombres internos, sin rutas de depuración.
3. **El servidor nunca confía en el cliente.** Licencias, titularidad, límites y precios se
   vuelven a validar en cada petición.
4. **Lo que tiene que quedarse en el cliente es caro y rastreable.** Ofuscación selectiva
   donde las tiendas lo permitan, marcas de agua por cliente, registros canario.
5. **Atácate a ti mismo antes de publicar.** Ejecuta la auditoría y REA contra el artefacto final.
   Si REA puede explicar cómo decide una funcionalidad, también puede hacerlo un competidor.

### Qué comprueba la auditoría

| Comprobación | Severidad |
|---|---|
| Archivos `.map` en el artefacto, mapas inline, mapas públicos en el sitio en producción, `asset-manifest.json` que lista mapas | CRITICAL |
| Secretos de servidor: AWS, claves privadas, `sk_live_`, claves de proveedores de LLM, tokens de GitHub/Slack, URLs de bases de datos con contraseñas, cuentas de servicio | CRITICAL (enmascarado en la salida) |
| `/.git/` y `/.env` expuestos en el sitio en producción | CRITICAL |
| Comentarios `sourceMappingURL` olvidados en el código | WARNING |
| Claves de Google/Firebase, JWT escritos en el código | WARNING |
| `localhost`, IPs privadas, hosts de staging/homologación | WARNING |
| Prompts de IA enviados al cliente (`You are…`, `systemPrompt`, `role: "system"`) | WARNING |
| Tus propios términos de negocio (`SHIELD_TERMS`) | WARNING |
| Archivos sin minificar, restos de `console.log`/`debugger` | WARNING |
| Bundle de React Native no compilado a bytecode de Hermes | WARNING |
| Endpoints de Swagger/OpenAPI/GraphQL accesibles en el sitio en producción | WARNING |

Entradas: carpetas de build, `.zip`, `.crx`, `.xpi`, `.apk`, `.aab`, `.ipa`, `.asar` o una URL.

### Playbooks por stack

La skill incluye checklists específicas que el agente carga cuando son relevantes:

| Stack | Playbook |
|---|---|
| Apps web (Vite, CRA, Next.js, webpack) | [web.md](.agents/skills/reverse-engineering-shield/references/web.md) |
| Extensiones de navegador (Chrome MV3, Firefox) | [extensions.md](.agents/skills/reverse-engineering-shield/references/extensions.md) |
| Móvil (React Native/Expo, Android, iOS, Flutter) | [mobile.md](.agents/skills/reverse-engineering-shield/references/mobile.md) |
| Escritorio (Electron, Tauri, nativo, Python) | [desktop.md](.agents/skills/reverse-engineering-shield/references/desktop.md) |
| .NET y JVM (C#, Java, Kotlin, Scala, bytecode de Android) | [managed-runtimes.md](.agents/skills/reverse-engineering-shield/references/managed-runtimes.md) |
| Juegos (Unity, Unreal, Godot) | [games.md](.agents/skills/reverse-engineering-shield/references/games.md) |
| WebAssembly | [webassembly.md](.agents/skills/reverse-engineering-shield/references/webassembly.md) |
| SDKs, paquetes, contenedores, instalaciones on-premise | [packages.md](.agents/skills/reverse-engineering-shield/references/packages.md) |
| Firmware, sistemas embebidos, IoT | [embedded.md](.agents/skills/reverse-engineering-shield/references/embedded.md) |
| Funciones de IA y modelos en el dispositivo | [ai-models.md](.agents/skills/reverse-engineering-shield/references/ai-models.md) |
| APIs y backends | [api.md](.agents/skills/reverse-engineering-shield/references/api.md) |
| Bots y automatizaciones | [server-driven.md](.agents/skills/reverse-engineering-shield/references/server-driven.md) |
| Marcas de agua, canarios, aspectos legales | [traceability.md](.agents/skills/reverse-engineering-shield/references/traceability.md) |

## Preguntas frecuentes

**¿No puedo simplemente ofuscarlo todo?**
La ofuscación, el bytecode y el pinning retrasan a un analista decidido; no lo detienen.
Los agentes son pacientes. Solo trasladar el valor al servidor lo elimina. Además, algunas tiendas
prohíben la ofuscación: la Chrome Web Store rechaza las extensiones ofuscadas.

**¿Sustituye esto a las revisiones de seguridad o los pentests?**
No. Cubre lo que revelan tus artefactos de cliente y tu superficie pública. Combínalo con
un trabajo de seguridad periódico.

**¿Puedo usar el modo URL contra cualquier sitio?**
Solo contra dominios que sean tuyos o que tengas autorización explícita para probar.

**¿Qué agentes son compatibles?**
Cualquier agente que cargue skills `SKILL.md` (Claude Code, Codex, Cursor, Gemini CLI y
otros). El script de auditoría es Bash puro y funciona en cualquier lugar con `curl`, `unzip` y `grep`.

## Contribuir

Los issues y pull requests son bienvenidos, sobre todo nuevos patrones de secretos, stacks y playbooks.
Consulta [CONTRIBUTING.md](CONTRIBUTING.md). Ejecuta `bash tests/run.sh` antes de abrir un PR.

## Licencia

[MIT](LICENSE) © Chosing Dept. Consulta [DISCLAIMER.md](DISCLAIMER.md).
