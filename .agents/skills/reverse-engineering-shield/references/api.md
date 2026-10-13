# APIs and backends

Your API responses are the "source code" of your data. A clean client with a leaky API
is still a leak.

## Access

- Authentication on every route; authorization by owner/tenant/scope on every resource
  (prevent IDOR — `GET /items/123` must check that item 123 belongs to the caller).
- Re-validate on the server everything the client "already checked": license, plan
  limits, prices, quantities, state transitions.
- Non-sequential identifiers (UUIDs) for exposed resources, so nobody can enumerate them.

## Responses

- Return only the fields the screen uses. Never serialize whole database rows
  (`SELECT *`), internal flags, scoring internals or other tenants' data.
- Generic errors to the client (no stack traces, SQL, table or column names);
  details go to your logs with a correlation id.
- Do not echo upstream provider errors verbatim (they reveal your vendors and keys' scopes).

## Surface

- Swagger/OpenAPI UIs, GraphQL introspection, `/debug`, verbose `/health` and admin
  routes: off in production or behind authentication.
- Strict CORS (explicit origins), no wildcard with credentials.
- Remove test and seed endpoints from production builds.

## Anti-scraping

- Rate limit per user, per tenant and per IP; lower limits on search/listing endpoints.
- Detect scraping patterns: walking pagination to the end, sequential ids, constant
  request intervals, unusual hours, many accounts from one network.
- Cap page sizes and total results per period.
- Seed canary records (see [traceability.md](traceability.md)).

## Verify

```bash
scripts/audit.sh https://api.your-domain.example     # docs and introspection endpoints
```
