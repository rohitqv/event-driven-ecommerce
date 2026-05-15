# Architecture

> **Status:** Phase 0 — skeleton. This document is fleshed out incrementally as each phase adds layers. Final form: full diagrams, narrative, and per-component deep-links.

## High-level shape

Five layers, each independently deployable:

1. **Event Sources** — webapp (FastAPI + HTMX), synthetic load generator (Locust), public-dataset replayer (RetailRocket).
2. **Transport** — Kafka cluster, Confluent Schema Registry, Kafka Connect (with Debezium).
3. **Stream Processing** — Apache Flink: 4 jobs (windowed KPIs, sessionization, funnel join, CDC fan-out).
4. **Serving** — ClickHouse: layered tables (raw → stage → fct/agg).
5. **Presentation & Observability** — Grafana dashboards, Prometheus, Loki, Tempo (OpenTelemetry).

```
[ Webapp ]──HTTP──┐
[ Load gen ]──────┼─► Postgres ──Debezium──► Kafka ──Flink──► ClickHouse ──► Grafana
[ Replayer ]──────┘                                    │
                                                       └──► OTel/Prom/Loki/Tempo
```

## Why event-driven?
- **Async ingest with sync confirmation** — user-facing writes commit to Postgres synchronously (the user gets an order confirmation); behavioral events go to Kafka via background queue. Kafka outages never 5xx the user.
- **CDC over dual-write** — order/inventory mutations propagate via Debezium reading the Postgres WAL, not via the application writing twice. No dual-write inconsistency.
- **Decoupled consumers** — analytics, search, fraud, ML, and dashboards all read from Kafka independently. Adding a consumer = subscribing to a topic, not a code change in the producer.

## Key decisions (full ADRs in [`adr/`](adr/))
- ADR 0001 — Flink over Kafka Streams (forthcoming, Phase 4).
- ADR 0002 — ClickHouse over Pinot (forthcoming, Phase 5).
- ADR 0003 — Protobuf over Avro (forthcoming, Phase 2).
- ADR 0004 — CDC over dual-write (forthcoming, Phase 3).
- ADR 0005 — Async events with sync confirmation (forthcoming, Phase 1).

## Roadmap
See [`../README.md`](../README.md#roadmap).
