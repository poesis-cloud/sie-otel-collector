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
- Sink selectable by values: `debug` (pod stdout, default) and/or one OTLP/gRPC
  backend (see [Sink](#sink)).
- Service pipelines for `traces` and `logs` only (no metrics).
- No processors — ADR-001 D-2 forbids sampling at the collector tier (keep all).
- `health_check` extension on `13133` powers liveness + readiness probes.

Out of scope this Story (S-002):

- Additional exporter profiles (`file`, multi-fan-out) → future.
- Tail sampling → forbidden by ADR-001 D-2.
- Authentication / mTLS on the OTLP receiver → future security Story.
- Actual prod-tuned `preprod` / `prod` configurations → future ops Story.

## Sink

By default the collector only writes to pod stdout (`sink.debug`). To forward
traces and logs to a backend, enable one OTLP/gRPC sink. The endpoint is
injected as environment variables of the container, never hardcoded:

| Variable | Source | Purpose |
|---|---|---|
| `SIE_OTLP_BACKEND_ENDPOINT` | `sink.otlp.endpoint` | backend `host:port` (required) |
| `SIE_OTLP_BACKEND_INSECURE` | `sink.otlp.insecure` | disable TLS (default `false`) |
| `SIE_OTLP_BACKEND_AUTHORIZATION` | Secret `sink.otlp.authorization.existingSecret` (key `authorization`) | `Authorization` header (optional) |

```bash
make prod-deploy DEPLOY_ENV=prod \
  OTLP_BACKEND_ENDPOINT=backend.example:4317 \
  OTLP_BACKEND_AUTH_SECRET=otlp-backend-auth
```

In CI/CD (`cd.yaml`) set the GitHub environment variables
`SIE_OTLP_BACKEND_ENDPOINT` and, optionally, `SIE_OTLP_BACKEND_AUTH_SECRET`
(name of a Kubernetes Secret created beforehand). Without endpoint, only the
debug sink is active. `extraEnv` allows injecting any other variable.

## Repo status

The `cd.yaml` workflow stays dormant until the Azure OIDC secrets are set.

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

The Service name must stay `sie-otel-collector` on port `4317` (ADR-001 D-1).
This is enforced by CI (`ci.yaml`, "Assert ADR-001 D-1 Service contract") and a
warning in `NOTES.txt`, not by a template guard.
