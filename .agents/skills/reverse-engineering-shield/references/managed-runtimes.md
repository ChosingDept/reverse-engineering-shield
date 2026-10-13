# Managed runtimes: .NET and the JVM (Java, Kotlin, Scala)

Managed bytecode keeps type names, method names and structure. Decompilers turn it back
into code that reads almost like the original. Plan as if you were shipping source.

## .NET (C#, F#, VB) — desktop, server installs, MAUI, Blazor WebAssembly

- Keep business rules in a service; ship clients that call it.
- **NativeAOT** (`<PublishAot>true</PublishAot>`) compiles to native code: no IL to
  decompile. Prefer it for CLI tools and desktop apps where it is supported.
- `<DebugType>none</DebugType>` in Release, and never ship `.pdb` files.
- If IL must ship (plugins, MAUI on some targets, Blazor WebAssembly): use a maintained
  obfuscator for the sensitive assemblies and remember that **Blazor WebAssembly
  downloads every DLL to the browser** — treat it like a JavaScript bundle.
- Turn off `InternalsVisibleTo` for release builds; remove test assemblies.
- Secrets never in `appsettings.json` shipped with a client app.

## JVM (Java, Kotlin, Scala) — desktop, CLI, SDKs, server software installed by customers

- Shrink and obfuscate release jars (R8 or ProGuard). Keep the mapping file private
  (upload it to your crash reporter only).
- Do not ship `-sources.jar` or `-javadoc.jar` for proprietary artifacts.
- Strip debug attributes for proprietary code if you do not need line numbers in
  customer stack traces (`-g:none`), or keep them and accept the trade-off consciously.
- Fat/uber jars bundle everything: audit the final jar, not your module.
- License checks belong on the server; a local `if (licensed)` is one edit away.

## Android bytecode (DEX)

- `minifyEnabled true` + R8 full mode for release; keep `mapping.txt` private.
- Kotlin metadata and reflection keep names alive: review keep rules so they do not
  preserve whole packages by accident.

## Verify

```bash
scripts/audit.sh build/libs/app.jar
scripts/audit.sh bin/Release/net8.0/publish/
```

Then check by hand: no `.pdb`, no `mapping.txt`, no `-sources.jar` in what you publish.
