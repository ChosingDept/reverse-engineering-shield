<div align="center">

[English](README.md) · [简体中文](README_zh.md) · [繁體中文](README_zh-TW.md) · [日本語](README_ja.md) · [한국어](README_ko.md) · **Türkçe** · [Русский](README_ru.md) · [Tiếng Việt](README_vi.md) · [ไทย](README_th.md) · [Deutsch](README_de.md) · [Español](README_es.md) · [Français](README_fr.md) · [Українська](README_uk.md) · [Polski](README_pl.md) · [Português (Brasil)](README_pt-BR.md) · [العربية](README_ar.md) · [فارسی](README_fa.md) · [Bahasa Indonesia](README_id.md) · [Italiano](README_it.md)

# Reverse Engineering Shield

### Tersine mühendisliği işe yaramaz hale getirin.

**Ajanınız her uygulamayı okuyabilir. Rakibinizinki de. Okumaya değmeyen kod yayınlayın.**

[![CI](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml/badge.svg)](https://github.com/ChosingDept/reverse-engineering-shield/actions/workflows/ci.yml)
[![MIT license](https://img.shields.io/badge/license-MIT-f4c430?style=flat-square)](LICENSE)
[![Agent skill](https://img.shields.io/badge/agent-skill-5c4ee5?style=flat-square)](.agents/skills/reverse-engineering-shield/SKILL.md)

<code>npx skills add ChosingDept/reverse-engineering-shield</code>

</div>

---

[REA](https://github.com/morluto/rea) gibi ajan araçları, herhangi bir web uygulamasının, tarayıcı
eklentisinin, Electron uygulamasının, APK/IPA dosyasının ya da yerel ikili dosyanın nasıl çalıştığını
kaynak koda ihtiyaç duymadan dakikalar içinde açıklayabilir. Yayınladığınız şeyin birileri tarafından
*okunmasını* engellemenin hiçbir yolu yok.

**Reverse Engineering Shield**, bu okumayı anlamsız kılan bir ajan becerisi (skill) ve bir denetim
betiğidir. Kodlama ajanınıza (Claude Code, Codex, Cursor, Gemini CLI ve diğerleri) değerli kısımları
sunucuda tutmayı, istemci kodunu haritasız yayınlamayı, her şeyi sunucu tarafında yeniden doğrulamayı,
geriye kalanı pahalı ve izlenebilir hale getirmeyi ve her sürümden önce kendi derlemenize saldırmayı öğretir.

**Her yığındaki her uygulamayı** kapsar: web, tarayıcı eklentileri, mobil, masaüstü, .NET ve JVM, oyunlar,
WebAssembly, SDK'lar ve paketler, konteynerler ve şirket içi (on-prem) kurulumlar, donanım yazılımı/IoT,
yapay zeka özellikleri ve cihaz üzerinde çalışan modeller — ve hepsinin arkasındaki API'ler.

## Hızlı başlangıç

### Beceriyi yükleyin

```bash
npx skills add ChosingDept/reverse-engineering-shield
```

Ya da yükleyiciyle (varsayılan olarak beceriyi `~/.claude/skills` dizinine kopyalar):

```bash
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash
# another skills directory:
curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/install.sh | bash -s -- --dir ~/.codex/skills
```

Ya da `.agents/skills/reverse-engineering-shield` klasörünü ajanınızın beceri klasörüne kopyalayın.

### Ajanınıza sorun

> Eklentiyi yayınlamadan önce bu projeyi reverse-engineering-shield ile gözden geçir.

> Fiyatlandırma mantığımız React uygulamasında. reverse-engineering-shield'a uyarak bunu API'nin arkasına taşı.

> `dist/` klasörünü ve canlı sitemizi denetle, ardından tüm CRITICAL bulguları düzelt.

### Ya da denetimi kendiniz çalıştırın

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

`2` çıkış kodu sürümü engeller, `1` bir gerekçe ister, `0` temiz demektir; doğrudan
CI'a eklenmeye hazırdır ([örnek](docs/ci.md)).

## Nasıl çalışır

### Beş ilke

1. **Beyin sunucuda kalır.** Kurallar, fiyatlandırma, puanlama, istemler (prompt), seçiciler ve
   sezgisel yöntemler API'nizin arkasında yaşar. İstemci yalnızca görüntüler ve çalıştırır.
2. **İstemciye giden şey haritasız gider.** Herkese açık source map yok, küçültülmüş (minified) kod,
   yorum yok, `console` yok, dahili adlar yok, hata ayıklama rotaları yok.
3. **Sunucu istemciye asla güvenmez.** Lisanslar, sahiplik, limitler ve fiyatlar
   her istekte yeniden doğrulanır.
4. **İstemcide kalması gereken şey pahalı ve izlenebilir olur.** Mağazaların izin verdiği yerlerde
   hedefli gizleme (obfuscation), müşteri başına filigranlar, kanarya kayıtları.
5. **Yayınlamadan önce kendinize saldırın.** Denetimi ve REA'yı nihai yapıt üzerinde çalıştırın.
   REA bir özelliğin nasıl karar verdiğini açıklayabiliyorsa, bir rakip de açıklayabilir.

### Denetimin kontrol ettikleri

| Kontrol | Önem derecesi |
|---|---|
| Yapıttaki `.map` dosyaları, satır içi haritalar, canlı sitedeki herkese açık haritalar, haritaları listeleyen `asset-manifest.json` | CRITICAL |
| Sunucu sırları: AWS, özel anahtarlar, `sk_live_`, LLM sağlayıcı anahtarları, GitHub/Slack token'ları, parola içeren veritabanı URL'leri, hizmet hesapları | CRITICAL (çıktıda maskelenir) |
| Canlı sitede açıkta olan `/.git/` ve `/.env` | CRITICAL |
| Kodda bırakılmış `sourceMappingURL` yorumları | WARNING |
| Google/Firebase anahtarları, koda gömülü JWT'ler | WARNING |
| `localhost`, özel IP'ler, staging/homolog sunucuları | WARNING |
| İstemciye gönderilen yapay zeka istemleri (`You are…`, `systemPrompt`, `role: "system"`) | WARNING |
| Size özgü iş terimleri (`SHIELD_TERMS`) | WARNING |
| Küçültülmemiş dosyalar, unutulmuş `console.log`/`debugger` satırları | WARNING |
| Hermes bayt koduna derlenmemiş React Native paketi | WARNING |
| Canlı sitede erişilebilen Swagger/OpenAPI/GraphQL uç noktaları | WARNING |

Girdiler: derleme klasörleri, `.zip`, `.crx`, `.xpi`, `.apk`, `.aab`, `.ipa`, `.asar` ya da bir URL.

### Teknoloji yığını kılavuzları

Beceri, ajanın ilgili olduğunda yüklediği odaklı kontrol listeleriyle birlikte gelir:

| Yığın | Kılavuz |
|---|---|
| Web uygulamaları (Vite, CRA, Next.js, webpack) | [web.md](.agents/skills/reverse-engineering-shield/references/web.md) |
| Tarayıcı eklentileri (Chrome MV3, Firefox) | [extensions.md](.agents/skills/reverse-engineering-shield/references/extensions.md) |
| Mobil (React Native/Expo, Android, iOS, Flutter) | [mobile.md](.agents/skills/reverse-engineering-shield/references/mobile.md) |
| Masaüstü (Electron, Tauri, yerel, Python) | [desktop.md](.agents/skills/reverse-engineering-shield/references/desktop.md) |
| .NET ve JVM (C#, Java, Kotlin, Scala, Android bayt kodu) | [managed-runtimes.md](.agents/skills/reverse-engineering-shield/references/managed-runtimes.md) |
| Oyunlar (Unity, Unreal, Godot) | [games.md](.agents/skills/reverse-engineering-shield/references/games.md) |
| WebAssembly | [webassembly.md](.agents/skills/reverse-engineering-shield/references/webassembly.md) |
| SDK'lar, paketler, konteynerler, şirket içi kurulumlar | [packages.md](.agents/skills/reverse-engineering-shield/references/packages.md) |
| Donanım yazılımı, gömülü sistemler, IoT | [embedded.md](.agents/skills/reverse-engineering-shield/references/embedded.md) |
| Yapay zeka özellikleri ve cihaz üzerinde çalışan modeller | [ai-models.md](.agents/skills/reverse-engineering-shield/references/ai-models.md) |
| API'ler ve arka uçlar | [api.md](.agents/skills/reverse-engineering-shield/references/api.md) |
| Botlar ve otomasyonlar | [server-driven.md](.agents/skills/reverse-engineering-shield/references/server-driven.md) |
| Filigranlar, kanaryalar, hukuki konular | [traceability.md](.agents/skills/reverse-engineering-shield/references/traceability.md) |

## SSS

**Her şeyi gizlesem (obfuscate) yetmez mi?**
Gizleme, bayt kodu ve pinning kararlı bir analisti yavaşlatır, durdurmaz.
Ajanlar sabırlıdır. Değeri ortadan kaldırmanın tek yolu onu sunucuya taşımaktır. Ayrıca bazı mağazalar
gizlemeyi yasaklar; Chrome Web Store gizlenmiş eklentileri reddeder.

**Bu, güvenlik incelemelerinin veya sızma testlerinin yerini alır mı?**
Hayır. İstemci yapıtlarınızın ve herkese açık yüzeyinizin neleri ortaya çıkardığını kapsar. Düzenli
güvenlik çalışmalarıyla birlikte kullanın.

**URL modunu herhangi bir sitede çalıştırabilir miyim?**
Yalnızca sahibi olduğunuz ya da test etmek için açıkça yetkilendirildiğiniz alan adlarında.

**Hangi ajanlar destekleniyor?**
`SKILL.md` becerilerini yükleyebilen her ajan (Claude Code, Codex, Cursor, Gemini CLI ve diğerleri).
Denetim betiği düz Bash'tir ve `curl`, `unzip` ve `grep` bulunan her yerde çalışır.

## Katkıda bulunma

Issue'lar ve pull request'ler memnuniyetle karşılanır; özellikle yeni sır kalıpları, yığınlar ve
kılavuzlar. [CONTRIBUTING.md](CONTRIBUTING.md) dosyasına bakın. PR açmadan önce `bash tests/run.sh` komutunu çalıştırın.

## Lisans

[MIT](LICENSE) © Chosing Dept. [DISCLAIMER.md](DISCLAIMER.md) dosyasına bakın.
