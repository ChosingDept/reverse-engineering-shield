# Contributing

Thanks for helping make reverse engineering useless.

## What helps most

- **Secret patterns** for providers the audit does not catch yet (with a public reference
  to the key format). Patterns must be case-sensitive and specific enough not to match
  random base64.
- **Stack playbooks**: new frameworks, stores and platforms, or corrections to existing
  ones. Cite official documentation for build flags and store policies.
- **False positives/negatives** in `scripts/audit.sh`, with a minimal reproduction.

## Ground rules

- Defensive only. This project helps teams protect what they ship. Contributions that
  teach how to break third-party software, bypass store policies or scrape sites
  without authorization will be closed.
- Never commit real secrets. Tests generate secret-looking fixtures at runtime
  (see `tests/run.sh`); follow the same approach.
- Keep the skill agent-agnostic: no instructions tied to a single vendor's tools unless
  marked as optional.

## Development

```bash
bash tests/run.sh                       # all tests must pass
shellcheck -S warning .agents/skills/reverse-engineering-shield/scripts/audit.sh tests/run.sh install.sh
```

Translations: `README.md` is the source of truth. If you change it, open an issue or
update the `README_*.md` files you can review confidently.
