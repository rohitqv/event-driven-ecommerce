# Event-Driven Real-Time Analytics Platform

A production-grade streaming data platform on **Kafka + Flink + ClickHouse + Kubernetes**, framed as a hybrid e-commerce backend so the data shape is realistic.

> **Status:** Phase 0 complete. Phase 1 (webapp + OLTP) next. Roadmap below.

## Why this exists
Demonstrates real-world data engineering patterns: windowed aggregations, sessionization, stream-stream/stream-table joins, change-data-capture, exactly-once processing, schema evolution, full observability — runnable on a laptop, deployable to Kubernetes.

## Quick start (Phase 0)
```bash
make up-core   # brings up Postgres
make down      # tears it down
```

## Architecture
See [`docs/architecture.md`](docs/architecture.md). Decisions live in [`docs/adr/`](docs/adr/).

## What works today (Phase 0)
- `make up-core` brings up Postgres 16 in Docker.
- `make psql` opens a psql shell.
- `make lint` runs ruff + black + hadolint + yamllint via pre-commit.
- GitHub Actions runs lint on every PR and main push.
- ADR practice established (`docs/adr/`); architecture overview at `docs/architecture.md`.

## Roadmap
- [x] Phase 0 — Foundation: repo skeleton, Postgres-only Compose, Makefile, lint CI, ADR practice
- [ ] Phase 1 — Webapp + OLTP (FastAPI + HTMX + Postgres)
- [ ] Phase 2 — Kafka + Schema Registry + Protobuf
- [ ] Phase 3 — CDC via Debezium
- [ ] Phase 4 — Flink jobs (KPIs, sessionization, joins, CDC fan-out)
- [ ] Phase 5 — ClickHouse + sinks
- [ ] Phase 6 — Grafana dashboards
- [ ] Phase 7 — Kubernetes + Helm
- [ ] Phase 8 — Full observability (OpenTelemetry traces end-to-end)
- [ ] Phase 9 — Polish, benchmarks, ADRs
