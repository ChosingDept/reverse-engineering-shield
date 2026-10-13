# Server-driven clients: bots, automations and robots

Use this pattern whenever a client (extension, desktop agent, mobile app, RPA worker on
a customer machine) acts on third-party sites or makes decisions with business value —
auctions, bidding, pricing, trading assistants, form automation.

## The pattern: the server decides, the client executes

1. The client observes and reports state:
   `POST /bot/next-action { session, observed: { page, fields, timer, ... } }`
2. The server decides and returns a short, signed **order** — data, not code:
   ```json
   { "action": "fill", "target": "bid-input", "value": "1234.56",
     "expires_at": "2026-01-01T12:00:05Z", "nonce": "7f3c...", "signature": "..." }
   ```
3. The client verifies the signature and expiry, executes, and reports the outcome.
   **Why** that value was chosen never leaves the server.

## Rules

- Orders expire in seconds and are single-use (nonce stored server-side).
- License and ownership are checked on every request, not at install time.
- Selectors, timing parameters and supported-site lists are served by version, so the
  server can rotate them and refuse old or leaked versions.
- Kill switch per customer and per client version.
- The client never contains thresholds, floors, margins or strategy tables — not even
  "defaults".
- In browser extensions, send data only: Manifest V3 forbids executing remote code.

## Trade-off

If the server is down, the bot stops. That is the price of not shipping the brain.
Mitigate with redundancy and short local retries, not with local decision logic.
