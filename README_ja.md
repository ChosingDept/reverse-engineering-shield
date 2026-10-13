<div align="center">

[English](README.md) · [简体中文](README_zh.md) · [繁體中文](README_zh-TW.md) · **日本語** · [한국어](README_ko.md) · [Türkçe](README_tr.md) · [Русский](README_ru.md) · [Tiếng Việt](README_vi.md) · [ไทย](README_th.md) · [Deutsch](README_de.md) · [Español](README_es.md) · [Français](README_fr.md) · [Українська](README_uk.md) · [Polski](README_pl.md) · [Português (Brasil)](README_pt-BR.md) · [العربية](README_ar.md) · [فارسی](README_fa.md) · [Bahasa Indonesia](README_id.md) · [Italiano](README_it.md)

# Reverse Engineering Shield

### リバースエンジニアリングを無意味にする。

**あなたのエージェントはどんなアプリでも読み解けます。競合のエージェントも同じです。だから、読んでも価値のないコードを出荷しましょう。**

[![CI](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml/badge.svg)](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml)
[![MIT license](https://img.shields.io/badge/license-MIT-f4c430?style=flat-square)](LICENSE)
[![Agent skill](https://img.shields.io/badge/agent-skill-5c4ee5?style=flat-square)](.agents/skills/reverse-engineering-shield/SKILL.md)

<code>npx skills add ChosingDept/reverse-engineering-shield</code>

</div>

---

[REA](https://github.com/morluto/rea) のようなエージェントツールを使えば、Web アプリ、ブラウザ拡張機能、
Electron アプリ、APK/IPA、ネイティブバイナリがどう動いているのかを、ソースコードなしで数分のうちに説明できます。
あなたが出荷したものを誰かが*読む*ことを止める手段はありません。

**Reverse Engineering Shield** は、その読み解きを無意味にするエージェントスキルと監査スクリプトです。
コーディングエージェント（Claude Code、Codex、Cursor、Gemini CLI など）に対して、価値のある部分はサーバーに残し、
クライアントコードはマップなしで出荷し、すべてをサーバー側で再検証し、残った部分は解析コストが高く追跡可能にすること、
そしてリリースのたびに自分のビルドを自ら攻撃することを教えます。

対象は**あらゆるスタックのあらゆるアプリ**です：Web、ブラウザ拡張機能、モバイル、デスクトップ、.NET と JVM、ゲーム、
WebAssembly、SDK とパッケージ、コンテナとオンプレミス環境へのインストール、ファームウェア/IoT、AI 機能とオンデバイスモデル——
そしてそれらすべての背後にある API までカバーします。

## クイックスタート

### スキルをインストールする

```bash
npx skills add ChosingDept/reverse-engineering-shield
```

またはインストーラーを使う方法（デフォルトではスキルを `~/.claude/skills` にコピーします）：

```bash
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash
# another skills directory:
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash -s -- --dir ~/.codex/skills
```

あるいは `.agents/skills/reverse-engineering-shield` をエージェントのスキルフォルダにコピーしてください。

### エージェントに頼む

> 拡張機能を公開する前に、reverse-engineering-shield でこのプロジェクトをレビューして。

> 価格計算のロジックが React アプリ内にある。reverse-engineering-shield に従って API の裏側に移して。

> `dist/` と本番サイトを監査して、CRITICAL をすべて修正して。

### または自分で監査を実行する

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

終了コード `2` はリリースをブロックし、`1` は正当な理由の説明を求め、`0` は問題なしを意味します。
そのまま CI に組み込めます（[例](docs/ci.md)）。

## 仕組み

### 5 つの原則

1. **頭脳はサーバーに置く。** ルール、価格設定、スコアリング、プロンプト、セレクター、ヒューリスティクスは
   API の裏側に置きます。クライアントは描画と実行だけを担当します。
2. **クライアントに出荷するものはマップなしで出荷する。** 公開ソースマップなし、minify 済み、
   コメントなし、`console` なし、内部名なし、デバッグ用ルートなし。
3. **サーバーはクライアントを決して信用しない。** ライセンス、所有権、上限、価格は
   リクエストのたびに再検証します。
4. **クライアントに残さざるを得ないものは、解析コストを高く、追跡可能にする。** ストアが許す範囲での的を絞った難読化、
   顧客ごとのウォーターマーク、カナリアレコード。
5. **出荷する前に自分を攻撃する。** 最終成果物に対して監査と REA を実行します。
   ある機能がどう判断しているかを REA が説明できるなら、競合にも説明できます。

### 監査のチェック項目

| チェック | 重大度 |
|---|---|
| 成果物内の `.map` ファイル、インラインマップ、本番サイトで公開されているマップ、マップを列挙している `asset-manifest.json` | CRITICAL |
| サーバーのシークレット：AWS、秘密鍵、`sk_live_`、LLM プロバイダーのキー、GitHub/Slack トークン、パスワード付きのデータベース URL、サービスアカウント | CRITICAL（出力ではマスク） |
| 本番サイトで公開されている `/.git/` と `/.env` | CRITICAL |
| コードに残った `sourceMappingURL` コメント | WARNING |
| Google/Firebase のキー、ハードコードされた JWT | WARNING |
| `localhost`、プライベート IP、staging/homolog ホスト | WARNING |
| クライアントに出荷された AI プロンプト（`You are…`、`systemPrompt`、`role: "system"`） | WARNING |
| 独自のビジネス用語（`SHIELD_TERMS`） | WARNING |
| minify されていないファイル、`console.log`/`debugger` の消し忘れ | WARNING |
| Hermes バイトコードにコンパイルされていない React Native バンドル | WARNING |
| 本番サイトからアクセス可能な Swagger/OpenAPI/GraphQL エンドポイント | WARNING |

入力：ビルドフォルダ、`.zip`、`.crx`、`.xpi`、`.apk`、`.aab`、`.ipa`、`.asar`、または URL。

### スタック別プレイブック

このスキルには、エージェントが必要に応じて読み込む、用途を絞ったチェックリストが同梱されています。

| スタック | プレイブック |
|---|---|
| Web アプリ（Vite、CRA、Next.js、webpack） | [web.md](.agents/skills/reverse-engineering-shield/references/web.md) |
| ブラウザ拡張機能（Chrome MV3、Firefox） | [extensions.md](.agents/skills/reverse-engineering-shield/references/extensions.md) |
| モバイル（React Native/Expo、Android、iOS、Flutter） | [mobile.md](.agents/skills/reverse-engineering-shield/references/mobile.md) |
| デスクトップ（Electron、Tauri、ネイティブ、Python） | [desktop.md](.agents/skills/reverse-engineering-shield/references/desktop.md) |
| .NET と JVM（C#、Java、Kotlin、Scala、Android バイトコード） | [managed-runtimes.md](.agents/skills/reverse-engineering-shield/references/managed-runtimes.md) |
| ゲーム（Unity、Unreal、Godot） | [games.md](.agents/skills/reverse-engineering-shield/references/games.md) |
| WebAssembly | [webassembly.md](.agents/skills/reverse-engineering-shield/references/webassembly.md) |
| SDK、パッケージ、コンテナ、オンプレミス環境へのインストール | [packages.md](.agents/skills/reverse-engineering-shield/references/packages.md) |
| ファームウェア、組み込み、IoT | [embedded.md](.agents/skills/reverse-engineering-shield/references/embedded.md) |
| AI 機能とオンデバイスモデル | [ai-models.md](.agents/skills/reverse-engineering-shield/references/ai-models.md) |
| API とバックエンド | [api.md](.agents/skills/reverse-engineering-shield/references/api.md) |
| ボットと自動化 | [server-driven.md](.agents/skills/reverse-engineering-shield/references/server-driven.md) |
| ウォーターマーク、カナリア、法務 | [traceability.md](.agents/skills/reverse-engineering-shield/references/traceability.md) |

## FAQ

**全部難読化すれば済むのでは？**
難読化、バイトコード化、ピンニングは、意志の固い解析者を遅らせることはできても、止めることはできません。
エージェントは根気強いのです。価値を取り除けるのは、それをサーバーに移すことだけです。また、ストアによっては
難読化を禁止しています。Chrome Web Store は難読化された拡張機能をリジェクトします。

**これはセキュリティレビューやペネトレーションテストの代わりになりますか？**
なりません。カバーするのは、クライアント成果物と公開されている領域から読み取れる内容です。
通常のセキュリティ対策と組み合わせて使ってください。

**URL モードはどのサイトに対しても実行できますか？**
自分が所有しているドメイン、またはテストを明示的に許可されたドメインに対してのみ実行してください。

**どのエージェントに対応していますか？**
`SKILL.md` 形式のスキルを読み込めるエージェントなら何でも対応します（Claude Code、Codex、Cursor、Gemini CLI など）。
監査スクリプトは素の Bash で書かれており、`curl`、`unzip`、`grep` があればどこでも動きます。

## コントリビューション

Issue と pull request を歓迎します。特に、新しいシークレットのパターン、スタック、プレイブックは大歓迎です。
[CONTRIBUTING.md](CONTRIBUTING.md) を参照してください。PR を作成する前に `bash tests/run.sh` を実行してください。

## ライセンス

[MIT](LICENSE) © Chosing Dept. [DISCLAIMER.md](DISCLAIMER.md) も参照してください。
