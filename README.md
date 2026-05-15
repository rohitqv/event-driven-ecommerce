# Event-Driven Real-Time Analytics Platform

A production-grade streaming data platform on **Kafka + Flink + ClickHouse + Kubernetes**, framed as a hybrid e-commerce backend so the data shape is realistic. Runs on a laptop via Docker Compose; deploys to Kubernetes via Helm.

> **Status:** Phase 0 of 9 complete. See [What works today](#what-works-today). See [Roadmap](#roadmap) for the rest.

---

## Why this exists

This is a portfolio project demonstrating real-world data engineering at meaningful scale. The framing is e-commerce because it produces a natural mix of OLTP writes (orders, inventory), behavioral events (clicks, sessions, carts), and CDC streams — enough variety to exercise every interesting pattern in modern streaming systems.

The technical scope is deliberately broad: change-data-capture, schema evolution, exactly-once processing, stream-stream and stream-table joins, sessionization, windowed aggregations, materialized views, full observability with distributed tracing. Each pattern is implemented in a way that would survive code review at a streaming-first company, not in a tutorial-grade way.

**It runs on one laptop** (Docker Compose + kind) so anyone reviewing it can clone and `make up-all`. The same Helm charts deploy to a real Kubernetes cluster — no cloud-specific gymnastics, so the architecture is portable.

---

## Architecture

Five layers, each independently deployable:

```
[ Webapp (FastAPI) ]──HTTP──┐
[ Load gen (Locust) ]───────┼─► Postgres ──Debezium──► Kafka ──Flink──► ClickHouse ──► Grafana
[ Replayer ]────────────────┘                                    │
                                                                 └──► OTel / Prom / Loki / Tempo
```

1. **Event Sources** — FastAPI webapp (user-facing writes + behavioral events), Locust load generator (synthetic stress), RetailRocket replayer (public-dataset realism).
2. **Transport** — Kafka cluster, Confluent Schema Registry (Protobuf), Kafka Connect with Debezium for CDC.
3. **Stream Processing** — Apache Flink: four jobs covering windowed KPIs (Flink SQL), sessionization (DataStream), funnel join + temporal table join (Table API), CDC fan-out (DataStream).
4. **Serving** — ClickHouse with layered tables: `raw_*` (full fidelity ingest) → `stage_*` (cleansing) → `agg_*` / `fct_*` (materialized aggregates).
5. **Presentation & Observability** — Grafana dashboards backed by Prometheus (metrics), Loki (logs), Tempo (traces), unified through OpenTelemetry. The end-to-end distributed trace through Kafka is the headline observability demo.

Full architecture and rationale: [`docs/architecture.md`](docs/architecture.md). Decisions documented as ADRs in [`docs/adr/`](docs/adr/).

---

## Tech stack

| Layer | Choice | Why (full rationale in linked ADR) |
|---|---|---|
| Stream processor | **PyFlink** + one Flink SQL job | Production-grade exactly-once, savepoints, rich windowing; covers both DataStream and Table API in one project. ADR 0001 (Phase 4). |
| Schema format | **Protobuf** + Confluent Schema Registry | Compact wire format, strict BACKWARD compatibility enforced in CI. ADR 0003 (Phase 2). |
| Analytical store | **ClickHouse** + Grafana | Columnar, fast scans, materialized views, projections. ADR 0002 (Phase 5). |
| Change capture | **Debezium** on Postgres logical replication | Avoids dual-write inconsistency; the source-of-truth pattern for OLTP→stream. ADR 0004 (Phase 3). |
| Ingest model | **Async events with sync write confirmation** | User-facing writes commit to Postgres synchronously; behavioral events go async to Kafka. Kafka outages never 5xx the user. ADR 0005 (Phase 1). |
| Deployment | **Docker Compose** (dev) + **kind/k3d + Helm** (prod-like) | Cloud-portable manifests, no EKS/GKE bills. |
| Observability | **Prometheus + Grafana + Loki + Tempo** via OpenTelemetry | Trace propagation through Kafka headers is the technical centerpiece. |
| Load generation | **Locust** + RetailRocket dataset replayer | Synthetic stress + real-world data distribution. |

---

## Use cases this project demonstrates

End-to-end streaming patterns covered across the 9 phases:

- **Windowed KPIs** (Flink SQL) — tumbling/hopping windows over event time with watermarks, allowed lateness, side outputs.
- **Sessionization** (PyFlink DataStream) — keyed session windows with gap-based eviction.
- **Funnel join** (PyFlink Table API) — interval join across event streams; temporal table join against slowly-changing dimensions.
- **CDC fan-out** (PyFlink) — Debezium changefeed → Kafka topic → multiple downstream consumers.
- **Schema evolution** — Protobuf field add/deprecate, BACKWARD compatibility enforced by Schema Registry + CI.
- **Exactly-once semantics** — Flink checkpoints + transactional Kafka sinks + idempotent ClickHouse upserts.
- **Distributed tracing through Kafka** — OpenTelemetry context propagated via Kafka headers; one user request traceable from webapp through Flink to ClickHouse.

**Explicitly out of scope** (to keep the project finishable): anomaly/fraud detection, real cloud deploys, ML pipelines, Spark Structured Streaming (alternative already known by author).

---

## Roadmap

Nine phases, each ends in something demoable. Phase 0 took ~1 week part-time; later phases take 1–2 weeks each.

- [x] **Phase 0 — Foundation.** Repo skeleton, Postgres-only Compose, Makefile, pre-commit lint (ruff/black/hadolint/yamllint/conventional-commits), GitHub Actions CI, ADR practice, architecture stub.
- [ ] **Phase 1 — Webapp + OLTP.** FastAPI + HTMX webapp on Postgres. User-facing writes + behavioral event emission. Async events with sync confirmation pattern.
- [ ] **Phase 2 — Kafka + Schema Registry + Protobuf.** Kafka cluster, Confluent Schema Registry, Protobuf message definitions, BACKWARD compat enforced in CI.
- [ ] **Phase 3 — CDC via Debezium.** Postgres logical replication → Debezium → Kafka. Order and inventory mutations flow without dual-writes.
- [ ] **Phase 4 — Flink jobs.** Four jobs: windowed KPIs (Flink SQL), sessionization (DataStream), funnel join + temporal table join (Table API), CDC fan-out (DataStream). Checkpoints, savepoints, RocksDB state.
- [ ] **Phase 5 — ClickHouse + sinks.** Layered schema (raw → stage → fct/agg), MergeTree family table types (ReplacingMergeTree for idempotent upserts, AggregatingMergeTree for materialized rollups), projections, TTLs.
- [ ] **Phase 6 — Grafana dashboards.** Committed JSON dashboards for live KPIs (revenue/min, top categories, session funnels). Dashboards-as-code via provisioning.
- [ ] **Phase 7 — Kubernetes + Helm.** Move the whole stack to kind via Helm charts. StatefulSets for stateful services, Deployments for stateless, Operators where they earn their keep (Strimzi for Kafka).
- [ ] **Phase 8 — Full observability.** OpenTelemetry instrumentation end-to-end. Distributed trace from a single user click, through Kafka, through Flink, to ClickHouse insert. Prometheus + Loki + Tempo all wired.
- [ ] **Phase 9 — Polish, benchmarks, ADRs.** Throughput benchmarks documented in `docs/benchmarks/`. Per-component runbooks in `docs/runbooks/`. Backfill of ADRs for any decisions made informally during earlier phases.

---

## What works today

**Phase 0 (Foundation).** Available right now:

- `make up-core` brings up Postgres 16 in Docker, healthy in ~15 seconds.
- `make psql` opens a `psql` shell to the running database.
- `make lint` runs the full hook chain (ruff, black, hadolint, yamllint, trailing whitespace, EOF, conventional-commits) via pre-commit.
- GitHub Actions runs `pre-commit run --all-files` on every PR and every push to `main`.
- Dependabot configured for `github-actions`, `docker`, and `pip` ecosystems, weekly cadence.
- ADR practice established with the meta-ADR ([`docs/adr/0000`](docs/adr/0000-record-architecture-decisions.md)) documenting the practice itself; template at [`docs/adr/template.md`](docs/adr/template.md).
- Architecture overview at [`docs/architecture.md`](docs/architecture.md).

Future phases append to this section as they land. Recruiters / reviewers can read this list to know exactly what they can clone and run today.

---

## Quick start

```bash
# Prereqs: see Local development setup below
git clone git@github.com:rohitqv/event-driven-ecommerce.git
cd event-driven-ecommerce
cp .env.example .env

make up-core              # bring up Postgres
make ps                   # confirm (healthy)
make psql                 # open psql shell — try \dt, SELECT version();
make down                 # stop, keep volume
```

`make help` lists every available target with a description.

---

## Repo layout

```
event-driven-ecommerce/
├── README.md                              ← this file
├── Makefile                               ← universal command surface (`make help`)
├── docker-compose.yml                     ← dev-environment services (Phase 0: Postgres only; grows per phase)
├── .env.example                           ← config schema; .env is gitignored
├── pyproject.toml                         ← shared tool config (ruff/black/mypy)
├── .pre-commit-config.yaml                ← lint hook orchestration
├── .github/
│   ├── workflows/ci.yml                   ← lint workflow (extends per phase)
│   └── dependabot.yml                     ← weekly dep bumps
├── proto/                                 ← Protobuf source of truth (Phase 2+)
├── services/
│   ├── webapp/                            ← FastAPI + HTMX (Phase 1)
│   ├── load-generator/                    ← Locust + RetailRocket replayer (Phase 2+)
│   └── clickhouse-init/                   ← DDL + materialized views (Phase 5)
├── pipelines/flink/                       ← 4 Flink jobs (Phase 4)
├── infra/
│   ├── helm/                              ← Helm charts (Phase 7)
│   ├── kind/                              ← kind cluster config (Phase 7)
│   └── grafana/dashboards/                ← committed JSON dashboards (Phase 6)
└── docs/
    ├── architecture.md                    ← high-level architecture
    ├── adr/                               ← Architecture Decision Records
    ├── runbooks/                          ← per-component operations docs (Phase 9)
    └── benchmarks/                        ← throughput numbers (Phase 9)
```

---

## Architectural targets

Designed for the following operating envelopes — not yet validated end-to-end (Phase 9 benchmarks will confirm):

- **Single laptop (Docker Compose):** ~10k events/sec sustained ingest, with full pipeline running. Sufficient for demo + development.
- **Real Kubernetes cluster (3-broker Kafka, 4-slot Flink):** ~100k+ events/sec, again architecturally — actual throughput depends on hardware. The architecture choices (partition count, parallelism, state backend, sink batching) are sized for this.

Benchmarks documented in [`docs/benchmarks/`](docs/benchmarks/) as Phase 9 lands.

---

## Decisions

Every non-obvious architectural choice is recorded as an [Architecture Decision Record](docs/adr/) in the lightweight Michael Nygard format. ADRs are immutable once accepted; supersede with a new ADR rather than editing.

Today: ADR 0000 establishes the practice. ADRs 0001–0005 are reserved for the major decisions covered in Phases 1–5 (linked from the [Tech stack](#tech-stack) table above).

---

## Local development setup

Tested on macOS (Apple Silicon) with the following toolchain. Linux equivalents work; Windows requires WSL.

| Tool | Version | Install |
|---|---|---|
| Docker runtime | Colima 0.6+ or Docker Desktop 4.30+ | `brew install colima` (then `colima start --cpu 4 --memory 8`) |
| docker compose plugin | v2.27+ | bundled with Docker Desktop; for Colima: see [docker-compose-plugin install](https://docs.docker.com/compose/install/linux/) |
| Python | 3.11.x (Homebrew) | `brew install python@3.11` |
| pipx | 1.4+ | `brew install pipx` then `pipx ensurepath` |
| pre-commit | 3.7.1 | `pipx install pre-commit==3.7.1` then `pre-commit install --install-hooks` |
| GitHub CLI | gh 2.40+ | `brew install gh` then `gh auth login` |

For Phase 4+ (Flink), bump Colima to `--memory 12`. For Phase 7+ (Kubernetes), bump to `--memory 16` and install `kind` + `helm`.

---

## License

Personal portfolio project. Not licensed for external use. If you'd like to discuss the architecture or any of the decisions, open an issue or contact the author.
