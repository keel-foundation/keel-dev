SHELL := /bin/bash

.PHONY: help demo demo-open test check boundary

help:
	@echo "KeelTube public demo"
	@echo ""
	@echo "  make demo       Serve the mocked demo at http://localhost:3000"
	@echo "  make demo-open  Serve and open the browser"
	@echo "  make test       Check demo assets, JavaScript syntax, doc links, and workspace boundary"
	@echo "  make boundary   Verify private repositories are not part of this public tree"
	@echo "  make check      Alias for make test"

demo:
	@if [ -f .env ]; then set -a; . ./.env; set +a; fi; python3 scripts/serve.py

demo-open:
	@if [ -f .env ]; then set -a; . ./.env; set +a; fi; OPEN=1 python3 scripts/serve.py

test:
	@python3 scripts/check_demo.py
	@python3 scripts/check-doc-links.py README.md CONTRIBUTING.md docs demo
	@python3 scripts/check_public_boundary.py
	@if command -v node >/dev/null 2>&1; then node --check demo/app.js; else echo "skip: node missing"; fi

boundary:
	@python3 scripts/check_public_boundary.py

check: test
