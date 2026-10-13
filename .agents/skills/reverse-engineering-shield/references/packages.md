# SDKs, packages, containers and on-premise installs

When customers install your software on their machines or servers, they hold every file.

## Published packages (npm, PyPI, NuGet, Maven, crates, gems)

- Use an allowlist of published files (`files` in `package.json`, `MANIFEST.in`,
  `.npmignore`, `<None Pack="false">`) instead of publishing the whole folder.
  Check the result before release: `npm pack --dry-run`, `python -m build` + inspect the
  wheel, `dotnet pack` + inspect the `.nupkg`.
- Never publish tests with real fixtures, `.env` files, internal docs or scripts.
- A proprietary SDK should be a thin client of your API, not a copy of your engine.

## Python delivered to customers

- `.py` and `.pyc` are readable; PyInstaller bundles unpack easily.
- Deliver a service (API, container you host) instead of code when the logic is valuable.
- If code must run on the customer side, compile the sensitive modules (Cython, Nuitka)
  and keep license checks on the server.

## Containers and on-premise installs

- Images are layered tarballs: every file in every layer is readable, including files
  deleted in a later layer. Use multi-stage builds and copy only runtime artifacts.
- No secrets in `ENV`, build args or image layers; inject them at runtime.
- Ship compiled artifacts, not source trees, in the final stage.
- Online license validation with short-lived tokens, plus a kill switch per installation.
- Watermark each customer's build (see [traceability.md](traceability.md)).

## Verify

```bash
scripts/audit.sh my-sdk-1.2.0.tgz          # npm pack output
scripts/audit.sh dist/my_pkg-1.2.0-py3-none-any.whl
scripts/audit.sh unpacked-image/           # filesystem exported from the final image
```
