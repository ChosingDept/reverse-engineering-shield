# Instructions for coding agents working on this repository

- The skill lives in `.agents/skills/reverse-engineering-shield/`. `SKILL.md` stays short;
  stack details go in `references/`.
- `scripts/audit.sh` must remain plain Bash with only `curl`, `unzip`, `grep`, `sed`,
  `awk`, `find` and `od` (Linux and macOS). Never print a full secret.
- Every change to the audit needs a test in `tests/run.sh`; fixtures are generated at
  runtime, never committed.
- Run `bash tests/run.sh` and ShellCheck before committing.
- `README.md` is the source of truth for translations.
