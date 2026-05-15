# webapp

FastAPI + HTMX storefront. Event source for the platform (Phase 1).

See the master plan at `../../docs/superpowers/plans/2026-05-15-phase-1-webapp-oltp.md` and the spec addendum at `../../docs/superpowers/specs/2026-05-08-event-driven-realtime-analytics-design.md` § 15.

## Run locally

From the repo root:

\`\`\`bash
make up-core      # Postgres
make up-webapp    # webapp + Postgres
curl http://localhost:8000/healthz
\`\`\`
