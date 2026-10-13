<div align="center">

[English](README.md) · [简体中文](README_zh.md) · [繁體中文](README_zh-TW.md) · [日本語](README_ja.md) · [한국어](README_ko.md) · [Türkçe](README_tr.md) · [Русский](README_ru.md) · [Tiếng Việt](README_vi.md) · **ไทย** · [Deutsch](README_de.md) · [Español](README_es.md) · [Français](README_fr.md) · [Українська](README_uk.md) · [Polski](README_pl.md) · [Português (Brasil)](README_pt-BR.md) · [العربية](README_ar.md) · [فارسی](README_fa.md) · [Bahasa Indonesia](README_id.md) · [Italiano](README_it.md)

# Reverse Engineering Shield

### ทำให้การทำวิศวกรรมย้อนกลับไร้ประโยชน์

**เอเจนต์ของคุณอ่านแอปไหนก็ได้ เอเจนต์ของคู่แข่งก็เช่นกัน จงส่งมอบโค้ดที่อ่านไปก็ไม่ได้อะไร**

[![CI](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml/badge.svg)](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml)
[![MIT license](https://img.shields.io/badge/license-MIT-f4c430?style=flat-square)](LICENSE)
[![Agent skill](https://img.shields.io/badge/agent-skill-5c4ee5?style=flat-square)](.agents/skills/reverse-engineering-shield/SKILL.md)

<code>npx skills add ChosingDept/reverse-engineering-shield</code>

</div>

---

เครื่องมือสำหรับเอเจนต์อย่าง [REA](https://github.com/morluto/rea) สามารถอธิบายได้ว่าเว็บแอป
ส่วนขยายเบราว์เซอร์ แอป Electron, APK/IPA หรือไบนารีเนทีฟใด ๆ ทำงานอย่างไร — ภายในไม่กี่นาที
โดยไม่ต้องมีซอร์สโค้ด ไม่มีทางห้ามใครไม่ให้ *อ่าน* สิ่งที่คุณส่งมอบออกไปได้

**Reverse Engineering Shield** คือสกิลสำหรับเอเจนต์พร้อมสคริปต์ตรวจสอบ (audit) ที่ทำให้การอ่านนั้น
ไร้ความหมาย มันสอนเอเจนต์เขียนโค้ดของคุณ (Claude Code, Codex, Cursor, Gemini CLI
และอื่น ๆ) ให้เก็บส่วนที่มีค่าไว้บนเซิร์ฟเวอร์ ส่งมอบโค้ดฝั่งไคลเอนต์โดยไม่มี source map
ตรวจสอบทุกอย่างซ้ำที่ฝั่งเซิร์ฟเวอร์ ทำให้สิ่งที่เหลืออยู่มีต้นทุนสูงในการวิเคราะห์และตรวจย้อนได้ — และ
โจมตีบิลด์ของคุณเองก่อนทุกการปล่อยเวอร์ชัน

## เริ่มต้นอย่างรวดเร็ว

### ติดตั้งสกิล

```bash
npx skills add ChosingDept/reverse-engineering-shield
```

หรือใช้ตัวติดตั้ง (โดยค่าเริ่มต้นจะคัดลอกสกิลไปที่ `~/.claude/skills`):

```bash
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash
# another skills directory:
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash -s -- --dir ~/.codex/skills
```

หรือคัดลอก `.agents/skills/reverse-engineering-shield` ไปไว้ในโฟลเดอร์สกิลของเอเจนต์

### สั่งเอเจนต์ของคุณ

> ตรวจทานโปรเจกต์นี้ด้วย reverse-engineering-shield ก่อนที่เราจะเผยแพร่ส่วนขยาย

> ตรรกะการคิดราคาของเราอยู่ในแอป React ย้ายมันไปไว้หลัง API ตามแนวทางของ reverse-engineering-shield

> ตรวจสอบ `dist/` และเว็บไซต์โปรดักชันของเรา แล้วแก้ไขทุกรายการที่เป็น CRITICAL

### หรือรัน audit ด้วยตัวเอง

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

exit code `2` จะบล็อกการปล่อยเวอร์ชัน, `1` ต้องการคำชี้แจงเหตุผล, `0` คือผ่านสะอาด — พร้อมใช้
กับ CI ([ตัวอย่าง](docs/ci.md))

## หลักการทำงาน

### หลักการห้าข้อ

1. **สมองอยู่บนเซิร์ฟเวอร์** กฎ การคิดราคา การให้คะแนน พรอมต์ ตัวเลือก (selector) และ
   ฮิวริสติกอยู่หลัง API ของคุณ ไคลเอนต์มีหน้าที่แค่เรนเดอร์และเรียกใช้งาน
2. **สิ่งที่ส่งไปถึงไคลเอนต์ต้องไม่มีแผนที่ติดไปด้วย** ไม่มี source map สาธารณะ ผ่านการ minify
   ไม่มีคอมเมนต์ ไม่มี `console` ไม่มีชื่อภายใน ไม่มีเส้นทางสำหรับดีบัก
3. **เซิร์ฟเวอร์ไม่เคยเชื่อไคลเอนต์** ไลเซนส์ ความเป็นเจ้าของ ขีดจำกัด และราคา จะถูก
   ตรวจสอบซ้ำในทุกคำขอ
4. **สิ่งที่จำเป็นต้องอยู่ฝั่งไคลเอนต์ต้องมีต้นทุนสูงและตรวจย้อนได้** ทำ obfuscation แบบเจาะจง
   ในที่ที่สโตร์อนุญาต ใส่ลายน้ำแยกตามลูกค้า และใช้ระเบียน canary
5. **โจมตีตัวเองก่อนส่งมอบ** รัน audit และ REA กับอาร์ทิแฟกต์ตัวสุดท้าย
   ถ้า REA อธิบายได้ว่าฟีเจอร์หนึ่งตัดสินใจอย่างไร คู่แข่งก็อธิบายได้เช่นกัน

### audit ตรวจสอบอะไรบ้าง

| รายการตรวจสอบ | ระดับความรุนแรง |
|---|---|
| ไฟล์ `.map` ในอาร์ทิแฟกต์, map แบบ inline, map สาธารณะบนเว็บไซต์จริง, `asset-manifest.json` ที่ระบุ map | CRITICAL |
| ความลับฝั่งเซิร์ฟเวอร์: AWS, private key, `sk_live_`, คีย์ของผู้ให้บริการ LLM, โทเค็น GitHub/Slack, URL ฐานข้อมูลที่มีรหัสผ่าน, service account | CRITICAL (ปิดบังในผลลัพธ์) |
| `/.git/` และ `/.env` ถูกเปิดเผยบนเว็บไซต์จริง | CRITICAL |
| คอมเมนต์ `sourceMappingURL` ที่หลงเหลืออยู่ในโค้ด | WARNING |
| คีย์ Google/Firebase, JWT ที่ฮาร์ดโค้ดไว้ | WARNING |
| `localhost`, IP ภายใน, โฮสต์ staging/homolog | WARNING |
| พรอมต์ AI ที่ส่งไปถึงไคลเอนต์ (`You are…`, `systemPrompt`, `role: "system"`) | WARNING |
| คำศัพท์ทางธุรกิจของคุณเอง (`SHIELD_TERMS`) | WARNING |
| ไฟล์ที่ยังไม่ minify, `console.log`/`debugger` ที่หลงเหลืออยู่ | WARNING |
| บันเดิล React Native ที่ไม่ได้คอมไพล์เป็น Hermes bytecode | WARNING |
| endpoint ของ Swagger/OpenAPI/GraphQL ที่เข้าถึงได้บนเว็บไซต์จริง | WARNING |

อินพุต: โฟลเดอร์บิลด์, `.zip`, `.crx`, `.xpi`, `.apk`, `.aab`, `.ipa`, `.asar` หรือ URL

### Playbook ตามสแตก

สกิลนี้มาพร้อมเช็กลิสต์เฉพาะทางที่เอเจนต์จะโหลดเมื่อเกี่ยวข้อง:

| สแตก | Playbook |
|---|---|
| เว็บแอป (Vite, CRA, Next.js, webpack) | [web.md](.agents/skills/reverse-engineering-shield/references/web.md) |
| ส่วนขยายเบราว์เซอร์ (Chrome MV3, Firefox) | [extensions.md](.agents/skills/reverse-engineering-shield/references/extensions.md) |
| มือถือ (React Native/Expo, Android, iOS, Flutter) | [mobile.md](.agents/skills/reverse-engineering-shield/references/mobile.md) |
| เดสก์ท็อป (Electron, Tauri, เนทีฟ, Python) | [desktop.md](.agents/skills/reverse-engineering-shield/references/desktop.md) |
| API และแบ็กเอนด์ | [api.md](.agents/skills/reverse-engineering-shield/references/api.md) |
| บอตและระบบอัตโนมัติ | [server-driven.md](.agents/skills/reverse-engineering-shield/references/server-driven.md) |
| ลายน้ำ, canary, ด้านกฎหมาย | [traceability.md](.agents/skills/reverse-engineering-shield/references/traceability.md) |

## คำถามที่พบบ่อย

**ฉันแค่ obfuscate ทุกอย่างไปเลยไม่ได้หรือ?**
obfuscation, bytecode และ pinning ช่วยถ่วงเวลานักวิเคราะห์ที่มุ่งมั่นได้ แต่หยุดเขาไม่ได้
เอเจนต์มีความอดทนสูง มีเพียงการย้ายสิ่งที่มีค่าไปไว้บนเซิร์ฟเวอร์เท่านั้นที่จะกำจัดมันออกไปได้ บางสโตร์ยัง
ห้าม obfuscation ด้วย — Chrome Web Store ปฏิเสธส่วนขยายที่ผ่านการ obfuscate

**สิ่งนี้ใช้แทน security review หรือ pentest ได้หรือไม่?**
ไม่ได้ มันครอบคลุมเฉพาะสิ่งที่อาร์ทิแฟกต์ฝั่งไคลเอนต์และพื้นผิวสาธารณะของคุณเปิดเผยออกมา ควรใช้ควบคู่กับ
งานด้านความปลอดภัยตามปกติ

**ฉันรันโหมด URL กับเว็บไซต์ใดก็ได้หรือไม่?**
ได้เฉพาะกับโดเมนที่คุณเป็นเจ้าของ หรือได้รับอนุญาตอย่างชัดแจ้งให้ทดสอบเท่านั้น

**รองรับเอเจนต์ใดบ้าง?**
เอเจนต์ใดก็ได้ที่โหลดสกิลแบบ `SKILL.md` (Claude Code, Codex, Cursor, Gemini CLI และ
อื่น ๆ) สคริปต์ audit เป็น Bash ล้วน และรันได้ทุกที่ที่มี `curl`, `unzip` และ `grep`

## การมีส่วนร่วม

ยินดีรับ issue และ pull request — โดยเฉพาะรูปแบบความลับ สแตก และ playbook ใหม่ ๆ
ดู [CONTRIBUTING.md](CONTRIBUTING.md) รัน `bash tests/run.sh` ก่อนเปิด PR

## สัญญาอนุญาต

[MIT](LICENSE) © Chosing Dept. ดู [DISCLAIMER.md](DISCLAIMER.md)
