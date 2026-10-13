# Browser extensions (Chrome MV3, Edge, Firefox)

An installed extension is a zip on the user's disk. Anyone can unpack it.

## Store rules change the playbook

- **Chrome Web Store forbids obfuscated code** (minification is allowed). Do not run
  `javascript-obfuscator` on an extension you publish there; it gets rejected.
- **Manifest V3 forbids remotely hosted code**: no `eval`, no downloading and running JS.
  The server may send **data** (orders, selectors, parameters), never code.
- **Firefox (AMO)** requires you to submit readable source for any minified build.

So for extensions the only real protection is principle 1: keep decisions on the server.

## Build

- `sourcemap: false` in the extension's Vite/webpack config, and confirm the packaged
  `.zip` contains no `.map` and no `sourceMappingURL` comments.
- Minify, drop `console`/`debugger`, strip comments.
- No API keys for paid providers inside the extension; call your own API with the user's token.
- Remove `localhost` and staging URLs from production builds (inject per environment).

## Architecture

- Content scripts **observe** the page and **execute** orders; they do not decide.
- Selectors, timing parameters and site lists come from your server, versioned, so a
  leaked build is useless without a valid session (see [server-driven.md](server-driven.md)).
- Check the license on every server call, not once at install.
- Keep a kill switch per version and per customer.

## Verify

```bash
scripts/audit.sh extension.zip
scripts/audit.sh dist/
```
