# Desktop apps (Electron, Tauri, native, Python)

## Electron

- `app.asar` opens in seconds (`npx @electron/asar extract`). Packaging is not protection.
- No source maps in the package; devtools closed in production.
- Turn on Electron fuses: `EnableEmbeddedAsarIntegrityValidation`, `OnlyLoadAppFromAsar`,
  and turn off `RunAsNode` and `EnableNodeCliInspectArguments`.
- Optional: compile sensitive main-process modules to V8 bytecode (e.g. bytenode).
  It delays reading; it does not hide logic from a determined analyst.
- Keep valuable logic on the server.

## Tauri

- Frontend assets are embedded in the binary but still extractable; apply the
  [web](web.md) checklist to them. Rust code compiles to native code: strip symbols.

## Native (C, C++, Rust, Go, Swift)

- Strip symbols in release builds; keep debug info private.
- Remember that decompilers (Ghidra, IDA, Hopper) produce readable pseudocode;
  secrets and rules still belong on the server.

## Python

- `.py` and `.pyc` are trivial to read; PyInstaller bundles are extractable.
- Do not distribute valuable Python to clients; run it as a service.
- If you must ship it, compiling with Nuitka raises the cost.

## Verify

```bash
scripts/audit.sh app.asar
scripts/audit.sh path/to/unpacked/resources
```
