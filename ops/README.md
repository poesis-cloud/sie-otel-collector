# sie-otel-collector deployables

This folder contains ops/runtime assets for the shared SIE OpenTelemetry collector.

- `ops/helm/`: Helm chart for Kubernetes deployments (dev/preprod/prod).

## Helm

Chart path: `ops/helm`

Install (dev):

```bash
helm upgrade --install sie-otel-collector \
  sie/sie-otel-collector/ops/helm \
  -n sie --create-namespace \
  -f sie/sie-otel-collector/ops/helm/environments/dev/values.yaml
```

Environment values:

- `environments/dev/values.yaml` (replicas: 1)
- `environments/preprod/values.yaml` (replicas: 2)
- `environments/prod/values.yaml` (replicas: 2)

Each environment file is self-contained.

Recommended deploy command (preprod):

```bash
helm upgrade --install sie-otel-collector \
  sie/sie-otel-collector/ops/helm \
  -n sie --create-namespace \
  -f sie/sie-otel-collector/ops/helm/environments/preprod/values.yaml
```

## Secrets policy

Cycle 1 ships **no secrets** — the collector exposes OTLP/gRPC in-cluster only,
no auth, no upstream backend credentials. Auth / mTLS / backend credentials are
out of scope and will land in a future security Story.

## Schema validation

`helm lint` + `helm template` are run for all three environments by
`.github/workflows/ci.yaml`. Local validation:

```bash
for env in dev preprod prod; do
  helm lint ops/helm -f "ops/helm/environments/$env/values.yaml"
  helm template test ops/helm -f "ops/helm/environments/$env/values.yaml" > /dev/null
done
```
