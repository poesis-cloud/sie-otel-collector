# sie-otel-collector

Shared OpenTelemetry Collector for SIE products.

**Binding ADR:** [ADR-001 — OpenTelemetry collector and conventions](../../products/sie-definition/architecture/adr-001-otel-collector-and-conventions.md)

## Purpose

Single shared OTLP receiver per tenant deployment (ADR-001 D-1). All SIE products
in the same `sie` namespace send traces and logs to the in-cluster Service:

```
sie-otel-collector.sie.svc.cluster.local:4317   # OTLP/gRPC
```

Cycle-1 scope (S-002):

- Stock upstream `otel/opentelemetry-collector-contrib` image (no fork).
- One OTLP/gRPC receiver on `0.0.0.0:4317`.
- One `debug` exporter writing to pod stdout (`logging` exporter was renamed
  `debug` upstream around 0.86; `debug` is the canonical name at the pinned
  appVersion).
- Service pipelines for `traces` and `logs` only (no metrics).
- No processors — ADR-001 D-2 forbids sampling at the collector tier (keep all).
- `health_check` extension on `13133` powers liveness + readiness probes.

Out of scope this Story (S-002):

- Additional exporter profiles (`otlp`, `file`, multi-fan-out) → S-003 + future.
- Tail sampling → forbidden by ADR-001 D-2.
- Authentication / mTLS on the OTLP receiver → future security Story.
- Actual prod-tuned `preprod` / `prod` configurations → future ops Story.

## Repo status

This folder is currently **workspace-only** inside the `poesis` monorepo
(per Governor decision 2026-05-25, S-002 HUDDLE issue 1, option b). The
GitHub repo `poesis-cloud/sie-otel-collector` and its Azure OIDC secrets
will be provisioned in a follow-up Story; until then, the `cd.yaml`
workflow is **dormant** (carried for forward-compatibility).

## Install

Dev:

```bash
make dev-up
```

Preprod / prod (after secrets + cluster context are set):

```bash
make prod-deploy DEPLOY_ENV=preprod
make prod-deploy DEPLOY_ENV=prod
```

See [ops/README.md](ops/README.md) for full deploy commands.

## Image tag

The collector image is pinned in each `ops/helm/environments/*/values.yaml`
under `image.tag`. The current pin is `0.115.0`. **Before merging S-002**,
verify the exact latest stable on
<https://github.com/open-telemetry/opentelemetry-collector-releases/releases>
and bump the pin if a newer stable exists. Avoid `latest`.

## Service contract

The Service name is pinned to `sie-otel-collector` by `templates/_helpers.tpl`
(`assertServiceName`) — overriding `service.name` in values.yaml will fail
`helm template` / `helm install` with an explicit error. This guards the
ADR-001 D-1 DNS contract.
