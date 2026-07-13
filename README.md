# FHE-Privacy integration reference

This directory is an isolated snapshot of the FHE-Privacy design and harness state used to plan its
OpenShell integration. It does not replace OpenShell's root documentation, architecture, or agent
instructions.

## Layout

- `docs/`: copied from the FHE-Privacy `docs/` directory
- `harness/FHE_PRIVACY_AGENTS.md`: copied from FHE-Privacy `AGENTS.md`
- `harness/FHE_PRIVACY_CLAUDE.md`: copied from FHE-Privacy `CLAUDE.md`
- `harness/feature_list.json`: copied feature state
- `harness/progress.md`: copied progress record
- `harness/session-handoff.md`: copied session handoff

The imported agent-routing files use prefixed names intentionally. OpenShell's root `AGENTS.md` points
to them explicitly without allowing the imported snapshot to replace the repository instructions.

Treat these files as a reference snapshot. Put future OpenShell implementation changes in their
normal OpenShell locations and update this snapshot only through an explicit synchronization task.
