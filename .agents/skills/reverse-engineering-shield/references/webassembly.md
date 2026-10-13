# WebAssembly

Moving logic from JavaScript to WASM does not hide it. The module is downloaded by every
visitor and decompiles to readable pseudo-code; it only raises the cost a little.

- Keep business rules on the server; use WASM for performance, not for secrecy.
- Release builds without debug info: `wasm-opt --strip-debug --strip-producers` (Binaryen),
  Rust `[profile.release] debug = false` and `strip = true`, Emscripten without `-g`.
- Remove the `name` section (function names) in release builds.
- Do not embed keys or tokens; WASM data segments are plain bytes.
- Blazor WebAssembly ships .NET assemblies to the browser: see
  [managed-runtimes.md](managed-runtimes.md).

## Verify

```bash
scripts/audit.sh dist/        # the folder that serves the .wasm and its JS glue
```
