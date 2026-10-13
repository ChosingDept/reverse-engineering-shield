<div align="center">

[English](README.md) · [简体中文](README_zh.md) · [繁體中文](README_zh-TW.md) · [日本語](README_ja.md) · **한국어** · [Türkçe](README_tr.md) · [Русский](README_ru.md) · [Tiếng Việt](README_vi.md) · [ไทย](README_th.md) · [Deutsch](README_de.md) · [Español](README_es.md) · [Français](README_fr.md) · [Українська](README_uk.md) · [Polski](README_pl.md) · [Português (Brasil)](README_pt-BR.md) · [العربية](README_ar.md) · [فارسی](README_fa.md) · [Bahasa Indonesia](README_id.md) · [Italiano](README_it.md)

# Reverse Engineering Shield

### 리버스 엔지니어링을 무의미하게 만드세요.

**여러분의 에이전트는 어떤 앱이든 읽어낼 수 있습니다. 경쟁사의 에이전트도 마찬가지입니다. 읽어도 쓸모없는 코드를 배포하세요.**

[![CI](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml/badge.svg)](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml)
[![MIT license](https://img.shields.io/badge/license-MIT-f4c430?style=flat-square)](LICENSE)
[![Agent skill](https://img.shields.io/badge/agent-skill-5c4ee5?style=flat-square)](.agents/skills/reverse-engineering-shield/SKILL.md)

<code>npx skills add ChosingDept/reverse-engineering-shield</code>

</div>

---

[REA](https://github.com/morluto/rea) 같은 에이전트 도구는 소스 코드 없이도 몇 분 만에 어떤 웹 앱,
브라우저 확장 프로그램, Electron 앱, APK/IPA, 네이티브 바이너리든 그 동작 방식을 설명해 낼 수 있습니다.
여러분이 배포한 것을 누군가 *읽는* 것을 막을 방법은 없습니다.

**Reverse Engineering Shield**는 그 읽기를 무의미하게 만드는 에이전트 스킬과 감사 스크립트입니다.
코딩 에이전트(Claude Code, Codex, Cursor, Gemini CLI 등)에게 가치 있는 부분은 서버에 두고,
클라이언트 코드는 맵 없이 배포하며, 모든 것을 서버 측에서 다시 검증하고, 남은 부분은 분석 비용이 크고 추적 가능하게 만들고,
매 릴리스 전에 자신의 빌드를 직접 공격하도록 가르칩니다.

## 빠른 시작

### 스킬 설치

```bash
npx skills add ChosingDept/reverse-engineering-shield
```

또는 설치 스크립트를 사용합니다(기본적으로 스킬을 `~/.claude/skills`에 복사합니다).

```bash
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash
# another skills directory:
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash -s -- --dir ~/.codex/skills
```

또는 `.agents/skills/reverse-engineering-shield`를 에이전트의 스킬 폴더에 복사하세요.

### 에이전트에게 요청하기

> 확장 프로그램을 게시하기 전에 reverse-engineering-shield로 이 프로젝트를 검토해 줘.

> 가격 책정 로직이 React 앱 안에 있어. reverse-engineering-shield에 따라 API 뒤로 옮겨 줘.

> `dist/`와 프로덕션 사이트를 감사하고, CRITICAL 항목을 전부 수정해 줘.

### 또는 직접 감사 실행하기

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

종료 코드 `2`는 릴리스를 차단하고, `1`은 사유 설명을 요구하며, `0`은 문제가 없음을 뜻합니다. 바로
CI에 연결할 수 있습니다([예시](docs/ci.md)).

## 작동 방식

### 다섯 가지 원칙

1. **두뇌는 서버에 둔다.** 규칙, 가격 책정, 스코어링, 프롬프트, 셀렉터, 휴리스틱은
   API 뒤에 둡니다. 클라이언트는 렌더링과 실행만 담당합니다.
2. **클라이언트로 가는 것은 맵 없이 보낸다.** 공개 소스 맵 없음, 압축(minify) 적용,
   주석 없음, `console` 없음, 내부 이름 없음, 디버그 라우트 없음.
3. **서버는 절대 클라이언트를 신뢰하지 않는다.** 라이선스, 소유권, 한도, 가격은
   매 요청마다 다시 검증합니다.
4. **클라이언트에 남아야 하는 것은 분석 비용이 크고 추적 가능하게 만든다.** 스토어가 허용하는 범위에서의 선택적 난독화,
   고객별 워터마크, 카나리아 레코드.
5. **배포하기 전에 스스로를 공격한다.** 최종 결과물에 대해 감사와 REA를 실행하세요.
   REA가 어떤 기능이 어떻게 판단하는지 설명할 수 있다면, 경쟁사도 할 수 있습니다.

### 감사 점검 항목

| 점검 항목 | 심각도 |
|---|---|
| 결과물 내 `.map` 파일, 인라인 맵, 라이브 사이트의 공개 맵, 맵을 나열하는 `asset-manifest.json` | CRITICAL |
| 서버 시크릿: AWS, 개인 키, `sk_live_`, LLM 제공자 키, GitHub/Slack 토큰, 비밀번호가 포함된 데이터베이스 URL, 서비스 계정 | CRITICAL(출력에서 마스킹) |
| 라이브 사이트에 노출된 `/.git/` 및 `/.env` | CRITICAL |
| 코드에 남아 있는 `sourceMappingURL` 주석 | WARNING |
| Google/Firebase 키, 하드코딩된 JWT | WARNING |
| `localhost`, 사설 IP, staging/homolog 호스트 | WARNING |
| 클라이언트로 배포된 AI 프롬프트(`You are…`, `systemPrompt`, `role: "system"`) | WARNING |
| 자체 비즈니스 용어(`SHIELD_TERMS`) | WARNING |
| 압축되지 않은 파일, 남아 있는 `console.log`/`debugger` | WARNING |
| Hermes 바이트코드로 컴파일되지 않은 React Native 번들 | WARNING |
| 라이브 사이트에서 접근 가능한 Swagger/OpenAPI/GraphQL 엔드포인트 | WARNING |

입력: 빌드 폴더, `.zip`, `.crx`, `.xpi`, `.apk`, `.aab`, `.ipa`, `.asar` 또는 URL.

### 스택별 플레이북

이 스킬에는 에이전트가 필요할 때 불러오는, 목적에 맞춘 체크리스트가 함께 제공됩니다.

| 스택 | 플레이북 |
|---|---|
| 웹 앱(Vite, CRA, Next.js, webpack) | [web.md](.agents/skills/reverse-engineering-shield/references/web.md) |
| 브라우저 확장 프로그램(Chrome MV3, Firefox) | [extensions.md](.agents/skills/reverse-engineering-shield/references/extensions.md) |
| 모바일(React Native/Expo, Android, iOS, Flutter) | [mobile.md](.agents/skills/reverse-engineering-shield/references/mobile.md) |
| 데스크톱(Electron, Tauri, 네이티브, Python) | [desktop.md](.agents/skills/reverse-engineering-shield/references/desktop.md) |
| API 및 백엔드 | [api.md](.agents/skills/reverse-engineering-shield/references/api.md) |
| 봇 및 자동화 | [server-driven.md](.agents/skills/reverse-engineering-shield/references/server-driven.md) |
| 워터마크, 카나리아, 법적 대응 | [traceability.md](.agents/skills/reverse-engineering-shield/references/traceability.md) |

## FAQ

**그냥 전부 난독화하면 안 되나요?**
난독화, 바이트코드, 피닝은 끈질긴 분석가를 늦출 수는 있어도 막지는 못합니다.
에이전트는 인내심이 강합니다. 가치를 서버로 옮기는 것만이 그 가치를 실제로 없앨 수 있습니다. 또한 일부 스토어는
난독화를 금지합니다. Chrome Web Store는 난독화된 확장 프로그램을 거부합니다.

**보안 검토나 모의 해킹을 대체하나요?**
아니요. 클라이언트 결과물과 공개 노출 영역이 드러내는 내용을 다룹니다. 정기적인
보안 작업과 함께 사용하세요.

**URL 모드를 아무 사이트에나 실행해도 되나요?**
본인이 소유한 도메인이나 테스트 권한을 명시적으로 받은 도메인에만 실행하세요.

**어떤 에이전트를 지원하나요?**
`SKILL.md` 스킬을 불러올 수 있는 모든 에이전트(Claude Code, Codex, Cursor, Gemini CLI 등)를 지원합니다.
감사 스크립트는 순수 Bash로 작성되어 `curl`, `unzip`, `grep`만 있으면 어디서든 실행됩니다.

## 기여하기

이슈와 pull request를 환영합니다. 특히 새로운 시크릿 패턴, 스택, 플레이북은 더욱 환영합니다.
[CONTRIBUTING.md](CONTRIBUTING.md)를 참고하세요. PR을 열기 전에 `bash tests/run.sh`를 실행하세요.

## 라이선스

[MIT](LICENSE) © Chosing Dept. [DISCLAIMER.md](DISCLAIMER.md)를 참고하세요.
