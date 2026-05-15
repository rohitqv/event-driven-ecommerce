# 0000. Record architecture decisions

Date: 2026-05-08
Status: Accepted

## Context
This project will accumulate architectural decisions whose *reasoning* matters as much as the outcome — choices around streaming framework, schema format, deployment model, etc. Without a written record, the reasoning evaporates and future contributors (or reviewers, or interviewers reading this repo) re-litigate decisions or assume the wrong rationale.

## Decision
We will use **Architecture Decision Records (ADRs)** in the lightweight Michael Nygard format. Every non-obvious architectural choice gets one short markdown file in `docs/adr/`, numbered sequentially.

ADRs are immutable once accepted. To change a decision, write a new ADR that supersedes the old one, and update the old ADR's status to `Superseded by NNNN`.

## Consequences
- **Easier:** onboarding (a reviewer can read decisions in order); interviews (each ADR is a talking point); refactors (we know the why, not just the what).
- **Harder:** writing one ADR per decision is small friction during development.
- **New problems:** none expected.

## Alternatives considered
- **Inline comments / commit messages** — too easily lost; not discoverable.
- **A single `decisions.md`** — grows unwieldy; hard to link to a specific decision.
- **External wiki (Confluence, Notion)** — drifts from the code; requires login.
