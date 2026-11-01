# Contributing to `keel-spec`

Repository: [keel-foundation/keel-spec](https://github.com/keel-foundation/keel-spec)

This repository owns the protocol, RFCs, JSON Schemas, examples, OpenAPI, and the policy-language draft.

## Validate schemas and examples

```sh
git clone https://github.com/keel-foundation/keel-spec.git
cd keel-spec

python3 -m venv .venv
.venv/bin/pip install -r requirements-dev.lock
.venv/bin/python scripts/validate_schemas.py
```

The validator checks schema meta-validity, every example, and `openapi.yaml`.

## Changing a schema

1. Open a discussion or RFC for protocol-breaking changes.
2. Update the schema.
3. Add or update at least one example.
4. Update `openapi.yaml` if an endpoint changes.
5. Update the affected code and tests in `keel-core`, `keel-moderation`, or `keel-web` in linked PRs.
6. Record substantive decisions in `DECISIONS.md`.
7. Run the validator.

Do not change an accepted RFC in place. Supersede it with a new RFC.

## Compatibility rules

- New required fields are breaking.
- Removing or renaming a field is breaking.
- Tightening validation is breaking unless the old value was invalid.
- `additionalProperties: false` means new fields must be added to the schema and all examples.
- IDs are opaque and stable across export/import.

## PR checklist

- `python scripts/validate_schemas.py` passes.
- Every changed schema has an example.
- The OpenAPI document validates.
- Compatibility impact is documented.
- Linked code PRs are identified.
- The decision log is updated where required.
- Commits are signed off with `git commit -s`.

See [PR guidelines](pr-guidelines.md).
