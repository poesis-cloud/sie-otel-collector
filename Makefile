SHELL := /bin/bash
.EXPORT_ALL_VARIABLES:

.PHONY: dev-check dev-up dev-down deploy-check prod-deploy package-helm

# No .env/.env.dev include — sie-otel-collector has no secrets in cycle 1
# (S-002 HUDDLE §7 — deliberate divergence from defman/defdb Makefiles).

NAMESPACE ?= sie
DEPLOY_ENV ?= preprod
RELEASE ?= sie-otel-collector

CHART ?= ops/helm
ENV_FILE ?= $(CHART)/environments/$(DEPLOY_ENV)/values.yaml

# Optional OTLP backend, injected by CI/CD (GitHub environment variable).
# Empty => the collector keeps the debug sink only.
OTLP_BACKEND_ENDPOINT ?=
OTLP_BACKEND_AUTH_SECRET ?=
HELM_SINK_ARGS := $(if $(OTLP_BACKEND_ENDPOINT),--set sink.otlp.enabled=true --set-string sink.otlp.endpoint=$(OTLP_BACKEND_ENDPOINT)) \
	$(if $(OTLP_BACKEND_AUTH_SECRET),--set-string sink.otlp.authorization.existingSecret=$(OTLP_BACKEND_AUTH_SECRET))

dev-check:
	@command -v kubectl >/dev/null 2>&1 || { echo "Missing required command: kubectl"; exit 1; }
	@command -v helm >/dev/null 2>&1 || { echo "Missing required command: helm"; exit 1; }
	@kubectl config current-context >/dev/null 2>&1 || { echo "No active Kubernetes context. Configure kubeconfig first."; exit 1; }
	@kubectl get ns >/dev/null 2>&1 || { echo "Cannot reach Kubernetes API with current context."; exit 1; }
	@test -d "$(CHART)" || { echo "Missing chart directory: $(CHART)"; exit 1; }
	@test -f "$(CHART)/environments/dev/values.yaml" || { echo "Missing dev values file: $(CHART)/environments/dev/values.yaml"; exit 1; }
	@echo "dev-check passed"

deploy-check:
	@command -v kubectl >/dev/null 2>&1 || { echo "Missing required command: kubectl"; exit 1; }
	@command -v helm >/dev/null 2>&1 || { echo "Missing required command: helm"; exit 1; }
	@kubectl config current-context >/dev/null 2>&1 || { echo "No active Kubernetes context. Configure kubeconfig first."; exit 1; }
	@kubectl get ns >/dev/null 2>&1 || { echo "Cannot reach Kubernetes API with current context."; exit 1; }
	@test -d "$(CHART)" || { echo "Missing chart directory: $(CHART)"; exit 1; }
	@test -f "$(ENV_FILE)" || { echo "Missing environment values file: $(ENV_FILE)"; exit 1; }
	@echo "deploy-check passed"

dev-up:
	@$(MAKE) dev-check
	kubectl get ns $(NAMESPACE) >/dev/null 2>&1 || kubectl create ns $(NAMESPACE) >/dev/null
	helm upgrade --install $(RELEASE) $(CHART) -n $(NAMESPACE) --create-namespace --wait --timeout 5m0s \
		-f $(CHART)/environments/dev/values.yaml
	@echo "sie-otel-collector is up in namespace $(NAMESPACE)."
	@echo "OTLP/gRPC endpoint: sie-otel-collector.$(NAMESPACE).svc.cluster.local:4317"

dev-down:
	helm uninstall $(RELEASE) -n $(NAMESPACE) || true

prod-deploy:
	@$(MAKE) deploy-check
	helm upgrade --install $(RELEASE) $(CHART) -n $(NAMESPACE) --create-namespace --wait --timeout 10m0s \
		-f $(ENV_FILE) $(HELM_SINK_ARGS)

package-helm:
	@command -v helm >/dev/null 2>&1 || { echo "Missing required command: helm"; exit 1; }
	@test -d "$(CHART)" || { echo "Missing chart directory: $(CHART)"; exit 1; }
	helm package $(CHART)
