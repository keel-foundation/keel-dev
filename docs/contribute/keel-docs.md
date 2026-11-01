# Contributing to `keel-docs`

Repository: [keel-foundation/keel-docs](https://github.com/keel-foundation/keel-docs)

This repository owns public creator and developer documentation. It must not contain the private Constitution, private infrastructure details, security reports, customer data, or secrets.

## Run only this repository

```sh
git clone https://github.com/keel-foundation/keel-docs.git
cd keel-docs
```

Documentation changes do not require the full ecosystem. Use the public demo in `keel-dev` for screenshots and flow examples.

## Style

- Write for creators first. Be specific and practical.
- State what the page covers and when it was last reviewed.
- Link to the public schema, OpenAPI, or RFC instead of copying private text.
- Do not publish unratified governance text or private board, finance, legal, or security records.
- Prefer short examples that a contributor can run with one repository.

## PR checklist

- Local Markdown links pass.
- The page states its scope and review date.
- Claims match the current implementation or are clearly marked as planned.
- No private governance text, secrets, or customer data.
- Commits are signed off with `git commit -s`.

See [PR guidelines](pr-guidelines.md).
