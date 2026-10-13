<div align="center">

[English](README.md) · [简体中文](README_zh.md) · **繁體中文** · [日本語](README_ja.md) · [한국어](README_ko.md) · [Türkçe](README_tr.md) · [Русский](README_ru.md) · [Tiếng Việt](README_vi.md) · [ไทย](README_th.md) · [Deutsch](README_de.md) · [Español](README_es.md) · [Français](README_fr.md) · [Українська](README_uk.md) · [Polski](README_pl.md) · [Português (Brasil)](README_pt-BR.md) · [العربية](README_ar.md) · [فارسی](README_fa.md) · [Bahasa Indonesia](README_id.md) · [Italiano](README_it.md)

# Reverse Engineering Shield

### 讓逆向工程變得毫無意義。

**你的 agent 能讀懂任何應用程式，你競爭對手的 agent 也一樣。那就發布不值得一讀的程式碼。**

[![CI](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml/badge.svg)](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml)
[![MIT license](https://img.shields.io/badge/license-MIT-f4c430?style=flat-square)](LICENSE)
[![Agent skill](https://img.shields.io/badge/agent-skill-5c4ee5?style=flat-square)](.agents/skills/reverse-engineering-shield/SKILL.md)

<code>npx skills add ChosingDept/reverse-engineering-shield</code>

</div>

---

像 [REA](https://github.com/morluto/rea) 這樣的 agent 工具，可以在幾分鐘內、在沒有原始碼的情況下，
解釋任何 Web 應用程式、瀏覽器擴充功能、Electron 應用程式、APK/IPA 或原生二進位檔的運作方式。
你無法阻止別人*讀懂*你發布的東西。

**Reverse Engineering Shield** 是一個 agent skill 加上一支稽核腳本，讓這種閱讀變得毫無價值。
它教你的程式設計 agent（Claude Code、Codex、Cursor、Gemini CLI 等）把有價值的部分留在伺服器上，
發布不帶對應檔的用戶端程式碼，在伺服器端重新驗證一切，讓剩下的部分代價高昂且可追溯——
並在每次發布前先攻擊你自己的建置產物。

它涵蓋**任何技術堆疊上的任何應用程式**：Web、瀏覽器擴充功能、行動裝置、桌面、.NET 與 JVM、遊戲、WebAssembly、
SDK 與套件、容器與地端安裝、韌體/IoT、AI 功能與裝置端模型——以及它們背後的所有 API。

## 快速開始

### 安裝 skill

```bash
npx skills add ChosingDept/reverse-engineering-shield
```

或使用安裝程式（預設會將 skill 複製到 `~/.claude/skills`）：

```bash
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash
# another skills directory:
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash -s -- --dir ~/.codex/skills
```

或將 `.agents/skills/reverse-engineering-shield` 複製到你的 agent 的 skills 資料夾中。

### 詢問你的 agent

> 在我們發布擴充功能之前，用 reverse-engineering-shield 審查這個專案。

> 我們的定價邏輯寫在 React 應用程式裡。依照 reverse-engineering-shield 把它移到 API 後面。

> 稽核 `dist/` 和我們的正式環境網站，然後修正所有 CRITICAL 問題。

### 或自行執行稽核

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

結束代碼 `2` 會阻擋發布，`1` 要求提出理由，`0` 代表乾淨——可直接整合到
CI（[範例](docs/ci.md)）。

## 運作方式

### 五大原則

1. **大腦留在伺服器上。** 規則、定價、評分、提示詞、選擇器與啟發式邏輯都放在你的 API 後面。
   用戶端只負責渲染與執行。
2. **送到用戶端的程式碼不附對應檔。** 不公開 source map、經過壓縮、
   不留註解、不留 `console`、不暴露內部名稱、不保留除錯路由。
3. **伺服器絕不信任用戶端。** 授權、擁有權、額度與價格在每次請求時都重新驗證。
4. **必須留在用戶端的部分要代價高昂且可追溯。** 在商店允許的地方進行針對性混淆、
   依客戶加上浮水印、埋設金絲雀紀錄。
5. **發布前先攻擊你自己。** 對最終產物執行稽核與 REA。
   如果 REA 能解釋某個功能如何做出決策，競爭對手也能。

### 稽核檢查項目

| 檢查項目 | 嚴重程度 |
|---|---|
| 產物中的 `.map` 檔、內嵌對應檔、線上網站公開的對應檔、列出對應檔的 `asset-manifest.json` | CRITICAL |
| 伺服器機密：AWS、私密金鑰、`sk_live_`、LLM 供應商金鑰、GitHub/Slack 權杖、含密碼的資料庫 URL、服務帳戶 | CRITICAL（輸出中已遮蔽） |
| 線上網站暴露的 `/.git/` 與 `/.env` | CRITICAL |
| 程式碼中殘留的 `sourceMappingURL` 註解 | WARNING |
| Google/Firebase 金鑰、寫死的 JWT | WARNING |
| `localhost`、私有 IP、staging/homolog 主機 | WARNING |
| 送到用戶端的 AI 提示詞（`You are…`、`systemPrompt`、`role: "system"`） | WARNING |
| 你自己的業務術語（`SHIELD_TERMS`） | WARNING |
| 未壓縮的檔案、殘留的 `console.log`/`debugger` | WARNING |
| 未編譯成 Hermes 位元組碼的 React Native bundle | WARNING |
| 線上網站可存取的 Swagger/OpenAPI/GraphQL 端點 | WARNING |

輸入：建置資料夾、`.zip`、`.crx`、`.xpi`、`.apk`、`.aab`、`.ipa`、`.asar`，或一個 URL。

### 技術堆疊手冊

這個 skill 附帶聚焦的檢查清單，agent 會在需要時載入：

| 技術堆疊 | 手冊 |
|---|---|
| Web 應用程式（Vite、CRA、Next.js、webpack） | [web.md](.agents/skills/reverse-engineering-shield/references/web.md) |
| 瀏覽器擴充功能（Chrome MV3、Firefox） | [extensions.md](.agents/skills/reverse-engineering-shield/references/extensions.md) |
| 行動裝置（React Native/Expo、Android、iOS、Flutter） | [mobile.md](.agents/skills/reverse-engineering-shield/references/mobile.md) |
| 桌面（Electron、Tauri、原生、Python） | [desktop.md](.agents/skills/reverse-engineering-shield/references/desktop.md) |
| .NET 與 JVM（C#、Java、Kotlin、Scala、Android 位元組碼） | [managed-runtimes.md](.agents/skills/reverse-engineering-shield/references/managed-runtimes.md) |
| 遊戲（Unity、Unreal、Godot） | [games.md](.agents/skills/reverse-engineering-shield/references/games.md) |
| WebAssembly | [webassembly.md](.agents/skills/reverse-engineering-shield/references/webassembly.md) |
| SDK、套件、容器、地端安裝 | [packages.md](.agents/skills/reverse-engineering-shield/references/packages.md) |
| 韌體、嵌入式、IoT | [embedded.md](.agents/skills/reverse-engineering-shield/references/embedded.md) |
| AI 功能與裝置端模型 | [ai-models.md](.agents/skills/reverse-engineering-shield/references/ai-models.md) |
| API 與後端 | [api.md](.agents/skills/reverse-engineering-shield/references/api.md) |
| 機器人與自動化 | [server-driven.md](.agents/skills/reverse-engineering-shield/references/server-driven.md) |
| 浮水印、金絲雀、法律 | [traceability.md](.agents/skills/reverse-engineering-shield/references/traceability.md) |

## 常見問題

**我直接把所有東西都混淆不就好了？**
混淆、位元組碼與憑證綁定只能拖慢一位執著的分析者，無法阻止他。
agent 很有耐心。只有把價值移到伺服器上，才能真正將它移除。此外，有些商店
禁止混淆——Chrome Web Store 會拒絕經過混淆的擴充功能。

**這能取代安全審查或滲透測試嗎？**
不能。它涵蓋的是你的用戶端產物與公開暴露面所揭露的內容。請搭配常規的
資安工作一起使用。

**我可以對任何網站執行 URL 模式嗎？**
只能針對你擁有的網域，或已明確取得測試授權的網域。

**支援哪些 agent？**
任何能載入 `SKILL.md` skill 的 agent（Claude Code、Codex、Cursor、Gemini CLI 等）。
稽核腳本是純 Bash，只要有 `curl`、`unzip` 與 `grep` 就能在任何地方執行。

## 參與貢獻

歡迎提交 issue 與 pull request——特別是新的機密模式、技術堆疊與手冊。
請參閱 [CONTRIBUTING.md](CONTRIBUTING.md)。開 PR 前請先執行 `bash tests/run.sh`。

## 授權條款

[MIT](LICENSE) © Chosing Dept. 請參閱 [DISCLAIMER.md](DISCLAIMER.md)。
