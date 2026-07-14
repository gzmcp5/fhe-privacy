# FHE-Privacy

FHE-Privacy is the top-level privacy product for running an untrusted Hermes agent through a
Secure Gateway. It uses OpenShell as its sandbox runtime while keeping privacy state, key shares,
plaintext, and reveal authority outside the OpenShell sandbox.

```text
User
  -> FHE-Privacy Secure Gateway
       -> OpenShell Gateway
            -> sealed Hermes sandbox
```

OpenShell is a pinned runtime dependency, not the owner of FHE-Privacy. A release may install an
OpenShell host package for local use or deploy the pinned OpenShell chart and images on Kubernetes.
The Secure Gateway, OpenShell Gateway, Privacy Core, reveal authorities, and Hermes sandbox remain
separate processes and security principals.

## Repository layout

- `docs/`: security decisions, architecture, contracts, and development plan
- `harness/`: feature state, progress, and session handoff
- `adapters/openshell/`: the narrow integration boundary with OpenShell
- `images/hermes/`: the Hermes sandbox image definition and stateless MCP Bridge packaging
- `deploy/`: local and Kubernetes product-level deployment orchestration
- `versions.lock`: reviewed OpenShell and Hermes release inputs; placeholders until validation

## Current status

The project is in the pre-implementation design phase. The product code and release artifacts do
not exist yet. Follow `docs/fhe-development-plan.md` from P0 and do not mark features as implemented
without their required verification evidence.

## Development boundary

Develop FHE-Privacy product behavior in this repository. Develop reusable sandbox primitives such
as sealed management access, workload identity, and policy-revision binding in OpenShell, then pin
the tested OpenShell commit or release here. Do not copy privacy masking, Vault, key-share, or reveal
logic into OpenShell.

Read `AGENTS.md`, `harness/session-handoff.md`, and
`docs/1-0. security-architecture-index.md` before making changes.
