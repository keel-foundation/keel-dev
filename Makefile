SHELL := /bin/bash

.PHONY: help demo demo-open test check

help:
	@echo "TubeKeel public demo"
	@echo ""
	@echo "  make demo       Serve the mocked demo at http://localhost:3000"
	@echo "  make demo-open  Serve and open the browser"
	@echo "  make test       Check demo assets, JavaScript syntax, and doc links"
	@echo "  make check      Alias for make test"

demo:
	@if [ -f .env ]; then set -a; . ./.env; set +a; fi; python3 scripts/serve.py

demo-open:
	@if [ -f .env ]; then set -a; . ./.env; set +a; fi; OPEN=1 python3 scripts/serve.py

test:
	@python3 scripts/check_demo.py
	@python3 scripts/check-doc-links.py README.md CONTRIBUTING.md docs demo
	@if command -v node >/dev/null 2>&1; then node --check demo/app.js; else echo "skip: node missing"; fi

check: test
