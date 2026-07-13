# FHE-Privacy — 목표 배포 구조

> 현재 구현과 릴리스 산출물은 없다. 이 문서는 새 아키텍처가 요구하는 목표 배포 경계다.

## 기본 배치

```text
Trusted host
  Gateway ingress/egress
  session-scoped Privacy Core
  Vault Coordinator
  Public Compute Worker (confidentiality-untrusted, integrity-trusted in v1)
  Reveal Coordinator (no secret share)
  PC Partial Decrypt Authority (sk_pc)
  optional PC Fusion Sink

Smartphone
  Phone Partial Decrypt Authority (sk_phone)
  Phone Fusion Sink

OpenShell sandbox
  Hermes Agent
  stateless Agent MCP Bridge

External
  LLM through approved inference route
```

## 배포 원칙

- Hermes Agent 전체를 OpenShell sandbox 안에서 실행한다.
- key, Vault, profile과 reveal credential은 sandbox에 mount하지 않는다.
- Agent-facing MCP는 stdio Bridge이며 handle-only tools만 제공한다.
- Bridge는 독자 권한이 없는 비신뢰 adapter이며 capability가 Hermes에 노출될 수 있다고 가정한다.
- sandbox와 Core 사이는 전용 HTTPS/mTLS agent-safe endpoint만 허용한다.
- Gateway는 별도 host-only Core UDS를 사용한다.
- Reveal Coordinator와 PC Partial Authority는 분리된 local UDS를 사용한다.
- Phone Partial Authority는 인증된 device-bound channel과 사용자 승인 뒤에만 참여한다.
- 완성된 FHE secret key와 단일 AEAD master key를 생성하거나 backup하지 않는다.
- secure mode는 connect/SSH, exec, sync, forward와 service exposure가 차단된 sealed sandbox만 사용한다.
- 네트워크 공개 MCP, cloud Vault와 원격 reveal은 별도 threat model 전까지 금지한다.

## 지원 모드

| 모드 | 상태 | 보안 의미 |
|---|---|---|
| Architecture/development | 현재 | 문서와 spike만, 제품 보안 주장 없음 |
| Secure gateway + OpenShell | 목표 기본 | ingress/egress와 Agent 격리를 모두 검증 |
| Diagnostic MCP-only | 초기 비지원 | 제공해도 privacy mode로 표시하지 않음 |
| Portable/Windows | 후속 | named pipe와 engine bundle 검증 필요 |
| Remote/multi-user Core | 비범위 | 별도 인증/threat model 필요 |

과거 `tool-only` profile은 현재 지원 모드가 아니다. Gateway 없이 MCP만 Agent에 등록하면 원문
선노출과 key/Vault 격리를 보장할 수 없으므로 제품의 privacy mode로 제공하지 않는다.

## 목표 사용자 흐름

```bash
fhe-privacy init
fhe-privacy adapter doctor --agent hermes
fhe-privacy adapter install --agent hermes --mode secure-gateway --apply
fhe-privacy gateway run --agent hermes
```

실제 CLI 이름은 구현 단계에서 확정한다. Installer는 기본 dry-run이며 command, OpenShell policy,
workspace, network allowlist, agent-safe HTTPS endpoint, sealed access control과 rollback 계획을 먼저 보여준다.

## 로컬 상태 분리

```text
~/.fhe-privacy/
  key-shares/        # PC share만 접근; phone share는 스마트폰 밖으로 나오지 않음
  profiles/          # versioned public/private metadata 분리
  vault/             # trusted Core만 접근
  policies/          # signed/versioned policy
  audit/             # redacted metadata only
  adapters/          # non-secret adapter config
```

Agent workspace에는 위 경로를 포함하지 않는다. Sandbox에는 agent-safe session capability만 전달하며
key/Vault root 경로를 환경변수로 주지 않는다. Capability는 Hermes가 읽을 수 있다고 가정하고
agent-safe API 자체에서 권한을 제한한다.

## OpenShell policy profile

- full Agent process sandbox
- filesystem `hard_requirement`
- non-root identity
- dedicated sanitized workspace
- deny-by-default egress
- approved inference route only
- host-only/coordinator/PC-partial endpoint 차단
- 전용 agent-safe HTTPS/mTLS endpoint만 허용
- connect/SSH, exec, sync, forward와 service exposure 차단
- policy revision/heartbeat와 짧은 Core lease 결합
- enforcement 실패 시 startup 중단

OpenShell이 alpha인 동안 production readiness를 주장하지 않으며 지원 version/runtime 조합을
명시하고 재검증한다.

## 플랫폼

| 플랫폼 | 목표 |
|---|---|
| macOS/Linux host | Python package + platform OpenFHE wheel + OpenShell 지원 runtime |
| Windows host | Python wrapper + portable/subprocess engine + ACL named pipe 검토 |
| Remote Kubernetes | 초기 비범위, 추후 별도 multi-user threat model |

OpenFHE wheel은 checksum/signature와 Python/OS/architecture compatibility를 검증한다. Secret이
release artifact, image, test fixture 또는 debug bundle에 포함되지 않아야 한다.

## Release gate

- `./init.sh` 전체 통과
- clean environment 설치
- OpenFHE numeric precision/context matrix
- MCP stdio round-trip와 forbidden tool absence
- OpenShell filesystem/network/channel negative tests
- sealed sandbox direct ingress/management API negative tests
- Gateway canary E2E와 terminal egress 테스트
- scheme별 2-of-2 joint keygen/partial decrypt/fusion과 exact threshold-envelope 테스트
- package/image에 key/Vault/profile/log 미포함
- checksums/signatures와 dependency inventory
- adapter version compatibility와 rollback test

## Upgrade와 migration

- key, context, handle, policy와 Vault format에 version을 둔다.
- 알 수 없는 version은 fail-closed한다.
- migration은 Agent sandbox 밖의 trusted tool에서만 실행한다.
- backup은 암호화와 접근 통제 없이는 생성하지 않는다.
- OpenFHE/context 변경 시 기존 ciphertext compatibility를 별도 검증한다.
