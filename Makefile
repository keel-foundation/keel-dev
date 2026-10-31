SHELL := /bin/bash

.PHONY: help bootstrap infra-up infra-down infra-logs core-dev pipeline-dev moderation-dev web-dev demo seed-alpha rfc-discussion test test-demo validate-schemas harden-org sync-remotes check fmt

help:
	@echo "TubeKeel workspace"
	@echo ""
	@echo "  make bootstrap      Clone the sibling repos into this workspace"
	@echo "  make infra-up       Start PostgreSQL, LocalStack S3, and NATS"
	@echo "  make infra-down     Stop the local stack"
	@echo "  make infra-logs     Tail local stack logs"
	@echo "  make core-dev       Run the API service"
	@echo "  make pipeline-dev   Run the transcode worker"
	@echo "  make moderation-dev Run the moderation service"
	@echo "  make web-dev        Run the web client"
	@echo "  make demo           Run the full walking-skeleton demo"
	@echo "  make seed-alpha     Create alpha-0.1 milestones, labels, and issues"
	@echo "  make rfc-discussion Open RFC-0001 in keel-spec Discussions"
	@echo "  make test           Run available unit tests and typechecks"
	@echo "  make test-demo      Run the moderation demo smoke test"
	@echo "  make validate-schemas Validate JSON schemas, examples, and OpenAPI"
	@echo "  make harden-org     Apply security settings to the GitHub organization"
	@echo "  make sync-remotes   Preview commits and pushes for every repo"
	@echo "  make check          Run tests, schema validation, and formatting checks"
	@echo "  make fmt            Format sources in the sibling repos"

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
	cd keel-moderation && if [ -x .venv/bin/uvicorn ]; then .venv/bin/uvicorn app.main:app --reload --host 127.0.0.1 --port 8082; else uvicorn app.main:app --reload --host 127.0.0.1 --port 8082; fi

web-dev:
	cd keel-web && npm run dev -- -H 127.0.0.1

demo:
	./scripts/demo.sh

seed-alpha:
	python3 scripts/seed-alpha.py

rfc-discussion:
	python3 scripts/open-rfc-discussion.py

test:
	@if [ -d keel-core ] && command -v go >/dev/null 2>&1; then (cd keel-core && go test ./...); else echo "skip: keel-core or go missing"; fi
	@if [ -d keel-pipeline ] && command -v go >/dev/null 2>&1; then (cd keel-pipeline && go test ./...); else echo "skip: keel-pipeline or go missing"; fi
	@if [ -d keel-moderation ] && [ -x keel-moderation/.venv/bin/pytest ]; then (cd keel-moderation && .venv/bin/pytest -q); else echo "skip: keel-moderation venv/pytest missing"; fi
	@if [ -d keel-web ] && [ -d keel-web/node_modules ]; then (cd keel-web && npm test && npm run typecheck); else echo "skip: keel-web dependencies missing"; fi
	@if [ -d keel-spec ] && [ -x keel-spec/.venv/bin/python ]; then (cd keel-spec && .venv/bin/python scripts/validate_schemas.py); else echo "skip: keel-spec venv missing"; fi

test-demo:
	./scripts/test-demo.sh

validate-schemas:
	@if [ -x keel-spec/.venv/bin/python ]; then (cd keel-spec && .venv/bin/python scripts/validate_schemas.py); else python3 keel-spec/scripts/validate_schemas.py; fi

harden-org:
	./scripts/harden-org.sh

sync-remotes:
	./scripts/sync-remotes.sh

check: test
	@for file in scripts/*.sh; do bash -n "$$file"; done
	@if command -v shellcheck >/dev/null 2>&1; then shellcheck scripts/*.sh; else echo "skip: shellcheck missing"; fi
	@python3 -m compileall -q scripts
	@if [ -d keel-web ] && [ -d keel-web/node_modules ]; then (cd keel-web && npm run format:check); else echo "skip: keel-web dependencies missing"; fi
	@if [ -x keel-moderation/.venv/bin/ruff ]; then (cd keel-moderation && .venv/bin/ruff check app tests); else echo "skip: ruff missing"; fi
	@python3 scripts/check-doc-links.py

fmt:
	@command -v gofmt >/dev/null && [ -d keel-core ] && (cd keel-core && gofmt -w .) || true
	@command -v gofmt >/dev/null && [ -d keel-pipeline ] && (cd keel-pipeline && gofmt -w .) || true
	@command -v ruff >/dev/null && [ -d keel-moderation ] && (cd keel-moderation && ruff format .) || true
	@[ -d keel-web ] && [ -d keel-web/node_modules ] && (cd keel-web && npm run format) || true
