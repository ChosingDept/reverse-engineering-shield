# Security policy

## Reporting a vulnerability

Please report security issues in this project (for example, a way to make the audit
script execute untrusted content, or a pattern that prints a full secret) **privately**
through GitHub: *Security* tab → *Report a vulnerability*. Do not open a public issue.

We aim to acknowledge reports within 5 business days.

## Scope

- `scripts/audit.sh`, `install.sh` and the skill instructions in this repository.
- Out of scope: vulnerabilities in third-party sites or apps found with this tool.
  Report those to their owners.

## Safe use

- The URL mode only sends ordinary GET requests, like a browser. Run it only against
  domains you own or are authorized to test.
- The audit never prints a complete secret; matches are truncated.
