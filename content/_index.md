---
title: Cairn Report
lead: >-
  A self-hosted place for the results your CI already produces: tests, coverage,
  performance checks and code-scanning findings, for any programming language.
status: >-
  Early development. Nothing is released yet. Everything on this page is planned
  for the first release and may change.
features:
  - title: One place for every stage
    text: >-
      Unit, integration, contract, end-to-end, smoke and performance tests, coverage
      and static analysis, grouped by repository, optional service (for monorepos) and stage.
      A repository appears on its first upload; there is nothing to set up first.
  - title: Playwright report parity
    text: >-
      Everything in the default Playwright HTML report: step tree, retries, errors,
      attachments, visual diffs and a self-hosted Trace Viewer, with sharded runs merged.
  - title: Fast search and filtering
    text: >-
      A query bar with `field:value` filters, facets, a time histogram and shareable URLs,
      across runs, tests, findings, coverage and screenshots.
  - title: History, comparison and flakiness
    text: >-
      Each run is compared with its baseline: new failures, fixes, new flaky tests and
      duration changes. Test history, flakiness and the slowest tests per repository.
  - title: Visual change tracking
    text: >-
      Screenshots from your Playwright tests are tracked across runs, with ignore regions,
      tolerances, noise detection, a side-by-side viewer and approval of new baselines.
  - title: Coverage and findings
    text: >-
      Coverage totals, per-file data, a folder tree and trends. SARIF findings from any linter
      or scanner, marked new, fixed or existing against the baseline.
  - title: Pipelines and quality gates
    text: >-
      Expected stages per repository, a verdict per commit and gates on failures, coverage,
      performance regressions and new findings. `cairn gate` can fail a CI job on a red verdict.
  - title: Commit tracking and badges
    text: >-
      The last green commit per branch, "broken since" with the commit range, and README
      badges per stage.
  - title: Simple to run
    text: >-
      One Go binary with a server-rendered UI. It needs only ClickHouse plus a file system
      or any S3-compatible object store. A Docker image and `docker compose up` for local use.
formats_intro: >-
  The server understands standard formats only. Language- and tool-specific details live in
  the reporters, which convert results into one platform format: the `cairn` command-line tool
  (all formats) and `@cairnreport/playwright`, a native Playwright reporter. Both are planned.
formats:
  - kind: Tests
    formats: "Playwright (native reporter or JSON report), JUnit XML, `go test -json`"
  - kind: Performance
    formats: "k6 summary (metrics, thresholds and checks)"
  - kind: Coverage
    formats: "LCOV, Cobertura, JaCoCo, Go coverprofile"
  - kind: Code scanning
    formats: "SARIF 2.1.0 (linters, SAST, dependency, secret and IaC scanners)"
---

## What it is

Cairn Report will collect test, coverage, performance and code-scanning results from your CI and
show them in one web UI that you host yourself. Because it reads standard formats such as JUnit
XML, LCOV and SARIF, it is meant to work with Java, JavaScript, Python, Go, .NET, Ruby, PHP, Rust
and any other language whose tools can write them.

Results will arrive from your CI through the Cairn Report reporters. By design, a failed upload
does not fail your build unless you ask it to.
