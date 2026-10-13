# Web apps (SPA, SSR, static sites)

Everything in the browser bundle is public. Treat it like a press release.

## Build configuration

**Vite**
```ts
// vite.config.ts
export default defineConfig(({ mode }) => ({
  build: {
    sourcemap: false,            // or 'hidden' ONLY if maps are uploaded to your error tracker and deleted from dist
  },
  esbuild: {
    drop: mode === 'production' ? ['console', 'debugger'] : [],
    legalComments: 'none',
  },
}))
```

**Create React App**: build with `GENERATE_SOURCEMAP=false`. CRA's default publishes
full source maps and lists them in `asset-manifest.json` — one of the most common leaks.

**Next.js**: keep `productionBrowserSourceMaps: false` (default). Import the
`server-only` package in modules that must never reach the client, so a stray import
from a `'use client'` component fails the build. Only `NEXT_PUBLIC_*` variables reach
the browser — never put secrets there.

**webpack**: `devtool: false` in production; Terser with `compress.drop_console: true`
and `format.comments: false`.

## Environment variables

`VITE_*`, `NEXT_PUBLIC_*`, `REACT_APP_*`, `EXPO_PUBLIC_*` and anything read through
`import.meta.env` are inlined **verbatim** into the bundle. Only identifiers that are
public by design belong there.

## Code that should not be in the bundle

- Admin and internal screens: lazy-load them and authorize on the server; a user without
  permission should never download that chunk.
- Business rules: if a component computes a price, a score, a ranking or an eligibility
  result, move the computation to an endpoint and render its output.
- AI prompts and model routing: always server-side; the client sends user input only.
- Feature-complete mocks, fixtures and seed data: exclude from production builds.

## Server and CDN

- Block `*.map`, `/.git/`, `/.env`, backup files (`*.bak`, `*.old`) at the edge.
- Do not serve `asset-manifest.json` if it lists maps.
- Disable directory listing.
- Send `X-Robots-Tag: noindex` on internal app routes.

## Obfuscation (optional)

For a web app, `javascript-obfuscator` on a whole React bundle costs performance and
gives little. Use it only on the few modules that must run on the client and reveal
something valuable (for example, a client-side watermark check). Prefer moving the logic.

## Verify

```bash
scripts/audit.sh dist
scripts/audit.sh https://your-domain.example
```
