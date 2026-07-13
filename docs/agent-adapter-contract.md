# FHE-Privacy Agent Adapter Contract

이 문서는 FHE-Privacy와 OpenShell sandbox 안의 Hermes Agent를 연결하는 adapter 계약이다.
Adapter는 Agent별 설정 차이를 흡수하지만 보안 경계를 완화할 수 없다.

## 대상 Agent

- 현재 구현 대상은 Hermes로 확정한다.
- Hermes 자체는 비신뢰이며 전체 프로세스를 OpenShell sandbox 안에서 실행한다.
- Hermes adapter가 아래 capability와 E2E 검증을 통과하기 전에는 지원 완료로 표시하지 않는다.
- Core protocol은 Hermes 전용 데이터 형식에 결합하지 않지만, 첫 배포와 검증 범위는 Hermes로 제한한다.

## 기본 원칙

- Secure Gateway가 사용자 원문의 유일한 ingress다.
- Hermes Agent 전체와 Agent MCP Bridge를 OpenShell sandbox 안에서 실행한다.
- Agent는 masked envelope만 받는다.
- Agent의 모든 사용자 출력은 Gateway terminal egress로 돌아온다.
- Agent MCP Bridge는 handle-only stdio tools만 제공한다.
- 격리 또는 ingress/egress를 강제할 수 없으면 secure-gateway adapter로 인정하지 않는다.

## Capability model

```json
{
  "agent": "hermes",
  "supportsHeadlessInput": true,
  "supportsCompleteOutputCapture": true,
  "supportsStreamingBuffer": true,
  "supportsMcpStdio": true,
  "supportsOpenShellFullProcess": true,
  "supportsCoreRelay": true,
  "blocksDirectUserIngress": true,
  "blocksDirectProviderAccess": true
}
```

| Capability | 의미 |
|---|---|
| `supportsHeadlessInput` | Gateway가 masked envelope를 Agent의 유일한 입력으로 전달 가능 |
| `supportsCompleteOutputCapture` | Agent 출력이 사용자 전에 Gateway로 회수됨 |
| `supportsStreamingBuffer` | 불완전 marker를 사용자에게 직접 흘리지 않음 |
| `supportsMcpStdio` | sandbox 내부에서 Agent MCP Bridge 실행 가능 |
| `supportsOpenShellFullProcess` | 일부 tool이 아니라 Agent 전체가 sandbox 내부 실행 |
| `supportsCoreRelay` | Bridge가 agent-safe Core interface에만 연결 가능 |
| `blocksDirectUserIngress` | Agent 자체 TUI/webhook/raw input 우회가 없음 |
| `blocksDirectProviderAccess` | 승인된 inference route 외 provider 접속 차단 |

모든 필수 capability가 검증돼야 secure-gateway 모드를 사용할 수 있다.

## 실행 흐름

```text
User
  -> Gateway ingress
  -> PII policy + masking + Core Vault registration
  -> masked envelope
  -> OpenShell Hermes Agent
  -> Agent MCP Bridge (handle-only)
  -> unresolved Agent response
  -> Gateway egress + Reveal Policy
  -> terminal User sink
```

## OpenShell policy 요구사항

- filesystem hard requirement
- non-root Agent identity
- secret 없는 전용 workspace
- key/Vault/profile/reveal credential 미마운트
- deny-by-default network
- 승인된 inference route만 허용
- host-only/reveal Core channel 접근 차단
- sandbox enforcement 실패 시 Agent 시작 중단

## Adapter 설치 계약

Installer는 기본 dry-run이며 실제 변경은 명시적 apply에서만 수행한다. 설치 계획은 다음을
표시한다.

- 실행될 정확한 command와 argument
- OpenShell image/runtime/policy
- read-only/read-write workspace
- network allowlist와 inference route
- Agent MCP Bridge command
- Core relay 종류
- ingress/egress 강제 방식
- backup/rollback 절차
- 검증되지 않은 blocker

기존 설정을 수정하면 백업하고, secure-gateway 필수 capability가 하나라도 없으면 apply를 거부한다.

## Doctor 결과

| 검사 | 결과 |
|---|---|
| Gateway가 raw ingress를 단독 소유 | pass/fail |
| Agent 전체 OpenShell 격리 | pass/fail |
| key/Vault filesystem 차단 | pass/fail |
| direct provider/network 차단 | pass/fail |
| MCP Bridge가 handle-only | pass/fail |
| host-only/reveal channel 차단 | pass/fail |
| post-LLM output 완전 회수 | pass/fail |
| streaming marker buffer | pass/fail |
| canary 누출 회귀 테스트 | pass/fail |
| secure-gateway 주장 가능 | yes/no |

## 비지원 연결

Gateway 없이 Agent에 MCP Bridge만 등록하는 연결은 FHE-Privacy secure mode가 아니다. 초기
재설계에서는 이를 편의용 `tool-only` 제품 모드로 제공하지 않는다. 향후 diagnostic profile로
추가하더라도 LLM plaintext zero, Agent key isolation 또는 local reveal 보장을 주장하지 않는다.

## Reference adapter 정책

- 특정 Agent 이름을 Core에 하드코딩하지 않는다.
- Hermes reference adapter는 모든 필수 capability와 E2E canary 테스트를 통과한 뒤 지원됨으로 표시한다.
- OpenClaw는 현재 구현 및 검증 범위에 포함하지 않는다.
- Agent 업데이트로 hook/CLI/output behavior가 바뀌면 compatibility를 다시 검증한다.
