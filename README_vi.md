<div align="center">

[English](README.md) · [简体中文](README_zh.md) · [繁體中文](README_zh-TW.md) · [日本語](README_ja.md) · [한국어](README_ko.md) · [Türkçe](README_tr.md) · [Русский](README_ru.md) · **Tiếng Việt** · [ไทย](README_th.md) · [Deutsch](README_de.md) · [Español](README_es.md) · [Français](README_fr.md) · [Українська](README_uk.md) · [Polski](README_pl.md) · [Português (Brasil)](README_pt-BR.md) · [العربية](README_ar.md) · [فارسی](README_fa.md) · [Bahasa Indonesia](README_id.md) · [Italiano](README_it.md)

# Reverse Engineering Shield

### Khiến dịch ngược trở nên vô dụng.

**Agent của bạn đọc được mọi ứng dụng. Agent của đối thủ cũng vậy. Hãy phát hành code mà đọc cũng chẳng thu được gì.**

[![CI](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml/badge.svg)](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml)
[![MIT license](https://img.shields.io/badge/license-MIT-f4c430?style=flat-square)](LICENSE)
[![Agent skill](https://img.shields.io/badge/agent-skill-5c4ee5?style=flat-square)](.agents/skills/reverse-engineering-shield/SKILL.md)

<code>npx skills add ChosingDept/reverse-engineering-shield</code>

</div>

---

Các công cụ dành cho agent như [REA](https://github.com/morluto/rea) có thể giải thích cách hoạt động
của bất kỳ ứng dụng web, tiện ích trình duyệt, ứng dụng Electron, APK/IPA hay binary native nào — chỉ
trong vài phút, mà không cần mã nguồn. Không có cách nào ngăn người khác *đọc* những gì bạn phát hành.

**Reverse Engineering Shield** là một skill cho agent kèm theo script kiểm tra (audit), khiến việc
đọc đó trở nên vô nghĩa. Nó dạy coding agent của bạn (Claude Code, Codex, Cursor, Gemini CLI và
các agent khác) giữ những phần giá trị trên server, phát hành code phía client không kèm source map,
xác thực lại mọi thứ ở phía server, khiến phần còn lại trở nên tốn kém để phân tích và có thể truy vết
— và tự tấn công bản build của chính bạn trước mỗi lần phát hành.

Nó bao quát **mọi ứng dụng trên mọi stack**: web, tiện ích trình duyệt, di động, desktop, .NET
và JVM, game, WebAssembly, SDK và package, container và bản cài đặt on-prem, firmware/IoT,
tính năng AI và mô hình chạy trên thiết bị — cùng các API đứng sau tất cả chúng.

## Bắt đầu nhanh

### Cài đặt skill

```bash
npx skills add ChosingDept/reverse-engineering-shield
```

Hoặc dùng trình cài đặt (mặc định sao chép skill vào `~/.claude/skills`):

```bash
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash
# another skills directory:
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash -s -- --dir ~/.codex/skills
```

Hoặc sao chép `.agents/skills/reverse-engineering-shield` vào thư mục skills của agent.

### Yêu cầu agent của bạn

> Rà soát dự án này bằng reverse-engineering-shield trước khi chúng ta phát hành tiện ích.

> Logic tính giá của chúng ta đang nằm trong ứng dụng React. Hãy chuyển nó ra sau API theo reverse-engineering-shield.

> Kiểm tra `dist/` và trang production của chúng ta, rồi sửa mọi lỗi CRITICAL.

### Hoặc tự chạy audit

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

Mã thoát `2` chặn bản phát hành, `1` yêu cầu giải trình, `0` là sạch — sẵn sàng
cho CI ([ví dụ](docs/ci.md)).

## Cách hoạt động

### Năm nguyên tắc

1. **Bộ não nằm trên server.** Quy tắc, định giá, chấm điểm, prompt, selector và
   heuristic nằm sau API của bạn. Client chỉ hiển thị và thực thi.
2. **Thứ gì gửi xuống client thì gửi không kèm bản đồ.** Không có source map công khai, đã minify,
   không comment, không `console`, không tên nội bộ, không route debug.
3. **Server không bao giờ tin client.** Giấy phép, quyền sở hữu, giới hạn và giá được
   xác thực lại ở mọi request.
4. **Thứ gì buộc phải ở lại client thì phải tốn kém và truy vết được.** Làm rối mã (obfuscation)
   có chọn lọc ở nơi store cho phép, watermark theo từng khách hàng, bản ghi canary.
5. **Tự tấn công mình trước khi phát hành.** Chạy audit và REA trên artifact cuối cùng.
   Nếu REA giải thích được một tính năng ra quyết định như thế nào, đối thủ cũng làm được.

### Audit kiểm tra những gì

| Hạng mục kiểm tra | Mức độ |
|---|---|
| File `.map` trong artifact, map inline, map công khai trên trang đang chạy, `asset-manifest.json` liệt kê map | CRITICAL |
| Bí mật phía server: AWS, khóa riêng tư, `sk_live_`, khóa của nhà cung cấp LLM, token GitHub/Slack, URL cơ sở dữ liệu kèm mật khẩu, service account | CRITICAL (được che trong output) |
| `/.git/` và `/.env` bị lộ trên trang đang chạy | CRITICAL |
| Comment `sourceMappingURL` còn sót trong code | WARNING |
| Khóa Google/Firebase, JWT viết cứng trong code | WARNING |
| `localhost`, IP nội bộ, host staging/homolog | WARNING |
| Prompt AI bị gửi xuống client (`You are…`, `systemPrompt`, `role: "system"`) | WARNING |
| Thuật ngữ nghiệp vụ của riêng bạn (`SHIELD_TERMS`) | WARNING |
| File chưa minify, `console.log`/`debugger` còn sót lại | WARNING |
| Bundle React Native chưa được biên dịch sang bytecode Hermes | WARNING |
| Endpoint Swagger/OpenAPI/GraphQL truy cập được trên trang đang chạy | WARNING |

Đầu vào: thư mục build, `.zip`, `.crx`, `.xpi`, `.apk`, `.aab`, `.ipa`, `.asar` hoặc một URL.

### Playbook theo stack

Skill đi kèm các checklist chuyên biệt mà agent sẽ nạp khi phù hợp:

| Stack | Playbook |
|---|---|
| Ứng dụng web (Vite, CRA, Next.js, webpack) | [web.md](.agents/skills/reverse-engineering-shield/references/web.md) |
| Tiện ích trình duyệt (Chrome MV3, Firefox) | [extensions.md](.agents/skills/reverse-engineering-shield/references/extensions.md) |
| Di động (React Native/Expo, Android, iOS, Flutter) | [mobile.md](.agents/skills/reverse-engineering-shield/references/mobile.md) |
| Desktop (Electron, Tauri, native, Python) | [desktop.md](.agents/skills/reverse-engineering-shield/references/desktop.md) |
| .NET và JVM (C#, Java, Kotlin, Scala, bytecode Android) | [managed-runtimes.md](.agents/skills/reverse-engineering-shield/references/managed-runtimes.md) |
| Game (Unity, Unreal, Godot) | [games.md](.agents/skills/reverse-engineering-shield/references/games.md) |
| WebAssembly | [webassembly.md](.agents/skills/reverse-engineering-shield/references/webassembly.md) |
| SDK, package, container, bản cài đặt on-prem | [packages.md](.agents/skills/reverse-engineering-shield/references/packages.md) |
| Firmware, hệ thống nhúng, IoT | [embedded.md](.agents/skills/reverse-engineering-shield/references/embedded.md) |
| Tính năng AI và mô hình chạy trên thiết bị | [ai-models.md](.agents/skills/reverse-engineering-shield/references/ai-models.md) |
| API và backend | [api.md](.agents/skills/reverse-engineering-shield/references/api.md) |
| Bot và tự động hóa | [server-driven.md](.agents/skills/reverse-engineering-shield/references/server-driven.md) |
| Watermark, canary, pháp lý | [traceability.md](.agents/skills/reverse-engineering-shield/references/traceability.md) |

## Câu hỏi thường gặp

**Chẳng lẽ tôi không thể cứ làm rối mã toàn bộ là xong?**
Obfuscation, bytecode và pinning chỉ làm chậm một nhà phân tích quyết tâm; chúng không ngăn được họ.
Agent rất kiên nhẫn. Chỉ có chuyển giá trị lên server mới thực sự loại bỏ nó. Một số store còn
cấm obfuscation — Chrome Web Store từ chối các tiện ích đã bị làm rối mã.

**Công cụ này có thay thế được security review hay pentest không?**
Không. Nó bao quát những gì artifact phía client và bề mặt công khai của bạn để lộ ra. Hãy kết hợp nó với
công việc bảo mật định kỳ.

**Tôi có thể chạy chế độ URL với bất kỳ trang nào không?**
Chỉ với các tên miền bạn sở hữu hoặc được cho phép kiểm thử một cách rõ ràng.

**Những agent nào được hỗ trợ?**
Bất kỳ agent nào nạp skill dạng `SKILL.md` (Claude Code, Codex, Cursor, Gemini CLI và
các agent khác). Script audit là Bash thuần và chạy ở bất cứ đâu có `curl`, `unzip` và `grep`.

## Đóng góp

Chúng tôi hoan nghênh issue và pull request — đặc biệt là các mẫu bí mật, stack và playbook mới.
Xem [CONTRIBUTING.md](CONTRIBUTING.md). Hãy chạy `bash tests/run.sh` trước khi mở PR.

## Giấy phép

[MIT](LICENSE) © Chosing Dept. Xem [DISCLAIMER.md](DISCLAIMER.md).
