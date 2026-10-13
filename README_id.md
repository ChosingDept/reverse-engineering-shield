<div align="center">

[English](README.md) · [简体中文](README_zh.md) · [繁體中文](README_zh-TW.md) · [日本語](README_ja.md) · [한국어](README_ko.md) · [Türkçe](README_tr.md) · [Русский](README_ru.md) · [Tiếng Việt](README_vi.md) · [ไทย](README_th.md) · [Deutsch](README_de.md) · [Español](README_es.md) · [Français](README_fr.md) · [Українська](README_uk.md) · [Polski](README_pl.md) · [Português (Brasil)](README_pt-BR.md) · [العربية](README_ar.md) · [فارسی](README_fa.md) · **Bahasa Indonesia** · [Italiano](README_it.md)

# Reverse Engineering Shield

### Buat reverse engineering jadi sia-sia.

**Agen Anda bisa membaca aplikasi apa pun. Agen pesaing Anda juga. Rilis kode yang tidak ada gunanya untuk dibaca.**

[![CI](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml/badge.svg)](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml)
[![MIT license](https://img.shields.io/badge/license-MIT-f4c430?style=flat-square)](LICENSE)
[![Agent skill](https://img.shields.io/badge/agent-skill-5c4ee5?style=flat-square)](.agents/skills/reverse-engineering-shield/SKILL.md)

<code>npx skills add ChosingDept/reverse-engineering-shield</code>

</div>

---

Tool agen seperti [REA](https://github.com/morluto/rea) dapat menjelaskan cara kerja aplikasi
web, ekstensi browser, aplikasi Electron, APK/IPA, atau binary native apa pun — dalam
hitungan menit, tanpa kode sumber. Tidak ada cara untuk mencegah seseorang *membaca* apa
yang Anda rilis.

**Reverse Engineering Shield** adalah skill agen beserta skrip audit yang membuat pembacaan
itu tidak ada gunanya. Skill ini mengajari agen coding Anda (Claude Code, Codex, Cursor,
Gemini CLI, dan lainnya) untuk menyimpan bagian yang bernilai di server, merilis kode klien
tanpa map, memvalidasi ulang semuanya di sisi server, membuat sisanya mahal dan dapat
dilacak — serta menyerang build Anda sendiri sebelum setiap rilis.

Skill ini mencakup **aplikasi apa pun di stack apa pun**: web, ekstensi browser, mobile,
desktop, .NET dan JVM, game, WebAssembly, SDK dan paket, container dan instalasi
on-premise, firmware/IoT, fitur AI dan model on-device — serta API di balik semuanya.

## Mulai cepat

### Instal skill

```bash
npx skills add ChosingDept/reverse-engineering-shield
```

Atau dengan installer (secara default menyalin skill ke `~/.claude/skills`):

```bash
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash
# another skills directory:
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash -s -- --dir ~/.codex/skills
```

Atau salin `.agents/skills/reverse-engineering-shield` ke folder skill agen Anda.

### Minta ke agen Anda

> Tinjau proyek ini dengan reverse-engineering-shield sebelum kita memublikasikan ekstensinya.

> Logika harga kita ada di aplikasi React. Pindahkan ke balik API sesuai reverse-engineering-shield.

> Audit `dist/` dan situs produksi kita, lalu perbaiki setiap CRITICAL.

### Atau jalankan audit sendiri

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

Exit code `2` memblokir rilis, `1` meminta justifikasi, `0` berarti bersih — siap untuk
CI ([contoh](docs/ci.md)).

## Cara kerjanya

### Lima prinsip

1. **Otaknya tetap di server.** Aturan, harga, scoring, prompt, selector, dan
   heuristik berada di balik API Anda. Klien hanya me-render dan mengeksekusi.
2. **Apa yang dikirim ke klien dikirim tanpa map.** Tanpa source map publik, di-minify,
   tanpa komentar, tanpa `console`, tanpa nama internal, tanpa rute debug.
3. **Server tidak pernah memercayai klien.** Lisensi, kepemilikan, batas, dan harga
   divalidasi ulang di setiap request.
4. **Apa yang harus tetap di klien dibuat mahal dan dapat dilacak.** Obfuskasi terarah
   di mana store mengizinkannya, watermark per pelanggan, record canary.
5. **Serang diri sendiri sebelum merilis.** Jalankan audit dan REA terhadap artefak final.
   Jika REA bisa menjelaskan bagaimana sebuah fitur mengambil keputusan, pesaing juga bisa.

### Apa yang diperiksa audit

| Pemeriksaan | Tingkat keparahan |
|---|---|
| File `.map` di artefak, map inline, map publik di situs live, `asset-manifest.json` yang mencantumkan map | CRITICAL |
| Rahasia server: AWS, private key, `sk_live_`, key penyedia LLM, token GitHub/Slack, URL database berisi kata sandi, service account | CRITICAL (disamarkan di output) |
| `/.git/` dan `/.env` terekspos di situs live | CRITICAL |
| Komentar `sourceMappingURL` yang tertinggal di kode | WARNING |
| Key Google/Firebase, JWT yang di-hard-code | WARNING |
| `localhost`, IP privat, host staging/homolog | WARNING |
| Prompt AI yang terkirim ke klien (`You are…`, `systemPrompt`, `role: "system"`) | WARNING |
| Istilah bisnis Anda sendiri (`SHIELD_TERMS`) | WARNING |
| File yang belum di-minify, sisa `console.log`/`debugger` | WARNING |
| Bundle React Native yang tidak dikompilasi ke bytecode Hermes | WARNING |
| Endpoint Swagger/OpenAPI/GraphQL yang dapat diakses di situs live | WARNING |

Input: folder build, `.zip`, `.crx`, `.xpi`, `.apk`, `.aab`, `.ipa`, `.asar`, atau URL.

### Playbook per stack

Skill ini menyertakan checklist terfokus yang dimuat agen saat relevan:

| Stack | Playbook |
|---|---|
| Aplikasi web (Vite, CRA, Next.js, webpack) | [web.md](.agents/skills/reverse-engineering-shield/references/web.md) |
| Ekstensi browser (Chrome MV3, Firefox) | [extensions.md](.agents/skills/reverse-engineering-shield/references/extensions.md) |
| Mobile (React Native/Expo, Android, iOS, Flutter) | [mobile.md](.agents/skills/reverse-engineering-shield/references/mobile.md) |
| Desktop (Electron, Tauri, native, Python) | [desktop.md](.agents/skills/reverse-engineering-shield/references/desktop.md) |
| .NET dan JVM (C#, Java, Kotlin, Scala, bytecode Android) | [managed-runtimes.md](.agents/skills/reverse-engineering-shield/references/managed-runtimes.md) |
| Game (Unity, Unreal, Godot) | [games.md](.agents/skills/reverse-engineering-shield/references/games.md) |
| WebAssembly | [webassembly.md](.agents/skills/reverse-engineering-shield/references/webassembly.md) |
| SDK, paket, container, instalasi on-premise | [packages.md](.agents/skills/reverse-engineering-shield/references/packages.md) |
| Firmware, embedded, IoT | [embedded.md](.agents/skills/reverse-engineering-shield/references/embedded.md) |
| Fitur AI dan model on-device | [ai-models.md](.agents/skills/reverse-engineering-shield/references/ai-models.md) |
| API dan backend | [api.md](.agents/skills/reverse-engineering-shield/references/api.md) |
| Bot dan otomatisasi | [server-driven.md](.agents/skills/reverse-engineering-shield/references/server-driven.md) |
| Watermark, canary, aspek hukum | [traceability.md](.agents/skills/reverse-engineering-shield/references/traceability.md) |

## FAQ

**Tidak bisakah saya mengobfuskasi semuanya saja?**
Obfuskasi, bytecode, dan pinning hanya memperlambat analis yang gigih; tidak menghentikannya.
Agen itu sabar. Hanya memindahkan nilai ke server yang benar-benar menghilangkannya. Beberapa
store juga melarang obfuskasi — Chrome Web Store menolak ekstensi yang diobfuskasi.

**Apakah ini menggantikan security review atau pentest?**
Tidak. Ini mencakup apa yang terungkap dari artefak klien dan permukaan publik Anda.
Padukan dengan pekerjaan keamanan rutin.

**Bisakah saya menjalankan mode URL terhadap situs apa pun?**
Hanya terhadap domain milik Anda atau yang Anda miliki izin eksplisit untuk mengujinya.

**Agen apa saja yang didukung?**
Agen apa pun yang memuat skill `SKILL.md` (Claude Code, Codex, Cursor, Gemini CLI, dan
lainnya). Skrip audit ini Bash murni dan berjalan di mana saja yang memiliki `curl`, `unzip`, dan `grep`.

## Berkontribusi

Issue dan pull request sangat diterima — terutama pola rahasia, stack, dan playbook baru.
Lihat [CONTRIBUTING.md](CONTRIBUTING.md). Jalankan `bash tests/run.sh` sebelum membuka PR.

## Lisensi

[MIT](LICENSE) © Chosing Dept. Lihat [DISCLAIMER.md](DISCLAIMER.md).
