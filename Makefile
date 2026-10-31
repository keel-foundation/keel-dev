SHELL := /bin/bash

.PHONY: help bootstrap infra-up infra-down infra-logs core-dev pipeline-dev moderation-dev web-dev test fmt publish

help:
	@echo "TubeKeel workspace"
	@echo ""
	@echo "  make bootstrap      Clone the sibling repos into this workspace"
	@echo "  make infra-up       Start PostgreSQL, MinIO, and NATS"
	@echo "  make infra-down     Stop the local stack"
	@echo "  make infra-logs     Tail local stack logs"
	@echo "  make core-dev       Run the API service"
	@echo "  make pipeline-dev   Run the transcode worker"
	@echo "  make moderation-dev Run the moderation service"
	@echo "  make web-dev        Run the web client"
	@echo "  make test           Run available tests"
	@echo "  make fmt            Format sources in the sibling repos"
	@echo "  make publish        Create/push GitHub org repos (requires gh auth)"

bootstrap:
	./scripts/bootstrap-dev.sh

infra-up:
	docker compose -f devstack/docker-compose.yml up -d

infra-down:
	docker compose -f devstack/docker-compose.yml down

infra-logs:
	docker compose -f devstack/docker-compose.yml logs -f

core-dev:
	cd keel-core && go run ./cmd/api

pipeline-dev:
	cd keel-pipeline && go run ./cmd/worker

moderation-dev:
	cd keel-moderation && uvicorn app.main:app --reload --port 8082

web-dev:
	cd keel-web && npm run dev

test:
	@if [ -d keel-core ]; then (cd keel-core && go test ./...); fi
	@if [ -d keel-pipeline ]; then (cd keel-pipeline && go test ./...); fi
	@if [ -d keel-moderation ]; then (cd keel-moderation && python3 -m compileall -q app); fi
	@if [ -d keel-web ]; then (cd keel-web && npm run typecheck); fi

fmt:
	@command -v gofmt >/dev/null && [ -d keel-core ] && (cd keel-core && gofmt -w .) || true
	@command -v gofmt >/dev/null && [ -d keel-pipeline ] && (cd keel-pipeline && gofmt -w .) || true
	@command -v ruff >/dev/null && [ -d keel-moderation ] && (cd keel-moderation && ruff format .) || true
	@[ -d keel-web ] && [ -d keel-web/node_modules ] && (cd keel-web && npm run format) || true

publish:
	./scripts/publish-org.sh
