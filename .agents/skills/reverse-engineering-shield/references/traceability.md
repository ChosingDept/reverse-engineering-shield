# Traceability and legal

When someone copies anyway, you want to know who, and to be able to prove it.

## Build watermarks

- Embed a per-customer or per-tenant build id in client artifacts (for extensions and
  desktop apps distributed per customer). Spread it across a few innocuous-looking
  constants rather than one obvious string.
- Log which build id each customer received.

## Canary records

- Seed each tenant's data with a few fictional but plausible records (a supplier, a
  product, a document). If they show up in a competitor's product, you have proof of
  copying and you know which tenant's data leaked.
- Honeytoken credentials in internal docs and repos: any use triggers an alert.

## Legal layer (complements engineering, never replaces it)

- Terms of service that prohibit reverse engineering, scraping and unauthorized
  automated access, accepted by every user.
- Copyright notices in your client artifacts and software registration where your
  jurisdiction offers it.
- Keep audit logs and watermark/canary evidence; they are what makes a takedown or a
  lawsuit viable.

Laws on reverse engineering differ by country (interoperability exceptions are common).
Consult a lawyer for your jurisdiction; this file is not legal advice.
