# Develop Loop

AI-native SDLC skills for this project. Skills are installed globally via `devloop install --global`.

## Commands

Orchestrator slash command: **`/devloop`**

| Command | Description |
|---------|-------------|
| `/devloop start <id>` | Create package, classify, select profile |
| `/devloop run <id>` | E2E orchestration (loop mode) |
| `/devloop run <id> --pipeline` | Single pass per phase |
| `/devloop gate <id> <phase>` | L2 gate check for one phase |
| `/devloop status <id>` | Package status and blockers |
| `/devloop classify <id>` | Re-run complexity classification |

Phase skills (requirements, design, test-plan, implementation, code-review, test-report, release-retro, traceability) are invokable standalone.

## State (this repo)

- Package manifest: `.ai/packages/<id>/package.yaml`
- Artifacts: `artifacts/<id>/`
- Trace matrix: `traceability/<id>/matrix.md`
- Profiles: `.ai/config/profiles.yaml`
- L3 verify: `./scripts/loop-verify.sh [--enforce] <package_id>`
