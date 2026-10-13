<div align="center">

[English](README.md) · **简体中文** · [繁體中文](README_zh-TW.md) · [日本語](README_ja.md) · [한국어](README_ko.md) · [Türkçe](README_tr.md) · [Русский](README_ru.md) · [Tiếng Việt](README_vi.md) · [ไทย](README_th.md) · [Deutsch](README_de.md) · [Español](README_es.md) · [Français](README_fr.md) · [Українська](README_uk.md) · [Polski](README_pl.md) · [Português (Brasil)](README_pt-BR.md) · [العربية](README_ar.md) · [فارسی](README_fa.md) · [Bahasa Indonesia](README_id.md) · [Italiano](README_it.md)

# Reverse Engineering Shield

### 让逆向工程变得毫无意义。

**你的 agent 能读懂任何应用，你竞争对手的 agent 也一样。那就发布不值得一读的代码。**

[![CI](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml/badge.svg)](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml)
[![MIT license](https://img.shields.io/badge/license-MIT-f4c430?style=flat-square)](LICENSE)
[![Agent skill](https://img.shields.io/badge/agent-skill-5c4ee5?style=flat-square)](.agents/skills/reverse-engineering-shield/SKILL.md)

<code>npx skills add ChosingDept/reverse-engineering-shield</code>

</div>

---

像 [REA](https://github.com/morluto/rea) 这样的 agent 工具，可以在几分钟内、在没有源代码的情况下，
解释任何 Web 应用、浏览器扩展、Electron 应用、APK/IPA 或原生二进制文件的工作原理。
你无法阻止别人*读懂*你发布的东西。

**Reverse Engineering Shield** 是一个 agent skill 加一个审计脚本，让这种阅读变得毫无价值。
它教会你的编程 agent（Claude Code、Codex、Cursor、Gemini CLI 等）把有价值的部分留在服务器上，
发布不带映射文件的客户端代码，在服务端重新校验一切，让剩下的部分代价高昂且可追溯——
并在每次发布前先攻击你自己的构建产物。

## 快速开始

### 安装 skill

```bash
npx skills add ChosingDept/reverse-engineering-shield
```

或者使用安装脚本（默认将 skill 复制到 `~/.claude/skills`）：

```bash
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash
# another skills directory:
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash -s -- --dir ~/.codex/skills
```

或者把 `.agents/skills/reverse-engineering-shield` 复制到你的 agent 的 skills 目录中。

### 向你的 agent 提问

> 在我们发布扩展之前，用 reverse-engineering-shield 审查一下这个项目。

> 我们的定价逻辑写在 React 应用里。按照 reverse-engineering-shield 把它移到 API 后面。

> 审计 `dist/` 和我们的生产站点，然后修复所有 CRITICAL 问题。

### 或者自己运行审计

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

退出码 `2` 会阻止发布，`1` 要求给出理由，`0` 表示干净——可直接接入
CI（[示例](docs/ci.md)）。

## 工作原理

### 五条原则

1. **大脑留在服务器上。** 规则、定价、评分、提示词、选择器和启发式逻辑都放在你的 API 之后。
   客户端只负责渲染和执行。
2. **发往客户端的代码不带映射。** 不公开 source map，代码压缩，
   不留注释、不留 `console`、不暴露内部名称、不保留调试路由。
3. **服务器从不信任客户端。** 许可证、归属权、限额和价格在每次请求时都重新校验。
4. **必须留在客户端的部分要代价高昂且可追溯。** 在商店允许的地方做针对性混淆，
   按客户添加水印，埋设金丝雀记录。
5. **发布前先攻击你自己。** 对最终产物运行审计和 REA。
   如果 REA 能解释某个功能是如何做决策的，竞争对手也能。

### 审计检查项

| 检查项 | 严重级别 |
|---|---|
| 产物中的 `.map` 文件、内联映射、线上站点公开的映射、列出映射的 `asset-manifest.json` | CRITICAL |
| 服务器密钥：AWS、私钥、`sk_live_`、LLM 服务商密钥、GitHub/Slack 令牌、带密码的数据库 URL、服务账号 | CRITICAL（输出中已脱敏） |
| 线上站点暴露的 `/.git/` 和 `/.env` | CRITICAL |
| 代码中残留的 `sourceMappingURL` 注释 | WARNING |
| Google/Firebase 密钥、硬编码的 JWT | WARNING |
| `localhost`、私有 IP、staging/homolog 主机 | WARNING |
| 发往客户端的 AI 提示词（`You are…`、`systemPrompt`、`role: "system"`） | WARNING |
| 你自己的业务术语（`SHIELD_TERMS`） | WARNING |
| 未压缩的文件、残留的 `console.log`/`debugger` | WARNING |
| 未编译为 Hermes 字节码的 React Native bundle | WARNING |
| 线上站点可访问的 Swagger/OpenAPI/GraphQL 端点 | WARNING |

输入：构建目录、`.zip`、`.crx`、`.xpi`、`.apk`、`.aab`、`.ipa`、`.asar`，或一个 URL。

### 技术栈手册

该 skill 附带有针对性的检查清单，agent 会在相关时加载：

| 技术栈 | 手册 |
|---|---|
| Web 应用（Vite、CRA、Next.js、webpack） | [web.md](.agents/skills/reverse-engineering-shield/references/web.md) |
| 浏览器扩展（Chrome MV3、Firefox） | [extensions.md](.agents/skills/reverse-engineering-shield/references/extensions.md) |
| 移动端（React Native/Expo、Android、iOS、Flutter） | [mobile.md](.agents/skills/reverse-engineering-shield/references/mobile.md) |
| 桌面端（Electron、Tauri、原生、Python） | [desktop.md](.agents/skills/reverse-engineering-shield/references/desktop.md) |
| API 与后端 | [api.md](.agents/skills/reverse-engineering-shield/references/api.md) |
| 机器人与自动化 | [server-driven.md](.agents/skills/reverse-engineering-shield/references/server-driven.md) |
| 水印、金丝雀、法律 | [traceability.md](.agents/skills/reverse-engineering-shield/references/traceability.md) |

## 常见问题

**我直接把所有代码都混淆不就行了吗？**
混淆、字节码和证书锁定只能拖慢一个执着的分析者，并不能阻止他。
agent 很有耐心。只有把价值移到服务器上，才能真正把它拿走。另外，有些商店
禁止混淆——Chrome Web Store 会拒绝经过混淆的扩展。

**它能取代安全审查或渗透测试吗？**
不能。它覆盖的是你的客户端产物和公开暴露面所泄露的信息。请与常规的
安全工作配合使用。

**我可以对任意网站运行 URL 模式吗？**
只能针对你拥有的域名，或已明确获得测试授权的域名。

**支持哪些 agent？**
任何能加载 `SKILL.md` skill 的 agent（Claude Code、Codex、Cursor、Gemini CLI 等）。
审计脚本是纯 Bash，只要有 `curl`、`unzip` 和 `grep` 就能在任何地方运行。

## 贡献

欢迎提交 issue 和 pull request——尤其是新的密钥模式、技术栈和手册。
参见 [CONTRIBUTING.md](CONTRIBUTING.md)。提交 PR 前请先运行 `bash tests/run.sh`。

## 许可证

[MIT](LICENSE) © Chosing Dept. 参见 [DISCLAIMER.md](DISCLAIMER.md)。
