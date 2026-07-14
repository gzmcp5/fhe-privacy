# Agent Instructions

This is the top-level FHE-Privacy product repository.

Read and follow `harness/FHE_PRIVACY_AGENTS.md` in full before planning or changing the product.
Then read `harness/session-handoff.md`, `docs/1-0. security-architecture-index.md`,
`docs/architecture-flow.md`, `docs/fhe-features.md`, and `docs/fhe-development-plan.md`.

OpenShell is a pinned external runtime dependency. Keep FHE-Privacy masking, Vault, cryptography,
key-share, and reveal code in this repository. Changes made to an OpenShell checkout must be generic
sandbox capabilities and must be validated through the adapter and end-to-end tests here.
