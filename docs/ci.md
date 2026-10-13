# Release gate in CI

Run the audit on the artifact you actually publish, after the production build.

## GitHub Actions

```yaml
name: release-gate
on: [push, pull_request]
jobs:
  shield:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm run build
      - name: Reverse Engineering Shield audit
        run: |
          curl -fsSL https://raw.githubusercontent.com/ChosingDept/reverse-engineering-shield/main/.agents/skills/reverse-engineering-shield/scripts/audit.sh -o audit.sh
          chmod +x audit.sh
          ./audit.sh dist || [ $? -eq 1 ]   # fail on CRITICAL (exit 2), allow WARNING (exit 1)
        env:
          SHIELD_TERMS: "pricing,margin"
```

Pin a tag or commit instead of `main` for reproducible builds.

## Any CI

```bash
./audit.sh dist; code=$?
[ $code -ge 2 ] && { echo "blocked by reverse-engineering-shield"; exit 1; }
```

## Self-attack with REA (optional, local)

```bash
npx -y rea-agents analyze-javascript-application "$(pwd)/dist" --json > rea-report.json
```

Read the report asking: *can I explain how our key feature decides from this?* If yes,
move that decision to the server.
