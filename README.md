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

제품·runtime·Agent의 소유 및 실행 관계는
[`docs/0. product-runtime-relationship.md`](docs/0.%20product-runtime-relationship.md)에서 설명하며,
편집 가능한 원본은
[`docs/0. product-runtime-relationship.drawio`](docs/0.%20product-runtime-relationship.drawio)다.

OpenShell is a pinned runtime dependency, not the owner of FHE-Privacy. A release may install an
OpenShell host package for local use or deploy the pinned OpenShell chart and images on Kubernetes.
The Secure Gateway, OpenShell Gateway, Privacy Core, reveal authorities, and Hermes sandbox remain
separate processes and security principals.

## Repository layout

- `docs/`: security decisions, architecture, contracts, and development plan
- `AGENTS.md` and `CLAUDE.md`: agent startup instructions and security invariants
- `feature_list.json`, `progress.md`, and `session-handoff.md`: feature state and lifecycle handoff
- `adapters/openshell/`: the narrow integration boundary with OpenShell
- `images/hermes/`: the Hermes sandbox image definition and stateless MCP Bridge packaging
- `deploy/`: local and Kubernetes product-level deployment orchestration
- `versions.lock`: reviewed OpenShell and Hermes release inputs; placeholders until validation
- `tools/bootstrap-dev-runtime.sh`: clone 후 현재 플랫폼용 OpenShell과 OpenFHE 개발 runtime 준비

## Current status

The project is in the pre-implementation design phase. The product code and release artifacts do
not exist yet. Follow `docs/fhe-development-plan.md` from P0 and do not mark features as implemented
without their required verification evidence.

## Development boundary

Develop FHE-Privacy product behavior in this repository. Develop reusable sandbox primitives such
as sealed management access, workload identity, and policy-revision binding in OpenShell, then pin
the tested OpenShell commit or release here. Do not copy privacy masking, Vault, key-share, or reveal
logic into OpenShell.

For native runtime work after a fresh clone, run `./tools/bootstrap-dev-runtime.sh`. It downloads
the exact OpenShell asset pinned in `versions.lock`, builds the platform-native OpenFHE wheel from
pinned commits, and runs the OpenFHE compatibility smoke test. Generated binaries remain outside
Git under `artifacts/` and `vendor/wheels/`.

Read `AGENTS.md`, `session-handoff.md`, and
`docs/1-0. security-architecture-index.md` before making changes.
