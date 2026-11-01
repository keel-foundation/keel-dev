# Contributing to policy

Policy is code. It is versioned, testable, and recorded with every enforcement action.

## Where policy lives

| Artifact | Location |
|---|---|
| Policy language | `keel-spec/protocol/policy-language.md` |
| Policy bundles | `keel-moderation/app/policies/` |
| Reason codes and action schemas | `keel-spec/schemas/` |
| Moderation behavior and tests | `keel-moderation/app/` and `keel-moderation/tests/` |
| Protocol changes | RFCs in `keel-spec/rfcs/` |
| Public decisions | `keel-spec/DECISIONS.md` |

## What a policy bundle contains

- `policy_version`;
- reason codes and scope;
- severity and penalty ranges;
- human-review gates;
- appeal windows and service levels;
- content-protection rules.

Policy must never be hardcoded in an endpoint handler. The action must record the `policy_version` used for the decision.

## Making a policy change

1. **Classify the change.**
   - Clarifying typo or test fix: normal PR.
   - New reason code, changed penalty, changed review gate, or changed appeal window: open a discussion or RFC first.
   - Constitutional or rights-affecting change: follow the Constitution's amendment process and record it in the public decision log.
2. **Update the bundle.** Add the rule, reason code, gate, or window in the policy bundle. Do not branch on policy inside handlers.
3. **Add tests.** Cover allowed and rejected actions, the human-review gate, and the appeal window. Use the local moderation service and the demo to exercise the flow.
4. **Update schemas and docs.** If the reason code, action type, evidence shape, or appeal route changes, update `keel-spec` and `keel-docs`.
5. **Record the decision.** Add a row to `keel-spec/DECISIONS.md` for substantive policy changes.
6. **Open a focused PR.** Link the RFC/discussion and explain the tradeoff.

## Test locally

You only need `keel-moderation`:

```sh
cd keel-moderation
.venv/bin/pytest -q
```

Then point the demo at the local service:

```sh
KEELTUBE_MODE=remote \
KEELTUBE_API_BASE_URL=https://stage-api.example.org \
KEELTUBE_MODERATION_BASE_URL=http://127.0.0.1:8082 \
make demo
```

The demo shows the policy version, Statement of Reasons, review gate, appeal deadline, reviewer, decision, and ledger records.

## Policy PR checklist

- The policy bundle is versioned.
- The human-review gate is enforced for channel-level or long-lived actions.
- The appeal window is tested.
- The action records `policy_version`.
- The ledger records the policy-dependent decision.
- The RFC/discussion and decision log are updated.
- No creator evidence or personal data is committed.

See [PR guidelines](pr-guidelines.md).
