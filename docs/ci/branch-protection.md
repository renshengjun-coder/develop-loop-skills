# Branch Protection — Loop Verify

1. GitHub → Settings → Branches → Add rule for `main`
2. Require status check: **Loop Verify / verify**
3. PRs touching `.ai/`, `artifacts/`, `traceability/`, or `scripts/devloop-verify.sh` must pass `./scripts/devloop-verify.sh --enforce <package_id>`

Default CI package: `FEAT-003` (full 7-phase). MVP package `FEAT-001` remains valid for local smoke tests.
